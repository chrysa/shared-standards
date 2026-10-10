"""Static extractors for the reference-documentation generator (ADR D-0018).

Each extractor reads source *text* of the target repo (``ast``, line scanning) and returns
deterministic markdown. Nothing here imports or executes the target repo's code.

An :class:`Extractor` carries four things: its ``name`` (also the generated file name), a
``detect`` predicate (does this repo have anything of that kind), a ``render`` function
(markdown body, no banner) and a ``covers`` predicate (is a changed path one this extractor
documents; used only by the non-blocking warning).

Determinism is a contract: sorted output, repo-relative ``/`` paths, ``\\n`` newlines, no
timestamps or absolute paths. Anything unreadable degrades to ``(not available)`` / a
``not parsed`` line, never to a crash and never to differing output.
"""

from __future__ import annotations

import ast
from collections.abc import Callable
from dataclasses import dataclass
from pathlib import Path
from typing import NamedTuple

NA = "(not available)"
_STRUCTURE_DEPTH = 2


@dataclass(frozen=True)
class Extractor:
    """One kind of reference documentation derivable from source."""

    name: str
    detect: Callable[[Path, list[str]], bool]
    render: Callable[[Path, list[str]], str]
    covers: Callable[[str], bool]


def read_source(root: Path, rel: str) -> str | None:
    """UTF-8 text of ``rel`` with ``\\n`` newlines, or None when it cannot be read."""
    try:
        text = (root / rel).read_text(encoding="utf-8")
    except (OSError, UnicodeDecodeError):
        return None
    return text.replace("\r\n", "\n")


# ── structure ─────────────────────────────────────────────────────────────────────────────


def _directories(files: list[str]) -> list[str]:
    """Sorted directories (down to ``_STRUCTURE_DEPTH`` levels) that hold at least a file."""
    dirs: set[str] = set()
    for rel in files:
        parts = rel.split("/")[:-1]
        for level in range(1, min(len(parts), _STRUCTURE_DEPTH) + 1):
            dirs.add("/".join(parts[:level]))
    return sorted(dirs)


def _count_under(files: list[str], directory: str) -> int:
    prefix = directory + "/"
    return sum(1 for rel in files if rel.startswith(prefix))


def detect_structure(root: Path, files: list[str]) -> bool:  # noqa: ARG001
    """Any repo with at least one file has a structure."""
    return bool(files)


def covers_structure(path: str) -> bool:  # noqa: ARG001
    """Structure documents everything and therefore never drives the code-without-doc warning."""
    return False


def render_structure(root: Path, files: list[str]) -> str:  # noqa: ARG001
    """Directory table: file count and whether the directory carries a ``README.md``."""
    present = set(files)
    rows = ["| Directory | Files | README |", "| --- | ---: | :---: |"]
    for directory in _directories(files):
        has_readme = "yes" if f"{directory}/README.md" in present else "no"
        rows.append(f"| `{directory}/` | {_count_under(files, directory)} | {has_readme} |")
    if len(rows) == 2:
        return NA + "\n"
    return "\n".join(rows) + "\n"


# ── shared AST helpers ────────────────────────────────────────────────────────────────────


def _python_files(files: list[str]) -> list[str]:
    return [rel for rel in files if rel.endswith(".py")]


def _parse(text: str) -> ast.AST | None:
    """Parse Python source, or None when it is not valid (syntax error, NUL byte)."""
    try:
        return ast.parse(text)
    except (SyntaxError, ValueError):
        return None


def _callee_name(call: ast.Call) -> str:
    """``f(...)`` -> ``f``; ``a.b(...)`` -> ``b``; anything else -> empty string."""
    func = call.func
    if isinstance(func, ast.Name):
        return func.id
    if isinstance(func, ast.Attribute):
        return func.attr
    return ""


def _keyword_literal(call: ast.Call, key: str) -> str | None:
    """The string-literal value of keyword ``key``, or None."""
    for keyword in call.keywords:
        value = keyword.value
        if keyword.arg == key and isinstance(value, ast.Constant) and isinstance(value.value, str):
            return value.value
    return None


def _keyword_source(call: ast.Call, key: str) -> str:
    """The source text of keyword ``key``, or an empty string."""
    for keyword in call.keywords:
        if keyword.arg == key:
            return ast.unparse(keyword.value)
    return ""


def _cell(value: str) -> str:
    """Escape ``|`` so a value cannot break a markdown table cell."""
    return value.replace("|", "\\|")


def _unparsed_lines(unparsed: list[str]) -> list[str]:
    return [f"- not parsed: `{rel}`" for rel in sorted(unparsed)]


# ── routes (FastAPI) ──────────────────────────────────────────────────────────────────────

_HTTP_METHODS = frozenset({"get", "post", "put", "patch", "delete", "head", "options"})
_ROUTE_HINTS = ("route", "api", "endpoint", "view", "main", "app")
_ROUTES_LIMITS = (
    "_Limits: router prefixes passed to `include_router(...)` are not resolved; "
    "`api_route`, websocket and non-literal routes are not listed._"
)


