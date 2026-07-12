---
name: sonar-coverage-config
status: approved
spec: docs/specs/sonar-coverage-config.md
created: 2026-07-10
---

# Plan — SonarCloud coverage configuration

## Summary

Collapse the two competing Sonar analyses into **one**, owned by `ci.yml`'s `sonar` job
(it runs in the same workflow run as the `test` job, so it already has the coverage
artifact). Delete the standalone `sonar.yml`. Widen the analysed sources to the real code
(`console/standards_console`, `scripts`, `web/src`) so the existing Python `coverage.xml`
(paths `console/standards_console/...`, from #171) finally maps. Deliver in **two phases in
one PR** so the Python fix (the actual bug) is validated on real CI before the heavier TS
coverage wiring: Phase 1 = single analysis + Python coverage counts; Phase 2 = TS coverage
via vitest lcov. Because Sonar's dedup + path mapping can't be verified locally, each phase
is validated by pushing and reading the PR's Sonar result.

## Files to touch

| File | Change |
| ---- | ------ |
| `.github/workflows/sonar.yml` | **Delete** — remove the standalone competing analysis (Python fix leaves `ci.yml`'s sonar job as the single owner). |
| `.github/workflows/ci.yml` | `sonar` job: `sources: console/standards_console,scripts,web/src`; keep `tests: tests`. Phase 2: `test` job also runs web coverage and uploads its lcov into the same `test-results-3.14` artifact (or a sibling the sonar step reads). |
| `sonar-project.properties` | Make it consistent: drop `sonar.sources=.` (the workflow owns sources) or align it; add `sonar.exclusions=**/web_dist/**,**/node_modules/**`; Phase 2 add `sonar.javascript.lcov.reportPaths=reports/web-lcov.info`. |
| `console/web/package.json` | Phase 2: add `@vitest/coverage-v8` devDep + `test:cov` script emitting lcov. |
| `console/web/vite.config.ts` | Phase 2: enable `coverage` (provider v8, `reporter: ['lcov']`, sane `include`/`exclude`). |
| `console/Makefile` (or root) | Phase 2: a target that runs web tests with coverage and places the lcov where CI uploads it. |

## Steps

**Phase 1 — one analysis, Python coverage counts (the bug)**
1. Delete `.github/workflows/sonar.yml`. *(commit: `ci: drop competing standalone Sonar workflow`)*
2. In `ci.yml`'s `sonar` job set `sources: console/standards_console,scripts,web/src`.
   *(commit: `ci: analyse real sources in the single Sonar run`)*
3. Reconcile `sonar-project.properties` (remove the contradicting `sonar.sources=.`, add
   `web_dist`/`node_modules` exclusions). *(commit: `ci: align sonar-project.properties`)*
4. Push; read the PR's `SonarCloud Code Analysis`. **Expect**: one analysis, `console/`
   analysed, `Coverage on New Code` reflects the console coverage (not 0%). Iterate on the
   `sources`/coverage path mapping until true. (1–2 round-trips.)

**Phase 2 — TypeScript coverage**
5. Add `@vitest/coverage-v8` + `test:cov` (lcov) to `console/web`; enable coverage in
   `vite.config.ts`. *(commit: `test(web): emit lcov coverage`)*
6. Make CI's `test` job run web coverage and expose `reports/web-lcov.info`; set
   `sonar.javascript.lcov.reportPaths`. *(commit: `ci: feed web lcov to Sonar`)*
7. Push; confirm a `web/` TS change shows non-zero TS new-code coverage. (1 round-trip.)

## Tests

- No application unit tests change. Validation is **CI-observed** (per spec FR6): the PR's
  SonarCloud result is the test oracle.
- Phase 2 adds a web coverage run; assert locally that `vitest run --coverage` emits
  `web-lcov.info` before wiring CI.
- Sanity: `make docker-test` still green (Python coverage.xml unchanged from #171).

## Risks & rollback

- **Additive/CI-only**; rollback = restore `sonar.yml` + revert the `ci.yml`/properties
  hunks. No application code touched. Gate is non-blocking, so a bad iteration harms nothing.
- **Sources syntax**: the `sonar-scan-python` action forces `-Dsonar.sources=<input>`; if it
  rejects a comma list or a non-python path, fall back to setting sources via
  `sonar-project.properties` and passing an empty/′.′ input — settle empirically in step 4.
- **TS coverage heavier than expected**: Phase 2 is isolated; if it stalls, Phase 1 (the
  actual bug fix) still ships and TS coverage becomes a follow-up.
- **Action expects ruff/mypy/junit artifacts**: their absence logs errors but must not fail
  the gate — confirm in step 4; if it does, produce them or adjust the action inputs.

## Standards checklist

- [ ] Conventional Commits; branch `fix/sonar-coverage-config`; base `main`
- [ ] CI-only change; no app code; no hardcoded constants introduced
- [ ] Validated on a real CI run before merge (spec FR6)
- [ ] `make docker-test` still green
- [ ] Follow-up issue filed for `workflows/sonar.yml` template propagation (fleet)
