from scripts.pii.config import ScanConfig
from scripts.pii.scanner import build_analyzer, scan_text

DIRTY = "Contact jean.dupont@example.com or IBAN FR7630006000011234567890189."


def test_scan_text_flags_email() -> None:
    cfg = ScanConfig(entities=["EMAIL_ADDRESS", "IBAN_CODE"])
    analyzer = build_analyzer(cfg)
    findings = scan_text(analyzer, cfg, "a.txt", DIRTY)
    assert any(f.entity == "EMAIL_ADDRESS" for f in findings)


def test_scan_text_clean_is_empty() -> None:
    cfg = ScanConfig()
    analyzer = build_analyzer(cfg)
    assert scan_text(analyzer, cfg, "a.txt", "just some words here") == []


def test_finding_has_stable_fingerprint() -> None:
    cfg = ScanConfig(entities=["EMAIL_ADDRESS"])
    analyzer = build_analyzer(cfg)
    f1 = scan_text(analyzer, cfg, "a.txt", DIRTY)[0]
    f2 = scan_text(analyzer, cfg, "a.txt", DIRTY)[0]
    assert f1.fingerprint == f2.fingerprint
