"""Read the fleet standards *rules* from local files (read-only).

Pure functions over the source files that already hold the norms:
``.claude/thresholds.json`` (structured) and the two standards markdown files
(prose). No I/O beyond reading; missing files raise :class:`StandardsUnavailable`
loudly rather than returning an empty "all good" result.
"""

from __future__ import annotations

import json
import re
from pathlib import Path

from .config import Settings

_H2 = re.compile(r"^##[ \t]+(.+?)[ \t]*$", re.MULTILINE)


class StandardsUnavailable(RuntimeError):
    """A required standards source file is missing or unreadable."""


def _read_text(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8")
    except OSError as exc:
        raise StandardsUnavailable(f"cannot read standards file {path}: {exc}") from exc


def _slug(heading: str) -> str:
    return re.sub(r"[^a-z0-9]+", "-", heading.lower()).strip("-")


def load_thresholds(settings: Settings | None = None) -> dict[str, object]:
    """Return the numeric thresholds, dropping the ``_notes`` documentation block."""
    settings = settings or Settings()
    raw = json.loads(_read_text(settings.thresholds_path))
    return {k: v for k, v in raw.items() if k != "_notes"}


def load_standard_sections(settings: Settings | None = None) -> dict[str, str]:
    """Return ``{section-slug: body}`` split on the H2 headings of the standards files."""
    settings = settings or Settings()
    sections: dict[str, str] = {}
    for path in settings.standard_file_paths:
        text = _read_text(path)
        matches = list(_H2.finditer(text))
        for i, match in enumerate(matches):
            end = matches[i + 1].start() if i + 1 < len(matches) else len(text)
            sections[_slug(match.group(1))] = text[match.end() : end].strip()
    return sections


def list_rules(settings: Settings | None = None) -> list[dict[str, str]]:
    """Enumerate every known rule: threshold keys + standards sections, with source."""
    settings = settings or Settings()
    rules: list[dict[str, str]] = [
        {"id": key, "section": "thresholds", "source": settings.thresholds_path.name}
        for key in load_thresholds(settings)
    ]
    for path in settings.standard_file_paths:
        for match in _H2.finditer(_read_text(path)):
            rules.append({"id": _slug(match.group(1)), "section": "standards", "source": path.name})
    return rules
