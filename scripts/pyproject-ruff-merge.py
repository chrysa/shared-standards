#!/usr/bin/env python3
"""Idempotently merge the canonical Ruff rule set into a repo's pyproject.toml.

The standards block mechanises its code-quality rules through Ruff, but the fleet
has no distributable Ruff config: `ruff.toml` is forbidden, every setting lives in
`[tool.ruff]` of the repo's own `pyproject.toml`. So the rule set cannot be copied
as a file — it has to be merged into a table that already carries repo-specific
tuning. That is this script.

Union by rule code, appended to `[tool.ruff.lint] select`. Existing entries win and
are never reordered, removed, or reformatted; `ignore`, `per-file-ignores` and every
other key are left untouched. Running it twice is a no-op.

The default set is LOT 1 — the structural, low-volume rules measured as armable
fleet-wide (see the standards block: complexity, dead branches, obvious perf traps).
It deliberately excludes PLR2004 (magic values, ~2500 fleet findings — that is the
`no hardcoded constants` chantier, not a flag) and RUF001 (ambiguous unicode, fires
on French prose).

Usage: pyproject-ruff-merge.py <pyproject.toml> [--check] [--rules C901,PERF401]
  --check  : exit 1 if any canonical rule is missing (no write), listing them.
  --rules  : comma list overriding the canonical set.
Exit: 0 ok / 1 drift (with --check) or error.
"""

from __future__ import annotations

import re
import sys
import tomllib
from pathlib import Path

# LOT 1 — armable now. Each code is a structural signal the standards block already
# demands in prose; volumes measured over 65 repos on 2026-07-31.
CANONICAL_RULES: tuple[str, ...] = (
    "C901",  # complex-structure — the `complexity <= 10` gate
    "PERF203",  # try-except-in-loop
    "PERF401",  # manual-list-comprehension
    "PLR0402",  # manual-from-import
    "PLR0911",  # too-many-return-statements
    "PLR0912",  # too-many-branches
    "PLR0915",  # too-many-statements — the `max function lines` gate's cousin
    "PLR1714",  # repeated-equality-comparison — the dispatch-ladder smell
    "PLR1730",  # if-stmt-min-max
    "PLR5501",  # collapsible-else-if
    "RUF005",  # collection-literal-concatenation
    "RUF006",  # asyncio-dangling-task
    "RUF007",  # zip-instead-of-pairwise
    "RUF009",  # function-call-in-dataclass-default-argument
    "RUF012",  # mutable-class-default — sibling of the mutable-default hook
    "RUF013",  # implicit-optional
    "RUF022",  # unsorted-dunder-all
    "RUF043",  # pytest-raises-ambiguous-pattern
    "RUF059",  # unused-unpacked-variable
    "RUF100",  # unused-noqa — autofixable, keeps suppressions honest
)

# Rules the `PLR*`/`RUF` shorthand in the standards block would imply, excluded on
# purpose. Named here so the decision is visible at the point of distribution rather
# than only in an issue — see STANDARDS.chrysa.md, *known anti-patterns*.
DELIBERATELY_EXCLUDED: dict[str, str] = {
    "PLR2004": "magic-value-comparison — 2519 fleet findings; the `no hardcoded constants` chantier, not a flag",
    "RUF001": "ambiguous-unicode — 493 findings on 4 repos, all French prose; arm locally with allowed-confusables",
}

_SELECT_RE = re.compile(r"(?P<head>^select\s*=\s*\[)(?P<body>.*?)(?P<tail>^\s*\])", re.DOTALL | re.MULTILINE)


def _lint_table(data: dict) -> dict:
    return data.get("tool", {}).get("ruff", {}).get("lint", {})


def selected_rules(data: dict) -> list[str]:
    """Return the codes already selected, whichever table style the repo uses."""
    lint = _lint_table(data)
    if "select" in lint:
        return list(lint["select"])
    # Pre-0.2 layout: select sat directly under [tool.ruff].
    return list(data.get("tool", {}).get("ruff", {}).get("select", []))


def missing_rules(data: dict, rules: tuple[str, ...]) -> list[str]:
    """Return canonical codes absent from the target, preserving canonical order.

    Ruff selectors are prefixes: a repo selecting `RUF` already enforces `RUF100`,
    and `ALL` enforces everything. Adding the individual code on top would be pure
    noise, so a selector covering the code counts as present.
    """
    current = set(selected_rules(data))
    if "ALL" in current:
        return []
    return [rule for rule in rules if not any(rule.startswith(sel) for sel in current)]


def _section_span(text: str, header: str) -> tuple[int, int] | None:
    """Return the [start, end) offsets of a TOML table body, or None if absent."""
    match = re.search(rf"^\[{re.escape(header)}\]\s*$", text, re.MULTILINE)
    if match is None:
        return None
    start = match.end()
    nxt = re.search(r"^\[", text[start:], re.MULTILINE)
    return (start, start + nxt.start() if nxt else len(text))


