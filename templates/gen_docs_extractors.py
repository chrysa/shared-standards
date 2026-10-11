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
import re
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


def is_safe_path(root: Path, rel: str) -> bool:
    """False when ``rel`` (or one of its parent directories under ``root``) is a symlink, or
    resolves outside ``root``. Symlinks are never followed, read or written through."""
    current = root
    for part in rel.split("/"):
        current = current / part
        if current.is_symlink():
            return False
    try:
        current.resolve().relative_to(root.resolve())
    except (OSError, ValueError):
        return False
    return True


def read_source(root: Path, rel: str) -> str | None:
    """UTF-8 text of ``rel`` with ``\\n`` newlines, or None when it cannot be read.

    A symlinked path, or one resolving outside ``root``, is never read.
    """
    if not is_safe_path(root, rel):
        return None
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
_NON_MODEL_DIRS = frozenset({"tests", "test", "migrations"})
_DATA_MODEL_LIMITS = (
    "_Limits: models whose bases are not `Model` or a model class found in the scanned files "
    "are not listed; inherited fields are not repeated; fields declared through tuple "
    "unpacking or inside expressions are not listed; non-literal relation targets are shown "
    "as source text; base classes are matched by simple name, so a same-named class in another "
    "file can be reported as the parent; `abstract` is detected only from a literal "
    "`abstract = True` in `class Meta`._"
)


class FieldRow(NamedTuple):
    """One declared model field."""

    name: str
    kind: str
    relation: str


class ModelEntry(NamedTuple):
    """A recognised model class: where it is, the model bases it inherits from."""

    rel: str
    node: ast.ClassDef
    inherits: tuple[str, ...]


def _is_model_file(rel: str) -> bool:
    parts = rel.split("/")
    if not rel.endswith(".py") or _NON_MODEL_DIRS.intersection(parts[:-1]):
        return False
    return parts[-1] == "models.py" or "models" in parts[:-1]


def _base_name(base: ast.expr) -> str:
    """``Model`` -> ``Model``; ``models.Model`` -> ``Model``; anything else -> empty string."""
    if isinstance(base, ast.Name):
        return base.id
    if isinstance(base, ast.Attribute):
        return base.attr
    return ""


def _model_bases(node: ast.ClassDef, known: set[str]) -> tuple[str, ...]:
    """Bases of ``node`` that are a model class already recognised (``Model`` excluded)."""
    names = [_base_name(base) for base in node.bases]
    return tuple(name for name in names if name in known)


def _is_model_class(node: ast.ClassDef, known: set[str]) -> bool:
    """A class deriving from ``Model``/``<module>.Model`` or from a known model class."""
    names = {_base_name(base) for base in node.bases}
    return "Model" in names or bool(names & known)


def _is_abstract(node: ast.ClassDef) -> bool:
    """True when the class body has ``class Meta`` with ``abstract = True``."""
    for meta in node.body:
        if not (isinstance(meta, ast.ClassDef) and meta.name == "Meta"):
            continue
        for item in meta.body:
            if not isinstance(item, ast.Assign):
                continue
            value = item.value
            names = [t.id for t in item.targets if isinstance(t, ast.Name)]
            if "abstract" in names and isinstance(value, ast.Constant) and value.value is True:
                return True
    return False


def _relation_source(call: ast.Call) -> str:
    """Source text of the relation target (first argument, else ``to=``), or empty."""
    if call.args:
        return ast.unparse(call.args[0])
    return _keyword_source(call, "to")


def _field_of(statement: ast.stmt) -> FieldRow | None:
    """The field declared by ``name = models.XField(...)`` (annotated or not), or None."""
    if isinstance(statement, ast.Assign) and len(statement.targets) == 1:
        target: ast.expr = statement.targets[0]
    elif isinstance(statement, ast.AnnAssign):
        target = statement.target
    else:
        return None
    if not isinstance(target, ast.Name) or not isinstance(statement.value, ast.Call):
        return None
    call = statement.value
    kind = _callee_name(call)
    if not kind.endswith("Field") and kind not in _RELATION_FIELDS:
        return None
    relation = _relation_source(call) if kind in _RELATION_FIELDS else ""
    return FieldRow(target.id, kind, relation)


