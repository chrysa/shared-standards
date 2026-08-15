# Annexe AP — API, SDK & public contracts

> **Normative annexe.** Authority: `standards/STANDARDS.chrysa.md`. Domain: `STD-API-001`
> (GV-015). Rule ids (`AP-nnn`) are stable. This annexe details the socle anchor *API, SDK &
> public contracts* and complements the `api-design` skill, the contract-testing rules
> ([`TESTING.md`](TESTING.md) TS-003, [`PROJECT-DECOUPLING.md`](PROJECT-DECOUPLING.md) DC-006),
> and the *everything is semantic* URL rules in the socle. Numeric values (rate limits,
> timeouts, page sizes) live in the per-repo contract, never restated here (GV-030).

## 1. The contract is the interface

### AP-000 — A machine-readable contract is the canonical definition

**OpenAPI, AsyncAPI, JSON Schema** (or an equivalent machine-readable contract) is the single
canonical definition of an interface — hand-written prose docs are derived from it, never the
reverse. Types consumed by a client are generated from the contract, never hand-copied
(mirrors the socle's *contract types generated from OpenAPI/AsyncAPI*).

### AP-001 — Explicit public version, backward compatibility, deprecation policy

Every public API carries an explicit version, preserves backward compatibility within a major
version, and publishes a **deprecation policy with a retirement schedule** — a removed field or
endpoint is announced, dated, and served through a documented sunset, never dropped silently.

______________________________________________________________________

## 2. Interface shape

### AP-010 — Stable typed errors

An error carries a **stable machine-readable code**, a human message, safe details, and a
**correlation id** — never a raw stack trace or a bare status. This is the API-tier expression
of the socle's *raised errors are typed* and *failures are contained, and observable*.

### AP-011 — Cursor pagination and documented collection controls

Evolving collections paginate by **cursor**, not offset. Limits, default page size, sort,
filters and rate limits are documented in the contract; their **values live in the per-repo
config** (GV-030). An unpaginated list endpoint is a defect (*bounded resources*).

### AP-012 — Critical writes are idempotent

A critical write is idempotent through an **idempotency key** or a stable business id, so a
retried request does not double-apply. Ties to the payments/idempotency rules in the socle.

### AP-013 — The contract states its guards

Timeouts, maximum sizes, authentication, authorization and permissions are described **in the
contract**, not left implicit. A consumer reads the contract and knows the limits before it
calls.

______________________________________________________________________

## 3. Contract tests & SDKs

### AP-020 — Inter-project contracts are tested on both sides

Provider **and** consumer contract tests are mandatory for cross-project communication — the
same obligation as [`TESTING.md`](TESTING.md) TS-003 and
[`PROJECT-DECOUPLING.md`](PROJECT-DECOUPLING.md) DC-006, stated here for the API domain.

### AP-021 — SDKs track the public contract, never internal models

A published SDK is generated from or aligned to the **public contract**, never to the
provider's internal models — leaking an internal model into an SDK couples consumers to
private shapes and breaks *projects talk through versioned contracts only*.

______________________________________________________________________

## 4. Events & webhooks

### AP-030 — Every event is identified, versioned, signed and replay-protected

An event/webhook carries an **event id**, a **schema version**, a timestamp, a **signature**,
and **replay protection** (a nonce or bounded timestamp window). An unsigned webhook is an
unauthenticated write.

### AP-031 — Delivery semantics are explicit

Delivery guarantee (at-least-once / at-most-once / exactly-once), ordering, and possible
duplication are **documented**, not assumed. A consumer that assumes exactly-once against an
at-least-once channel is a defect.

### AP-032 — Bounded retry, dedup, dead-letter and recovery

Event delivery uses **bounded** retry (never an unbounded loop — *failures are contained*),
**deduplication** on the event id, a **dead-letter queue**, and a documented recovery
procedure.

______________________________________________________________________

## 5. Gates

| Gate | Rule | Mode (Wave 2) |
| ---- | ---- | ------------- |
| Contract present & valid (OpenAPI/AsyncAPI lint) | AP-000 | CI |
| Backward-compatibility diff on the public contract | AP-001 | CI |
| Provider + consumer contract tests | AP-020 | CI (see TS-003) |
| Unpaginated collection endpoint | AP-011 | `guideline-checker` · **info** |

Rollout follows GV-020: any new deterministic detector lands as `info`, then `warning`, then
`error` once the fleet's debt is cleared.
