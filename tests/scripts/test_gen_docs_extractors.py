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


def test_routes_unresolved_prefix_variable_is_omitted_and_listed(tmp_path: Path) -> None:
    src = (
        "from fastapi import APIRouter\n"
        "PREFIX = '/v1'\n"
        "router = APIRouter(prefix=PREFIX)\n\n\n"
        "@router.get('/x')\ndef x():\n    return 1\n"
    )
    _write(tmp_path, "api/a.py", src)
    out = x.render_routes(tmp_path, ["api/a.py"])
    assert "`x`" not in out
    assert "- unresolved router prefix: `api/a.py`" in out


def test_routes_router_assigned_twice_is_ambiguous(tmp_path: Path) -> None:
    src = (
        "from fastapi import APIRouter\n"
        "router = APIRouter(prefix='/a')\n"
        "router = APIRouter(prefix='/b')\n\n\n"
        "@router.get('/x')\ndef x():\n    return 1\n"
    )
    _write(tmp_path, "api/a.py", src)
    out = x.render_routes(tmp_path, ["api/a.py"])
    assert "/a/x" not in out and "/b/x" not in out
    assert out.count("- unresolved router prefix: `api/a.py`") == 1


def test_routes_same_router_name_in_two_files_stays_per_file(tmp_path: Path) -> None:
    for rel, prefix in (("api/a.py", "/a"), ("api/b.py", "/b")):
        _write(
            tmp_path,
            rel,
            f"from fastapi import APIRouter\nrouter = APIRouter(prefix='{prefix}')\n\n\n"
            "@router.get('/x')\ndef x():\n    return 1\n",
        )
    out = x.render_routes(tmp_path, ["api/a.py", "api/b.py"])
    assert "`/a/x`" in out and "`/b/x`" in out
    assert "unresolved" not in out


def test_routes_path_keyword_is_supported(tmp_path: Path) -> None:
    src = "from fastapi import FastAPI\napp = FastAPI()\n\n\n@app.get(path='/kw')\ndef kw():\n    return 1\n"
    _write(tmp_path, "api/k.py", src)
    assert "| GET | `/kw` | `kw` |" in x.render_routes(tmp_path, ["api/k.py"])


def test_routes_fastapi_word_without_import_is_ignored(tmp_path: Path) -> None:
    _write(tmp_path, "api/doc.py", "# fastapi is great\nNAME = 'fastapi'\n")
    assert x.ROUTES.detect(tmp_path, ["api/doc.py"]) is False
    assert x.render_routes(tmp_path, ["api/doc.py"]).startswith(x.NA)


def test_routes_unparsable_file_mentioning_fastapi_is_detected_and_listed(tmp_path: Path) -> None:
    _write(tmp_path, "api/bad.py", "import fastapi\ndef broken(:\n")
    assert x.ROUTES.detect(tmp_path, ["api/bad.py"]) is True
    assert "- not parsed: `api/bad.py`" in x.render_routes(tmp_path, ["api/bad.py"])


def test_routes_import_forms_are_detected(tmp_path: Path) -> None:
    _write(tmp_path, "a.py", "import fastapi.routing\n")
    _write(tmp_path, "b.py", "from fastapi.routing import APIRouter\n")
    assert x.ROUTES.detect(tmp_path, ["a.py"]) is True
    assert x.ROUTES.detect(tmp_path, ["b.py"]) is True


DJANGO_SRC = textwrap.dedent('''\
    from django.db import models


    class Order(models.Model):
        title = models.CharField(max_length=10)
        owner = models.ForeignKey("auth.User", on_delete=models.CASCADE)
        tags = models.ManyToManyField("Tag")
        note = "not a field"

        class Meta:
            ordering = ["title"]


    class Helper:
        name = models.CharField(max_length=3)


    class Tag(models.Model):
        pass
''')


def test_data_model_lists_models_fields_and_relations(tmp_path: Path) -> None:
    _write(tmp_path, "shop/models.py", DJANGO_SRC)
    out = x.render_data_model(tmp_path, ["shop/models.py"])
    assert "### `Order` — `shop/models.py`" in out
    assert "| `title` | `CharField` |  |" in out
    assert "| `owner` | `ForeignKey` | `'auth.User'` |" in out
    assert "| `tags` | `ManyToManyField` | `'Tag'` |" in out
    assert "note" not in out
    assert "Helper" not in out
    assert "Meta" not in out
    assert "### `Tag` — `shop/models.py`" in out
    assert "_no fields detected_" in out
    assert "not listed" in out


def test_data_model_reads_a_models_package(tmp_path: Path) -> None:
    _write(tmp_path, "shop/models/order.py", DJANGO_SRC)
    assert "### `Order`" in x.render_data_model(tmp_path, ["shop/models/order.py"])


def test_data_model_unparsable_and_unreadable_files(tmp_path: Path) -> None:
    _write(tmp_path, "a/models.py", "from django.db import models\nclass X(:\n")
    (tmp_path / "b").mkdir()
    (tmp_path / "b" / "models.py").write_bytes(b"\xff\x00")
    out = x.render_data_model(tmp_path, ["a/models.py", "b/models.py"])
    assert "- not parsed: `a/models.py`" in out
    assert "b/models.py" not in out
    assert out.startswith(x.NA)


