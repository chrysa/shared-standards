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


_RUFF = {"repo": "https://github.com/astral-sh/ruff-pre-commit", "hooks": [{"id": "ruff-check"}]}
_HADOLINT = {"repo": "https://github.com/hadolint/hadolint", "hooks": [{"id": "hadolint-docker"}]}


def _policy(tmp_path: Path, pyproject: str | None, *extra_repos: dict):
    if pyproject is not None:
        (tmp_path / "pyproject.toml").write_text(pyproject, encoding="utf-8")
    target = _target("debugger-detection", "no-bare-except", "dockerfile-no-latest")
    target["repos"].extend(extra_repos)
    return M.replacement_policy(tmp_path, {"repos": []}, target), target


def test_hook_kept_when_replacement_code_not_selected(tmp_path: Path) -> None:
    can_prune, target = _policy(tmp_path, '[tool.ruff.lint]\nselect = ["E", "F"]\n', _RUFF)
    assert not can_prune("debugger-detection")
    assert can_prune("no-bare-except")  # E722 is covered by "E"
    merged = M.merge({"repos": []}, target, set(), can_prune)
    ids = [h["id"] for h in merged["repos"][0]["hooks"]]
    assert "debugger-detection" in ids and "no-bare-except" not in ids


def test_hook_kept_when_code_is_ignored(tmp_path: Path) -> None:
    can_prune, _ = _policy(
        tmp_path, '[tool.ruff.lint]\nextend-select = ["T10"]\nignore = ["T100"]\n', _RUFF
    )
    assert not can_prune("debugger-detection")


def test_more_specific_select_beats_broad_ignore(tmp_path: Path) -> None:
    can_prune, _ = _policy(
        tmp_path, '[tool.ruff.lint]\nextend-select = ["T100"]\nignore = ["T"]\n', _RUFF
    )
    assert can_prune("debugger-detection")


def test_hook_kept_without_pyproject(tmp_path: Path) -> None:
    can_prune, _ = _policy(tmp_path, None, _RUFF)
    assert not can_prune("no-bare-except")


def test_hook_kept_without_ruff_hook(tmp_path: Path) -> None:
    can_prune, _ = _policy(tmp_path, '[tool.ruff.lint]\nselect = ["ALL"]\n')
    assert not can_prune("no-bare-except")


def test_hook_kept_on_invalid_pyproject(tmp_path: Path) -> None:
    can_prune, _ = _policy(tmp_path, "[tool.ruff.lint\nselect = [", _RUFF)
    assert not can_prune("no-bare-except")


def test_nested_pyproject_must_also_arm_the_code(tmp_path: Path) -> None:
    (tmp_path / "backend").mkdir()
    (tmp_path / "backend" / "pyproject.toml").write_text(
        '[tool.ruff.lint]\nselect = ["F"]\n', encoding="utf-8"
    )
    can_prune, _ = _policy(tmp_path, '[tool.ruff.lint]\nselect = ["ALL"]\n', _RUFF)
    assert not can_prune("no-bare-except")


def test_dockerfile_hook_needs_hadolint(tmp_path: Path) -> None:
    without, _ = _policy(tmp_path, None)
    with_hadolint, _ = _policy(tmp_path, None, _HADOLINT)
    assert not without("dockerfile-no-latest")
    assert with_hadolint("dockerfile-no-latest")


def test_check_does_not_report_unprunable_hook_as_drift(tmp_path: Path) -> None:
    can_prune, target = _policy(tmp_path, '[tool.ruff.lint]\nselect = ["F"]\n', _RUFF)
    gaps = M.missing_items({"repos": []}, target, set(), can_prune)
    assert not [g for g in gaps if g.endswith("!deprecated")]
