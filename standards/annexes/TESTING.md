# Annexe TS — Common test standard

> **Normative annexe.** Authority: `standards/STANDARDS.chrysa.md`. Rule ids (`TS-nnn`) are
> stable. Language-specific stacks live elsewhere: Python → the socle (*pytest only*) and
> the `testing-pytest` skill; frontend → [`FRONTEND.md`](FRONTEND.md) §4 (Vitest + Testing
> Library + MSW).

## 1. Test levels

| Level         | Purpose                                                        |
| ------------- | -------------------------------------------------------------- |
| Unit domain   | invariants, value objects, aggregates, business rules           |
| Application   | use-case orchestration                                          |
| Architecture  | dependency direction and layer boundaries                       |
| Contract      | API, SDK, WebSocket, and event compatibility                    |
| Integration   | database, broker, files, third-party APIs                       |
| Component     | one component with controlled adapters                          |
| E2E           | critical journeys only                                          |

______________________________________________________________________

## 2. Rules

### TS-000 — Domain tests touch nothing external

No database, no container, no network in a domain test.

### TS-001 — Every fixed bug ships a regression test

The test fails without the fix. How it is traced, proven and kept: §3 (TS-012 to TS-014).

### TS-002 — Adapters have integration tests

An adapter with only unit tests is untested where it matters.

### TS-003 — Cross-project contracts are tested on both sides

Provider **and** consumer. See [`PROJECT-DECOUPLING.md`](PROJECT-DECOUPLING.md) DC-006.

### TS-004 — Flaky tests are defects

A flaky test is fixed or deleted — never retried into green, never muted and forgotten.

### TS-005 — Non-determinism is injectable

Time, randomness, UUIDs, and network are controllable from the test.

### TS-006 — Coverage is a signal, not a target

The socle's ≥ 85 % floor stands, but a green coverage number never substitutes for the
levels above.

### TS-007 — A unit test is isolated from external state by default

A unit test exercises logic **without touching the store, the broker, the network, or the
filesystem** — those are stubbed/faked. Real external state is **opt-in**, reachable only under
an explicit `integration` marker (or its stack equivalent), never the default path. Pure
business logic is tested through its functional core, not by standing up a database to verify a
rule that has nothing to do with persistence — the *decompose into independently unit-testable
methods* socle rule is what makes this possible. This generalises TS-000 (domain) to every unit
test: the fast default suite runs with no external dependency up.

### TS-008 — Every assertion states its expectation

An assertion that fails must say **what was expected and what was observed**, not just that a
boolean was false. A bare truth-check whose failure message is unreadable (`assert result`,
`expect(x).toBeTruthy()` on a value that should equal something specific) is a defect: the next
person reads a stack trace instead of a sentence. Assert on the **specific expected value** with
a message or a matcher that renders both sides (the stack's idiomatic form — a pytest assert
message, a Testing-Library assertion, an xUnit `Assert.Equal`). A test that cannot explain its
own failure is half a test.

### TS-009 — Every public API has a negative-path test

For each public entry point — a function/method contract, an HTTP/RPC route, an event handler —
at least one test exercises a **failure path**: invalid input rejected, an unauthorised caller
refused, a dependency failure surfaced as the typed error the contract promises (mirrors the
socle *raised errors are typed* and *every form is a hostile input surface*). Happy-path-only
coverage is how a `4xx`/validation branch ships untested and regresses silently; the negative
test is part of the surface's Definition of Done, not an extra.

### TS-010 — The suite is fast and parallel-safe by default

Tests are **order-independent and mutually isolated** — no shared mutable state, no reliance on
execution order, nothing evaluated at import/collection time that should be per-test (a random
value, a fake-data default, a clock read). The suite therefore runs **in parallel** without
flaking, and the fast default run is the reviewer's inner loop. A test slower than the repo's
declared budget is **marked `slow`** and excluded from that fast run (it still runs in CI), and
a test that needs real external state carries the `integration` marker of TS-007. Speed is a
correctness property here, not a nicety: a slow or order-dependent suite stops being run.

### TS-011 — Public surface carries documentation, measured against the declared floor

