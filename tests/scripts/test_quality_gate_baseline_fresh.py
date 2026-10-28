"""detect-secrets baseline awareness and coverage.xml freshness for the canonical gate.

The Secrets gate used to count every detect-secrets finding and compare it with ``=``:
a repo's acknowledged fixtures were measured instead of new leaks, and removing one
failed the gate as a regression (pre-commit-tools pilot). The coverage XML fallback
could read a report left on disk by an earlier run (story sc-5280).
"""

from __future__ import annotations

import json
import os
import time
from pathlib import Path

import pytest

from scripts.quality_gate import DEFAULT_GATES, CommandSpec, QualityGate

# Placeholder digests: never real values, only shapes detect-secrets would emit.
H1 = "0" * 40
H2 = "1" * 40
SCAN_FINDINGS_AFTER_FIX = 16
PILOT_BASELINE = 25
RATE_FRESH = 87.5
RATE_ROOT = 80.0
RATE_OUTSIDE_RUN = 90.0


def _gate() -> QualityGate:
    return QualityGate.__new__(QualityGate)


def _scan(results: dict[str, list[dict[str, object]]]) -> str:
    return json.dumps({"version": "1.5.0", "results": results})


def _finding(
    hashed: str, line: int = 1, kind: str = "Secret Keyword"
) -> dict[str, object]:
    return {
        "type": kind,
        "hashed_secret": hashed,
        "line_number": line,
        "is_verified": False,
    }


def _write_baseline(
    tmp_path: Path,
    results: dict[str, list[dict[str, object]]],
    filters: list[dict[str, object]] | None = None,
) -> None:
    data = {"version": "1.5.0", "filters_used": filters or [], "results": results}
    (tmp_path / QualityGate.SECRETS_BASELINE_FILE).write_text(
        json.dumps(data), encoding="utf-8"
    )


class TestSecretCount:
    def test_without_baseline_every_finding_counts(
        self, tmp_path: Path, monkeypatch: pytest.MonkeyPatch
    ) -> None:
        monkeypatch.chdir(tmp_path)
        out = _scan({"a.py": [_finding(H1)], "b.py": [_finding(H2)]})
        assert _gate()._parse_secret_count(out) == 2

    def test_acknowledged_findings_do_not_count_even_if_lines_moved(
        self, tmp_path: Path, monkeypatch: pytest.MonkeyPatch
    ) -> None:
        monkeypatch.chdir(tmp_path)
        _write_baseline(tmp_path, {"a.py": [_finding(H1, line=3)]})
        out = _scan({"a.py": [_finding(H1, line=42)]})
        assert _gate()._parse_secret_count(out) == 0

    def test_new_finding_counts(
        self, tmp_path: Path, monkeypatch: pytest.MonkeyPatch
    ) -> None:
        monkeypatch.chdir(tmp_path)
        _write_baseline(tmp_path, {"a.py": [_finding(H1)]})
        out = _scan({"a.py": [_finding(H1), _finding(H2)]})
        assert _gate()._parse_secret_count(out) == 1

    def test_same_hash_in_another_file_is_new(
        self, tmp_path: Path, monkeypatch: pytest.MonkeyPatch
    ) -> None:
        monkeypatch.chdir(tmp_path)
        _write_baseline(tmp_path, {"a.py": [_finding(H1)]})
        assert _gate()._parse_secret_count(_scan({"b.py": [_finding(H1)]})) == 1

    def test_unreadable_baseline_fails_closed(
        self, tmp_path: Path, monkeypatch: pytest.MonkeyPatch
    ) -> None:
        monkeypatch.chdir(tmp_path)
        (tmp_path / QualityGate.SECRETS_BASELINE_FILE).write_text(
            "{not json", encoding="utf-8"
        )
        assert _gate()._parse_secret_count(_scan({"a.py": [_finding(H1)]})) == 1

    def test_text_output_fallback_unchanged(
        self, tmp_path: Path, monkeypatch: pytest.MonkeyPatch
    ) -> None:
        monkeypatch.chdir(tmp_path)
        assert _gate()._parse_secret_count("Secrets found: 3") == 3


