# Annexe GV — Standards governance

> **Normative annexe.** Authority: `standards/STANDARDS.chrysa.md`. Rule ids (`GV-nnn`) are
> stable. This annexe governs the standards corpus itself: where a rule may live, how it is
> identified, and how it is adopted or retired.

## 1. Source of truth

### GV-000 — The repo holds the canon, Notion holds governance

Executable canon lives in `chrysa/shared-standards`. **Notion is a governance and decision
view** — a mirror, never the authority. On conflict, the repo wins; the Notion page is
realigned, not the reverse.

> This narrows the socle's *Notion logging* rule, which makes Notion the source of truth for
> **project state** (progress, decisions, status). It does not, and never did, make Notion
> the source of truth for the standards corpus.

### GV-001 — One distributed artifact

`standards/STANDARDS.chrysa.md` is the only file inlined into consumer repos (managed
`chrysa:standards` block, `scripts/distribute-standards.sh`). Annexes are **normative but not
inlined**: the socle references them by stable URL and states their authority.

A rule that lives **only** in an annexe with no anchor in the socle is a ghost rule — it
governs nothing. Every annexe must be reachable from the socle's *Normative annexes* section.

### GV-002 — Deprecated repos

`chrysa/standards` is deprecated (archived 2026-07-19). Nothing is added to it; nothing reads
from it. Its distribution mechanism (`sync.yml`, `standards-hooks`) is dead.

______________________________________________________________________

## 2. Rule identity

### GV-010 — Stable unique ids

Every rule carries a unique, stable id (`FE-010`, `AR-031`, …). An id collision is a blocking
error. An id is never reused for a different rule — a retired id stays retired.

### GV-011 — Every rule declares its scope

Profile, target, DDD level (where relevant), and enforcement mode.

### GV-012 — Every rule declares how it is enforced

Automated (hook / CI / linter, with the check named) or manually reviewed. A rule claiming
automation with no check behind it is misdeclared.

### GV-013 — Exceptions are dated and owned

An exception requires an ADR, a named owner, and an **expiry date**.

### GV-014 — Versioning & deprecation

Rules are versioned and may be deprecated with a migration window. Each repo exposes the
standards version it applies.

### GV-015 — `STD-*` domain aliases

The corpus is identified at two altitudes (ADR [`D-0010`](../../docs/adr/D-0010-standards-id-taxonomy.md)):
a **domain** `STD-<DOMAIN>-nnn` is the unit of governance, adoption status, ownership and
priority (what Notion tracks and a PRD references); a **rule** `XX-nnn` is a single
deterministic rule under a stable two-letter prefix owned by one home. Every `STD-*` domain
maps to **exactly one home** (a normative annexe, or the socle for cross-cutting rules) and to
**one rule prefix**. This table is the single source of truth for that correspondence, and it
is published in machine-readable form at [`standards/domains.yaml`](../domains.yaml) — consumers
(the `project-init` standards profiles, `guideline-checker`, the Standards Hub) read that data
file rather than hand-mirroring this prose. Edit the two together; a drift check keeps them one
source in two forms.

| Domain (`STD-*`)     | Home (annexe / socle)                     | Rule prefix |
| -------------------- | ----------------------------------------- | ----------- |
| `STD-GOV-001`        | `GOVERNANCE.md`                           | `GV-`       |
| `STD-DATA-001`       | `DATA-MIGRATIONS.md`                      | `DA-`       |
| `STD-OPS-001`        | `OBSERVABILITY-OPS.md`                    | `OP-`       |
| `STD-API-001`        | `API-CONTRACTS.md`                        | `AP-`       |
| `STD-SUPPLY-001`     | `CI-CD.md` (supply-chain section)         | `CI-`       |
| `STD-DEPLOY-001`     | `CI-CD.md`                                | `CI-`       |
| `STD-PRIVACY-001`    | `GOVERNANCE.md` (GV-040) + socle          | `GV-`       |
| `STD-UX-STATE-001`   | `FRONTEND.md`                             | `FE-`       |
| `STD-CONFIG-001`     | socle (config rules)                      | socle       |
| `STD-TEST-001`       | `TESTING.md`                              | `TS-`       |
| `STD-PERF-001`       | `CI-CD.md` (CI-053)                       | `CI-`       |
| `STD-AI-QUALITY-001` | `AGENTIC-CAPABILITIES.md`                 | `AG-`       |