Where the repo's contract sets a **documentation-coverage floor**, the public surface (exported
functions, classes, endpoints) meets it — a public symbol with no docstring/description is a
gap the gate reports, the same way the coverage floor reports an untested branch. The threshold
value lives in the per-repo contract (GV-030), never restated here; a repo whose profile sets no
floor is exempt, but a distributed library always sets one (its Public API Contract is its
interface).

______________________________________________________________________

## 3. Non-regression

A fixed defect must stay fixed, and an accepted behaviour must stay accepted. TS-001 says a
fixed bug ships a regression test; the rules below make that test **findable, proven, and
permanent**, and the map at the end names the one mechanism that guards each other kind of
regression, so nothing is guarded twice or not at all.

### TS-012 — A regression test is traceable to the defect it pins

A regression test names the story or issue it pins (`sc-1234`, `#123`) in its name or
docstring, and carries the stack's regression marker — `@pytest.mark.regression` (registered
in the repo's pytest configuration, so `-m regression` selects the suite) or a
`describe("regression sc-1234 …")` block in Vitest. Each scenario has one line in
`docs/tests/regression-tests.md` (story · symptom · test path). A regression test nobody can
tie back to its defect is the first one deleted during a refactor.

### TS-013 — The regression test is seen failing before the fix

The `fix` PR proves the test is red without the fix: a first commit holding the test alone,
whose CI run fails, or the failing output quoted in the PR body's regression-test field (the
`fix` body of `SCM.md`). A test written after the fix and never seen failing proves nothing —
it may exercise a path the bug never took. The proof lives in the PR; the squash merge keeps
`develop` green.

### TS-014 — Regression tests are permanent and run on every PR

Regression tests belong to the default suite: never excluded as `slow` from CI, never behind
an opt-in marker, never `skip`/`xfail` without a linked issue that says when the skip ends.
They run on every PR to `develop` and `main` inside the required test check. Removing one
requires the PR body to state why the defect can no longer occur (code path deleted, contract
retired). The suite only grows: the `regression-gate` pre-push hook (`chrysa/pre-commit-tools`)
and CI-042 block a coverage or test-count drop against the stored baseline.

### TS-015 — Recorded outputs are reviewed, never re-recorded by CI

Snapshot and golden-file tests (generators, CLIs, renderers, serialisers, generated views)
commit their expected output. CI runs them read-only: an update flag in a CI job
(`--snapshot-update`, `vitest -u`, `--force-regen`, an `UPDATE_GOLDEN`-style variable) is
forbidden, because it turns every drift into a pass. Re-recording is a deliberate change,
reviewed as a diff in its own PR. A snapshot that changes on every run (timestamps, ordering,
absolute paths) is a TS-005 defect to fix, not a snapshot to update.

### TS-016 — Visual non-regression is declared per repo

A repo with a design system or critical screens may compare screenshots (Playwright
`toHaveScreenshot`) on its design-system components and its E2E critical journeys. As for
E2E, the gate status is declared in the local `CLAUDE.md`, and the fleet default is
non-blocking (GV-020). Baselines are rendered in the CI container image, never on a developer
host (fonts and anti-aliasing differ), and are updated only through a reviewed PR (TS-015).

### Non-regression map

| Regression                         | Mechanism                                   | Rule                           | Runs                                |
| ---------------------------------- | ------------------------------------------- | ------------------------------ | ----------------------------------- |
| A fixed bug comes back             | regression test, seen red before the fix    | TS-001, TS-012, TS-013, TS-014 | CI, required test check             |
| The suite silently shrinks         | coverage and test-count baseline            | TS-014, CI-042                 | pre-push (`regression-gate`) and CI |
| Generated output drifts            | committed snapshot / golden file            | TS-015                         | CI, read-only                       |
| A public API breaks its consumers  | backward-compatibility diff on the contract | AP-001                         | CI                                  |
| A cross-project contract breaks    | provider and consumer contract tests        | TS-003, AP-020                 | CI, both sides                      |
| A schema change breaks stored data | compatibility check, reversible migration   | DA-012, DA-013                 | CI                                  |
| Performance or cost drifts         | per-profile budget                          | CI-053                         | CI                                  |
| AI quality drifts                  | evaluation set                              | AG-013                         | CI                                  |
| The UI drifts visually             | screenshot comparison                       | TS-016                         | CI, gate declared per repo          |
