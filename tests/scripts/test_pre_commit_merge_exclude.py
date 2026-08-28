"""Tests for pre-commit-merge's distributed-canonical exclude (shared-standards#469).

A consumer that runs an autofixer (ruff-format single quotes, add-trailing-comma,
auto-walrus) rewrites a distributed canonical (scripts/quality_gate.py) on every touch and
drifts the managed copy from its source. The merge must OR-append a top-level exclude, and
--check must report the gap so exposed repos are flagged.

pre-commit-merge.py carries a hyphen, so it is loaded by path rather than imported.
"""

from __future__ import annotations

import importlib.util
from pathlib import Path

_MODULE_PATH = Path(__file__).resolve().parents[2] / "scripts" / "pre-commit-merge.py"
_spec = importlib.util.spec_from_file_location("pre_commit_merge", _MODULE_PATH)
assert _spec and _spec.loader
pcm = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(pcm)

_RUFF = {"repo": "https://github.com/astral-sh/ruff-pre-commit", "hooks": [{"id": "ruff-format"}]}
_PLAIN = {"repo": "https://github.com/pre-commit/pre-commit-hooks", "hooks": [{"id": "end-of-file-fixer"}]}


class TestCanonicalExclude:
    def test_autofixer_without_exclude_is_a_gap(self) -> None:
        target = {"repos": [_RUFF]}
        assert "top-level!exclude" in pcm.missing_items({"repos": []}, target, set())

    def test_no_autofixer_is_not_a_gap(self) -> None:
        target = {"repos": [_PLAIN]}
        assert "top-level!exclude" not in pcm.missing_items({"repos": []}, target, set())

    def test_existing_exclude_covering_canonical_is_not_a_gap(self) -> None:
        target = {"exclude": r"^(\.claude/|scripts/quality_gate\.py$)", "repos": [_RUFF]}
        assert "top-level!exclude" not in pcm.missing_items({"repos": []}, target, set())

    def test_ensure_adds_exclude_when_absent(self) -> None:
        target = {"repos": [_RUFF]}
        pcm.ensure_canonical_exclude(target)
        assert "quality_gate" in target["exclude"]

    def test_ensure_preserves_existing_exclude(self) -> None:
        target = {"exclude": r"^\.claude/", "repos": [_RUFF]}
        pcm.ensure_canonical_exclude(target)
        assert r"\.claude/" in target["exclude"]
        assert "quality_gate" in target["exclude"]

    def test_ensure_is_idempotent(self) -> None:
        target = {"repos": [_RUFF]}
        pcm.ensure_canonical_exclude(target)
        once = target["exclude"]
        pcm.ensure_canonical_exclude(target)
        assert target["exclude"] == once

    def test_ensure_noop_without_autofixer(self) -> None:
        target = {"repos": [_PLAIN]}
        pcm.ensure_canonical_exclude(target)
        assert "exclude" not in target

    def test_merge_applies_exclude_end_to_end(self) -> None:
        target = {"repos": [dict(_RUFF)]}
        merged = pcm.merge({"repos": []}, target, set())
        assert "quality_gate" in merged["exclude"]
