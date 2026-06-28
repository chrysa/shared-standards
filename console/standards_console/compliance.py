"""Read fleet compliance from the hosted guideline-checker central server.

This is the *hosted read* half of the hybrid model. When no central server is
configured (or it is unreachable) the console degrades gracefully: it reports
the absence loudly in the UI rather than pretending the fleet is compliant.
"""

from __future__ import annotations

from dataclasses import dataclass

import httpx

from .config import constants


@dataclass(frozen=True)
class ComplianceSnapshot:
    repo: str
    errors: int
    warnings: int
    updated_at: str


class ComplianceClient:
    def __init__(self, base_url: str | None, api_key: str | None) -> None:
        self._base_url = base_url.rstrip("/") if base_url else None
        self._api_key = api_key

    @property
    def configured(self) -> bool:
        return self._base_url is not None

    def fetch(self) -> list[ComplianceSnapshot]:
        """Return per-repo compliance, or ``[]`` if no server is configured.

        Network/HTTP failures raise :class:`ComplianceUnavailable` so the caller
        can show an explicit banner instead of a silent empty table.
        """
        if not self._base_url:
            return []
        cfg = constants().compliance
        headers = {"X-Api-Key": self._api_key} if self._api_key else {}
        try:
            resp = httpx.get(
                f"{self._base_url}{cfg.repos_endpoint}",
                headers=headers,
                timeout=cfg.request_timeout_seconds,
            )
            resp.raise_for_status()
        except httpx.HTTPError as exc:
            raise ComplianceUnavailable(str(exc)) from exc
        return [
            ComplianceSnapshot(
                repo=item["repo"],
                errors=int(item.get("errors", 0)),
                warnings=int(item.get("warnings", 0)),
                updated_at=str(item.get("updated_at", "")),
            )
            for item in resp.json()
        ]


class ComplianceUnavailable(RuntimeError):
    """The configured central server could not be reached."""
