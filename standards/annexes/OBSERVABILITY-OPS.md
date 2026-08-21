# Annexe OP — Observability & production readiness

> **Normative annexe.** Authority: `standards/STANDARDS.chrysa.md`. Domain: `STD-OPS-001`
> (GV-015). Rule ids (`OP-nnn`) are stable. This annexe details the socle anchor *Observability
> & production readiness* and complements the error rules (*failures are contained, and
> observable*) and the version-surfacing rules in the socle. Numeric values (SLI/SLO targets,
> resource limits, retention) live in the per-repo contract, never restated here (GV-030).

## 1. Health & readiness

### OP-000 — A deployable service exposes startup, liveness and readiness probes

Three distinct probes, each matching how the service actually behaves: **startup** (slow init
done), **liveness** (the process is healthy, restart if not), **readiness** (fit to receive
traffic — dependencies reachable). One probe reused for all three is a defect: a service that
reports ready before its database is reachable drops the first requests. Probes are the hook for
the readiness gate (OP-050) and are checked in `info` mode by `guideline-checker` (GV-020).

______________________________________________________________________

## 2. Telemetry

### OP-010 — Structured logs, metrics and correlated traces

Logs are structured (machine-parseable, no PII — `GV-040`), metrics are exported, and traces
are **correlated with the logs and metrics through a common id** (a `correlation_id` / trace id
threading a request across services, as required by *failures are contained, and observable*).
A log line that cannot be tied back to its trace is half-instrumented.

### OP-011 — OpenTelemetry is the instrumentation contract; the backend is replaceable

Instrumentation uses **OpenTelemetry** (OTel SDK + semantic conventions) as the vendor-neutral
API for traces, metrics and logs. The export **backend is swappable behind the OTel collector /
`OTLP` exporter** — Sentry, a self-hosted collector, Mirador, or another OTLP-compatible sink —
selected by environment (endpoint via env, per *external servers addressed through the
environment*), never a vendor SDK wired into business code. This is the observability-tier
application of pillar 5 (*adaptation layer*): the domain emits OTel spans; which backend
receives them is configuration. A product that can only export to one proprietary backend, or
that hard-codes a vendor tracer in its domain, is a defect. Correlation ids (OP-010) travel as
OTel context so a trace, its logs and its metrics share one identity.

______________________________________________________________________

## 3. Alerting & runbooks

### OP-020 — Minimal dashboard, actionable alerts, an owner and a runbook per main incident

Every service ships a minimal dashboard, and each principal incident class has an **actionable
alert**, a **named owner**, and a **runbook**. An alert with no runbook is a 3 a.m. puzzle.

### OP-021 — SLI/SLO proportionate to criticality

Service-level indicators and objectives are defined proportionately to the service's
criticality; an alert fires on **real user impact or genuine operational risk**, not on a
metric crossing an arbitrary line. Targets live in the per-repo contract (GV-030).

### OP-022 — Silent or non-actionable alerts are fixed or deleted

An alert nobody acts on trains everyone to ignore the board — it is tuned to be actionable or
removed. A permanently-firing or permanently-muted alert is a defect (mirrors TS-004 for tests
and CI-040 for red checks).

### OP-023 — Dashboards are code

A dashboard is a **versioned definition in a single-source artifact**, not a view hand-built in
the monitoring tool's UI. The rules:

- **Source of truth in git.** The dashboard's native machine definition (its exported
  JSON/model) lives in a repository and is the only authority. A change made directly in the
  running tool that is not in the repo is **drift**, reconciled back to the repo (never the
  reverse) — the same GV-000 discipline the standards corpus applies to itself.
- **Mandated metadata.** Each definition carries a **stable machine id**, the **schema/format
  version** it targets, ownership/domain **tags**, and **templating variables** for the
  environment axes (cluster / namespace / instance) so one definition serves every environment
  rather than a copy per env. The concrete field names and the schema version are the
  monitoring tool's contract, declared per-repo (GV-030), not restated here.
- **Deployed by GitOps.** A merge to the source branch is what updates the deployed dashboards
  (provisioning / a sync step applies the definition); no human clicks "save" in production.
  This is the observability-tier expression of the socle *k8s config in-project* pillar —
  nothing that shapes what operators see exists only inside a running tool.
- **One canonical definition per view, organised by domain** (core / infrastructure / service /
  third-party), so a metric has one board, not five divergent copies (mirrors *no code
  duplication*).

A dashboard that exists only in the tool, or drifts from its committed definition, is a defect —
it cannot be reviewed, reproduced in a fresh environment, or restored after the tool is lost.

______________________________________________________________________

## 4. Resource envelope & resilience

### OP-030 — Explicit resource limits with documented saturation behaviour

CPU, memory, storage, queues and connections carry explicit limits, and the behaviour **at
saturation** is documented (shed load, backpressure, reject with a typed error) — never an
undefined collapse. Ties to *bounded resources* in the socle.

### OP-031 — Graceful shutdown, restart recovery and dependency-loss are tested

The service shuts down gracefully (drains in-flight work), recovers its state after restart,
and has a **tested** behaviour when a dependency is lost (degrade, not crash). Untested
resilience is assumed, not real.

### OP-032 — Backup, restore, rollback and degraded mode documented before first prod deploy

Before the first production deployment, backup, restore, rollback and degraded-mode procedures
exist and are documented. Shipping to prod without a rollback path is the incident you have not
had yet. (Data-side backup/restore detail: [`DATA-MIGRATIONS.md`](DATA-MIGRATIONS.md) DA-020,
DA-021, DA-031.)

______________________________________________________________________

## 5. Version surfacing

### OP-040 — The service publishes what it is at `/version`

A small, unauthenticated-safe **`/version`** endpoint (or the health payload) returns the
application version, the image tag + digest, the git SHA, the build timestamp and the
environment name — enough to answer "which build is this?" and nothing more (no secrets, no
dependency inventory). This operationalises the socle's *container versioned separately from the
application* rule and is checked in `info` mode by `guideline-checker` (GV-020).

______________________________________________________________________

## 6. Production Ready gate

### OP-050 — The Production Ready checklist

A service is **Production Ready** only when all hold, validated:

- deployment + the three healthchecks (OP-000) green;
- telemetry present and correlated (OP-010, OP-011);
- a runbook and owner per principal incident (OP-020);
- backup / restore / rollback / degraded mode documented and exercised (OP-032);
- a failure-injection test passed (OP-031);
- **no critical dependency unmonitored**, and **no alert without an owner** (OP-021, OP-022).

Rollout follows GV-020: the deterministic OP-000 and OP-040 detectors land as `info`, are
promoted to `warning`, then `error` once the fleet's existing debt is cleared.
