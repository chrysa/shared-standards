# PII (Presidio) Detection Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add Microsoft Presidio-based PII (GDPR) detection to `chrysa/shared-standards`, running as a blocking pre-commit hook and a blocking CI job.

**Architecture:** A small `scripts/pii/` Python package holds custom recognizers (French NIR/CNI) and config loading; `scripts/pii_scan.py` is the CLI entrypoint used by both a `repo: local` pre-commit hook and a GitHub Actions workflow. Findings above a score threshold and not present in `.pii-allowlist.json` cause a non-zero exit.

**Tech Stack:** Python 3.14, `presidio-analyzer`, spaCy models `fr_core_news_sm` + `en_core_web_sm` (pinned wheels), pytest + pytest-mock, Ruff, Mypy.

## Global Constraints

- Language: **English** for all code, comments, docs, config — verbatim from STANDARDS.md.
- Python target **3.14** (CI matrix 3.12 + 3.14).
- Linting: **Ruff + Mypy**, lint warnings **0**, Mypy clean.
- Max function lines **50** · max file lines **500** · cyclomatic complexity ≤ 10.
- **No nested named function > 5 lines** — extract to top-level (Ruff `PLR0915` + `def-inside-def`).
- Commits: **Conventional Commits** (`feat`, `fix`, `chore`, `docs`, `test`, `ci`).
- Test coverage **≥ 85%**.
- Work on a `feature/` branch off `develop`. Do NOT commit to `main`.
- pytest style per `.claude/skills/testing-pytest/SKILL.md` (DDD, pytest-mock, named constants).

---

## File Structure

- Create: `scripts/pii/__init__.py` — package marker.
- Create: `scripts/pii/recognizers.py` — custom `FR_NIR`, `FR_CNI` recognizers + NIR key validation.
- Create: `scripts/pii/config.py` — load `.pii-scan.toml` + `.pii-allowlist.json` into typed dataclasses.
- Create: `scripts/pii/scanner.py` — build analyzer, scan text/files, apply threshold + allowlist.
- Create: `scripts/pii_scan.py` — CLI entrypoint (`--all`, `--report`, `--selftest`, file args).
- Create: `.pii-scan.toml` — default config.
- Create: `.pii-allowlist.json` — empty allowlist seed.
- Create: `tests/pii/test_recognizers.py`, `tests/pii/test_config.py`, `tests/pii/test_scanner.py`, `tests/pii/test_cli.py`.
- Create: `tests/pii/fixtures/` — `dirty.txt`, `clean.txt`.
- Create: `workflows/pii-scan.yml` — CI job.
- Modify: `.pre-commit-config.yaml` — add `repo: local` hook `id: pii-scan`.
- Modify: `README.md` — document the scanner.
- Modify: `CHANGELOG.md` — add entry.

---

## Task 0: Branch + dependency baseline

**Files:**
- Create: `scripts/pii/__init__.py`

**Interfaces:**
- Produces: the `scripts.pii` package path; pinned dependency list reused by hook + workflow.

- [ ] **Step 1: Create the feature branch**

```bash
cd chrysa/shared-standards
git checkout develop && git pull --ff-only
git checkout -b feature/pii-presidio-detection
```

- [ ] **Step 2: Create the package marker**

Create `scripts/pii/__init__.py`:

```python
"""PII (GDPR) detection package: Presidio recognizers, config, and scanner."""
```

- [ ] **Step 3: Record the pinned dependency set**

These exact pins are reused verbatim in the pre-commit hook (`additional_dependencies`) and the CI workflow. spaCy models are installed as pip wheels so the pre-commit environment stays hermetic (no `spacy download`).

```text
presidio-analyzer==2.2.359
fr_core_news_sm @ https://github.com/explosion/spacy-models/releases/download/fr_core_news_sm-3.8.0/fr_core_news_sm-3.8.0-py3-none-any.whl
en_core_web_sm @ https://github.com/explosion/spacy-models/releases/download/en_core_web_sm-3.8.0/en_core_web_sm-3.8.0-py3-none-any.whl
```

- [ ] **Step 4: Install locally for development**

