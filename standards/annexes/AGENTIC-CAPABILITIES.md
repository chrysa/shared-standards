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

### AG-012 — AI functions are versioned

Prompts, models, parameters, and the tool set an AI feature uses are versioned like code. A
change to any of them is a traceable change, not an invisible drift.

### AG-013 — Critical AI tasks have an evaluation set

Every critical AI task ships an **evaluation dataset** and non-regression tests run in CI.
Quality, hallucinations, refusals, latency, and cost are **measured**, not asserted by feel.

### AG-014 — Every AI answer is traceable

An AI output records the model, its version, the prompt, and the sources it used, so any
answer can be reproduced and audited after the fact.

### AG-015 — An AI feature degrades to a fallback

The product provides a fallback model or a no-AI mode wherever it can, and **human validation
is proportionate to the risk** of the action. The policy for what data is sent to a model is
explicit (pillar 1 · `PROJECT-DECOUPLING.md`) — no per-person or sensitive data reaches an
external model without a documented authorisation.

______________________________________________________________________

### AG-016 — Agent autonomy scales with layer determinism

AG-003 grades confirmation by the risk of a single **action**. AG-016 grades an **agent's**
standing autonomy by the determinism of the **layer** it works in — the two compose.

An agent operating a deterministic layer (data model, repositories, API/GraphQL contract,
provider ACL, deploy manifests) may run at **high autonomy**: its correctness is checkable
against a fixed rule or schema. An agent operating a non-deterministic layer (canvas /
visual rendering, voice, RAG, LLM prompting) runs **assisted only** — output requires human
judgment, so it gets no prescriptive skill and every result is validated before it lands.

Consequences:
- High-autonomy agents still obey per-action gates: infra/deploy agents **never `apply`
  automatically** and **never merge to main** (AG-009), whatever their layer autonomy.
- A non-deterministic layer must not be given a prescriptive rule-skill; its guidance is
  advisory. Encoding "assisted" as "automatic" is a defect.
- Each agent declares its layer and autonomy tier (`high` | `assisted`) in its manifest
  (AG-001), so the grading is auditable, not implicit.

## 2. CI gates (progressive rollout)

Add as `info`, promote to `warning`, then `error` once existing debt is cleared:

- direct LLM SDK imports;
- committed secrets, certificates, and private keys;
- shell calls not wrapped by an adapter;
- capability manifest validation;
- dry-run, idempotency, timeout, and rollback tests;
- R3–R5 actions requiring the expected confirmation;
- evaluation-set non-regression on critical AI tasks (AG-013);
- agent manifest declares layer + autonomy tier, non-deterministic layers stay `assisted` (AG-016);
- `.env` secret files staged or present in the tree (AG-005, `check-no-env-files.cjs --ci`).
