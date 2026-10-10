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
    "non-literal paths are omitted._"
)


class Route(NamedTuple):
    """One HTTP route; field order is the sort order of the generated table."""

    path: str
    method: str
    handler: str
    response: str
    file: str


def _router_prefixes(tree: ast.AST) -> dict[str, str]:
    """``name = APIRouter(prefix="/x")`` assignments: variable name -> literal prefix."""
    prefixes: dict[str, str] = {}
    for node in ast.walk(tree):
        if isinstance(node, ast.Assign) and isinstance(node.value, ast.Call):
            if _callee_name(node.value) != "APIRouter":
                continue
            for target in node.targets:
                if isinstance(target, ast.Name):
                    prefixes[target.id] = _keyword_literal(node.value, "prefix") or ""
    return prefixes


def _literal_path(decorator: ast.Call) -> str | None:
    if not decorator.args:
        return None
    first = decorator.args[0]
    if isinstance(first, ast.Constant) and isinstance(first.value, str):
        return first.value
    return None


def _route_of(
    decorator: ast.expr, handler: str, rel: str, prefixes: dict[str, str]
) -> Route | None:
    """The route declared by one decorator, or None when it is not a literal HTTP route."""
    if not isinstance(decorator, ast.Call) or not isinstance(decorator.func, ast.Attribute):
        return None
    owner = decorator.func.value
    method = decorator.func.attr
    path = _literal_path(decorator)
    if method not in _HTTP_METHODS or not isinstance(owner, ast.Name) or path is None:
        return None
    response = _keyword_source(decorator, "response_model")
    return Route(prefixes.get(owner.id, "") + path, method.upper(), handler, response, rel)


def _routes_in(tree: ast.AST, rel: str) -> list[Route]:
    prefixes = _router_prefixes(tree)
    found: list[Route] = []
    for node in ast.walk(tree):
        if not isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)):
            continue
        for decorator in node.decorator_list:
            route = _route_of(decorator, node.name, rel, prefixes)
            if route is not None:
                found.append(route)
    return found


def _mentions_fastapi(text: str | None) -> bool:
    return text is not None and "fastapi" in text.lower()


def detect_routes(root: Path, files: list[str]) -> bool:
    return any(_mentions_fastapi(read_source(root, rel)) for rel in _python_files(files))


def covers_routes(path: str) -> bool:
    lowered = path.lower()
    return lowered.endswith(".py") and any(hint in lowered for hint in _ROUTE_HINTS)


def render_routes(root: Path, files: list[str]) -> str:
    """Route table (method, path, handler, response model, file) plus the documented limits."""
    routes: list[Route] = []
    unparsed: list[str] = []
    for rel in _python_files(files):
        text = read_source(root, rel)
        if not _mentions_fastapi(text):
            continue
        tree = _parse(text or "")
        if tree is None:
            unparsed.append(rel)
            continue
        routes.extend(_routes_in(tree, rel))
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
    lines += ["", _ROUTES_LIMITS, *_unparsed_lines(unparsed)]
    return "\n".join(lines) + "\n"


ROUTES = Extractor(
    name="routes", detect=detect_routes, render=render_routes, covers=covers_routes
)


# ── registry ──────────────────────────────────────────────────────────────────────────────

STRUCTURE = Extractor(
    name="structure",
    detect=detect_structure,
    render=render_structure,
    covers=covers_structure,
)

EXTRACTORS: tuple[Extractor, ...] = (ROUTES, STRUCTURE)
BY_NAME: dict[str, Extractor] = {extractor.name: extractor for extractor in EXTRACTORS}
