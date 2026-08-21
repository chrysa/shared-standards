"""Orchestrator tests: triage routing and the merge safety envelope.

Uses a hand-rolled fake gateway (no network). The load-bearing assertions:
merge_billing only ever squash-merges the BILLING bucket, and only when
``execute`` is set.
"""

from __future__ import annotations

from scripts.fleet_pr.bucket import Bucket
from scripts.fleet_pr.fleet_pr import FleetPr
from scripts.fleet_pr.gateway import GhError


class FakeGh:
    def __init__(self, *, visibilities: dict[str, str], prs: dict[str, list[dict]],
                 steps: dict[tuple[str, str], tuple[int, ...]]) -> None:
        self._vis = visibilities
        self._prs = prs
        self._steps = steps
        self.merged: list[tuple[str, int]] = []

    def visibility(self, repo: str) -> str:
        return self._vis[repo]

    def open_prs(self, repo: str) -> list[dict]:
        return self._prs.get(repo, [])

    def failing_job_steps(self, repo: str, head_sha: str) -> tuple[int, ...]:
        return self._steps.get((repo, head_sha), ())

    def merge_squash(self, repo: str, number: int) -> None:
        self.merged.append((repo, number))


def _raw(number: int, state: str, sha: str = "sha", ref: str = "dependabot/x") -> dict:
    return {"number": number, "title": "t", "headRefName": ref,
            "headRefOid": sha, "mergeStateStatus": state}


def _fleet() -> tuple[FleetPr, FakeGh]:
    gh = FakeGh(
        visibilities={"priv": "PRIVATE", "pub": "PUBLIC"},
        prs={
            "priv": [_raw(1, "UNSTABLE", "s1"), _raw(2, "DIRTY"), _raw(3, "UNSTABLE", "s3")],
            "pub": [_raw(9, "UNSTABLE", "s9")],
        },
        steps={
            ("priv", "s1"): (0, 0),   # billing
            ("priv", "s3"): (0, 7),   # real failure
            ("pub", "s9"): (0,),      # public -> real
        },
    )
    return FleetPr(gh), gh


def test_triage_routes_each_pr_to_the_right_bucket() -> None:
    fleet, _ = _fleet()
    buckets = fleet.triage(["priv", "pub"])
    assert [pr.number for pr in buckets[Bucket.BILLING]] == [1]
    assert [pr.number for pr in buckets[Bucket.DIRTY]] == [2]
    assert sorted(pr.number for pr in buckets[Bucket.REAL_RED]) == [3, 9]


def test_excluded_repos_are_never_scanned() -> None:
    fleet, _ = _fleet()
    buckets = fleet.triage(["priv", "frogscollective"])
    assert all(pr.repo != "frogscollective" for prs in buckets.values() for pr in prs)


def test_merge_billing_dry_run_does_not_merge() -> None:
    fleet, gh = _fleet()
    billing = fleet.triage(["priv", "pub"])[Bucket.BILLING]
    results = fleet.merge_billing(billing, execute=False)
    assert gh.merged == []
    assert results[0][1] == "would merge (dry-run)"


def test_flaky_repo_is_recorded_and_does_not_abort_the_fleet() -> None:
    fleet, gh = _fleet()

    def boom(repo: str) -> str:
        raise GhError("Could not resolve to a Repository")

    gh.visibility = boom  # type: ignore[method-assign]  # 'priv' now blows up
    buckets = fleet.triage(["priv"])
    assert buckets == {}
    assert fleet.errors == [("priv", "Could not resolve to a Repository")]


def test_merge_billing_execute_merges_only_billing() -> None:
    fleet, gh = _fleet()
    buckets = fleet.triage(["priv", "pub"])
    # Feed the WHOLE fleet, not just the billing bucket: the envelope must
    # still refuse everything that is not billing.
    everything = [pr for prs in buckets.values() for pr in prs]
    fleet.merge_billing(everything, execute=True)
    assert gh.merged == [("priv", 1)]
