"""Tests for scripts/gen_docs.py — reference-docs generator and drift gate (ADR D-0018).

Hermetic: tiny repos built on disk (no git unless a test needs it), no network, no Docker.
"""

from __future__ import annotations

from pathlib import Path

import pytest

from scripts import gen_docs as g

STRUCTURE_MD = "docs/reference/structure.md"


def _repo(tmp_path: Path, name: str = "repo") -> Path:
    root = tmp_path / name
    (root / "src" / "app").mkdir(parents=True)
    (root / "README.md").write_text("# Sample\n", encoding="utf-8")
    (root / "src" / "app" / "main.py").write_text("x = 1\n", encoding="utf-8")
    return root


def test_structure_doc_is_generated_for_a_detected_repo(tmp_path: Path) -> None:
    expected = g.generate(_repo(tmp_path))
    assert STRUCTURE_MD in expected
    assert expected[STRUCTURE_MD].required is False
    assert g.BANNER in expected[STRUCTURE_MD].content
    assert "| `src/app/` | 1 | no |" in expected[STRUCTURE_MD].content


def test_generation_is_a_fixed_point(tmp_path: Path) -> None:
    """Review focus 1: the generated file must not list itself, or every run differs."""
    root = _repo(tmp_path)
    first = g.generate(root)
    g.write_all(root)
    second = g.generate(root)
    assert {k: v.content for k, v in first.items()} == {k: v.content for k, v in second.items()}
    assert g.drift(root) == []


def test_output_is_byte_identical_across_roots(tmp_path: Path) -> None:
    a = g.generate(_repo(tmp_path, "one"))
    b = g.generate(_repo(tmp_path, "two"))
    assert {k: v.content for k, v in a.items()} == {k: v.content for k, v in b.items()}


def test_no_absolute_path_or_timestamp_leaks(tmp_path: Path) -> None:
    root = _repo(tmp_path)
    content = g.generate(root)[STRUCTURE_MD].content
    assert str(root) not in content
    assert "202" not in content


def test_missing_auto_detected_file_is_not_drift(tmp_path: Path) -> None:
    assert g.drift(_repo(tmp_path)) == []


def test_stale_file_is_drift_once_written(tmp_path: Path) -> None:
    root = _repo(tmp_path)
    g.write_all(root)
    (root / "src" / "app" / "extra.py").write_text("y = 2\n", encoding="utf-8")
    assert g.drift(root) == [f"stale: {STRUCTURE_MD}"]


def test_empty_repo_generates_nothing(tmp_path: Path) -> None:
    root = tmp_path / "empty"
    root.mkdir()
    assert g.generate(root) == {}
    assert g.drift(root) == []


def test_profile_listing_makes_a_missing_file_drift(tmp_path: Path) -> None:
    pytest.importorskip("yaml")
    root = _repo(tmp_path)
    (root / "project-profile.yml").write_text("docs:\n  - structure\n", encoding="utf-8")
    assert g.drift(root) == [f"missing: {STRUCTURE_MD}"]
    g.write_all(root)
    assert g.drift(root) == []


def test_profile_with_unknown_extractor_is_reported(tmp_path: Path) -> None:
    pytest.importorskip("yaml")
    root = _repo(tmp_path)
    (root / "project-profile.yml").write_text("docs:\n  - nope\n  - structure\n", encoding="utf-8")
    assert "unknown extractor in project-profile.yml: nope" in g.drift(root)


def test_markers_replace_only_the_block(tmp_path: Path) -> None:
    root = _repo(tmp_path)
    (root / "ARCHITECTURE.md").write_text(
        "# Arch\n\nintro kept\n\n"
        "<!-- chrysa:docs:structure:start -->\nOLD\n<!-- chrysa:docs:structure:end -->\n\n"
        "outro kept\n",
        encoding="utf-8",
    )
    g.write_all(root)
    text = (root / "ARCHITECTURE.md").read_text(encoding="utf-8")
    assert "OLD" not in text
    assert text.startswith("# Arch\n\nintro kept\n\n<!-- chrysa:docs:structure:start -->\n")
    assert text.endswith("<!-- chrysa:docs:structure:end -->\n\noutro kept\n")
    assert "| `src/app/` | 1 | no |" in text
    assert g.drift(root) == []


def test_unknown_or_unterminated_markers_are_left_untouched(tmp_path: Path) -> None:
    """Review focus 5."""
    root = _repo(tmp_path)
    original = (
        "<!-- chrysa:docs:nothing:start -->\nkeep\n<!-- chrysa:docs:nothing:end -->\n"
        "<!-- chrysa:docs:structure:start -->\nno end marker here\n"
    )
    (root / "NOTES.md").write_text(original, encoding="utf-8")
    g.write_all(root)
    assert (root / "NOTES.md").read_text(encoding="utf-8") == original


