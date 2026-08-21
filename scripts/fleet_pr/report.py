"""Render a triage result to a human-readable text report."""

from __future__ import annotations

from scripts.fleet_pr.bucket import Bucket
from scripts.fleet_pr.pull_request import PullRequest

_ACTION: dict[Bucket, str] = {
    Bucket.BILLING: "mergeable (billing) -> fleet-pr --merge",
    Bucket.REAL_RED: "genuine CI failure -> fix",
    Bucket.DIRTY: "merge conflict -> manual rebase",
    Bucket.BLOCKED: "review/checks required -> owner unblock",
    Bucket.CLEAN: "green -> merge at will",
}
_ORDER: tuple[Bucket, ...] = (
    Bucket.BILLING, Bucket.CLEAN, Bucket.DIRTY, Bucket.BLOCKED, Bucket.REAL_RED,
)


def render(buckets: dict[Bucket, list[PullRequest]]) -> str:
    total = sum(len(prs) for prs in buckets.values())
    lines = [f"# fleet-pr triage — {total} open PR(s)", ""]
    for bucket in _ORDER:
        prs = buckets.get(bucket, [])
        if not prs:
            continue
        lines.append(f"## {bucket.value.upper()} ({len(prs)}) — {_ACTION[bucket]}")
        for pr in sorted(prs, key=lambda p: (p.repo, p.number)):
            lines.append(f"  {pr.repo}#{pr.number}  [{pr.head_ref}]  {pr.title}")
        lines.append("")
    return "\n".join(lines).rstrip() + "\n"
