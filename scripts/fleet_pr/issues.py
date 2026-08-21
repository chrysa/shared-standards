"""Pure label-based triage of open issues into report categories."""

from __future__ import annotations

# First matching label wins; order encodes priority.
_LABEL_CATEGORY: tuple[tuple[str, str], ...] = (
    ("bug", "bug"),  # actionable -> becomes a PR
    ("veille", "veille"),  # research/watch -> doc, no code
    ("enhancement", "backlog"),
)


def classify_issue(labels: list[str]) -> str:
    lowered = {label.lower() for label in labels}
    for needle, category in _LABEL_CATEGORY:
        if needle in lowered:
            return category
    return "other"
