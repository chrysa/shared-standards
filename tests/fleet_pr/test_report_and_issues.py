from __future__ import annotations

import pytest

from scripts.fleet_pr.bucket import Bucket
from scripts.fleet_pr.issues import classify_issue
from scripts.fleet_pr.pull_request import PullRequest
from scripts.fleet_pr.report import render


def _pr(repo: str, number: int) -> PullRequest:
    return PullRequest(
        repo=repo, number=number, title="t", head_ref="dependabot/x",
        visibility="PRIVATE", merge_state="UNSTABLE", failing_job_steps=(0,),
    )


def test_report_lists_billing_first_and_counts_total() -> None:
    out = render({Bucket.BILLING: [_pr("a", 1)], Bucket.DIRTY: [_pr("b", 2)]})
    assert "2 open PR(s)" in out
    assert out.index("BILLING") < out.index("DIRTY")
    assert "a#1" in out and "b#2" in out


def test_empty_report_renders_header_only() -> None:
    assert render({}).startswith("# fleet-pr triage — 0 open PR(s)")


@pytest.mark.parametrize(
    ("labels", "expected"),
    [
        (["bug", "veille"], "bug"),  # bug wins over veille
        (["veille"], "veille"),
        (["enhancement"], "backlog"),
        (["Bug"], "bug"),  # case-insensitive
        ([], "other"),
    ],
)
def test_classify_issue(labels: list[str], expected: str) -> None:
    assert classify_issue(labels) == expected
