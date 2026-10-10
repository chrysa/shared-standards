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

from collections.abc import Callable
from dataclasses import dataclass
from pathlib import Path

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


# ── registry ──────────────────────────────────────────────────────────────────────────────

STRUCTURE = Extractor(
    name="structure",
    detect=detect_structure,
    render=render_structure,
    covers=covers_structure,
)

EXTRACTORS: tuple[Extractor, ...] = (STRUCTURE,)
BY_NAME: dict[str, Extractor] = {extractor.name: extractor for extractor in EXTRACTORS}
