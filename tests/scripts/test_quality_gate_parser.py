"""Coverage parser tests for the canonical quality_gate.

Guards shared-standards#274 (a repo at 42% reported 85% and passed its own gate) and
the regression this fix closes: a pytest progress marker `[ 42%]` on a test name
containing "covered" was read as coverage. The canonical is fanned out to the fleet, so
this test protects every consumer's gate — it must live with the source.
"""

from __future__ import annotations

import pytest

from scripts.quality_gate import QualityGate


def _parser() -> QualityGate:
    """A QualityGate whose XML fallback is neutralised, so -1.0 means 'no coverage found'."""
    gate = QualityGate.__new__(QualityGate)
    gate._parse_coverage_report = lambda: -1.0  # type: ignore[method-assign]
    return gate


class TestParseCoverage:
    @pytest.mark.parametrize(
        ("output", "expected"),
        [
            ("Total coverage: 64.2%\n", 64.2),
            ("TOTAL    3595  234  1336  171  91%\n", 91.0),
            ("no numbers here\n", -1.0),
            ("", -1.0),
        ],
    )
    def test_reads_real_coverage_or_reports_absence(self, output: str, expected: float) -> None:
        assert _parser()._parse_coverage(output) == expected

    @pytest.mark.parametrize(
        "output",
        [
            "tests/test_x.py::test_everything_is_covered PASSED [ 42%]\n",
            "test_synthesis_multiple_repos_totals PASSED [ 93%]\n",
            "tests/test_a.py::test_total_recall PASSED [100%]\n",
        ],
    )
    def test_pytest_progress_marker_is_not_coverage(self, output: str) -> None:
        # The line matches a token ("covered"/"total") but the only percentage is the
        # bracketed pytest progress marker — it must not be read as coverage.
        assert _parser()._parse_coverage(output) == -1.0

    def test_real_total_line_wins_over_a_progress_marker(self) -> None:
        output = "test_everything_is_covered PASSED [ 42%]\nTotal coverage: 88.8%\n"
        assert _parser()._parse_coverage(output) == 88.8
