"""Tests for the pruning of deprecated chrysa/pre-commit-tools hooks in pre-commit-merge.py."""

from __future__ import annotations

import importlib.util
from pathlib import Path

_SCRIPT = Path(__file__).resolve().parents[1] / "scripts" / "pre-commit-merge.py"
_URL = "https://github.com/chrysa/pre-commit-tools"


def _load():
    spec = importlib.util.spec_from_file_location("pre_commit_merge", _SCRIPT)
    assert spec and spec.loader
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


M = _load()


def _target(*ids: str) -> dict:
    return {"repos": [{"repo": _URL, "rev": "v0.2.0-253", "hooks": [{"id": i} for i in ids]}]}


def test_deprecated_ids_are_no_longer_governed() -> None:
    assert not set(M.DEPRECATED_HOOK_IDS) & M.GOVERNED
    assert not set(M.DEPRECATED_HOOK_IDS) & M.EXCLUDE_ALIGNED_IDS


def test_check_reports_deprecated_hook_as_drift() -> None:
    gaps = M.missing_items({"repos": []}, _target("python-pprint-detection"), set())
    assert f"{_URL}#python-pprint-detection!deprecated" in gaps


def test_merge_prunes_deprecated_and_keeps_the_rest() -> None:
    merged = M.merge({"repos": []}, _target("python-pprint-detection", "adr-gate"), set())
    assert [h["id"] for h in merged["repos"][0]["hooks"]] == ["adr-gate"]


def test_merge_drops_repo_left_without_hooks() -> None:
    merged = M.merge({"repos": []}, _target("no-bare-except", "dockerfile-no-latest"), set())
    assert merged["repos"] == []


def test_other_repos_are_never_pruned() -> None:
    target = {"repos": [{"repo": "local", "hooks": [{"id": "python-pprint-detection"}]}]}
    merged = M.merge({"repos": []}, target, set())
    assert merged["repos"][0]["hooks"] == [{"id": "python-pprint-detection"}]


def test_describe_actions_counts_removals() -> None:
    assert M.describe_actions([f"{_URL}#no-bare-except!deprecated"]) == "removed 1 deprecated hook(s)"


def test_merge_is_idempotent_after_pruning() -> None:
    merged = M.merge({"repos": []}, _target("python-pprint-detection", "adr-gate"), set())
    gaps = M.missing_items({"repos": []}, merged, set())
    assert not [gap for gap in gaps if gap.endswith("!deprecated")]


def test_print_hook_stays_governed_until_t201_is_armed() -> None:
    assert "python-print-detection" not in M.DEPRECATED_HOOK_IDS
    assert "python-print-detection" in M.HOOK_GROUPS["python"]
