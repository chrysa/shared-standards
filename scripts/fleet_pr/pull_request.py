"""The typed view of a pull request that the classifier reasons about."""

from __future__ import annotations

from dataclasses import dataclass, field


@dataclass(frozen=True)
class PullRequest:
    """A fleet PR reduced to exactly what triage needs.

    ``failing_job_steps`` holds the step count of each **failing** CI job
    (from ``gh run view --json jobs``). A count of ``0`` means the job never
    started (``startup_failure``) — the billing signature; a count ``> 0``
    means a step really ran and failed.
    """

    repo: str
    number: int
    title: str
    head_ref: str
    visibility: str  # "PUBLIC" | "PRIVATE"
    merge_state: str  # GitHub mergeStateStatus: CLEAN|UNSTABLE|BLOCKED|DIRTY|...
    failing_job_steps: tuple[int, ...] = field(default=())

    @property
    def is_dependabot(self) -> bool:
        return self.head_ref.startswith("dependabot/")
