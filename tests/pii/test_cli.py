from pathlib import Path

from scripts.pii_scan import main

FIXTURES = Path(__file__).parent / "fixtures"
EXIT_CLEAN = 0
EXIT_FINDINGS = 1


def test_main_clean_file_returns_zero() -> None:
    assert main([str(FIXTURES / "clean.txt")]) == EXIT_CLEAN


def test_main_dirty_file_returns_one() -> None:
    assert main([str(FIXTURES / "dirty.txt")]) == EXIT_FINDINGS


def test_main_selftest_returns_zero() -> None:
    assert main(["--selftest"]) == EXIT_CLEAN
