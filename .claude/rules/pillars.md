# Strategic Pillars — chrysa non-negotiables

______________________________________________________________________

> Five constraints every chrysa project holds, whatever its stack. They are
> not preferences: breaking one requires an ADR (see [`adr.md`](adr.md)) with a
> kill-test, not a shrug. Canonical source: `chrysa/shared-standards`.

______________________________________________________________________

## The five pillars

### 1. LLM-provider independence

No vendor SDK is called from business code. All inference goes through a local
interface (a port), with **at least two real, tested implementations** (e.g.
Claude + a local/open model). A prompt that only works on one vendor is a bug,
not a feature. A vendor-only capability is emulated behind the port or forbidden
— and if it is truly required, it needs an ADR.

### 2. GAFAM independence

Every managed-cloud dependency has a **documented exit path** — a procedure, not
"we'll see". No managed service without an identified self-hosted equivalent
(S3 → MinIO, RDS → Postgres, Lambda → container, …). The cloud SDK stays confined
to an adapter; the domain speaks `BlobStore`, not `S3Client`.

### 3. Portable personalisation data

All user/personal data is exportable to an **open format** (JSON, SQLite, CSV) by
a documented command. Zero hidden lock-in: a stored-but-unexportable field
requires an ADR justifying it. `export → import → export` is idempotent, and that
is a test, not an intention.

### 4. k8s config in-project

Kubernetes manifests live in `deploy/k8s/` of the project repo. No separate infra
repo, no config that exists only inside a running cluster. If `kubectl get` shows
something absent from the repo, that is drift to fix.

### 5. Adaptation layer for every external dependency

A third-party lib/API/service is never imported directly by the domain — it goes
through an adapter. The port is written in the domain's language, not the vendor's:
if renaming the vendor changes the port signature, the port is wrong.

______________________________________________________________________

## When a pillar forces an ADR

Any exception to a pillar, and specifically: a new external dependency, an
LLM/cloud provider choice, a data-model change that touches exportability, a
manifest placed outside `deploy/k8s/`. Format: [`adr.md`](adr.md). Scaffold:
`/adr-new`.

______________________________________________________________________

## Manual verification

No linter enforces these. In review, check:

- Domain code imports no vendor SDK (grep for the SDK package in the domain layer).
- Each external dependency sits behind an adapter; the port signature is
  vendor-agnostic.
- The LLM path has ≥2 tested adapters, exercised by a shared contract test.
- Every managed-cloud dependency has an exit path in the runbook.
- Personal data has an export command, and a round-trip test.
