# D-0014: Migrate the local-AI-orchestration doctrine into the canon (STD-AIORCH-001)

- **Status:** Accepted
- **Date:** 2026-09-19
- **Deciders:** chrysa
- **Pillars touched:** llm-independence, gafam-independence, adaptation-layer
- **Supersedes / Superseded by:** —

## Context

The transverse *Local AI / Offline AI Platform* doctrine lived only in Notion
("🧠 Architecture IA locale", "🏛️ Architecture & Standards"). A conformance
verification found seven invariants **stated in Notion but absent from the repo
canon**: offline/local-first as an operating mode, "prefer local over remote
token-consuming work", typed-tools-before-free-shell, the MCP/A2A protocol
boundary, ported/reconstructible vector memory + RAG, the memory-candidate rule,
and gateway service identity (incl. mTLS). Notion's own doctrine flags this drift
("Standards décrits dans Notion mais non publiés dans shared-standards") and its
roadmap asks to add the standard to shared-standards. Governance (GV-000) is
explicit: the repo is canon, Notion is a view, and a standard reaches projects
only once it is published here.

## Decision

Publish the doctrine as the normative annexe `AI-ORCHESTRATION.md` (domain
`STD-AIORCH-001`, rule prefix `AI-`), anchored in the socle and generated into the
distributed agent views.

## Fatal hypothesis

Codifying these invariants once, product-agnostically, lets every project
reference them instead of re-deriving (or drifting from) local-AI rules — without
forcing a runtime or vendor.

## Kill-test

If, six months after adoption (checked 2027-03-19), fewer than three real projects
reference `STD-AIORCH-001` OR the annexe has to name a concrete runtime/vendor to
be usable, the domain is too abstract: fold its live rules into the projects that
need them and mark the domain `Killed`.

## Validation gate

The annexe is reachable from the socle *Normative annexes* section, `domains.yaml`
and GV-015 agree (`check_domains_drift` green), the agent views regenerate with the
domain present (`gen_agent_views --check` green), and a `distribute-standards
--dry-run` on a consumer refreshes only the managed block.

## Options considered

| Option | Why not |
| ------ | ------- |
| Leave the doctrine in Notion only | Ghost standard: not enforceable, not distributed, drifts from code (the very failure observed). |
| Fold the rules into existing annexes (agents/security) | Spreads one governance unit across homes, breaks the one-domain-one-home rule (GV-015) and hides the local-first cost discipline. |
| Name Ollama/Qdrant directly in the rules | Couples the canon to a vendor; the settled products already live in `STACK.chrysa.md` behind agnostic categories. |

## Consequences

Accepted costs: one more domain to maintain; the socle managed block grows by a
short section (refreshes ~68 consumers on the next distribution). Gains: the
local-first + cost discipline (AI-010) and the agent-protocol invariants become
referable and auditable. Debt: no mechanised `guideline-checker` detector yet —
verification stays manual until an `info`-mode gate is added (GV-020). Blast
radius if Killed: remove the annexe, the socle section, the `domains.yaml`/GV-015
rows, the `rule-domains.yaml` mapping, and regenerate the views.
