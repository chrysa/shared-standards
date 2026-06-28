from pathlib import Path

from scripts.pii.config import ScanConfig
from scripts.pii_scan import _excluded, main

FIXTURES = Path(__file__).parent / "fixtures"
EXIT_CLEAN = 0
EXIT_FINDINGS = 1


def test_main_clean_file_returns_zero() -> None:
    assert main([str(FIXTURES / "clean.txt")]) == EXIT_CLEAN


def test_main_dirty_file_returns_one() -> None:
    assert main([str(FIXTURES / "dirty.txt")]) == EXIT_FINDINGS


def test_main_selftest_returns_zero() -> None:
    assert main(["--selftest"]) == EXIT_CLEAN


def test_main_print_fingerprint_returns_zero() -> None:
    assert main(["--print-fingerprint", str(FIXTURES / "dirty.txt")]) == EXIT_CLEAN


def test_main_report_writes_json(tmp_path: Path) -> None:
    report = tmp_path / "r.json"
    main([str(FIXTURES / "dirty.txt"), "--report", str(report)])
    assert report.exists()
    import json

    data = json.loads(report.read_text())
    assert len(data) > 0
    assert set(data[0].keys()) >= {"path", "line", "entity", "score", "fingerprint"}


def test_excluded_does_not_match_partial_name() -> None:
    cfg = ScanConfig(exclude_paths=[".git/"])
    assert not _excluded(Path(".gitignore"), cfg)
    assert _excluded(Path(".git/config"), cfg)
