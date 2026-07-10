"""Unit tests for the local compliance reader (offline fixtures)."""

from __future__ import annotations

import pytest

from standards_console import compliance_reader
from standards_console.compliance_reader import ComplianceSnapshotUnavailable
from standards_console.config import Settings


def test_audit_status_sorted_and_deviations(std_settings: Settings) -> None:
    rows = compliance_reader.audit_status(settings=std_settings)
    repos = [r["repo"] for r in rows]
    assert "alpha" not in repos  # only "ok" everywhere -> no deviation
    assert set(repos) == {"beta", "gamma"}
    assert rows == sorted(rows, key=lambda r: r["score"], reverse=True)
    gamma = next(r for r in rows if r["repo"] == "gamma")
    assert gamma["deviations"] == [{"dimension": "makefile", "signal": "fail"}]


def test_audit_min_severity_filters_warn(std_settings: Settings) -> None:
    rows = compliance_reader.audit_status(min_severity="fail", settings=std_settings)
    assert {r["repo"] for r in rows} == {"gamma"}


def test_audit_section_filter(std_settings: Settings) -> None:
    rows = compliance_reader.audit_status(section="cliff", settings=std_settings)
    assert rows == []  # cliff rows are all "ok"


def test_repo_diff_includes_classification(std_settings: Settings) -> None:
    diff = compliance_reader.repo_diff("gamma", settings=std_settings)
    assert diff["compliant"] is False
    assert diff["deviations"] == [{"dimension": "makefile", "signal": "fail"}]
    assert diff["classification"] == {"status": "dev", "runtime": "exempt:native"}


def test_repo_diff_compliant_repo(std_settings: Settings) -> None:
    diff = compliance_reader.repo_diff("alpha", settings=std_settings)
    assert diff["compliant"] is True
    assert diff["deviations"] == []


def test_source_mtimes_lists_dimensions(std_settings: Settings) -> None:
    mtimes = compliance_reader.source_mtimes(std_settings)
    assert set(mtimes) == {"makefile", "cliff"}
    assert all("T" in ts for ts in mtimes.values())  # ISO-8601


def test_missing_compliance_dir_raises(std_settings: Settings) -> None:
    for path in std_settings.compliance_dir_path.glob("*.json"):
        path.unlink()
    with pytest.raises(ComplianceSnapshotUnavailable):
        compliance_reader.audit_status(settings=std_settings)
