"""Tests for the baseline Ruff hook and the canonical install hook types.

The baseline ships `ruff-check` and `ruff-format` (python stack). A repo that already
runs Ruff under the legacy `ruff` id, or as a `repo: local` hook, must not get a second
copy. `default_install_hook_types` gains `commit-msg` and `pre-push` so a plain
`pre-commit install` sets up the conventional-commit and regression gates.
Hyphenated filename → loaded by path.
"""

from __future__ import annotations

import importlib.util
from pathlib import Path

_SCRIPT = Path(__file__).resolve().parents[1] / "scripts" / "pre-commit-merge.py"
_BASELINE = Path(__file__).resolve().parents[1] / ".pre-commit-config.yaml"
RUFF = "https://github.com/astral-sh/ruff-pre-commit"


def _load():
    spec = importlib.util.spec_from_file_location("pcm", _SCRIPT)
    assert spec and spec.loader
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


M = _load()


def _baseline() -> dict:
    return {
        "repos": [
            {
                "repo": RUFF,
                "rev": "v0.17.4",
                "hooks": [
                    {"id": "ruff-check", "args": ["--fix"]},
                    {"id": "ruff-format"},
                ],
            }
        ],
        "default_install_hook_types": list(M.CANONICAL_INSTALL_HOOK_TYPES),
    }


def _ruff_ids(target: dict) -> list[str]:
    return [
        hook["id"]
        for repo in target["repos"]
        for hook in repo.get("hooks", [])
        if hook["id"].startswith("ruff")
    ]


def test_adds_ruff_hooks_to_a_python_repo_without_them() -> None:
    merged = M.merge(_baseline(), {"repos": []}, M.enforced_ids({"python"}))
    assert _ruff_ids(merged) == ["ruff-check", "ruff-format"]


def test_skips_ruff_hooks_outside_the_python_stack() -> None:
    merged = M.merge(_baseline(), {"repos": []}, M.enforced_ids({"docker"}))
    assert _ruff_ids(merged) == []


def test_legacy_ruff_id_satisfies_ruff_check() -> None:
    target = {
        "repos": [
            {
                "repo": RUFF,
                "rev": "v0.6.9",
                "hooks": [{"id": "ruff"}, {"id": "ruff-format"}],
            }
        ]
    }
    merged = M.merge(_baseline(), target, M.enforced_ids({"python"}))
    assert _ruff_ids(merged) == ["ruff", "ruff-format"]
    assert merged["repos"][0]["rev"] == "v0.6.9"  # existing pin wins


def test_local_ruff_hook_satisfies_the_baseline() -> None:
    target = {
        "repos": [
            {
                "repo": "local",
                "hooks": [
                    {"id": "ruff-check", "entry": "ruff check", "language": "system"},
                    {"id": "ruff-format", "entry": "ruff format", "language": "system"},
                ],
            }
        ]
    }
    gaps = M.missing_items(_baseline(), target, M.enforced_ids({"python"}))
    assert not [gap for gap in gaps if gap.startswith(RUFF)]


def test_install_hook_types_are_unioned_keeping_existing_order() -> None:
    target = {
        "repos": [],
        "default_install_hook_types": ["post-checkout", "pre-commit"],
    }
    M.ensure_install_hook_types(target)
    assert target["default_install_hook_types"] == [
        "post-checkout",
        "pre-commit",
        "commit-msg",
        "pre-push",
        "post-merge",
    ]


def test_install_hook_types_are_drift_until_merged() -> None:
    target = {"repos": [], "default_install_hook_types": ["pre-commit"]}
    gaps = M.missing_items({"repos": []}, target, set())
    assert "default_install_hook_types+=commit-msg" in gaps
    M.ensure_install_hook_types(target)
    assert not [
        gap for gap in M.missing_items({"repos": []}, target, set()) if "install" in gap
    ]


def test_install_hook_types_are_created_when_absent() -> None:
    target: dict = {"repos": []}
    M.ensure_install_hook_types(target)
    assert target["default_install_hook_types"] == list(M.CANONICAL_INSTALL_HOOK_TYPES)


def test_canonical_baseline_declares_ruff_and_every_install_type() -> None:
    baseline = M.load(_BASELINE)
    assert M._declares_hook(baseline, RUFF, {"ruff-check"})
    assert set(M.CANONICAL_INSTALL_HOOK_TYPES) <= set(
        baseline["default_install_hook_types"]
    )
