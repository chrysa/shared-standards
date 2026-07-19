"""Unit tests for the standards rules reader (offline fixtures)."""

from __future__ import annotations

import pytest

from standards_console import rules_reader
from standards_console.config import Settings
from standards_console.rules_reader import StandardsUnavailable


def test_load_thresholds_drops_notes(std_settings: Settings) -> None:
    thresholds = rules_reader.load_thresholds(std_settings)
    assert "_notes" not in thresholds
    assert thresholds["max_file_lines"] == 500


def test_load_sections_splits_on_h2_only(std_settings: Settings) -> None:
    sections = rules_reader.load_standard_sections(std_settings)
    assert "quality-gates" in sections
    assert "commits" in sections
    assert "stack" in sections  # a further H2 section of the canonical standard
    assert "not-a-section" not in sections  # H3 must not become a section
    assert "Coverage >= 85%." in sections["quality-gates"]


def test_list_rules_enumerates_sources(std_settings: Settings) -> None:
    rules = rules_reader.list_rules(std_settings)
    ids = {r["id"] for r in rules}
    assert {"max_file_lines", "quality-gates", "stack"} <= ids
    thresholds_rule = next(r for r in rules if r["id"] == "max_file_lines")
    assert thresholds_rule["section"] == "thresholds"
    assert thresholds_rule["source"] == "thresholds.json"


def test_missing_file_raises_loudly(std_settings: Settings) -> None:
    (std_settings.thresholds_path).unlink()
    with pytest.raises(StandardsUnavailable):
        rules_reader.load_thresholds(std_settings)