def _body_statements(body: list[ast.stmt]) -> list[ast.stmt]:
    """Statements of a class body, descending into ``if``/``try`` blocks only."""
    out: list[ast.stmt] = []
    for statement in body:
        if isinstance(statement, ast.If):
            out += _body_statements(statement.body) + _body_statements(statement.orelse)
        elif isinstance(statement, ast.Try):
            out += _body_statements(statement.body)
            for handler in statement.handlers:
                out += _body_statements(handler.body)
            out += _body_statements(statement.orelse) + _body_statements(statement.finalbody)
        else:
            out.append(statement)
    return out


def _model_section(entry: ModelEntry) -> list[str]:
    node = entry.node
    marker = " (abstract)" if _is_abstract(node) else ""
    lines = [f"### `{node.name}` — `{entry.rel}`{marker}", ""]
    if entry.inherits:
        bases = ", ".join(f"`{name}`" for name in entry.inherits)
        lines += [f"_inherits: {bases}_", ""]
    fields = [row for row in map(_field_of, _body_statements(node.body)) if row is not None]
    if not fields:
        return [*lines, "_no fields detected_", ""]
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


def _models_of(trees: dict[str, ast.AST]) -> list[ModelEntry]:
    """Model classes of all scanned files, resolved by simple name until a fixpoint."""
    classes = [
        (rel, node)
        for rel, tree in trees.items()
        for node in ast.walk(tree)
        if isinstance(node, ast.ClassDef)
    ]
    known: set[str] = set()
    recognised: set[tuple[str, int]] = set()
    changed = True
    while changed:
        changed = False
        for rel, node in classes:
            key = (rel, node.lineno)
            if key not in recognised and _is_model_class(node, known):
                recognised.add(key)
                known.add(node.name)
                changed = True
    entries = [
        ModelEntry(rel, node, _model_bases(node, known))
        for rel, node in classes
        if (rel, node.lineno) in recognised
    ]
    return sorted(entries, key=lambda entry: (entry.rel, entry.node.lineno))


def render_data_model(root: Path, files: list[str]) -> str:
    """One section per Django model class, in file then source-line order."""
    trees: dict[str, ast.AST] = {}
    unparsed: list[str] = []
    for rel in sorted(rel for rel in files if _is_model_file(rel)):
        tree, relevant = _django_state(root, rel)
        if not relevant:
            continue
        if tree is None:
            unparsed.append(rel)
            continue
        trees[rel] = tree
    sections: list[str] = []
    for entry in _models_of(trees):
        sections += _model_section(entry)
    lines = sections if sections else [NA, ""]
    lines += [_DATA_MODEL_LIMITS, *_unparsed_lines(unparsed)]
    return "\n".join(lines).rstrip("\n") + "\n"


DATA_MODEL = Extractor(
    name="data-model",
    detect=detect_data_model,
    render=render_data_model,
    covers=covers_data_model,
)


# ── components (React) ────────────────────────────────────────────────────────────────────

_EXPORT_FUNCTION = re.compile(r"^export\s+(?:default\s+)?function\s+([A-Z]\w*)\s*\(", re.MULTILINE)
_EXPORT_CONST = re.compile(r"^export\s+const\s+([A-Z]\w*)\b", re.MULTILINE)
# Positive criteria for ``export const Name``: a component type annotation ...
_COMPONENT_TYPE = re.compile(
    r"\s*:\s*(?:React\.)?(?:FC|FunctionComponent|VFC|ComponentType)\b[^=\n;]{0,200}=(?!>)"
)
# ... or an initialiser that is an arrow function, a function, or memo/forwardRef/lazy.
_COMPONENT_INIT = re.compile(
    r"""\s*(?::[^=\n;]{0,200})?=(?!=)\s*(?:
        (?:async\s+)?(?:<[^()]{0,200}>\s*)?\((?:[^()]|\([^()]{0,200}\)){0,400}\)\s*(?::\s*[^=;\n]{1,100})?\s*=>
      | (?:async\s+)?[A-Za-z_$][\w$]*\s*=>
      | (?:async\s+)?function\b
      | (?:React\.)?(?:memo|forwardRef|lazy)\s*(?:<[^()]{0,200}>)?\s*\(
    )""",
    re.VERBOSE,
)
_NEXT_EXPORT = re.compile(r"^export\b", re.MULTILINE)
_PROPS_NEAR = re.compile(r"([A-Z]\w*Props)\b")
_PROPS_WINDOW = 200
_SKIPPED_DIRS = frozenset({"node_modules", "dist", "build", "__tests__"})
_NOT_COMPONENT_MARKERS = (".test.", ".spec.", ".stories.")
# Strings are matched first so a ``//`` inside a literal is not taken for a comment.
_JS_TOKEN = re.compile(
    r"""("(?:\\.|[^"\\\n])*"|'(?:\\.|[^'\\\n])*'|`(?:\\.|[^`\\])*`)|//[^\n]*|/\*.*?\*/""",
    re.DOTALL,
)
_COMPONENTS_LIMITS = (
    "_Limits: components are `export function`, `export default function` and `export const` "
    "initialised with an arrow function, a function, `memo`/`forwardRef`/`lazy` or typed `FC`; "
    "`export default class`, default arrow functions, `export { X }` re-exports, styled or other "
    "wrappers and `.jsx`/`.js` files are not listed; the props type is a best guess (first "
    "`*Props` name in the declaration signature)._"
)


