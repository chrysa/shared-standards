# Annexe DA — Data, persistence & migrations

> **Normative annexe.** Authority: `standards/STANDARDS.chrysa.md`. Domain: `STD-DATA-001`
> (GV-015). Rule ids (`DA-nnn`) are stable. This annexe details the socle anchor *Data,
> persistence & migrations* and complements the GDPR rules (`GV-040`, the `rgpd-compliance`
> skill) and *portable personalisation data* (pillar 3). Numeric values (RPO/RTO, retention,
> coverage) are declared in the per-repo contract, never restated here (GV-030).

## 1. Ownership & classification

### DA-000 — Every data category declares its owners and system of record

Each category of data names its **source of truth**, its **functional owner**, and its
**technical owner**. Two stores holding the same fact without one declared authoritative is a
defect.

### DA-001 — Every data category is classified

Minimum classes: **public · internal · sensitive · personal · secret**. Classification drives
handling (logging, export, masking, encryption) and is the hook for `GV-040` — personal/secret
data never lands in logs, traces, screenshots, fixtures, or prompts without an explicit,
justified exception.

______________________________________________________________________

## 2. Schema & migration lifecycle

### DA-010 — Schemas and events are versioned; migrations are reproducible, ordered, tested

A schema or event contract carries a version. Migrations are deterministic, ordered, and run
in tests — not applied by hand against a live database. Python stacks use Alembic
(see the `alembic-migration-validator` skill); every migration is exercised in CI.

### DA-011 — Zero-downtime migrations follow `expand → migrate → contract`

When the service must stay available across a schema change, the change is split:
**expand** (add the new shape, both readable), **migrate** (backfill + dual-write), **contract**
(remove the old shape) — never a single breaking alter under live traffic.

### DA-012 — Backward compatibility is verified

A migration is checked against the previous application version (the rollout runs old code
against the new schema during `expand`). An incompatible change that assumes lockstep deploy is
a defect.

### DA-013 — Every migration is reversible and bounded

A migration has an **inverse**: a schema step is reversible, and a data transformation ships the
reverse transformation beside it — a one-way migration is accepted only with a documented restore
(DA-021) and a comment saying why no inverse exists. It is also **bounded**: a large table is
never rewritten in a single transaction (batch it, so a failure rolls back a batch, not the
release), and a heavy backfill runs as a **dedicated job** (a management command / a one-off
cluster job), never inside the request-path migration that gates a deploy. An unbounded rewrite
is how a migration locks a production table and takes the service down.

### DA-014 — Migrations are hygienic per change, and immutable once applied

A change carries the **minimum viable set** of migration files — consolidated before review, not
a trail of incremental edits — and each migration comments its **purpose, risk, and rollback**.
Once a migration is applied in any shared environment it is **immutable**: never edited, never
squashed, never reordered — the next correction is a new migration. Editing an applied migration
desynchronises every environment that already ran it, which is an incident, not a tidy-up.

______________________________________________________________________

## 3. Safety, rollback & recovery

### DA-020 — No immediate destructive change in production; snapshot first

A destructive operation (drop, irreversible transform, bulk delete) is preceded by a
**backup or snapshot**, and the destructive step is deferred behind a `contract` phase
(DA-011) rather than applied inline. An immediate `DROP` under live traffic is an incident
generator.

### DA-021 — Every migration carries a rollback or documented restore

Each migration ships either a reversible down-path or a documented restore procedure. A
forward-only migration with no recovery story is a defect.

### DA-022 — A destructive change ships with a migration plan

A change that drops or irreversibly rewrites data references an explicit migration plan
(expand/contract phases, snapshot, rollback). This is the rule the `guideline-checker`
`info`-mode detector reports (GV-020): destructive DDL/ORM change with no accompanying plan.

______________________________________________________________________

## 4. Continuity, retention & portability

### DA-030 — Continuity objectives are declared per criticality

`RPO`, `RTO`, retention, archival, and deletion are defined per data category according to
criticality. The **values live in the per-repo contract** (GV-030); this rule mandates that
they exist and are owned, not their numbers.

### DA-031 — Restores are tested periodically

A backup that has never been restored is **not** a validated backup. Restore drills run on a
declared cadence; the result is recorded.

### DA-040 — Full export in an open, documented format

Data is exportable to an open, documented format (JSON/SQLite/CSV as fits) with **no lock-in**
to Notion or any single vendor. This is the persistence-tier expression of pillar 3
(*portable personalisation data*): `export → import → export` is idempotent and tested.

### DA-041 — Dev and test never use raw production data

Development and test environments use **synthetic or anonymised** data — never a raw,
non-anonymised copy of production (`GV-040`). A prod dump loaded into a dev database is a
privacy incident, not a convenience.

______________________________________________________________________

## 5. Gates

| Gate | Rule | Mode (this wave) |
| ---- | ---- | ---------------- |
| Migrations tested on empty **and** existing DB | DA-010 | CI |
| Backward-compatibility check across versions | DA-012 | CI |
| Backup / restore drill | DA-031 | scheduled |
| Destructive change without a migration plan | DA-022 | `guideline-checker` · **info** |

Rollout follows GV-020: the `DA-022` detector lands as `info`, is promoted to `warning`, then
`error` once the fleet's existing debt is cleared — never blocking on introduction.
