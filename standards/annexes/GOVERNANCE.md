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