```bash
pip install presidio-analyzer==2.2.359
pip install "fr_core_news_sm @ https://github.com/explosion/spacy-models/releases/download/fr_core_news_sm-3.8.0/fr_core_news_sm-3.8.0-py3-none-any.whl"
pip install "en_core_web_sm @ https://github.com/explosion/spacy-models/releases/download/en_core_web_sm-3.8.0/en_core_web_sm-3.8.0-py3-none-any.whl"
pip install pytest pytest-mock
```

Expected: installs succeed.

- [ ] **Step 5: Commit**

```bash
git add scripts/pii/__init__.py
git commit -m "chore: scaffold pii detection package"
```

---

## Task 1: French NIR control-key validation

**Files:**
- Create: `scripts/pii/recognizers.py`
- Test: `tests/pii/test_recognizers.py`

**Interfaces:**
- Produces: `is_valid_nir(digits: str) -> bool` — True iff the 15-char French social-security number has a correct 2-digit control key. Handles Corsica (`2A`→`19`, `2B`→`18`).

- [ ] **Step 1: Write the failing test**

Create `tests/pii/test_recognizers.py`:

```python
from scripts.pii.recognizers import is_valid_nir

VALID_NIR = "180127505200124"      # control key 24, valid
INVALID_KEY_NIR = "180127505200199"  # wrong control key
CORSICA_NIR = "1820212A00125"      # contains 2A → normalized to 19


def test_is_valid_nir_accepts_correct_key() -> None:
    assert is_valid_nir(VALID_NIR) is True


def test_is_valid_nir_rejects_wrong_key() -> None:
    assert is_valid_nir(INVALID_KEY_NIR) is False


def test_is_valid_nir_rejects_wrong_length() -> None:
    assert is_valid_nir("12345") is False
```

- [ ] **Step 2: Run test to verify it fails**

Run: `pytest tests/pii/test_recognizers.py -v`
Expected: FAIL with `ModuleNotFoundError` / `ImportError: cannot import name 'is_valid_nir'`.

- [ ] **Step 3: Write minimal implementation**

Create `scripts/pii/recognizers.py`:

```python
"""Custom Presidio recognizers for French personal identifiers."""

from presidio_analyzer import Pattern, PatternRecognizer

NIR_LENGTH = 15
NIR_KEY_MODULO = 97
_CORSICA = {"2A": "19", "2B": "18"}


def is_valid_nir(digits: str) -> bool:
    """Return True if a 15-char French NIR has a valid 2-digit control key."""
    raw = digits.strip().replace(" ", "")
    if len(raw) != NIR_LENGTH:
        return False
    body, key = raw[:13], raw[13:]
    normalized = _normalize_corsica(body)
    if not normalized.isdigit() or not key.isdigit():
        return False
    expected = NIR_KEY_MODULO - (int(normalized) % NIR_KEY_MODULO)
    return expected == int(key)


def _normalize_corsica(body: str) -> str:
    """Replace a Corsica department code (2A/2B) with its numeric equivalent."""
    dept = body[5:7].upper()
    if dept in _CORSICA:
        return body[:5] + _CORSICA[dept] + body[7:]
    return body
```

- [ ] **Step 4: Run test to verify it passes**

Run: `pytest tests/pii/test_recognizers.py -v`
Expected: PASS (3 tests).

- [ ] **Step 5: Commit**

```bash
git add scripts/pii/recognizers.py tests/pii/test_recognizers.py
git commit -m "feat: add French NIR control-key validation"
```

---

## Task 2: Custom NIR + CNI recognizers

**Files:**
- Modify: `scripts/pii/recognizers.py`
- Test: `tests/pii/test_recognizers.py`

**Interfaces:**
- Consumes: `is_valid_nir` from Task 1.
- Produces: `build_custom_recognizers() -> list[PatternRecognizer]` returning recognizers with `supported_entity` values `FR_NIR` and `FR_CNI`. The NIR recognizer rejects matches whose control key is invalid via `validate_result`.

- [ ] **Step 1: Write the failing test**

Append to `tests/pii/test_recognizers.py`:

```python
from scripts.pii.recognizers import build_custom_recognizers


def test_build_custom_recognizers_covers_fr_entities() -> None:
    entities = {r.supported_entities[0] for r in build_custom_recognizers()}
    assert {"FR_NIR", "FR_CNI"} <= entities


def test_nir_recognizer_invalidates_bad_key() -> None:
    nir = next(r for r in build_custom_recognizers() if r.supported_entities[0] == "FR_NIR")
    assert nir.validate_result("180127505200199") is False
    assert nir.validate_result("180127505200124") is True
```