def _is_component_file(rel: str) -> bool:
    parts = rel.split("/")
    if not rel.endswith(".tsx") or _SKIPPED_DIRS.intersection(parts[:-1]):
        return False
    return not any(marker in parts[-1] for marker in _NOT_COMPONENT_MARKERS)


def _strip_js_comments(text: str) -> str:
    """``text`` without ``//`` and ``/* */`` comments (string literals are left intact)."""
    return _JS_TOKEN.sub(lambda match: match.group(1) or " ", text)


def _signature_end(text: str, start: int, depth: int) -> int:
    """End of the declaration signature: the ``=>`` or body ``{`` (a ``{`` at paren depth 0 or
    right after a ``)``), at most ``_PROPS_WINDOW`` chars, never reaching the next ``export``."""
    end = min(len(text), start + _PROPS_WINDOW)
    following = _NEXT_EXPORT.search(text, start)
    if following is not None:
        end = min(end, following.start())
    previous = ""
    for index in range(start, end):
        char = text[index]
        if char == "=" and text[index + 1 : index + 2] == ">":
            return index
        if char == "{" and (depth <= 0 or previous == ")"):
            return index
        depth += (char == "(") - (char == ")")
        if not char.isspace():
            previous = char
    return end


def _props_type(text: str, start: int, depth: int) -> str:
    """First ``*Props`` name in the signature after a declaration (a best guess)."""
    match = _PROPS_NEAR.search(text, start, _signature_end(text, start, depth))
    return match.group(1) if match else ""


def _is_component_const(code: str, end: int) -> bool:
    return bool(_COMPONENT_TYPE.match(code, end) or _COMPONENT_INIT.match(code, end))


def _components_in(text: str, rel: str) -> list[tuple[str, str, str]]:
    code = _strip_js_comments(text)
    found: list[tuple[str, str, str]] = []
    for match in _EXPORT_FUNCTION.finditer(code):
        found.append((match.group(1), _props_type(code, match.end(), 1), rel))
    for match in _EXPORT_CONST.finditer(code):
        if _is_component_const(code, match.end()):
            found.append((match.group(1), _props_type(code, match.end(), 0), rel))
    return found


def detect_components(root: Path, files: list[str]) -> bool:  # noqa: ARG001
    return any(_is_component_file(rel) for rel in files)


def covers_components(path: str) -> bool:
    return _is_component_file(path)


def render_components(root: Path, files: list[str]) -> str:
    """Component inventory: name, props type (when named ``*Props``), file, plus the limits."""
    rows: list[tuple[str, str, str]] = []
    for rel in files:
        text = read_source(root, rel) if _is_component_file(rel) else None
        if text is not None:
            rows += _components_in(text, rel)
    if not rows:
        return NA + "\n"
    lines = ["| Component | Props | File |", "| --- | --- | --- |"]
    for name, props, rel in sorted(set(rows), key=lambda row: (row[2], row[0])):
        cell = f"`{_cell(props)}`" if props else ""
        lines.append(f"| `{name}` | {cell} | `{_cell(rel)}` |")
    return "\n".join([*lines, "", _COMPONENTS_LIMITS]) + "\n"


COMPONENTS = Extractor(
    name="components",
    detect=detect_components,
    render=render_components,
    covers=covers_components,
)


# ── registry ──────────────────────────────────────────────────────────────────────────────

STRUCTURE = Extractor(
    name="structure",
    detect=detect_structure,
    render=render_structure,
    covers=covers_structure,
)

EXTRACTORS: tuple[Extractor, ...] = (COMPONENTS, DATA_MODEL, ROUTES, STRUCTURE)
BY_NAME: dict[str, Extractor] = {extractor.name: extractor for extractor in EXTRACTORS}
