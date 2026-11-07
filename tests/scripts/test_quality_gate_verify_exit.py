"""Exit codes of the canonical quality gate's ``verify`` command.

``verify`` used to print ``OVERALL_RESULT|SKIP`` and exit 0 when no baseline existed:
every repo without a baseline looked green although nothing had been compared. SKIP
now means "not evaluated" and exits with its own code, distinct from PASS and FAIL.
"""

from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

import pytest

from scripts.quality_gate import (
    EXIT_FAIL,
    EXIT_NOT_EVALUATED,
    EXIT_PASS,
    QualityGate,
)

SCRIPT = Path(__file__).resolve().parents[2] / "scripts" / "quality_gate.py"


def _repo(tmp_path: Path, monkeypatch: pytest.MonkeyPatch) -> Path:
    (tmp_path / QualityGate.CONFIG_FILE).write_text("{}", encoding="utf-8")
    monkeypatch.chdir(tmp_path)
    return tmp_path


def _stub_gates(gate: QualityGate, exit_code: int, metric: float) -> None:
    def fake_run_gate(gate_name: str, *_args: object) -> dict[str, object]:
        return {"gate": gate_name, "exit_code": exit_code, "metric": metric, "command": "stub"}

    gate._run_gate = fake_run_gate  # type: ignore[method-assign]


def test_exit_codes_are_distinct() -> None:
    assert len({EXIT_PASS, EXIT_FAIL, EXIT_NOT_EVALUATED}) == 3
    assert EXIT_PASS == 0


def test_verify_without_baseline_is_not_evaluated(
    tmp_path: Path, monkeypatch: pytest.MonkeyPatch, capsys: pytest.CaptureFixture[str]
) -> None:
    repo = _repo(tmp_path, monkeypatch)

    assert QualityGate().verify() == EXIT_NOT_EVALUATED

    out = capsys.readouterr().out
    assert "OVERALL_RESULT|SKIP" in out
    assert "not evaluated" in out
    report = json.loads((repo / QualityGate.LAST_REPORT_FILE).read_text(encoding="utf-8"))
    assert report["overall"] == "SKIP"
    assert report["reason"] == "no_baseline"


def test_verify_with_baseline_and_no_regression_passes(
    tmp_path: Path, monkeypatch: pytest.MonkeyPatch
) -> None:
    _repo(tmp_path, monkeypatch)
    gate = QualityGate()
    _stub_gates(gate, exit_code=0, metric=1)
    assert gate.baseline() is True

    assert gate.verify() == EXIT_PASS


def test_verify_with_failing_command_fails(
    tmp_path: Path, monkeypatch: pytest.MonkeyPatch
) -> None:
    _repo(tmp_path, monkeypatch)
    gate = QualityGate()
    _stub_gates(gate, exit_code=0, metric=1)
    assert gate.baseline() is True
    _stub_gates(gate, exit_code=1, metric=1)

    assert gate.verify() == EXIT_FAIL


def test_cli_verify_without_baseline_exits_not_evaluated(tmp_path: Path) -> None:
    (tmp_path / QualityGate.CONFIG_FILE).write_text("{}", encoding="utf-8")

    result = subprocess.run(  # noqa: S603 - fixed argv, test-owned script path
        [sys.executable, str(SCRIPT), "verify"],
        cwd=tmp_path,
        capture_output=True,
        text=True,
        check=False,
    )

    assert result.returncode == EXIT_NOT_EVALUATED
    assert "OVERALL_RESULT|SKIP" in result.stdout