- [ ] **Step 2: Run test to verify it fails**

Run: `pytest tests/pii/test_recognizers.py -v`
Expected: FAIL with `ImportError: cannot import name 'build_custom_recognizers'`.

- [ ] **Step 3: Write minimal implementation**

Append to `scripts/pii/recognizers.py`:

```python
NIR_PATTERN = r"\b[12]\s?\d{2}\s?\d{2}\s?\d{2}[AB0-9]\s?\d{3}\s?\d{3}\s?\d{2}\b"
CNI_PATTERN = r"\b\d{12}\b"


class FrNirRecognizer(PatternRecognizer):
    """French social-security number recognizer with control-key validation."""

    def __init__(self) -> None:
        super().__init__(
            supported_entity="FR_NIR",
            patterns=[Pattern("FR_NIR", NIR_PATTERN, 0.6)],
            supported_language="fr",
        )

    def validate_result(self, pattern_text: str) -> bool:
        return is_valid_nir(pattern_text)


def build_custom_recognizers() -> list[PatternRecognizer]:
    """Return the custom French PII recognizers (NIR, CNI)."""
    cni = PatternRecognizer(
        supported_entity="FR_CNI",
        patterns=[Pattern("FR_CNI", CNI_PATTERN, 0.3)],
        supported_language="fr",
    )
    return [FrNirRecognizer(), cni]
```

- [ ] **Step 4: Run test to verify it passes**

Run: `pytest tests/pii/test_recognizers.py -v`
Expected: PASS (5 tests).

- [ ] **Step 5: Commit**

```bash
git add scripts/pii/recognizers.py tests/pii/test_recognizers.py
git commit -m "feat: add FR_NIR and FR_CNI custom recognizers"
```

---

## Task 3: Config + allowlist loader

**Files:**
- Create: `scripts/pii/config.py`
- Create: `.pii-scan.toml`
- Create: `.pii-allowlist.json`
- Test: `tests/pii/test_config.py`

**Interfaces:**
- Produces:
  - `ScanConfig` dataclass: `score_threshold: float`, `languages: list[str]`, `entities: list[str]`, `exclude_paths: list[str]`.
  - `load_config(path: Path) -> ScanConfig` — reads TOML, falls back to defaults if file missing.
  - `load_allowlist(path: Path) -> set[str]` — reads a JSON `{"allow": ["<sha256>", ...]}` of finding fingerprints; missing file → empty set.

- [ ] **Step 1: Write the failing test**

Create `tests/pii/test_config.py`:

```python
from pathlib import Path

from scripts.pii.config import load_allowlist, load_config

DEFAULT_THRESHOLD = 0.5


def test_load_config_defaults_when_missing(tmp_path: Path) -> None:
    cfg = load_config(tmp_path / "nope.toml")
    assert cfg.score_threshold == DEFAULT_THRESHOLD
    assert "fr" in cfg.languages


def test_load_config_reads_threshold(tmp_path: Path) -> None:
    toml = tmp_path / ".pii-scan.toml"
    toml.write_text('score_threshold = 0.8\nlanguages = ["fr"]\nentities = ["EMAIL_ADDRESS"]\nexclude_paths = []\n', encoding="utf-8")
    cfg = load_config(toml)
    assert cfg.score_threshold == 0.8
    assert cfg.entities == ["EMAIL_ADDRESS"]


def test_load_allowlist_missing_is_empty(tmp_path: Path) -> None:
    assert load_allowlist(tmp_path / "nope.json") == set()
```

- [ ] **Step 2: Run test to verify it fails**

Run: `pytest tests/pii/test_config.py -v`
Expected: FAIL with `ImportError`.

- [ ] **Step 3: Write minimal implementation**

Create `scripts/pii/config.py`:

