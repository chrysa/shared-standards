"""FastAPI JSON API behind the React SPA.

Every route handler is a top-level function (chrysa "no nested functions" rule),
wired through the :func:`get_services` dependency. Domain errors are translated
to HTTP responses by exception handlers rather than per-route try/except, so the
handlers stay tiny and never swallow a failure silently.
"""

from __future__ import annotations

from datetime import UTC, datetime
from pathlib import Path

from fastapi import APIRouter, Depends, FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.staticfiles import StaticFiles

from . import manifest
from .config import constants
from .github_gateway import GitHubError
from .manifest import ManifestError
from .schemas import (
    DistributionResponse,
    DistributionRun,
    FleetResponse,
    Meta,
    Ok,
    PullInfo,
    RunInfo,
    StandardDoc,
    StandardEditRequest,
    StandardEditResponse,
    StatusUpdate,
)
from .services import Services
from .views import assemble_fleet

router = APIRouter(prefix="/api")

# Vite dev server origins allowed to call the local API during development.
_DEV_ORIGINS = ["http://localhost:5173", "http://127.0.0.1:5173"]  # no-hardcoded-localhost: disable — dev CORS origins


def get_services(request: Request) -> Services:
    return request.app.state.services


def _github_error_handler(_: Request, exc: GitHubError) -> JSONResponse:
    return JSONResponse(status_code=502, content={"detail": str(exc)})


def _manifest_error_handler(_: Request, exc: ManifestError) -> JSONResponse:
    return JSONResponse(status_code=400, content={"detail": str(exc)})


@router.get("/health", response_model=dict[str, str])
def health() -> dict[str, str]:
    return {"status": "ok"}


@router.get("/meta", response_model=Meta)
def meta(services: Services = Depends(get_services)) -> Meta:
    return Meta(
        standards_full_name=services.settings.standards_full_name,
        branch=services.settings.standards_branch,
        valid_status=list(manifest.valid_status()),
        valid_runtime=list(manifest.valid_runtime()),
        central_configured=services.compliance.configured,
    )


@router.get("/fleet", response_model=FleetResponse)
def fleet(services: Services = Depends(get_services)) -> FleetResponse:
    return assemble_fleet(services)


@router.post("/repos/{name}/status", response_model=Ok)
def update_status(
    name: str, body: StatusUpdate, services: Services = Depends(get_services)
) -> Ok:
    text, sha = services.read_manifest_text()
    new_text = manifest.set_fields(text, name, status=body.status)
    services.commit_manifest(
        text=new_text, sha=sha, message=f"chore(repos): set {name} status={body.status}"
    )
    return Ok(message=f"{name} → {body.status}")


@router.get("/distribution", response_model=DistributionResponse)
def distribution(services: Services = Depends(get_services)) -> DistributionResponse:
    runs = [RunInfo(**r.__dict__) for r in services.distribution.recent_runs()]
    pulls = [
        PullInfo(number=p["number"], title=p["title"], html_url=p["html_url"])
        for p in services.distribution.open_sync_pulls()
    ]
    return DistributionResponse(runs=runs, pulls=pulls)


@router.post("/distribution/run", response_model=Ok)
def run_distribution(
    body: DistributionRun, services: Services = Depends(get_services)
) -> Ok:
    services.distribution.trigger(dry_run=(body.mode == "check"), only=body.only.strip())
    label = "check (dry-run)" if body.mode == "check" else "apply"
    return Ok(message=f"Distribution {label} dispatched.")


@router.get("/standard", response_model=StandardDoc)
def standard(services: Services = Depends(get_services)) -> StandardDoc:
    path = services.settings.standard_path
    return StandardDoc(path=path, text=services.standard.read(path))


@router.post("/standard", response_model=StandardEditResponse)
def edit_standard(
    body: StandardEditRequest, services: Services = Depends(get_services)
) -> StandardEditResponse:
    branch_id = datetime.now(UTC).strftime("%Y%m%d-%H%M%S")
    edit = services.standard.propose_edit(
        services.settings.standard_path,
        new_text=body.content,
        summary=body.summary or "update standard",
        branch_id=branch_id,
    )
    return StandardEditResponse(pr_number=edit.pr_number, pr_url=edit.pr_url, branch=edit.branch)


def create_app(services: Services) -> FastAPI:
    app = FastAPI(title="chrysa standards console")
    app.state.services = services
    app.add_middleware(
        CORSMiddleware,
        allow_origins=_DEV_ORIGINS,
        allow_methods=["*"],
        allow_headers=["*"],
    )
    app.add_exception_handler(GitHubError, _github_error_handler)  # type: ignore[arg-type]
    app.add_exception_handler(ManifestError, _manifest_error_handler)  # type: ignore[arg-type]
    app.include_router(router)

    # Serve the built SPA in production when present (dev uses the Vite server).
    dist = Path(__file__).parent / "web_dist"
    if dist.is_dir():
        app.mount("/", StaticFiles(directory=str(dist), html=True), name="spa")
    return app


def main() -> None:  # pragma: no cover - thin runtime entrypoint
    import uvicorn

    from .config import Settings

    settings = Settings()
    uvicorn.run(create_app(Services.build(settings)), host=settings.host, port=settings.port)


# Touch the constants loader at import so misconfiguration fails fast, loudly.
_ = constants
