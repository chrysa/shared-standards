---
name: sonar-coverage-config
status: approved
author: chrysa <greau.anthony@gmail.com>
created: 2026-07-10
---

# Spec — SonarCloud coverage configuration

## Context / problem

SonarCloud's **"Coverage on New Code"** quality gate reports **0.0%** for any Python code
in this repo (issue #173), even though the console suite has ~95% coverage. Verified in CI
logs, the cause is a mis-wired Sonar setup, not missing tests:

- **`ci.yml`'s integrated `sonar` job** runs `-Dsonar.sources=scripts -Dsonar.tests=tests`
  → it analyses only `scripts/`, never `console/` (the real backend). The correct
  `coverage.xml` (paths `console/standards_console/...`, produced by `make docker-test`
  and rewritten in #171) matches **no analysed file** → coverage ignored.
- **`sonar.yml`** (a standalone workflow) runs `sources: .` → analyses `console/` but runs
  **no tests** → 0% coverage.
- `sonar-project.properties` declares `sonar.sources=.`, disagreeing with both.

Both workflows push analyses of the **same** Sonar project on the same PR; the
last-processed one wins the gate, and it carries no usable coverage. The result is a
permanently red (though currently non-blocking) coverage gate for every Python PR.

## Goals

- Exactly **one** SonarCloud analysis per PR (no competing overwrites).
- That analysis covers the repo's real code — **`console/standards_console` + `scripts/`
  (Python) + `web/` (TypeScript)** — and consumes matching coverage for each, so the
  gate reflects true coverage.
- Python coverage (already correct from #171) and **TypeScript coverage (new: vitest lcov)**
  are both wired into the single analysis.
- `sonar-project.properties` and the workflow args are consistent (one source of truth).

## Non-goals

- **Fleet-template propagation.** Fixing `workflows/sonar.yml` (the copied-across-repos
  template) and re-distributing is a separate follow-up; this spec fixes
  `shared-standards` only and validates the approach first.
- Enabling required status checks / branch protection (out of scope; the gate stays
  advisory here).
- Changing coverage thresholds or the Quality Gate definition itself.
- Raising Python or TS test coverage numbers — only making the existing coverage *count*.

## Functional requirements

- FR1: A PR triggers **one** Sonar analysis of project `chrysa_shared-standards`, not two
  competing ones (remove the standalone `sonar.yml`, or make it the single owner —
  decided in `/plan`).
- FR2: `sonar.sources` includes `console/standards_console` and `scripts`; `web/src`
  (TypeScript) is analysed; generated/vendor paths (`**/web_dist/**`, `node_modules`,
  `__pycache__`, `*.egg-info`, `tests`) are excluded.
- FR3: Python coverage is imported from the existing `coverage.xml`
  (`sonar.python.coverage.reportPaths`) with paths matching the analysed console sources.
- FR4: TypeScript coverage is produced by the web suite (add `@vitest/coverage-v8` + an
  lcov report) and imported via `sonar.javascript.lcov.reportPaths`.
- FR5: `sonar-project.properties` is the single, consistent source of Sonar config; the
  workflow does not pass contradicting `-Dsonar.sources` values.
- FR6: The change is validated by real CI runs on the PR (not only local reasoning).

## Acceptance criteria

- [ ] A PR shows a single `SonarCloud Code Analysis` result (no duplicate/competing runs).
- [ ] `Coverage on New Code` reflects real coverage (a PR touching `console/` shows its
      ~95%, not 0%).
- [ ] SonarCloud's project shows `console/standards_console`, `scripts/`, and `web/src`
      as analysed sources; `web_dist`/`node_modules` excluded.
- [ ] A PR touching `web/` TypeScript shows non-zero TS new-code coverage.
- [ ] `sonar-project.properties` and workflow args do not disagree on `sonar.sources`.
- [ ] Verified green (or true-value) on at least one real CI run before merge.

## Constraints & dependencies

- Depends on #171 (already merged): `make docker-test` + `scripts/rewrite-coverage-paths.py`
  produce the correct Python `coverage.xml`.
- `chrysa/github-actions/sonar-scan-python@v1.3.0` is the shared scan action; its inputs
  (`sources`, `tests`, coverage report paths, artifact names) constrain the wiring.
- Requires **2–3 CI round-trips** to validate Sonar behaviour (analysis dedup + coverage
  mapping can't be fully verified locally).
- Branch `fix/sonar-coverage-config`; base `main`; Conventional Commits; squash merge.
- The coverage gate is **non-blocking** today (required checks disabled), so iteration
  carries low risk.

## Risks / open questions

- **TS coverage wiring** (vitest lcov + `sonar.javascript.lcov.reportPaths`) is net-new and
  may need its own CI iteration; if it proves heavy, TS coverage could ship as a second
  step while Python coverage is fixed first.
- **Analysis ownership**: whether the single analysis lives in `ci.yml` (same run as tests,
  so it already has the coverage artifact) or a fixed `sonar.yml` — settled in `/plan`.
  Keeping it in `ci.yml` is the natural choice since coverage is produced there.
- **`sonar-scan-python` action assumptions**: it also looks for `ruff-report`/`mypy-report`
  artifacts; missing ones log errors but shouldn't fail the gate — confirm in CI.
- **Fleet drift**: once proven here, the template `workflows/sonar.yml` and every repo that
  copied it remain broken until the follow-up propagation — track separately.