class Route(NamedTuple):
    """One HTTP route; field order is the sort order of the generated table."""

    path: str
    method: str
    handler: str
    response: str
    file: str


class _UnresolvedPrefix(Exception):
    """A route hangs off a router whose prefix cannot be known statically."""


def _router_prefixes(tree: ast.AST) -> dict[str, str | None]:
    """``name = APIRouter(prefix="/x")``: variable -> literal prefix, None when unresolvable.

    A non-literal ``prefix=`` or a name assigned to a router more than once is ambiguous.
    """
    prefixes: dict[str, str | None] = {}
    for node in ast.walk(tree):
        if not (isinstance(node, ast.Assign) and isinstance(node.value, ast.Call)):
            continue
        if _callee_name(node.value) != "APIRouter":
            continue
        has_prefix = any(keyword.arg == "prefix" for keyword in node.value.keywords)
        prefix = _keyword_literal(node.value, "prefix")
        for target in node.targets:
            if not isinstance(target, ast.Name):
                continue
            ambiguous = target.id in prefixes or (has_prefix and prefix is None)
            prefixes[target.id] = None if ambiguous else (prefix or "")
    return prefixes


def _literal_path(decorator: ast.Call) -> str | None:
    first = decorator.args[0] if decorator.args else None
    if first is None:
        for keyword in decorator.keywords:
            if keyword.arg == "path":
                first = keyword.value
    if isinstance(first, ast.Constant) and isinstance(first.value, str):
        return first.value
    return None


def _route_of(
    decorator: ast.expr, handler: str, rel: str, prefixes: dict[str, str | None]
) -> Route | None:
    """The route declared by one decorator, or None when it is not a literal HTTP route."""
    if not isinstance(decorator, ast.Call) or not isinstance(decorator.func, ast.Attribute):
        return None
    owner = decorator.func.value
    method = decorator.func.attr
    path = _literal_path(decorator)
    if method not in _HTTP_METHODS or not isinstance(owner, ast.Name) or path is None:
        return None
    prefix = prefixes.get(owner.id, "")
    if prefix is None:
        raise _UnresolvedPrefix
    response = _keyword_source(decorator, "response_model")
    return Route(prefix + path, method.upper(), handler, response, rel)


def _routes_in(tree: ast.AST, rel: str) -> tuple[list[Route], bool]:
    """Routes of one file, and whether some were dropped for an unresolvable router prefix."""
    prefixes = _router_prefixes(tree)
    found: list[Route] = []
    unresolved = False
    for node in ast.walk(tree):
        if not isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)):
            continue
        for decorator in node.decorator_list:
            try:
                route = _route_of(decorator, node.name, rel, prefixes)
            except _UnresolvedPrefix:
                unresolved = True
                continue
            if route is not None:
                found.append(route)
    return found, unresolved


def _imports_fastapi(tree: ast.AST) -> bool:
    for node in ast.walk(tree):
        if isinstance(node, ast.Import):
            if any(alias.name.split(".")[0] == "fastapi" for alias in node.names):
                return True
        elif isinstance(node, ast.ImportFrom) and node.level == 0:
            if (node.module or "").split(".")[0] == "fastapi":
                return True
    return False


def _fastapi_state(root: Path, rel: str) -> tuple[ast.AST | None, bool]:
    """(tree, relevant): relevant when it imports fastapi, or is unparsable and mentions it."""
    text = read_source(root, rel)
    if text is None or "fastapi" not in text.lower():
        return None, False
    tree = _parse(text)
    if tree is None:
        return None, True
    return tree, _imports_fastapi(tree)


def detect_routes(root: Path, files: list[str]) -> bool:
    return any(_fastapi_state(root, rel)[1] for rel in _python_files(files))


def covers_routes(path: str) -> bool:
    lowered = path.lower()
    return lowered.endswith(".py") and any(hint in lowered for hint in _ROUTE_HINTS)


def render_routes(root: Path, files: list[str]) -> str:
    """Route table (method, path, handler, response model, file) plus the documented limits."""
    routes: list[Route] = []
    unparsed: list[str] = []
    unresolved: list[str] = []
    for rel in _python_files(files):
        tree, relevant = _fastapi_state(root, rel)
        if not relevant:
            continue
        if tree is None:
            unparsed.append(rel)
            continue
        found, dropped = _routes_in(tree, rel)
        routes.extend(found)
        if dropped:
            unresolved.append(rel)
    lines: list[str] = []
    if routes:
        lines += ["| Method | Path | Handler | Response model | File |", "| --- | --- | --- | --- | --- |"]
        for route in sorted(routes):
            response = f"`{_cell(route.response)}`" if route.response else ""
            lines.append(
                f"| {route.method} | `{_cell(route.path)}` | `{route.handler}` | "
                f"{response} | `{route.file}` |"
            )
    else:
        lines.append(NA)
    unresolved_lines = [f"- unresolved router prefix: `{rel}`" for rel in sorted(set(unresolved))]
    lines += ["", _ROUTES_LIMITS, *unresolved_lines, *_unparsed_lines(unparsed)]
    return "\n".join(lines) + "\n"