def _with_trailing_comma(body: str) -> str:
    """Close the last entry with a comma, without writing it inside a comment.

    `"F",  # pyflakes` already ends the entry; naively appending a comma to the
    stripped body would produce `# pyflakes,` — valid TOML, corrupted comment.
    """
    lines = body.rstrip("\n").split("\n")
    for index in range(len(lines) - 1, -1, -1):
        code = lines[index].split("#", 1)[0].rstrip()
        if not code:
            continue  # blank or comment-only line: keep looking upwards
        if code.endswith((",", "[")):
            break
        comment = lines[index][len(lines[index].split("#", 1)[0]) :]
        lines[index] = f"{code}," + (f"  {comment.strip()}" if comment.strip() else "")
        break
    return "\n".join(lines)


def _append_to_select(section: str, rules: list[str]) -> str | None:
    """Add the missing codes to an existing `select = [...]` array.

    Both array styles occur in the fleet: one entry per line (the common shape,
    often with a trailing comment per code) and a single-line `["E", "F"]`. The
    array's own layout is kept — a one-line array stays one line.
    """
    opening = re.search(r"^select\s*=\s*\[", section, re.MULTILINE)
    if opening is None:
        return None
    closing = section.find("]", opening.end())
    if closing == -1:
        return None
    body = section[opening.end() : closing]

    if "\n" not in body:
        inline = body.strip()
        prefix = f"{inline}, " if inline and not inline.endswith(",") else f"{inline} " if inline else ""
        added = ", ".join(f'"{rule}"' for rule in rules)
        return section[: opening.end()] + prefix + added + section[closing:]

    body = _with_trailing_comma(body)
    indent_match = re.search(r"\n(\s+)\S", body)
    indent = indent_match.group(1) if indent_match else "    "
    added = "".join(f'\n{indent}"{rule}",' for rule in rules)
    closing_indent = re.search(r"\n([ \t]*)$", body)
    tail = f"\n{closing_indent.group(1)}" if closing_indent else "\n"
    return section[: opening.end()] + body.rstrip("\n") + added + tail + section[closing:]


def merge(text: str, rules: list[str]) -> str:
    """Return `text` with every rule in `rules` present in the Ruff select list."""
    if not rules:
        return text
    span = _section_span(text, "tool.ruff.lint")
    if span is not None:
        start, end = span
        merged = _append_to_select(text[start:end], rules)
        if merged is not None:
            return text[:start] + merged + text[end:]
        block = "select = [\n" + "".join(f'    "{rule}",\n' for rule in rules) + "]\n"
        return text[:start] + "\n" + block + text[start:end].lstrip("\n") + text[end:]
    block = "\n[tool.ruff.lint]\nselect = [\n" + "".join(f'    "{rule}",\n' for rule in rules) + "]\n"
    if not text.endswith("\n"):
        text += "\n"
    return text + block


def _resolve_target(argv: list[str]) -> Path | None:
    """The single positional argument, or None when the usage is wrong."""
    args = [a for a in argv if not a.startswith("--")]
    if len(args) != 1:
        sys.stderr.write(__doc__ or "")
        return None
    target = Path(args[0])
    if not target.is_file():
        sys.stderr.write(f"{target}: not found\n")
        return None
    return target


def _resolve_rules(argv: list[str]) -> tuple[str, ...]:
    """The canonical set, unless --rules= overrides it."""
    for arg in argv:
        if arg.startswith("--rules="):
            return tuple(code.strip() for code in arg.split("=", 1)[1].split(",") if code.strip())
    return CANONICAL_RULES


def main(argv: list[str]) -> int:
    target = _resolve_target(argv)
    if target is None:
        return 2
    rules = _resolve_rules(argv)

    text = target.read_text(encoding="utf-8")
    try:
        data = tomllib.loads(text)
    except tomllib.TOMLDecodeError as exc:
        sys.stderr.write(f"{target}: invalid TOML — {exc}\n")
        return 2

    missing = missing_rules(data, rules)
    if "--check" in argv:
        if missing:
            sys.stderr.write(f"{target}: missing Ruff rules: {', '.join(missing)}\n")
            return 1
        return 0
    if not missing:
        return 0
    return _write_merged(target, text, missing)


def _write_merged(target: Path, text: str, missing: list[str]) -> int:
    """Merge the missing codes in, refusing to write a pyproject that would not parse."""
    merged = merge(text, missing)
    try:
        tomllib.loads(merged)
    except tomllib.TOMLDecodeError as exc:  # never hand back a broken pyproject
        sys.stderr.write(f"{target}: merge would produce invalid TOML — {exc}\n")
        return 2
    target.write_text(merged, encoding="utf-8")
    print(f"{target}: added {', '.join(missing)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