def test_data_model_detect_and_covers(tmp_path: Path) -> None:
    _write(tmp_path, "shop/models.py", DJANGO_SRC)
    _write(tmp_path, "pkg/models.py", "class Plain:\n    pass\n")
    assert x.DATA_MODEL.detect(tmp_path, ["shop/models.py"]) is True
    assert x.DATA_MODEL.detect(tmp_path, ["pkg/models.py"]) is False
    assert x.DATA_MODEL.covers("shop/models.py") is True
    assert x.DATA_MODEL.covers("shop/views.py") is False
    assert x.BY_NAME["data-model"] is x.DATA_MODEL


def test_data_model_comment_mentioning_django_does_not_detect(tmp_path: Path) -> None:
    _write(tmp_path, "pkg/models.py", "# django-like\nclass Model:\n    pass\n")
    assert x.DATA_MODEL.detect(tmp_path, ["pkg/models.py"]) is False


def test_data_model_escapes_pipes_and_shows_non_literal_source(tmp_path: Path) -> None:
    src = (
        "from django.db import models\n\n\n"
        "class A(models.Model):\n"
        '    one = models.ForeignKey("a|b", on_delete=models.CASCADE)\n'
        "    two = models.ForeignKey(TARGET, on_delete=models.CASCADE)\n"
    )
    _write(tmp_path, "app/models.py", src)
    out = x.render_data_model(tmp_path, ["app/models.py"])
    assert "`'a\\|b'`" in out
    assert "| `two` | `ForeignKey` | `TARGET` |" in out


def test_data_model_sections_sorted_by_file_then_line_with_nested(tmp_path: Path) -> None:
    src = (
        "from django.db import models\n\n\n"
        "class Outer(models.Model):\n"
        "    class Inner(models.Model):\n"
        "        pass\n\n\n"
        "class Later(models.Model):\n"
        "    pass\n"
    )
    _write(tmp_path, "b/models.py", src)
    _write(tmp_path, "a/models.py", "from django.db import models\n\n\nclass Z(models.Model):\n    pass\n")
    out = x.render_data_model(tmp_path, ["b/models.py", "a/models.py"])
    order = [out.index(f"### `{name}`") for name in ("Z", "Outer", "Inner", "Later")]
    assert order == sorted(order)


def test_data_model_marks_abstract_and_lists_inheritance_to_fixpoint(tmp_path: Path) -> None:
    _write(
        tmp_path,
        "app/models.py",
        "from django.db import models\n\n\n"
        "class Leaf(Mid):\n    z = models.IntegerField()\n\n\n"
        "class Mid(Base):\n    pass\n\n\n"
        "class Base(models.Model):\n"
        "    class Meta:\n        abstract = True\n\n\n"
        "class Other(TimeStampedModel):\n    pass\n",
    )
    _write(tmp_path, "app/models/x.py", "from django.db import models\n\n\nclass Far(Leaf):\n    pass\n")
    out = x.render_data_model(tmp_path, ["app/models.py", "app/models/x.py"])
    assert "### `Base` — `app/models.py` (abstract)" in out
    assert "### `Mid` — `app/models.py`\n\n_inherits: `Base`_" in out
    assert "### `Leaf` — `app/models.py`\n\n_inherits: `Mid`_" in out
    assert "### `Far` — `app/models/x.py`\n\n_inherits: `Leaf`_" in out
    assert "Other" not in out
    assert out.index("### `Leaf`") < out.index("### `Mid`") < out.index("### `Base`")
    assert "non-literal" in out and "tuple unpacking" in out


def test_data_model_annotated_and_conditional_fields(tmp_path: Path) -> None:
    _write(
        tmp_path,
        "app/models.py",
        "from django.db import models\n\n\n"
        "class A(models.Model):\n"
        "    a: models.CharField = models.CharField(max_length=1)\n"
        "    if DEBUG:\n        b = models.IntegerField()\n"
        "    try:\n        c = models.TextField()\n    except Exception:\n        pass\n"
        "    d = models.CharField() if DEBUG else None\n"
        "    e, f = models.CharField(), models.CharField()\n"
        "    class Inner:\n        g = models.CharField()\n",
    )
    out = x.render_data_model(tmp_path, ["app/models.py"])
    for name in ("a", "b", "c"):
        assert f"| `{name}` |" in out
    for name in ("d", "e", "f", "g"):
        assert f"| `{name}` |" not in out


def test_data_model_excludes_tests_and_migrations(tmp_path: Path) -> None:
    files = ["tests/models.py", "app/migrations/models.py", "app/test/models.py"]
    for rel in files:
        _write(tmp_path, rel, DJANGO_SRC)
    assert x.render_data_model(tmp_path, files).startswith(x.NA)
    assert x.DATA_MODEL.detect(tmp_path, files) is False
    assert x.DATA_MODEL.covers("app/migrations/models.py") is False
