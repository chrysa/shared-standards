"""Tests for the top-level canonical `exclude` management in pre-commit-merge.py.

Distributed canonicals (scripts/quality_gate.py, .claude/ape/) must be skipped by a
consumer's autofixers or the managed copy drifts from source (shared-standards#469).
The distributor guarantees a top-level `exclude` covering them, unioned into whatever
the repo already has, idempotently. Hyphenated filename → loaded by path.
"""

from __future__ import annotations

import importlib.util
from pathlib import Path

_SCRIPT = Path(__file__).resolve().parents[1] / "scripts" / "pre-commit-merge.py"


def _load():
    spec = importlib.util.spec_from_file_location("pcm", _SCRIPT)
    assert spec and spec.loader
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


M = _load()


def test_sets_exclude_when_absent() -> None:
    target: dict = {"repos": []}
    M.ensure_top_level_exclude(target)
    for pattern in M.CANONICAL_EXCLUDE_PATTERNS:
        assert pattern in target["exclude"]


def test_extends_existing_exclude_keeping_it() -> None:
    target = {"repos": [], "exclude": "^docs/"}
    M.ensure_top_level_exclude(target)
    assert target["exclude"].startswith("^docs/")  # repo's own pattern preserved
    for pattern in M.CANONICAL_EXCLUDE_PATTERNS:
        assert pattern in target["exclude"]


def test_is_idempotent() -> None:
    target = {"repos": [], "exclude": "^docs/"}
    M.ensure_top_level_exclude(target)
    once = target["exclude"]
    M.ensure_top_level_exclude(target)
    assert target["exclude"] == once
    assert M._exclude_gaps(target) == []


def test_partial_exclude_only_adds_the_missing_fragment() -> None:
    # Already carries the quality_gate pattern; only the .claude/ape one is missing.
    target = {"repos": [], "exclude": r"(^|/)quality_gate\.py$"}
    gaps = M._exclude_gaps(target)
    assert gaps == [r"^\.claude/ape/"]
    M.ensure_top_level_exclude(target)
    assert target["exclude"].count(r"quality_gate\.py") == 1  # not duplicated


def test_missing_items_reports_exclude_gaps() -> None:
    baseline = {"repos": []}
    target = {"repos": []}
    gaps = M.missing_items(baseline, target, set(M.HOOK_GROUPS))
    assert f"exclude:{M.CANONICAL_EXCLUDE_PATTERNS[0]}" in gaps