def test_main_check_exit_codes(tmp_path: Path) -> None:
    root = _repo(tmp_path)
    assert g.main(["--check"], root=root) == 0
    assert g.main([], root=root) == 0
    (root / "src" / "app" / "extra.py").write_text("y = 2\n", encoding="utf-8")
    assert g.main(["--check"], root=root) == 1
    assert g.main([], root=root) == 0
    assert g.main(["--check"], root=root) == 0


def test_stray_start_marker_does_not_swallow_prose() -> None:
    text = (
        "<!-- chrysa:docs:structure:start -->\nUSER PROSE\n## Heading\n"
        "<!-- chrysa:docs:structure:start -->\nO\n<!-- chrysa:docs:structure:end -->\nC\n"
    )
    assert g.splice_blocks(text, {"structure": "NEW\n"}) == (
        "<!-- chrysa:docs:structure:start -->\nUSER PROSE\n## Heading\n"
        "<!-- chrysa:docs:structure:start -->\nNEW\n<!-- chrysa:docs:structure:end -->\nC\n"
    )


def _crlf(root: Path, body: str) -> bytes:
    raw = (
        "# Arch\r\n\r\nintro\r\n<!-- chrysa:docs:structure:start -->\r\n"
        + body
        + "<!-- chrysa:docs:structure:end -->\r\noutro\r\n"
    ).encode()
    (root / "ARCHITECTURE.md").write_bytes(raw)
    return raw


def test_crlf_file_keeps_its_newlines_outside_markers(tmp_path: Path) -> None:
    root = _repo(tmp_path)
    _crlf(root, "OLD\r\n")
    assert g.drift(root) == ["stale: ARCHITECTURE.md"]
    g.write_all(root)
    data = (root / "ARCHITECTURE.md").read_bytes()
    assert data.startswith(b"# Arch\r\n\r\nintro\r\n<!-- chrysa:docs:structure:start -->\r\n")
    assert data.endswith(b"<!-- chrysa:docs:structure:end -->\r\noutro\r\n")
    assert b"\n" not in data.replace(b"\r\n", b"")
    assert g.drift(root) == []


def test_crlf_file_with_current_block_is_untouched(tmp_path: Path) -> None:
    root = _repo(tmp_path)
    _crlf(root, "OLD\r\n")
    g.write_all(root)
    before = (root / "ARCHITECTURE.md").read_bytes()
    assert g.drift(root) == []
    g.write_all(root)
    assert (root / "ARCHITECTURE.md").read_bytes() == before


def _fence_repo(tmp_path: Path, doc: str) -> Path:
    root = _repo(tmp_path)
    (root / "doc.md").write_text(doc, encoding="utf-8")
    return root


_EXAMPLE = "<!-- chrysa:docs:structure:start -->\nold\n<!-- chrysa:docs:structure:end -->\n"


def test_fenced_marker_example_is_left_untouched_and_not_drift(tmp_path: Path) -> None:
    doc = f"# D\n\n```markdown\n{_EXAMPLE}```\n"
    root = _fence_repo(tmp_path, doc)
    g.write_all(root)
    assert (root / "doc.md").read_text(encoding="utf-8") == doc
    assert g.drift(root) == []


def test_real_block_outside_the_fence_is_still_updated(tmp_path: Path) -> None:
    doc = f"```markdown\n{_EXAMPLE}```\n\n{_EXAMPLE}"
    root = _fence_repo(tmp_path, doc)
    g.write_all(root)
    out = (root / "doc.md").read_text(encoding="utf-8")
    head, tail = out.split("```\n\n", 1)
    assert "old" in head
    assert "old" not in tail and "| Directory |" in tail


def test_tilde_fence_is_respected(tmp_path: Path) -> None:
    doc = f"~~~markdown\n{_EXAMPLE}~~~\n"
    root = _fence_repo(tmp_path, doc)
    g.write_all(root)
    assert (root / "doc.md").read_text(encoding="utf-8") == doc


def test_unterminated_fence_covers_rest_of_file(tmp_path: Path) -> None:
    doc = f"```markdown\n{_EXAMPLE}"
    root = _fence_repo(tmp_path, doc)
    g.write_all(root)
    assert (root / "doc.md").read_text(encoding="utf-8") == doc
    assert g.drift(root) == []


def test_main_refuses_old_python(monkeypatch: pytest.MonkeyPatch, tmp_path: Path, capsys: pytest.CaptureFixture[str]) -> None:
    monkeypatch.setattr(g.sys, "version_info", (3, 9, 0))
    assert g.main([], root=_repo(tmp_path)) == 2
    assert "Python >= 3.12" in capsys.readouterr().err