ROUTES = Extractor(
    name="routes", detect=detect_routes, render=render_routes, covers=covers_routes
)


# ── data model (Django) ───────────────────────────────────────────────────────────────────

_RELATION_FIELDS = frozenset({"ForeignKey", "OneToOneField", "ManyToManyField"})
_DATA_MODEL_LIMITS = (
    "_Limits: models inheriting from non-`Model` bases are not listed; "
    "non-literal relation targets are shown as source text._"
)


class FieldRow(NamedTuple):
    """One declared model field."""

    name: str
    kind: str
    relation: str


def _is_model_file(rel: str) -> bool:
    parts = rel.split("/")
    return rel.endswith(".py") and (parts[-1] == "models.py" or "models" in parts[:-1])


def _is_model_class(node: ast.ClassDef) -> bool:
    """A class deriving from ``Model`` or ``<module>.Model``."""
    for base in node.bases:
        if isinstance(base, ast.Name) and base.id == "Model":
            return True
        if isinstance(base, ast.Attribute) and base.attr == "Model":
            return True
    return False


def _relation_source(call: ast.Call) -> str:
    """Source text of the relation target (first argument, else ``to=``), or empty."""
    if call.args:
        return ast.unparse(call.args[0])
    return _keyword_source(call, "to")


def _field_of(statement: ast.stmt) -> FieldRow | None:
    """The field declared by ``name = models.XField(...)``, or None."""
    if not isinstance(statement, ast.Assign) or not isinstance(statement.value, ast.Call):
        return None
    if len(statement.targets) != 1 or not isinstance(statement.targets[0], ast.Name):
        return None
    call = statement.value
    kind = _callee_name(call)
    if not kind.endswith("Field") and kind not in _RELATION_FIELDS:
        return None
    relation = _relation_source(call) if kind in _RELATION_FIELDS else ""
    return FieldRow(statement.targets[0].id, kind, relation)


def _model_section(node: ast.ClassDef, rel: str) -> list[str]:
    lines = [f"### `{node.name}` — `{rel}`", ""]
    fields = [row for row in map(_field_of, node.body) if row is not None]
    if not fields:
        return [*lines, "_no declared fields_", ""]
    lines += ["| Field | Type | Relation |", "| --- | --- | --- |"]
    for row in fields:
        relation = f"`{_cell(row.relation)}`" if row.relation else ""
        lines.append(f"| `{row.name}` | `{row.kind}` | {relation} |")
    return [*lines, ""]


def _imports_django(tree: ast.AST) -> bool:
    for node in ast.walk(tree):
        if isinstance(node, ast.Import):
            if any(alias.name.split(".")[0] == "django" for alias in node.names):
                return True
        elif isinstance(node, ast.ImportFrom) and node.level == 0:
            if (node.module or "").split(".")[0] == "django":
                return True
    return False


def _django_state(root: Path, rel: str) -> tuple[ast.AST | None, bool]:
    """(tree, relevant): relevant when it imports django, or is unparsable and mentions it."""
    text = read_source(root, rel)
    if text is None or "django" not in text.lower():
        return None, False
    tree = _parse(text)
    if tree is None:
        return None, True
    return tree, _imports_django(tree)


def detect_data_model(root: Path, files: list[str]) -> bool:
    return any(_django_state(root, rel)[1] for rel in files if _is_model_file(rel))


def covers_data_model(path: str) -> bool:
    return _is_model_file(path)


def _model_classes(tree: ast.AST) -> list[ast.ClassDef]:
    """Model classes of one tree, ordered by source line."""
    found = [n for n in ast.walk(tree) if isinstance(n, ast.ClassDef) and _is_model_class(n)]
    return sorted(found, key=lambda node: node.lineno)


def render_data_model(root: Path, files: list[str]) -> str:
    """One section per Django model class, in file then source-line order."""
    sections: list[str] = []
    unparsed: list[str] = []
    for rel in sorted(rel for rel in files if _is_model_file(rel)):
        tree, relevant = _django_state(root, rel)
        if not relevant:
            continue
        if tree is None:
            unparsed.append(rel)
            continue
        for node in _model_classes(tree):
            sections += _model_section(node, rel)
    lines = sections if sections else [NA, ""]
    lines += [_DATA_MODEL_LIMITS, *_unparsed_lines(unparsed)]
    return "\n".join(lines).rstrip("\n") + "\n"


DATA_MODEL = Extractor(
    name="data-model",
    detect=detect_data_model,
    render=render_data_model,
    covers=covers_data_model,
)


# ── registry ──────────────────────────────────────────────────────────────────────────────

STRUCTURE = Extractor(
    name="structure",
    detect=detect_structure,
    render=render_structure,
    covers=covers_structure,
)

EXTRACTORS: tuple[Extractor, ...] = (DATA_MODEL, ROUTES, STRUCTURE)
BY_NAME: dict[str, Extractor] = {extractor.name: extractor for extractor in EXTRACTORS}
