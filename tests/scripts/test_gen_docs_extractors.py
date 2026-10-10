"""Tests for scripts/gen_docs_extractors.py — static extractors (ADR D-0018)."""

from __future__ import annotations

from pathlib import Path

from scripts import gen_docs_extractors as x


def test_read_source_normalises_crlf(tmp_path: Path) -> None:
    (tmp_path / "a.txt").write_bytes(b"one\r\ntwo\r\n")
    assert x.read_source(tmp_path, "a.txt") == "one\ntwo\n"


def test_read_source_returns_none_for_missing_and_non_utf8(tmp_path: Path) -> None:
    (tmp_path / "bin.py").write_bytes(b"\xff\xfe\x00bad")
    assert x.read_source(tmp_path, "missing.py") is None
    assert x.read_source(tmp_path, "bin.py") is None


def test_structure_lists_directories_with_counts_and_readme_flag() -> None:
    files = ["README.md", "src/app/a.py", "src/app/README.md", "tests/test_a.py"]
    out = x.render_structure(Path("."), files)
    assert "| `src/` | 2 | no |" in out
    assert "| `src/app/` | 2 | yes |" in out
    assert "| `tests/` | 1 | no |" in out
    assert out.endswith("\n")


def test_structure_is_not_available_when_there_are_no_directories() -> None:
    assert x.render_structure(Path("."), ["README.md"]) == x.NA + "\n"


def test_structure_output_is_independent_of_input_order() -> None:
    files = ["src/b.py", "src/a.py", "docs/x.md"]
    assert x.render_structure(Path("."), files) == x.render_structure(Path("."), sorted(files))


def test_registry_exposes_structure_by_name() -> None:
    assert x.BY_NAME["structure"].name == "structure"
    assert x.BY_NAME["structure"].detect(Path("."), ["a/b.py"]) is True
    assert x.BY_NAME["structure"].detect(Path("."), []) is False
    assert x.BY_NAME["structure"].covers("a/b.py") is False
