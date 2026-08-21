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

The test fails without the fix.

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
