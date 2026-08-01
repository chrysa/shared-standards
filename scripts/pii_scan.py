#!/usr/bin/env python3
"""PII (GDPR) scanner CLI — pre-commit and CI entrypoint.

Exit codes: 0 = clean, 1 = findings, 2 = selftest failure.
"""

import argparse
import json
import sys
from dataclasses import asdict
from fnmatch import fnmatch
from pathlib import Path

from scripts.pii.config import ScanConfig, load_allowlist, load_config
from scripts.pii.scanner import Finding, build_analyzer, scan_text, selftest

CONFIG_FILE = Path(".pii-scan.toml")
ALLOWLIST_FILE = Path(".pii-allowlist.json")
EXIT_CLEAN, EXIT_FINDINGS, EXIT_SELFTEST_FAIL = 0, 1, 2


def main(argv: list[str]) -> int:
    args = _parse_args(argv)
    cfg = load_config(CONFIG_FILE)
    if args.selftest:
        return EXIT_CLEAN if selftest(cfg) else EXIT_SELFTEST_FAIL
    if args.print_fingerprint:
        return _run_print_fingerprint(args.print_fingerprint, cfg)
    allowed = load_allowlist(ALLOWLIST_FILE)
    paths = _resolve_paths(args, cfg)
    findings = _scan_paths(cfg, paths, allowed)
    if args.report:
        _write_report(Path(args.report), findings)
    _print_findings(findings)
    return EXIT_FINDINGS if findings else EXIT_CLEAN


def _parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="PII (GDPR) scanner")
    parser.add_argument("files", nargs="*", help="files to scan (pre-commit mode)")
    parser.add_argument("--all", action="store_true", help="scan the whole repo")
    parser.add_argument("--selftest", action="store_true", help="verify recognizers load")
    parser.add_argument("--report", help="write findings JSON to PATH")
    parser.add_argument(
        "--print-fingerprint",
        metavar="FILE",
        help="scan FILE and print fingerprints (for allowlist authoring)",
    )
    return parser.parse_args(argv)


def _run_print_fingerprint(file: str, cfg: ScanConfig) -> int:
    analyzer = build_analyzer(cfg)
    path = Path(file)
    text = _read_text(path)
    if text is None:
        print(f"error: cannot read {file}", file=sys.stderr)  # print-detection: disable
        return EXIT_CLEAN
    for finding in scan_text(analyzer, cfg, str(path), text):
        print(f"{finding.fingerprint}  {finding.entity}  {finding.path}:{finding.line}")  # print-detection: disable
    return EXIT_CLEAN


def _resolve_paths(args: argparse.Namespace, cfg: ScanConfig) -> list[Path]:
    if args.all:
        return [p for p in Path().rglob("*") if p.is_file() and not _excluded(p, cfg)]
    return [Path(f) for f in args.files if not _excluded(Path(f), cfg)]


def _is_dir_prefix_match(text: str, prefix: str) -> bool:
    return text == prefix or text.startswith(prefix + "/")


def _excluded(path: Path, cfg: ScanConfig) -> bool:
    text = str(path)
    for pat in cfg.exclude_paths:
        if fnmatch(text, pat):
            return True
        if pat.endswith("/") or ("*" not in pat and "?" not in pat and "[" not in pat):
            if _is_dir_prefix_match(text, pat.rstrip("/")):
                return True
    return False


def _scan_paths(cfg: ScanConfig, paths: list[Path], allowed: set[str]) -> list[Finding]:
    analyzer = build_analyzer(cfg)
    findings: list[Finding] = []
    for path in paths:
        text = _read_text(path)
        if text is None:
            continue
        findings.extend(
            finding
            for finding in scan_text(analyzer, cfg, str(path), text)
            if finding.fingerprint not in allowed
        )
    return findings


def _read_text(path: Path) -> str | None:
    try:
        return path.read_text(encoding="utf-8")
    except (UnicodeDecodeError, OSError):
        return None


def _write_report(path: Path, findings: list[Finding]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    payload = [asdict(f) for f in findings]
    path.write_text(json.dumps(payload, indent=2), encoding="utf-8")


def _print_findings(findings: list[Finding]) -> None:
    for f in findings:
        print(f"{f.path}:{f.line} · {f.entity} · score={f.score} · fp={f.fingerprint[:12]}")  # print-detection: disable
    if findings:
        print(f"\nPII_RESULT|FAIL|{len(findings)} finding(s). Allowlist a false positive in .pii-allowlist.json.")  # print-detection: disable
    else:
        print("PII_RESULT|PASS|0 findings")  # print-detection: disable


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