```python
"""Load PII scan configuration and false-positive allowlist."""

import json
import tomllib
from dataclasses import dataclass, field
from pathlib import Path

DEFAULT_THRESHOLD = 0.5
DEFAULT_LANGUAGES = ["fr", "en"]
DEFAULT_ENTITIES = [
    "EMAIL_ADDRESS", "IBAN_CODE", "PHONE_NUMBER", "CREDIT_CARD",
    "IP_ADDRESS", "PERSON", "FR_NIR", "FR_CNI",
]


@dataclass(frozen=True)
class ScanConfig:
    score_threshold: float = DEFAULT_THRESHOLD
    languages: list[str] = field(default_factory=lambda: list(DEFAULT_LANGUAGES))
    entities: list[str] = field(default_factory=lambda: list(DEFAULT_ENTITIES))
    exclude_paths: list[str] = field(default_factory=list)


def load_config(path: Path) -> ScanConfig:
    """Read scan config from TOML, falling back to defaults if absent."""
    if not path.exists():
        return ScanConfig()
    data = tomllib.loads(path.read_text(encoding="utf-8"))
    return ScanConfig(
        score_threshold=float(data.get("score_threshold", DEFAULT_THRESHOLD)),
        languages=list(data.get("languages", DEFAULT_LANGUAGES)),
        entities=list(data.get("entities", DEFAULT_ENTITIES)),
        exclude_paths=list(data.get("exclude_paths", [])),
    )


def load_allowlist(path: Path) -> set[str]:
    """Read the allowlist of finding fingerprints; missing file → empty set."""
    if not path.exists():
        return set()
    data = json.loads(path.read_text(encoding="utf-8"))
    return set(data.get("allow", []))
```

- [ ] **Step 4: Run test to verify it passes**

Run: `pytest tests/pii/test_config.py -v`
Expected: PASS (3 tests).

- [ ] **Step 5: Create the seed config files**

Create `.pii-scan.toml`:

```toml
# PII (GDPR) scan configuration — see docs and scripts/pii_scan.py
score_threshold = 0.5
languages = ["fr", "en"]
entities = [
  "EMAIL_ADDRESS", "IBAN_CODE", "PHONE_NUMBER", "CREDIT_CARD",
  "IP_ADDRESS", "PERSON", "FR_NIR", "FR_CNI",
]
# Globs excluded from scanning (binary/generated/large artifacts).
exclude_paths = ["graphify", "sys", "seeds/", "*.svg", "*.png", "*.lock"]
```

Create `.pii-allowlist.json`:

```json
{
  "_comment": "sha256 fingerprints of reviewed false positives (synthetic fixtures). Add with: pii_scan.py --print-fingerprint <file>",
  "allow": []
}
```

- [ ] **Step 6: Commit**

```bash
git add scripts/pii/config.py tests/pii/test_config.py .pii-scan.toml .pii-allowlist.json
git commit -m "feat: add PII scan config and allowlist loader"
```

---

## Task 4: Scanner core

**Files:**
- Create: `scripts/pii/scanner.py`
- Test: `tests/pii/test_scanner.py`

**Interfaces:**
- Consumes: `build_custom_recognizers` (Task 2), `ScanConfig` (Task 3).
- Produces:
  - `Finding` dataclass: `path: str`, `line: int`, `entity: str`, `score: float`, `fingerprint: str` (sha256 of `entity|path|line|matched_text`).
  - `build_analyzer(cfg: ScanConfig) -> AnalyzerEngine` — analyzer with custom recognizers registered for `fr`.
  - `scan_text(analyzer, cfg, path, text) -> list[Finding]` — findings above `cfg.score_threshold`.
  - `selftest(cfg: ScanConfig) -> bool` — True if a known dirty string yields ≥1 finding.

- [ ] **Step 1: Write the failing test**

Create `tests/pii/test_scanner.py`:

```python
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `pytest tests/pii/test_scanner.py -v`
Expected: FAIL with `ImportError`.

- [ ] **Step 3: Write minimal implementation**

Create `scripts/pii/scanner.py`:

```python
"""Presidio-backed PII scanner: build the engine and scan text into Findings."""

import hashlib
from dataclasses import dataclass

from presidio_analyzer import AnalyzerEngine
from presidio_analyzer.nlp_engine import NlpEngineProvider

from scripts.pii.config import ScanConfig
from scripts.pii.recognizers import build_custom_recognizers

SELFTEST_SAMPLE = "Email test.user@example.com"
_MODELS = {"fr": "fr_core_news_sm", "en": "en_core_web_sm"}


