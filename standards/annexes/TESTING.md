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
