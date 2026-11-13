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
memory, the cost discipline that keeps work local, and the parity of the coding assistants a
repository supports (AI-090). Business contracts stay owned by their
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

## AI-080 — One common LLM contract, read from the environment

A product that calls a language model reaches it through **one contract**, not through its own
provider wiring:

| Variable        | Required | Meaning                                                              |
|-----------------|----------|----------------------------------------------------------------------|
| `LLM_BASE_URL`  | yes      | Base URL of an **OpenAI-compatible** API (`/v1/chat/completions`, `/v1/embeddings`). |
| `LLM_MODEL`     | yes      | Model identifier sent as `model`.                                    |
| `LLM_API_KEY`   | no       | Bearer token, only when the endpoint requires one; never committed.  |

- **Local default.** When `LLM_BASE_URL` is unset the product uses the local endpoint of the
  settled stack ([`STACK.chrysa.md`](STACK.chrysa.md), row *LLM endpoint*), so a fresh checkout
  works offline (AI-000). `.env.example` documents the three variables with that default.
- **Switching is configuration.** A cloud model, a self-hosted vLLM/TGI server or a gateway is a
  different `LLM_BASE_URL`/`LLM_MODEL`, never a code change. Business code imports no vendor SDK.
- **No facade by default.** A shared gateway service is introduced only when a measured need
  (routing between models, central cost/token budget, shared cache) is recorded in an ADR; until
  then the contract above is the integration point. Products that already have a local LLM
  module keep it as their adapter and read these variables on their next change.
- **Legacy names.** `OLLAMA_URL`, `OLLAMA_HOST`, `OLLAMA_BASE_URL`, `OLLAMA_MODEL` are accepted as
  deprecated fallbacks during migration; new code reads `LLM_*` first.
- **Degraded mode.** When the endpoint is unreachable the product shows a documented no-AI
  fallback; it does not crash or silently call another provider.

## AI-090 — Coding assistants at parity, behind one neutral source

A repository works the same with every **supported coding assistant**. Today the supported set is
**Claude Code and Codex, at parity**. The set is open: adding a tool (opencode, an agent driven by
a local model, the next assistant) means adding an adapter, never rewriting the repo for it.

- **One neutral source, one thin adapter per tool.** Instructions, rules and shared capabilities
  are written once, in a tool-neutral form: the canon and the repo's own rules. Every tool's
  entry file is generated from that source by the same generator (`CLAUDE.md`, `AGENTS.md`,
  `.github/copilot-instructions.md`), and each tool's configuration is a thin adapter
  (`.claude/settings.json`; `.codex/config.toml` and `.codex/rules/`; `opencode.json`). An
  adapter adds only what its tool needs; it never forks the content, and no entry file is
  hand-diverged.
- **The same guard rails in every tool.** A `deny`/`ask` rule set for one tool exists for every
  supported tool (Claude Code `deny`/`ask` ↔ Codex `forbidden`/`prompt`). A protection that one
  tool can only give through a tool-specific hook is also a pre-commit or CI gate, so it holds
  whatever tool made the change. `prism-ai-lint --align` checks this alignment and repairs it;
  a rule present in one tool and missing in another is a defect.
- **Shared capabilities come from one source.** Skills, commands and subagents are distributed
  once (the `chrysa-standards` plugin for Claude Code, and the matching export for each other
  tool as it becomes available), never copied per repo and per tool. A capability that exists
  for one tool only is listed as such in the adapter, with the gap tracked in an issue; it is
  never missing silently.
- **No assistant setup requires one vendor's model.** The model is a setting of each adapter,
  not a requirement of the shared content. A model tier set for one tool (for example a
  subagent's `model:`) names a role, so another tool can map that role to its own models.
  Consistent with pillar 1 and AI-000: at least one supported assistant can run on a local
  model.
- **A new tool joins by adapter.** Supporting another assistant means: its adapter generated
  from the neutral source, its rules added to `prism-ai-lint --align`, and a smoke check that
  the tool loads the repo's instructions. Nothing in the shared content is duplicated for it.
- **Tool-specific features are allowed, documented.** A feature with no equivalent in the other
  tools (a hook event, a setting) may be used. The adapter states what is missing elsewhere, and
  when the feature protects something, the shared gate above covers it.

## Manual verification

No single linter covers this annexe. In review, check: a degraded/offline path exists and is tested
(AI-000); lookups/checks that a local tool answers are not routed through a metered model (AI-010);
agents reach effects through typed tools, not a raw shell (AI-020); the capability model is
protocol-agnostic with MCP/A2A as projections (AI-030); vector/RAG sit behind a port with a
reconstructible index (AI-040); auto-extracted memory is a validatable candidate (AI-050); fetched
active content is sandboxed (AI-060); gateway-mediated calls keep identity and least privilege end
to end (AI-070); the model endpoint comes from `LLM_BASE_URL`/`LLM_MODEL` with a local default
and no vendor SDK in business code (AI-080); every supported coding assistant gets the same
instructions and guard rails from one neutral source, `prism-ai-lint --align` reports no gap,
and no assistant setup requires one vendor's model (AI-090).
