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


import textwrap

FASTAPI_SRC = textwrap.dedent('''\
    from fastapi import APIRouter, FastAPI

    app = FastAPI()
    router = APIRouter(prefix="/items")


    @router.get("/{item_id}", response_model=Item)
    async def read_item(item_id: int):
        return item_id


    @app.post("/login")
    def login():
        return {}


    @router.get(some_dynamic_path)
    def dynamic():
        return {}
''')


def _write(root: Path, rel: str, text: str) -> None:
    path = root / rel
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8")


def test_routes_extracts_method_path_handler_and_response_model(tmp_path: Path) -> None:
    _write(tmp_path, "api/app.py", FASTAPI_SRC)
    out = x.render_routes(tmp_path, ["api/app.py"])
    assert "| GET | `/items/{item_id}` | `read_item` | `Item` | `api/app.py` |" in out
    assert "| POST | `/login` | `login` |  | `api/app.py` |" in out
    assert "dynamic" not in out
    assert "include_router" in out  # the documented limit is part of the block


def test_routes_rows_are_sorted_by_path(tmp_path: Path) -> None:
    _write(tmp_path, "api/app.py", FASTAPI_SRC)
    out = x.render_routes(tmp_path, ["api/app.py"])
    assert out.index("`/items/{item_id}`") < out.index("`/login`")


def test_routes_lists_unparsable_files_without_crashing(tmp_path: Path) -> None:
    """Review focus 3."""
    _write(tmp_path, "api/bad.py", "from fastapi import FastAPI\ndef broken(:\n")
    _write(tmp_path, "api/app.py", FASTAPI_SRC)
    out = x.render_routes(tmp_path, ["api/app.py", "api/bad.py"])
    assert "- not parsed: `api/bad.py`" in out
    assert "`read_item`" in out


def test_routes_skips_unreadable_and_non_fastapi_files(tmp_path: Path) -> None:
    (tmp_path / "api").mkdir()
    (tmp_path / "api" / "bin.py").write_bytes(b"\xff\xfe\x00")
    _write(tmp_path, "api/plain.py", "def f():\n    return 1\n")
    out = x.render_routes(tmp_path, ["api/bin.py", "api/plain.py"])
    assert out.startswith(x.NA)


def test_routes_detect_and_covers(tmp_path: Path) -> None:
    _write(tmp_path, "api/app.py", FASTAPI_SRC)
    _write(tmp_path, "lib/util.py", "x = 1\n")
    assert x.ROUTES.detect(tmp_path, ["api/app.py"]) is True
    assert x.ROUTES.detect(tmp_path, ["lib/util.py"]) is False
    assert x.ROUTES.covers("api/routes/users.py") is True
    assert x.ROUTES.covers("lib/util.py") is False
    assert x.BY_NAME["routes"] is x.ROUTES


def test_routes_escape_pipe_in_cells(tmp_path: Path) -> None:
    src = (
        "from fastapi import FastAPI\n"
        "app = FastAPI()\n\n\n"
        "@app.get(\"/a|b\", response_model=int | None)\n"
        "def pipe():\n    return 1\n"
    )
    _write(tmp_path, "api/pipe.py", src)
    out = x.render_routes(tmp_path, ["api/pipe.py"])
    assert "| GET | `/a\\|b` | `pipe` | `int \\| None` | `api/pipe.py` |" in out
