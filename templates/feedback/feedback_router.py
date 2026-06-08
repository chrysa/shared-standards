"""In-app bug report → feedback-gateway proxy router (chrysa canonical template).

Drop this into any chrysa FastAPI backend so the app's frontend can POST a bug
report to its OWN backend, which forwards it server-side to feedback-gateway.
feedback-gateway holds the single GitHub credential and creates the issue on the
app's repo. The app key selects the repo and never reaches the browser bundle.

Wiring (mirror the app's existing router-include style):

    from app.routers.feedback import create_feedback_router

    app.include_router(
        create_feedback_router(
            settings.feedback_gateway_url,
            settings.feedback_app_key,
        ),
        prefix=API_PREFIX,
    )

Add to the app's Settings (pydantic-settings):

    feedback_gateway_url: str = ""   # e.g. http://feedback-gateway:8000
    feedback_app_key: str = ""       # this app's opaque key (server-side only)

Requires `httpx` (already a chrysa backend dependency).
"""

from __future__ import annotations

import httpx
from fastapi import APIRouter, HTTPException, status
from pydantic import BaseModel, Field

# Mirror of feedback-gateway/app/schemas.py. Keep in sync if the gateway evolves.
_MAX_TITLE_LEN = 160
_MAX_TEXT_LEN = 8000
_MAX_CONSOLE_LINES = 50
_APP_KEY_HEADER = "X-Feedback-Key"


class EnvironmentInfo(BaseModel):
    """Client-captured context, auto-filled by the frontend."""

    url: str = Field(default="", max_length=2048)
    user_agent: str = Field(default="", max_length=512)
    app_version: str = Field(default="", max_length=64)
    console_tail: list[str] = Field(default_factory=list, max_length=_MAX_CONSOLE_LINES)


class FeedbackRequest(BaseModel):
    """A bug report submitted by the app frontend.

    ``website`` is a honeypot — real clients leave it empty; forwarded unchanged
    so the gateway can silently drop bot submissions.
    """

    title: str = Field(min_length=3, max_length=_MAX_TITLE_LEN)
    description: str = Field(min_length=1, max_length=_MAX_TEXT_LEN)
    severity: str = "Medium"
    steps: str = Field(default="", max_length=_MAX_TEXT_LEN)
    expected: str = Field(default="", max_length=_MAX_TEXT_LEN)
    actual: str = Field(default="", max_length=_MAX_TEXT_LEN)
    environment: EnvironmentInfo = Field(default_factory=EnvironmentInfo)
    reporter: str | None = Field(default=None, max_length=256)
    website: str = Field(default="", max_length=256)  # honeypot


class FeedbackResponse(BaseModel):
    issue_number: int
    issue_url: str
    deduplicated: bool
    links: dict[str, str] = Field(default_factory=dict)


def create_feedback_router(gateway_url: str, app_key: str) -> APIRouter:
    """Build a ``POST /feedback`` router that proxies reports to feedback-gateway.

    ``gateway_url`` / ``app_key`` come from the app's server-side settings and are
    never exposed to the browser. When unset the endpoint returns 503 so the UI
    degrades gracefully.
    """
    router = APIRouter(tags=["feedback"])

    @router.post("/feedback", response_model=FeedbackResponse, summary="Report a bug")
    async def submit_feedback(report: FeedbackRequest) -> FeedbackResponse:
        if not gateway_url or not app_key:
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="Feedback gateway is not configured.",
            )
        try:
            async with httpx.AsyncClient(timeout=10.0) as client:
                resp = await client.post(
                    f"{gateway_url.rstrip('/')}/v1/reports",
                    json=report.model_dump(),
                    headers={_APP_KEY_HEADER: app_key},
                )
        except httpx.HTTPError as exc:
            raise HTTPException(
                status_code=status.HTTP_502_BAD_GATEWAY,
                detail="Could not reach the feedback gateway.",
            ) from exc

        if resp.status_code >= status.HTTP_400_BAD_REQUEST:
            raise HTTPException(
                status_code=status.HTTP_502_BAD_GATEWAY,
                detail=f"Feedback gateway error ({resp.status_code}).",
            )
        data = resp.json()
        return FeedbackResponse(
            issue_number=data["issue_number"],
            issue_url=data["issue_url"],
            deduplicated=data["deduplicated"],
            links={"issue": data["issue_url"]},
        )

    return router
