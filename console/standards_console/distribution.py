"""Pilot the ``distribute-standards`` workflow and surface its activity.

``check`` runs the workflow in dry-run (no PRs); ``apply`` runs it for real
(one PR per drifting repo). Recent runs and the open ``chore/sync-shared-standards``
PRs are read back so the UI reflects live state, never a cached guess.
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import Any

from .config import constants
from .github_gateway import GitHubGateway


@dataclass(frozen=True)
class RunSummary:
    status: str
    conclusion: str | None
    created_at: str
    html_url: str
    event: str


class DistributionController:
    def __init__(
        self,
        gateway: GitHubGateway,
        *,
        repo: str,
        workflow: str,
        ref: str,
    ) -> None:
        self._gw = gateway
        self._repo = repo
        self._workflow = workflow
        self._ref = ref

    def trigger(self, *, dry_run: bool, only: str = "") -> None:
        """Dispatch the workflow. ``dry_run=True`` is a check (no PRs)."""
        self._gw.dispatch_workflow(
            self._repo,
            self._workflow,
            ref=self._ref,
            inputs={"dry_run": "true" if dry_run else "false", "only": only},
        )

    def recent_runs(self, *, limit: int | None = None) -> list[RunSummary]:
        limit = limit or constants().distribution.default_run_limit
        runs = self._gw.list_workflow_runs(self._repo, self._workflow, limit=limit)
        return [
            RunSummary(
                status=r["status"],
                conclusion=r.get("conclusion"),
                created_at=r["created_at"],
                html_url=r["html_url"],
                event=r["event"],
            )
            for r in runs
        ]

    def open_sync_pulls(self) -> list[dict[str, Any]]:
        """Open sync PRs across the fleet are per-target-repo, so we read them
        from each target lazily via the caller; here we expose the source repo's
        own open sync PRs for quick visibility."""
        branch = constants().distribution.sync_pr_branch
        return self._gw.list_open_pulls(self._repo, head_branch=branch)
