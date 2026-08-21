"""Classification buckets for open pull requests across the fleet."""

from __future__ import annotations

from enum import Enum


class Bucket(Enum):
    """Where a PR lands after triage.

    Only ``BILLING`` is ever merged by ``fleet-pr --merge``; every other
    bucket is report-only and left to a human.
    """

    BILLING = "billing"  # private + startup_failure (Actions quota) -> safe to force-merge
    REAL_RED = "real_red"  # genuine failing CI (public, or a step actually ran and failed)
    DIRTY = "dirty"  # merge conflicts -> manual rebase
    BLOCKED = "blocked"  # required review/checks -> owner unblock
    CLEAN = "clean"  # green and mergeable
