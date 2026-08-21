"""The pure triage decision: a PullRequest -> a Bucket.

Kept free of I/O so it can be exhaustively unit-tested. The safety property
is one-directional: nothing but a *private* repo whose failing jobs are *all*
0-step (startup_failure) may ever be called BILLING. Any doubt resolves to
REAL_RED so a human looks at it.
"""

from __future__ import annotations

from scripts.fleet_pr.bucket import Bucket
from scripts.fleet_pr.pull_request import PullRequest

_DIRECT_STATES: dict[str, Bucket] = {
    "DIRTY": Bucket.DIRTY,
    "BLOCKED": Bucket.BLOCKED,
    "CLEAN": Bucket.CLEAN,
}


def _is_billing(pr: PullRequest) -> bool:
    if pr.visibility != "PRIVATE":
        return False
    if not pr.failing_job_steps:
        # No observed failing job -> cannot confirm the startup_failure signature.
        return False
    return all(steps == 0 for steps in pr.failing_job_steps)


def classify_pr(pr: PullRequest) -> Bucket:
    direct = _DIRECT_STATES.get(pr.merge_state)
    if direct is not None:
        return direct
    if pr.merge_state == "UNSTABLE" and _is_billing(pr):
        return Bucket.BILLING
    return Bucket.REAL_RED
