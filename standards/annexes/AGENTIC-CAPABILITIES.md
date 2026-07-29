# Annexe AG — Agentic capabilities & actions

> **Normative annexe.** Authority: `standards/STANDARDS.chrysa.md`. Rule ids (`AG-nnn`) are
> stable. Applies to any feature where an LLM or an agent **acts** — writes a file, calls an
> API, runs a command, changes state — as opposed to merely producing text.
> Complements the socle pillar *LLM-provider independence*.

## 1. Mandatory rules

### AG-000 — No vendor LLM SDK in a feature

Inference goes through `ai-aggregator` (or the repo's local port). A feature importing a
vendor SDK directly is a defect — see the socle's pillar 1 and pillar 5.

### AG-001 — Every action has a versioned manifest

Typed inputs/outputs, a version, and a **named business owner**. An action with no manifest
cannot be exposed.

### AG-002 — Least privilege

Minimum permissions, an explicit allowlist of reachable resources, and a clean refusal when
a request falls outside the declared scope.

### AG-003 — Risk level R0–R5 with proportionate confirmation

Every action declares a risk level. Confirmation strength scales with it; **dry-run is
offered whenever the action supports it**. R3–R5 require explicit confirmation.

### AG-004 — Operational safety envelope

Idempotency, timeout, resource limits, circuit breaker, and a documented rollback. All five,
documented — an action missing any of them is not production-ready.

### AG-005 — Secrets out of git

Secrets, keys, and private certificates never enter the repo; they are generated and rotated
per installation/environment.

### AG-006 — Prefer reversible destruction

Logical deletion, trash, or quarantine over permanent destruction.

### AG-007 — Untrusted execution is sandboxed

Generated code, dependency installation, and system commands run inside DEV Nexus or an
unprivileged sandbox. **Network off by default** for executions; dependencies pinned and
provenance recorded.

### AG-008 — Correlated audit log

Every action emits a log correlated by `session_id` / `plan_id` / `request_id` / `action_id`,
shipped to Mirador or the audit log.

### AG-009 — No automatic merge to main by an agent

### AG-010 — No physical or access control without a business policy

Strong confirmation and an immutable audit trail are mandatory for such actions.

### AG-011 — A capability is born in its consumer

A capability is first built inside its first consuming project. Extraction into a shared
brick happens only at the **second real consumer** — not in anticipation.

______________________________________________________________________

## 2. CI gates (progressive rollout)

Add as `info`, promote to `warning`, then `error` once existing debt is cleared:

- direct LLM SDK imports;
- committed secrets, certificates, and private keys;
- shell calls not wrapped by an adapter;
- capability manifest validation;
- dry-run, idempotency, timeout, and rollback tests;
- R3–R5 actions requiring the expected confirmation.
