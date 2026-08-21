"""Tests for the fleet-pr PR classifier — the pure decision core.

The classifier is the single source of truth for what `fleet-pr` may merge.
It must never route a public repo or a real (steps>0) failure into the
mergeable BILLING bucket; those are genuine failures a human must handle.
"""

from __future__ import annotations

import pytest

from scripts.fleet_pr.bucket import Bucket
from scripts.fleet_pr.classifier import classify_pr
from scripts.fleet_pr.pull_request import PullRequest


def _pr(
    *,
    visibility: str = "PRIVATE",
    merge_state: str = "UNSTABLE",
    failing_job_steps: tuple[int, ...] = (),
) -> PullRequest:
    return PullRequest(
        repo="acme",
        number=1,
        title="bump x",
        head_ref="dependabot/npm_and_yarn/x",
        visibility=visibility,
        merge_state=merge_state,
        failing_job_steps=failing_job_steps,
    )


def test_dirty_is_reported_never_merged() -> None:
    assert classify_pr(_pr(merge_state="DIRTY")) is Bucket.DIRTY


def test_blocked_is_reported_never_merged() -> None:
    assert classify_pr(_pr(merge_state="BLOCKED")) is Bucket.BLOCKED


def test_clean_green_pr_is_its_own_bucket() -> None:
    assert classify_pr(_pr(merge_state="CLEAN")) is Bucket.CLEAN


def test_private_unstable_with_only_zero_step_jobs_is_billing() -> None:
    # startup_failure signature: private repo, jobs never started (0 steps).
    assert classify_pr(_pr(failing_job_steps=(0, 0))) is Bucket.BILLING


def test_private_unstable_with_a_real_failing_step_is_real_red() -> None:
    # One job actually ran and failed -> genuine failure, do NOT merge.
    assert classify_pr(_pr(failing_job_steps=(0, 9))) is Bucket.REAL_RED


def test_public_unstable_is_never_billing() -> None:
    # Public repos are not billing-throttled: their red is real.
    assert classify_pr(_pr(visibility="PUBLIC", failing_job_steps=(0,))) is Bucket.REAL_RED


def test_private_unstable_without_observed_jobs_is_conservatively_real_red() -> None:
    # Cannot confirm the startup_failure signature -> refuse to call it billing.
    assert classify_pr(_pr(failing_job_steps=())) is Bucket.REAL_RED


@pytest.mark.parametrize("state", ["UNKNOWN", "DRAFT", "BEHIND", ""])
def test_unrecognised_state_is_conservatively_real_red(state: str) -> None:
    assert classify_pr(_pr(merge_state=state)) is Bucket.REAL_RED