def build_analyzer(cfg: ScanConfig) -> AnalyzerEngine:
    """Assemble an AnalyzerEngine for the configured languages + custom recognizers."""
    models = [{"lang_code": lang, "model_name": _MODELS[lang]} for lang in cfg.languages]
    provider = NlpEngineProvider(
        nlp_configuration={"nlp_engine_name": "spacy", "models": models}
    )
    analyzer = AnalyzerEngine(
        nlp_engine=provider.create_engine(),
        supported_languages=cfg.languages,
    )
    for recognizer in build_custom_recognizers():
        analyzer.registry.add_recognizer(recognizer)
    return analyzer


@dataclass(frozen=True)
class Finding:
    path: str
    line: int
    entity: str
    score: float
    fingerprint: str


def scan_text(analyzer: AnalyzerEngine, cfg: ScanConfig, path: str, text: str) -> list[Finding]:
    """Return findings above the score threshold for one file's text."""
    lang = cfg.languages[0]
    results = analyzer.analyze(text=text, language=lang, entities=cfg.entities)
    findings: list[Finding] = []
    for res in results:
        if res.score < cfg.score_threshold:
            continue
        line = text.count("\n", 0, res.start) + 1
        matched = text[res.start:res.end]
        findings.append(_to_finding(path, line, res.entity_type, res.score, matched))
    return findings


def _to_finding(path: str, line: int, entity: str, score: float, matched: str) -> Finding:
    digest = hashlib.sha256(f"{entity}|{path}|{line}|{matched}".encode()).hexdigest()
    return Finding(path=path, line=line, entity=entity, score=round(score, 3), fingerprint=digest)


def selftest(cfg: ScanConfig) -> bool:
    """Return True if recognizers load and flag a known dirty sample."""
    analyzer = build_analyzer(cfg)
    return len(scan_text(analyzer, cfg, "<selftest>", SELFTEST_SAMPLE)) >= 1
```

- [ ] **Step 4: Run test to verify it passes**

Run: `pytest tests/pii/test_scanner.py -v`
Expected: PASS (3 tests). First run downloads nothing (models are pip-installed).

- [ ] **Step 5: Commit**

```bash
git add scripts/pii/scanner.py tests/pii/test_scanner.py
git commit -m "feat: add Presidio scanner core"
```

---

## Task 5: CLI entrypoint

**Files:**
- Create: `scripts/pii_scan.py`
- Create: `tests/pii/fixtures/dirty.txt`
- Create: `tests/pii/fixtures/clean.txt`
- Test: `tests/pii/test_cli.py`

**Interfaces:**
- Consumes: `load_config`, `load_allowlist`, `build_analyzer`, `scan_text`, `selftest`.
- Produces: `main(argv: list[str]) -> int` — exit code `0` (clean), `1` (findings), `2` (selftest failure). Modes: positional file paths (pre-commit), `--all` (walk repo honoring `exclude_paths`), `--selftest`, `--report PATH` (write JSON), `--print-fingerprint FILE`.

- [ ] **Step 1: Create the fixtures**

Create `tests/pii/fixtures/dirty.txt`:

```text
Reach me at jean.dupont@example.com
IBAN: FR7630006000011234567890189
```

Create `tests/pii/fixtures/clean.txt`:

```text
This file mentions no personal data whatsoever.
Just lorem ipsum dolor sit amet.
```

- [ ] **Step 2: Write the failing test**

Create `tests/pii/test_cli.py`:

```python
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
```

- [ ] **Step 3: Run test to verify it fails**

Run: `pytest tests/pii/test_cli.py -v`
Expected: FAIL with `ImportError`.

- [ ] **Step 4: Write minimal implementation**

Create `scripts/pii_scan.py`:

```python
#!/usr/bin/env python3
"""PII (GDPR) scanner CLI — pre-commit and CI entrypoint.

Exit codes: 0 = clean, 1 = findings, 2 = selftest failure.
"""

import argparse
import json
import sys
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
    return parser.parse_args(argv)


def _resolve_paths(args: argparse.Namespace, cfg: ScanConfig) -> list[Path]:
    if args.all:
        return [p for p in Path().rglob("*") if p.is_file() and not _excluded(p, cfg)]
    return [Path(f) for f in args.files if not _excluded(Path(f), cfg)]


