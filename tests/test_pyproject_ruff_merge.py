"""Tests for scripts/pyproject-ruff-merge.py — the canonical Ruff distributor.

The script has a hyphenated filename (not importable as a module), so it is loaded
by path. Coverage focuses on the PLR2004 arming + its companion test-ignore, which
is the one per-file-ignore this distributor is allowed to manage (shared-standards#272).
"""

from __future__ import annotations

import importlib.util
import tomllib
from pathlib import Path

_SCRIPT = Path(__file__).resolve().parents[1] / "scripts" / "pyproject-ruff-merge.py"


def _load():
    spec = importlib.util.spec_from_file_location("ruff_merge", _SCRIPT)
    assert spec and spec.loader
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


M = _load()


def _ignores(text: str) -> dict:
    return tomllib.loads(text)["tool"]["ruff"]["lint"]["per-file-ignores"]


def test_plr2004_is_armed_and_no_longer_excluded() -> None:
    assert "PLR2004" in M.CANONICAL_RULES
    assert "PLR2004" not in M.DELIBERATELY_EXCLUDED


def test_appends_canonical_ignore_table_when_absent(tmp_path: Path) -> None:
    p = tmp_path / "pyproject.toml"
    p.write_text('[project]\nname = "x"\n', encoding="utf-8")
    assert M.main([str(p)]) == 0
    ig = _ignores(p.read_text())
    assert ig["**/tests/**"] == ["PLR2004"]
    assert ig["**/test_*.py"] == ["PLR2004"]
    assert ig["**/conftest.py"] == ["PLR2004"]


def test_merges_into_existing_glob_keeping_other_codes(tmp_path: Path) -> None:
    p = tmp_path / "pyproject.toml"
    p.write_text(
        '[tool.ruff.lint]\nselect = ["E", "PLR2004"]\n\n'
        '[tool.ruff.lint.per-file-ignores]\n'
        '"**/tests/**" = ["S101"]\n"scripts/*.py" = ["T201"]\n',
        encoding="utf-8",
    )
    assert M.main([str(p)]) == 0
    ig = _ignores(p.read_text())
    assert ig["**/tests/**"] == ["S101", "PLR2004"]  # existing code preserved
    assert ig["scripts/*.py"] == ["T201"]  # unrelated ignore untouched


def test_merges_into_existing_multiline_array(tmp_path: Path) -> None:
    # Regression: a multi-line ignore array must be detected, not treated as absent
    # (which appended a second row → duplicate TOML key → tomllib validation failure).
    p = tmp_path / "pyproject.toml"
    p.write_text(
        '[tool.ruff.lint]\nselect = ["E", "PLR2004"]\n\n'
        '[tool.ruff.lint.per-file-ignores]\n'
        '"**/tests/**" = [\n    "S101",\n    "ARG001",\n]\n',
        encoding="utf-8",
    )
    assert M.main([str(p)]) == 0  # no duplicate-key crash
    ig = _ignores(p.read_text())
    assert ig["**/tests/**"] == ["S101", "ARG001", "PLR2004"]  # merged in place


def test_is_idempotent(tmp_path: Path) -> None:
    p = tmp_path / "pyproject.toml"
    p.write_text('[project]\nname = "x"\n', encoding="utf-8")
    M.main([str(p)])
    first = p.read_text()
    assert M.main([str(p)]) == 0  # second run: nothing to do
    assert p.read_text() == first
    assert M.main([str(p), "--check"]) == 0  # --check sees no drift


def test_rules_override_without_plr2004_leaves_ignores_alone(tmp_path: Path) -> None:
    p = tmp_path / "pyproject.toml"
    p.write_text('[tool.ruff.lint]\nselect = ["E"]\n', encoding="utf-8")
    assert M.main([str(p), "--rules=C901"]) == 0
    assert "per-file-ignores" not in tomllib.loads(p.read_text())["tool"]["ruff"]["lint"]


def test_check_flags_missing_test_ignore(tmp_path: Path) -> None:
    p = tmp_path / "pyproject.toml"
    p.write_text('[tool.ruff.lint]\nselect = ["ALL"]\n', encoding="utf-8")  # rules covered by ALL
    assert M.main([str(p), "--check"]) == 1  # but the canonical test-ignore is still missing
