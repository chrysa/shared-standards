# D-0010 — Standards ID taxonomy: `STD-*` domains over `XX-nnn` rules

- **Status:** Accepted
- **Date:** 2026-08-15
- **Series:** D (standards-governance decisions)
- **Owner:** standards maintainers (`chrysa/shared-standards`)
- **Supersedes:** none
- **Related:** GV-001, GV-010, GV-015; Notion decision 2026-07-31
  ("Standards transverses prioritaires", `3ae59293-e35e-81fc-a372-e84631c7c2b3`)

______________________________________________________________________

## Context

The Notion governance view groups transverse standards under **domain** identifiers
(`STD-GOV-001`, `STD-DATA-001`, …). The executable canon in this repo identifies **individual
rules** under short stable prefixes (`FE-010`, `AR-031`, `TS-000`, …) inside normative annexes
(GV-010). The two naming schemes describe the same corpus at two altitudes, but nothing linked
them: a reader coming from a `STD-DATA-001` decision had no deterministic way to find the rules
that implement it, and a rule prefix (`DA-nnn`) had no declared home.

Without a fixed correspondence, the domain layer and the rule layer drift: a domain can be
"adopted" in Notion while no annexe implements it (a ghost domain, the domain-level analogue of
GV-001's ghost rule), and a new rule prefix can be invented per PR with no uniqueness guarantee.

## Decision

Adopt a **hybrid two-tier taxonomy**, and make the correspondence itself a governed artifact:

1. **`STD-<DOMAIN>-nnn`** is the *domain* identifier — the unit of governance, adoption status,
   ownership and priority. It is what Notion tracks and what a PRD references.
2. **`XX-nnn`** is the *rule* identifier — a single deterministic rule, `XX` a stable
   two-letter prefix owned by exactly one normative annexe (or the socle), `nnn` unique and
   never reused (GV-010).
3. Every `STD-*` domain **maps to exactly one home** (an annexe, or the socle for cross-cutting
   rules) and to **one rule prefix**. The mapping is published as **GV-015** in
   `GOVERNANCE.md` and is the single source of truth for the correspondence.
4. A `STD-*` domain with no annexe/home is a **ghost domain** — it governs nothing and must not
   be marked `Adopted`. This extends GV-001 (ghost rule) to the domain tier.

Existing `XX-nnn` ids are **not renamed**. The taxonomy is additive: it names the mapping that
was already implicit and reserves prefixes for the domains not yet migrated.

### Mapping table (canonical — mirrored in GV-015)

| Domain (`STD-*`)     | Home (annexe / socle)                     | Rule prefix | State (this wave) |
| -------------------- | ----------------------------------------- | ----------- | ----------------- |
| `STD-GOV-001`        | `GOVERNANCE.md`                           | `GV-`       | present           |
| `STD-DATA-001`       | `DATA-MIGRATIONS.md`                      | `DA-`       | this wave (PR-2)  |
| `STD-OPS-001`        | `OBSERVABILITY-OPS.md`                    | `OP-`       | this wave (PR-3)  |
| `STD-API-001`        | `API-CONTRACTS.md` (pending)              | `AP-`       | Wave 2            |
| `STD-SUPPLY-001`     | `CI-CD.md` (supply-chain section)         | `CI-`       | Wave 2            |
| `STD-DEPLOY-001`     | `CI-CD.md` / `CONTAINERS-K3S.md`          | `CI-`/`CT-` | Wave 2            |
| `STD-PRIVACY-001`    | `GOVERNANCE.md` (GV-040) + socle          | `GV-`       | present (P1)      |
| `STD-UX-STATE-001`   | `FRONTEND.md`                             | `FE-`       | present (P1)      |
| `STD-CONFIG-001`     | socle (config rules)                      | socle       | present (P1)      |
| `STD-TEST-001`       | `TESTING.md`                              | `TS-`       | present (P1)      |
| `STD-PERF-001`       | `CI-CD.md` (CI-053)                       | `CI-`       | present (P2)      |
| `STD-AI-QUALITY-001` | `AGENTIC-CAPABILITIES.md`                 | `AG-`       | present (P2)      |

Reserved prefixes are unique: no two domains share a prefix except where they genuinely share
a home annexe (`CI-` covers supply-chain, deploy and perf inside `CI-CD.md`; the domain
identifier disambiguates the governance unit, the rule id stays unique within the annexe).

## Consequences

- A domain decision in Notion is now resolvable to executable rules in one hop (GV-015 table).
- Adoption gets a falsifiable precondition: `Adopted` requires a non-pending home — no ghost
  domains.
- Blast radius of this ADR is **nil**: it is a doc plus a governance-annexe rule, neither
  inlined into consumer repos (GV-001). Consumers see nothing until a domain's annexe gains a
  socle anchor.

## Refutable frame

- **Fatal hypothesis:** the domain tier and the rule tier are a *stable many-to-one* mapping —
  each governance domain resolves to exactly one implementing home. If domains routinely split
  their rules across several annexes with no single home, the one-hop resolution breaks and the
  table becomes a lie.
- **Kill-test:** at each wave close, `guideline-checker` (or a scripted audit) verifies that
  every `Adopted` `STD-*` domain has exactly one home row in GV-015 and that its rule prefix
  resolves to that home. First breach (a domain needing two homes, or a prefix with two homes)
  fires the hypothesis; the taxonomy is revised to a domain→[homes] relation.
- **Validation gate:** PR-2 and PR-3 land `DATA-MIGRATIONS.md` (`DA-`) and
  `OBSERVABILITY-OPS.md` (`OP-`) each reachable from the socle's *Normative annexes* section,
  with their GV-015 rows present and no `XX-nnn` collision — proving the mapping holds for the
  two P0 domains before the rest of the fleet migrates.