def _excluded(path: Path, cfg: ScanConfig) -> bool:
    text = str(path)
    return any(fnmatch(text, pat) or text.startswith(pat.rstrip("/")) for pat in cfg.exclude_paths)


def _scan_paths(cfg: ScanConfig, paths: list[Path], allowed: set[str]) -> list[Finding]:
    analyzer = build_analyzer(cfg)
    findings: list[Finding] = []
    for path in paths:
        text = _read_text(path)
        if text is None:
            continue
        for finding in scan_text(analyzer, cfg, str(path), text):
            if finding.fingerprint not in allowed:
                findings.append(finding)
    return findings


def _read_text(path: Path) -> str | None:
    try:
        return path.read_text(encoding="utf-8")
    except (UnicodeDecodeError, OSError):
        return None


def _write_report(path: Path, findings: list[Finding]) -> None:
    payload = [vars(f) for f in findings]
    path.write_text(json.dumps(payload, indent=2), encoding="utf-8")


def _print_findings(findings: list[Finding]) -> None:
    for f in findings:
        print(f"{f.path}:{f.line} · {f.entity} · score={f.score} · fp={f.fingerprint[:12]}")
    if findings:
        print(f"\nPII_RESULT|FAIL|{len(findings)} finding(s). Allowlist a false positive in .pii-allowlist.json.")
    else:
        print("PII_RESULT|PASS|0 findings")


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
```

- [ ] **Step 5: Run test to verify it passes**

Run: `pytest tests/pii/test_cli.py -v`
Expected: PASS (3 tests).

- [ ] **Step 6: Run the full suite + lint + types**

Run: `pytest tests/pii/ -v && ruff check scripts/pii_scan.py scripts/pii/ && mypy scripts/pii_scan.py scripts/pii/`
Expected: all PASS, 0 lint warnings, Mypy clean.

- [ ] **Step 7: Commit**

```bash
git add scripts/pii_scan.py tests/pii/test_cli.py tests/pii/fixtures/
git commit -m "feat: add PII scanner CLI entrypoint"
```

---

## Task 6: Pre-commit hook wiring

**Files:**
- Modify: `.pre-commit-config.yaml`

**Interfaces:**
- Consumes: `scripts/pii_scan.py` (Task 5) and the pinned deps (Task 0, Step 3).

- [ ] **Step 1: Add the local hook**

In `.pre-commit-config.yaml`, extend the existing `repo: local` block (the one with `gitversion-canonical-drift`) by adding this hook to its `hooks:` list:

```yaml
  - id: pii-scan
    name: PII (GDPR) detection (Presidio)
    entry: python -m scripts.pii_scan
    language: python
    pass_filenames: true
    require_serial: true
    exclude: ^(graphify|sys|seeds/|tests/pii/fixtures/)
    additional_dependencies:
    - presidio-analyzer==2.2.359
    - fr_core_news_sm @ https://github.com/explosion/spacy-models/releases/download/fr_core_news_sm-3.8.0/fr_core_news_sm-3.8.0-py3-none-any.whl
    - en_core_web_sm @ https://github.com/explosion/spacy-models/releases/download/en_core_web_sm-3.8.0/en_core_web_sm-3.8.0-py3-none-any.whl
```

Note: `entry: python -m scripts.pii_scan` requires `scripts/__init__.py` to exist so `scripts.pii_scan` is importable as a module. If `scripts/__init__.py` is absent, create it empty in this step and `git add` it.

- [ ] **Step 2: Verify the hook runs against the dirty fixture**

Run: `pre-commit run pii-scan --files tests/pii/fixtures/dirty.txt`
Expected: FAIL — output shows `EMAIL_ADDRESS` / `IBAN_CODE` findings. (The fixture is excluded from normal staged runs but `--files` forces it.)

- [ ] **Step 3: Verify the hook passes against the clean fixture**

Run: `pre-commit run pii-scan --files tests/pii/fixtures/clean.txt`
Expected: PASS.

- [ ] **Step 4: Commit**

```bash
git add .pre-commit-config.yaml scripts/__init__.py
git commit -m "ci: wire pii-scan pre-commit hook"
```

---

## Task 7: CI workflow

**Files:**
- Create: `workflows/pii-scan.yml`

**Interfaces:**
- Consumes: `scripts/pii_scan.py --all --report`.

- [ ] **Step 1: Create the workflow**

Create `workflows/pii-scan.yml`:

```yaml
name: PII Scan (GDPR)
on:
  push:
    branches: [develop, main]
  pull_request:
jobs:
  pii-scan:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    - uses: actions/setup-python@v5
      with:
        python-version: '3.14'
    - name: Install Presidio + models
      run: |
        pip install presidio-analyzer==2.2.359
        pip install "fr_core_news_sm @ https://github.com/explosion/spacy-models/releases/download/fr_core_news_sm-3.8.0/fr_core_news_sm-3.8.0-py3-none-any.whl"
        pip install "en_core_web_sm @ https://github.com/explosion/spacy-models/releases/download/en_core_web_sm-3.8.0/en_core_web_sm-3.8.0-py3-none-any.whl"
    - name: Selftest
      run: python -m scripts.pii_scan --selftest
    - name: Scan repository
      run: python -m scripts.pii_scan --all --report pii-report.json
    - name: Upload report
      if: always()
      uses: actions/upload-artifact@v4
      with:
        name: pii-report
        path: pii-report.json
```

- [ ] **Step 2: Lint the workflow YAML**

Run: `python -c "import yaml,sys; yaml.safe_load(open('workflows/pii-scan.yml'))" && echo OK`
Expected: `OK`.

- [ ] **Step 3: Commit**

```bash
git add workflows/pii-scan.yml
git commit -m "ci: add PII scan GitHub Actions workflow"
```

---

## Task 8: Documentation

**Files:**
- Modify: `README.md`
- Modify: `CHANGELOG.md`

- [ ] **Step 1: Document in README**

Add a section to `README.md` under the existing structure/tooling area:

```markdown
## PII (GDPR) detection

Microsoft Presidio scans staged files (pre-commit) and the whole repo (CI) for
personal data: emails, IBAN, phone numbers, credit cards, IP addresses, person
names, French NIR (with control-key validation) and CNI.

- Config: `.pii-scan.toml` (entities, score threshold, excluded globs).
- Allowlist false positives by fingerprint in `.pii-allowlist.json`.
- Run manually: `python -m scripts.pii_scan --all`
- Self-check: `python -m scripts.pii_scan --selftest`

The hook is blocking in both pre-commit and CI. PII in test fixtures is in scope
by design — allowlist synthetic data rather than excluding `tests/`.
```

- [ ] **Step 2: Add a CHANGELOG entry**

Add under the unreleased section of `CHANGELOG.md`:

```markdown
### Added
- PII (GDPR) detection via Presidio: blocking pre-commit hook + CI workflow,
  French NIR/CNI recognizers, configurable entities/threshold, fingerprint allowlist.
```

- [ ] **Step 3: Run the full gate one last time**

Run: `pytest tests/pii/ -v && ruff check scripts/pii/ scripts/pii_scan.py && mypy scripts/pii/ scripts/pii_scan.py`
Expected: all PASS.

- [ ] **Step 4: Commit**

```bash
git add README.md CHANGELOG.md
git commit -m "docs: document PII (GDPR) detection"
```

- [ ] **Step 5: Push and open PR (when ready)**

```bash
git push -u origin feature/pii-presidio-detection
gh pr create --base develop --fill
```

---

## Self-Review (completed during authoring)

- **Spec coverage:** scanner (Task 4), custom NIR/CNI recognizers (Tasks 1–2), config + allowlist (Task 3), pre-commit hook (Task 6), CI workflow (Task 7), hermetic models (Tasks 0/6/7), tests-in-scope + selftest (Tasks 4–5), docs (Task 8). All spec components mapped.
- **Out of scope confirmed:** Gitleaks/detect-private-key untouched; Semgrep + Fides left as follow-ups.
- **Type consistency:** `ScanConfig`, `Finding`, `build_analyzer`, `scan_text`, `build_custom_recognizers`, `is_valid_nir` names match across tasks.
- **Open risk to validate at execution:** exact Presidio/spaCy wheel versions (`2.2.355`, `3.8.0`) — confirm the latest compatible pins at install time; the `2.2.355`/`3.8.0` values are placeholders for "current stable" and may need bumping.