class TestSecretsOperatorAndSpec:
    def test_secrets_gate_compares_with_at_most(self) -> None:
        row = next(gate for gate in DEFAULT_GATES if gate[0] == "Secrets")
        assert row[3] == "≤"

    def test_fewer_findings_than_baseline_passes(self) -> None:
        assert _gate()._compare(SCAN_FINDINGS_AFTER_FIX, PILOT_BASELINE, "≤") is True
        assert _gate()._compare(PILOT_BASELINE + 1, PILOT_BASELINE, "≤") is False

    def test_baseline_exclusions_are_replayed_without_a_shell(
        self, tmp_path: Path, monkeypatch: pytest.MonkeyPatch
    ) -> None:
        monkeypatch.chdir(tmp_path)
        filters: list[dict[str, object]] = [
            {
                "path": "detect_secrets.filters.regex.should_exclude_file",
                "pattern": ["^tests/fixtures/"],
            }
        ]
        _write_baseline(tmp_path, {}, filters)
        default = next(gate for gate in DEFAULT_GATES if gate[0] == "Secrets")[4]
        spec = _gate()._secrets_spec(default)
        assert spec.alternatives == (
            ("detect-secrets", "scan", "--exclude-files", "^tests/fixtures/"),
        )
        assert spec.swallow_exit is True

    @pytest.mark.parametrize(
        ("filter_path", "pattern"),
        [
            ("detect_secrets.filters.regex.should_exclude_file", ".*"),
            ("detect_secrets.filters.regex.should_exclude_file", "^"),
            ("detect_secrets.filters.regex.should_exclude_file", ""),
            ("detect_secrets.filters.regex.should_exclude_file", "["),
            ("detect_secrets.filters.regex.should_exclude_file", r"\.py$"),
            ("detect_secrets.filters.regex.should_exclude_line", "="),
            ("detect_secrets.filters.regex.should_exclude_line", "password"),
            ("detect_secrets.filters.regex.should_exclude_secret", "[a-z]"),
            ("detect_secrets.filters.regex.should_exclude_secret", "x*"),
        ],
    )
    def test_broad_exclusion_patterns_are_ignored(
        self,
        tmp_path: Path,
        monkeypatch: pytest.MonkeyPatch,
        capsys: pytest.CaptureFixture[str],
        filter_path: str,
        pattern: str,
    ) -> None:
        monkeypatch.chdir(tmp_path)
        _write_baseline(tmp_path, {}, [{"path": filter_path, "pattern": [pattern]}])
        default = CommandSpec((("detect-secrets", "scan"),), swallow_exit=True)
        assert _gate()._secrets_spec(default) is default
        assert (
            "WARNING|Secrets|ignored broad exclusion pattern" in capsys.readouterr().out
        )

    def test_targeted_pattern_kept_next_to_a_broad_one(
        self, tmp_path: Path, monkeypatch: pytest.MonkeyPatch
    ) -> None:
        monkeypatch.chdir(tmp_path)
        filters: list[dict[str, object]] = [
            {
                "path": "detect_secrets.filters.regex.should_exclude_file",
                "pattern": ["^tests/fixtures/", ".*"],
            }
        ]
        _write_baseline(tmp_path, {}, filters)
        default = CommandSpec((("detect-secrets", "scan"),), swallow_exit=True)
        spec = _gate()._secrets_spec(default)
        assert spec.alternatives == (
            ("detect-secrets", "scan", "--exclude-files", "^tests/fixtures/"),
        )

    def test_spec_unchanged_without_filters(
        self, tmp_path: Path, monkeypatch: pytest.MonkeyPatch
    ) -> None:
        monkeypatch.chdir(tmp_path)
        default = CommandSpec((("detect-secrets", "scan"),), swallow_exit=True)
        assert _gate()._secrets_spec(default) is default


class TestCoverageReportFreshness:
    @staticmethod
    def _xml(path: Path, rate: str, age_seconds: float) -> None:
        path.write_text(
            f'<?xml version="1.0" ?>\n<coverage line-rate="{rate}">\n</coverage>\n',
            encoding="utf-8",
        )
        past = time.time() - age_seconds
        os.utime(path, (past, past))

    def test_stale_report_is_ignored(
        self, tmp_path: Path, monkeypatch: pytest.MonkeyPatch
    ) -> None:
        monkeypatch.chdir(tmp_path)
        self._xml(tmp_path / "coverage.xml", "0.9", age_seconds=3600)
        gate = _gate()
        gate._gate_started_at = time.time()
        assert gate._parse_coverage_report() == -1.0

    def test_report_written_by_this_run_is_read(
        self, tmp_path: Path, monkeypatch: pytest.MonkeyPatch
    ) -> None:
        monkeypatch.chdir(tmp_path)
        gate = _gate()
        gate._gate_started_at = time.time()
        self._xml(tmp_path / "coverage.xml", "0.875", age_seconds=0)
        assert gate._parse_coverage_report() == RATE_FRESH

    def test_stale_reports_dir_falls_back_to_fresh_root_report(
        self, tmp_path: Path, monkeypatch: pytest.MonkeyPatch
    ) -> None:
        monkeypatch.chdir(tmp_path)
        (tmp_path / "reports").mkdir()
        self._xml(tmp_path / "reports" / "coverage.xml", "0.5", age_seconds=3600)
        gate = _gate()
        gate._gate_started_at = time.time()
        self._xml(tmp_path / "coverage.xml", "0.8", age_seconds=0)
        assert gate._parse_coverage_report() == RATE_ROOT

    def test_outside_a_gate_run_no_freshness_check(
        self, tmp_path: Path, monkeypatch: pytest.MonkeyPatch
    ) -> None:
        monkeypatch.chdir(tmp_path)
        self._xml(tmp_path / "coverage.xml", "0.9", age_seconds=3600)
        assert _gate()._parse_coverage_report() == RATE_OUTSIDE_RUN
