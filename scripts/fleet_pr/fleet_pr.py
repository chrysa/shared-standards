"""Fleet-wide PR triage orchestrator.

Composes the gateway (I/O) and the pure classifier (decision). Reads only;
:meth:`merge_billing` is the sole writer, and only when ``execute`` is set it
squash-merges the BILLING bucket one PR at a time — never a public repo, a real
failure, a conflict, or a blocked PR.
"""

from __future__ import annotations

from collections import defaultdict

from scripts.fleet_pr.bucket import Bucket
from scripts.fleet_pr.classifier import classify_pr
from scripts.fleet_pr.gateway import GhError, GhGateway
from scripts.fleet_pr.pull_request import PullRequest

# Extra owner-adjacent orgs the fleet loop also covers, and repos it never touches.
EXTRA_OWNERS: tuple[str, ...] = ()
EXCLUDED_REPOS: frozenset[str] = frozenset(
    {"frogscollective", "Rural-Assistant-Integration-Nature", "aovim"}
)


class FleetPr:
    def __init__(self, gateway: GhGateway) -> None:
        self._gh = gateway
        self.errors: list[tuple[str, str]] = []

    def _build_pr(self, repo: str, visibility: str, raw: dict) -> PullRequest:
        merge_state = str(raw.get("mergeStateStatus", ""))
        steps: tuple[int, ...] = ()
        # Only UNSTABLE PRs need the (costly) job-step inspection to tell
        # billing from a real failure; every other state classifies directly.
        if merge_state == "UNSTABLE":
            steps = self._gh.failing_job_steps(repo, str(raw.get("headRefOid", "")))
        return PullRequest(
            repo=repo,
            number=int(raw["number"]),
            title=str(raw.get("title", "")),
            head_ref=str(raw.get("headRefName", "")),
            visibility=visibility,
            merge_state=merge_state,
            failing_job_steps=steps,
        )

    def triage(self, repos: list[str]) -> dict[Bucket, list[PullRequest]]:
        buckets: dict[Bucket, list[PullRequest]] = defaultdict(list)
        self.errors = []
        for repo in repos:
            if repo in EXCLUDED_REPOS:
                continue
            # A flaky GitHub response on one repo must not abort the whole fleet.
            try:
                visibility = self._gh.visibility(repo)
                for raw in self._gh.open_prs(repo):
                    pr = self._build_pr(repo, visibility, raw)
                    buckets[classify_pr(pr)].append(pr)
            except GhError as exc:
                self.errors.append((repo, str(exc)))
        return dict(buckets)

    def merge_billing(
        self, prs: list[PullRequest], *, execute: bool
    ) -> list[tuple[PullRequest, str]]:
        results: list[tuple[PullRequest, str]] = []
        for pr in prs:
            if classify_pr(pr) is not Bucket.BILLING:
                # Defence in depth: never merge anything not re-confirmed BILLING.
                results.append((pr, "skipped: not billing"))
                continue
            if not execute:
                results.append((pr, "would merge (dry-run)"))
                continue
            try:
                self._gh.merge_squash(pr.repo, pr.number)
                results.append((pr, "merged"))
            except GhError as exc:
                results.append((pr, f"error: {exc}"))
        return results
