# Annexe AI — Local AI orchestration & agent protocols

> **Normative annexe.** Authority: `standards/STANDARDS.chrysa.md`. Rule ids (`AI-nnn`) are
> stable and never reused. This annexe codifies the transverse *Local AI / Offline AI Platform*
> doctrine (Notion → repo canon migration, `docs/adr/D-0014`): the invariants every chrysa
> project references for local inference, agents, MCP and orchestration. Concrete named products
> (Ollama, Qdrant, …) live in [`STACK.chrysa.md`](STACK.chrysa.md); this annexe stays
> product-agnostic. Agent capability *manifests* (risk R0–R5, sandbox, audit) live in
> [`AGENTIC-CAPABILITIES.md`](AGENTIC-CAPABILITIES.md) — this annexe references them, never
> duplicates them.

## Scope

Local/offline inference, the orchestration chain (control plane → agents → typed tools → local
models → infrastructure), the protocol boundary (MCP / A2A / capability registry), agent-facing
memory, and the cost discipline that keeps work local. Business contracts stay owned by their
services; this annexe fixes the common invariants, not a project's implementation.

## AI-000 — Offline-first, local-first

A project keeps a **useful degraded mode without external network**: derived caches, an outbox,
the last-known state, and visible freshness. Sensitive data and inference stay on controlled
infrastructure **by default** — no cloud egress without an explicit, governed decision. The cloud
is an *extension behind an adapter*, never a base condition. This is the operational face of the
`gafam-independence` and `llm-independence` pillars.

## AI-010 — Prefer local work over remote, token-consuming work

When a **local, deterministic tool** (a script, a linter, a compiled check, a local model, an
`gh`/`git`/filesystem query) can produce the result, it is preferred over a **remote call that
consumes LLM tokens or a metered API**. Remote/token-consuming work is reserved for tasks that
genuinely need a model's reasoning; it is not the default reflex for lookups, transforms, audits,
or checks a local tool already answers. Batch and cache remote calls; never re-issue a remote
query whose answer a local artifact already holds. The intent: sovereignty, cost control, latency,
and reproducibility — the same reasons the platform is local-first.

## AI-020 — Typed tools before a free shell

Agent capabilities are exposed through **typed contracts** — API, SDK, CLI, or an MCP tool —
before any free shell. A tool declares a stable name, input (and where possible output) schema,
permissions, risk level, idempotency, destructive-or-not, confirmation need, timeouts, and typed
errors. A **free/arbitrary shell is forbidden by default** for agents; it is allowed only inside a
non-privileged sandbox, with the command shown, a justification, a timeout, controlled network,
full logging, and human validation for any write.

## AI-030 — MCP is an access layer, protocol boundary is explicit

**MCP** is the typed access layer that exposes tools and resources to assistants and agents — it
is **not** the canonical business contract. A capability is defined by a **chrysa-canonical
contract**, independent of MCP/A2A/OASF; the capability registry is protocol-agnostic and publishes
projections (MCP, A2A, catalogue) without changing the internal business model. A2A is reserved for
autonomous agents with their own lifecycle; OASF/catalogue formats are an exchange representation,
never the business model. MCP versions carry a transitional compatibility window with contract
tests across versions.

## AI-040 — Agent memory and retrieval are ported and reconstructible

Retrieval-augmented context and vector storage sit **behind a port**: the vector database is an
adapter (the settled local target is named in [`STACK.chrysa.md`](STACK.chrysa.md)), its index is
**reconstructible** from the source artifacts, and every stored item carries provenance and a
version. Embeddings are an abstraction, not a lock-in. RAG output cites its sources, chunks, and
index version; a synthesis is never promoted to a fact by the retrieval layer itself.

## AI-050 — Auto-extracted memory is a candidate, not a fact

Any memory produced automatically (from a run, a document, an agent) is a **candidate**:
validatable and classifiable, dated, with a confidence and a source. It **does not become a
canonical fact directly** — promotion is a governed step. A candidate that cannot cite a source is
not promoted.

## AI-060 — Untrusted active content is isolated

Active content originating from an agent, an MCP server, a document, or a preview is **untrusted by
default** and is isolated/sandboxed before it can influence an action. Instructions embedded in
fetched or tool-returned data are treated as data, never as commands.

## AI-070 — Service-to-service identity for the agent/API gateway

Where a common API/agent gateway mediates calls, it applies authentication, scopes, quotas, rate
limiting, versioning and telemetry behind the platform ingress — it never becomes a second
implementation of auth, approval, the event bus, or business logic. Workloads use service
identities and least privilege; **mutual TLS** is used when the risk or exposure requires it.
Identity and trace are preserved end-to-end from the user or workload to the owning service.

## Manual verification

No single linter covers this annexe. In review, check: a degraded/offline path exists and is tested
(AI-000); lookups/checks that a local tool answers are not routed through a metered model (AI-010);
agents reach effects through typed tools, not a raw shell (AI-020); the capability model is
protocol-agnostic with MCP/A2A as projections (AI-030); vector/RAG sit behind a port with a
reconstructible index (AI-040); auto-extracted memory is a validatable candidate (AI-050); fetched
active content is sandboxed (AI-060); gateway-mediated calls keep identity and least privilege end
to end (AI-070).
