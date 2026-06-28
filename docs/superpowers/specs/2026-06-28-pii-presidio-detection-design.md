# PII (GDPR) Detection with Presidio — Design

- **Date:** 2026-06-28
- **Repo:** `chrysa/shared-standards`
- **Status:** Approved (design), pending implementation plan
- **Author:** Anthony Gréau

## Goal

Add detection of **personal data (PII)** to the shared standards using Microsoft
**Presidio**, running both as a **pre-commit hook** and in **CI**. `shared-standards`
is the source of truth propagated to the fleet, so the hook and workflow added here
become reusable across repositories.

## Scope

### In scope
- Presidio-based PII scanner (script).
- Local pre-commit hook (`repo: local`, `language: python`).
- GitHub Actions workflow for CI.
- Config file + allowlist for false positives.
- Documentation (README, CHANGELOG, docs page).

### Out of scope (deliberate — YAGNI)
- **Gitleaks / detect-private-key** — already present in `.pre-commit-config.yaml`; untouched.
- **Semgrep privacy rules** — useful, but a separate follow-up effort. Not in this design.
- **Fides / record of processing activities** — governance layer (a service to deploy),
  not a hook. Out of scope.

## Components

| # | File | Role |
|---|------|------|
| 1 | `scripts/pii_scan.py` | Presidio scanner. Pre-commit mode (files as args) **and** CI mode (`--all`). FR+EN recognizers + custom (NIR/social-security, IBAN, CNI, FR phone). Output `file:line · entity · score`. Non-zero exit on non-allowlisted findings. |
| 2 | `.pre-commit-config.yaml` | New `repo: local` hook `id: pii-scan`, `language: python`, `additional_dependencies` = presidio + pinned spaCy model wheels (hermetic). |
| 3 | `.pii-scan.toml` | Config: enabled entities, score threshold (default 0.5), excluded paths. |
| 4 | `.pii-allowlist.json` | Validated false positives (synthetic fixtures) — same spirit as `secret-scanner-allowlist.json`. |
| 5 | `workflows/pii-scan.yml` | GitHub Actions: setup Python → install presidio+models → `pii_scan.py --all --report` → upload report + fail on PII. |
| 6 | README / CHANGELOG / `docs/` | Usage documentation + changelog entry. |

## Data flow

```
pre-commit ─► pii_scan.py <staged files>
                   │  AnalyzerEngine (fr + en + custom recognizers)
                   │  threshold filter + allowlist
                   └─► 0 findings → exit 0   |   findings → table + exit 1

CI (push/PR) ─► pii_scan.py --all --report report.json
                   └─► uploaded artifact + status (fail on PII)
```

## Design notes

- **Hermetic spaCy models.** Pin `fr_core_news_sm` + `en_core_web_sm` wheels in
  `additional_dependencies` (a bare `spacy download` would break pre-commit's
  isolated environment). This makes the hook reproducible.
- **Custom NIR recognizer.** Presidio has no French social-security number support →
  a `PatternRecognizer` (regex) plus control-key validation to cut false positives.
- **Tests are scanned too.** A real PII value in a fixture *is* a GDPR risk, so
  `tests/` is in scope; synthetic datasets are explicitly allowlisted. (Deliberate
  departure from other hooks that exclude `tests/`.)
- **Blocking behavior.** Exit 1 in both pre-commit and CI, with the allowlist as the
  escape hatch. Consistent with the "Presidio everywhere" decision.
- **Performance, accepted.** ~5–15 s per run. The analyzer is loaded once per invocation.

## Default detected entities

- Built-in Presidio: `EMAIL_ADDRESS`, `IBAN_CODE`, `PHONE_NUMBER`, `CREDIT_CARD`,
  `IP_ADDRESS`, `PERSON`, `LOCATION`.
- Custom: `FR_NIR` (social-security number, with control-key validation),
  `FR_CNI` (national ID card), French phone format.

## Configuration (`.pii-scan.toml`)

```toml
score_threshold = 0.5
languages = ["fr", "en"]
entities = ["EMAIL_ADDRESS", "IBAN_CODE", "PHONE_NUMBER", "CREDIT_CARD",
            "IP_ADDRESS", "PERSON", "FR_NIR", "FR_CNI"]
exclude_paths = ["graphify", "sys", "*.svg", "*.png", "seeds/"]
```

## Tests & validation

- Validation fixtures: a file with synthetic fake PII (email, test IBAN, fake NIR) →
  must trigger; a clean file → must pass; an allowlisted PII → must pass.
- `pii_scan.py --selftest` to verify recognizers load (useful in CI before the real scan).

## Follow-ups (not in this design)

- Semgrep privacy ruleset (logs of sensitive data, missing encryption).
- Fides data mapping / DSAR handling at the org level.