A `STD-*` domain whose home is `pending` (no annexe implements it yet) is a **ghost domain** —
it governs nothing and **must not be marked `Adopted`** (in the repo or in Notion). This is the
domain-tier extension of GV-001 (ghost rule): a governance unit is real only when an executable
home implements it. A prefix is shared across domains only where those domains genuinely share
one home annexe (e.g. `CI-` across supply-chain, deploy and perf inside `CI-CD.md`); the domain
id disambiguates the governance unit, the rule id stays unique within its home (GV-010).

______________________________________________________________________

## 3. Maturity ladder

A candidate rule moves through:

| Marker         | Meaning                                                |
| -------------- | ------------------------------------------------------ |
| 💡 suggestion  | proposed, not instructed yet — governs nothing          |
| ⚖️ to-arbitrate | conflicting or unresolved — owner decision required    |
| 🔧 derived     | extracted from real repos, validated, candidate for canon |
| ✅ adopted     | canon — lives in the socle or a normative annexe        |

Only **adopted** rules belong in the socle or an annexe body. Suggestions and open
arbitrations stay in a clearly-marked *Deferred* section, or in Notion.

### GV-020 — Enforcement rollout

A new automated check lands as `info`, is promoted to `warning`, then to `error` once the
existing debt is cleared. It is never introduced as blocking on a fleet with known debt.

______________________________________________________________________

## 4. Numeric values

### GV-030 — Numbers live in one machine-readable place

Thresholds (coverage, file/function length, complexity), tool versions, and canonical
Makefile target names are consumed from a versioned contract — not restated as prose in
several documents. Prose references the contract; it does not duplicate its values.

Known consumers to keep aligned: `.claude/thresholds.json`, `.quality-gate.json`,
`guideline-checker/guidelines/`.

______________________________________________________________________

## 5. External compliance

The fleet is held to two external compliance frameworks. Neither is a parallel corpus: each is
operationalised by rules that already exist in the canon. Declaring the target does not by
itself grant certification — it names the obligation the existing rules must satisfy.

### GV-040 — GDPR / RGPD by construction

Any product handling personal data is **compliant by design**, not by a later audit: lawful
basis or consent and purpose are recorded, data is minimised and its retention bounded, and
export / rectification / erasure of a person's data is served by a documented command
(pillar 3 · *portable personalisation data*). No PII in logs, traces, screenshots, test
fixtures, or prompts without an explicit justification; development and demos use synthetic or
anonymised data. Operationalised by the *per-person data implies a user account* and privacy
rules in the socle, and the `rgpd-compliance` skill.

### GV-041 — ISO/IEC 27001 as the security baseline

The fleet targets **ISO/IEC 27001** compliance: information security is a governed, documented
Information Security Management System (ISMS), not ad-hoc practice. The Annex A control
families map onto existing canon rules — conformance is reached by satisfying those, not by a
separate checklist:

| ISO/IEC 27001 Annex A theme | Canon rule that satisfies it |
| --- | --- |
| Access control (A.5.15–18, A.8.2–5) | cluster SSO + identity hierarchy, session security & revocation (socle) · least privilege `AG-002` |
| Cryptography (A.8.24) | TLS in the platform layer, secrets out of git, modern password hashing, encryption at rest for sensitive data (socle · `AG-005`) |
| Logging & monitoring (A.8.15–16) | structured logs, correlated audit trail, Sentry → issues, observability backend (socle · `AG-008`) |
| Operations & change (A.8.9, A.8.32) | CI gates, build-once-promote (`CI-046`), protected `main`, ADRs for structural change |
| Supplier & supply-chain (A.5.19–23, A.8.30) | versioned contracts (`PROJECT-DECOUPLING`), pinned dependencies + SBOM + signed artefacts (`CI-*`) |
| Incident management (A.5.24–28) | typed & contained errors, automatic issue creation, management backoffice + runbooks (socle) |
| Privacy (A.5.34) | `GV-040` |

What ISO 27001 additionally requires is **organizational, not code**: a documented ISMS scope,
a risk assessment and treatment plan, a Statement of Applicability (SoA), defined security
roles, and periodic internal audit plus management review. Those artefacts are versioned under
`docs/` (or a dedicated governance repo) and tracked as a governance backlog — the code rules
above are necessary for certification but not sufficient on their own.
