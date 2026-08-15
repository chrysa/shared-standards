# Annexe CI — Continuous integration & delivery

> **Normative annexe.** Authority: `standards/STANDARDS.chrysa.md` (section *GitHub Actions*).
> Rule ids (`CI-nnn`) are stable. Where this annexe and the socle disagree, the socle wins.
> Related: [`CONTAINERS-K3S.md`](CONTAINERS-K3S.md) for what the pipeline builds,
> [`TESTING.md`](TESTING.md) for what it runs, [`GOVERNANCE.md`](GOVERNANCE.md) for how a rule
> is enforced.

A pipeline has one job: **tell the truth about the code, fast, without becoming a codebase of
its own**. Every rule below serves one of three properties — *trustworthy* (a red check means
the code is wrong), *cheap* (in wall-clock and in attention), *maintainable* (a fleet-wide
change costs one pull request, not sixty).

______________________________________________________________________

## 1. Architecture — thin workflows, reusable cores

### CI-000 — A workflow is a graph of jobs, not a script

An entry-point workflow declares *what runs, in what order, in parallel where possible*, and
delegates the doing. A job does one thing; two unrelated concerns are two jobs, so a failure
names the discipline that failed (`tests`, `quality-python`, `quality-docker`, `sonar`,
`secrets-scan`) instead of "CI".

### CI-001 — Shared stages are reusable workflows, prefixed `_`

A stage used by more than one entry point is a `workflow_call` workflow named `_<stage>.yml`
(`_tests.yml`, `_quality-python.yml`, `_sonar.yml`, `_version.yml`, `_image-setup.yml`). Its
contract is typed: every input declares `type`, `required` and a `default`; every secret is
declared by name. An untyped reusable workflow is a global variable with extra steps.

### CI-002 — Logic lives in an action or a tested script, never in YAML

A step is a `uses:` or a one-line `run:`. Past ~15 lines, or at the first conditional, parse
or retry, the behaviour moves into a **composite action** with declared inputs/outputs, or a
script in the repo that a test can call. Workflow YAML is not a programming language and no
test covers it.

### CI-003 — One home for custom actions, one for workflow templates

Custom actions live in a **single** shared actions repository; reusable workflow templates in
the standards repository. Two action repositories with overlapping content is drift by
construction: the same action exists twice, diverges silently, and consumers cannot tell which
is canonical. Merge them, alias the retired one, delete the copy.

### CI-004 — The second occurrence is an extraction order

The same CI logic appearing in a second repository moves to the shared home and both consume
it from there. This is the socle's *no code duplication* applied to pipelines — and pipelines
are where duplication hurts most, because a fleet-wide fix otherwise costs one pull request
per repository.

### CI-005 — `.github/workflows/` carries a README

It lists the reusable workflows (purpose, inputs, outputs, runner) and draws the job graph of
each entry point. A pipeline nobody can read is a pipeline nobody dares change, and it ossifies.

### CI-006 — Every repo runs CI

There is **no repository without CI**. Every repo has a workflow that runs its gate on every
push and pull request to `develop`, and on every PR to `main`. What the gate runs scales with
the `runtime:` tier (`repos.yml`): an **application** runs the full `make ci` (lint, typecheck,
tests + coverage, build, quality gate); an **`exempt:lib`** runs its suite in a container
(`docker-test`) plus lint; an **`exempt:config`** validates and lints what it ships (YAML,
manifests) with no application gate; an **`exempt:native`** runs its tests where the host
allows. The gate is the one a developer runs locally (`pre-commit`, `make ci`), invoked by glue
— not re-implemented in YAML. A repo with no pipeline, or one whose check is green only because
nothing ran, is a defect (`CI-040`, `CI-032`).

______________________________________________________________________

## 2. Supply chain

### CI-010 — Third-party actions are pinned by commit SHA

Full 40-character SHA, with the human version in a trailing comment:

```yaml
uses: actions/checkout@08c6903cd8c0fde910a37f88322edcfb5dd907a8 # v5.0.0
```

A tag is mutable; a branch (`@main`, `@master`) is arbitrary code execution, updated by a third
party, whenever they choose, with the workflow token in scope. Pinning a *third-party* action
to a branch is a security defect, not a convenience.

### CI-011 — Internal shared actions are pinned by tag, never by branch

The shared actions repository is released like any other product; consumers move deliberately
by bumping a tag. `@main` is not "always up to date" — it is unversioned, untestable, and
unrollbackable: a push changes every consumer's CI retroactively, with no review at the call
site. Floating on `main` is also how a broken action takes down the whole fleet at once.

### CI-012 — Pinning implies Dependabot

Pinning without an update mechanism freezes the fleet years behind. The `github-actions`
ecosystem is declared in `dependabot.yml`, and its pull requests are reviewed like any other.

### CI-013 — No long-lived credential where a short-lived one works

Cloud access uses OIDC (`permissions: id-token: write`) against a role, not a stored key.
Cross-repository writes use a scoped app token minted in the job, not a personal access token.
A long-lived provider key in a repository secret is a finding with an owner and an expiry, not
a configuration choice.

### CI-014 — Reuse before writing

The first choice is a maintained public action (checkout, language setup, build-push, publish,
artifact upload). Re-implementing caching, toolchain setup or publishing in a `run:` block is a
defect; "it's shorter this way" is not a reason.

> **`STD-SUPPLY-001` — software supply-chain security.** Rules CI-010…CI-019 are the executable
> home of the supply-chain domain (GV-015). They cover pinning (CI-010, CI-011, CI-015),
> provenance & signing (CI-019), inventory (CI-016), scanning & remediation (CI-017, CI-018),
> and least-privilege publishing (CI-013, CI-024). Numeric remediation windows live in the
> per-repo contract (GV-030).

### CI-015 — Production images are pinned by version, critical components by digest

A production image references an immutable version tag, and a **critical** component
(base runtime, security-sensitive dependency) is additionally pinned by **digest**
(`image@sha256:…`). A bare `:latest` in a deployed manifest is a defect (mirrors *build once,
promote the artefact*, CI-046).

### CI-016 — An SBOM is generated for every distributed release

Every release that ships an artefact or image produces a **Software Bill of Materials** (SPDX
or CycloneDX), attached to the release. A distributed build with no inventory of what it
contains cannot be audited when a dependency is later found vulnerable.

### CI-017 — Vulnerability, secret, PII and license scans run in CI

The pipeline scans, per the repo's `runtime:` profile, for **vulnerabilities, leaked secrets,
PII, and license violations**. License policy is an explicit **allowlist / denylist** with a
review step on any license change — a dependency that changes to a forbidden license is a
finding, not a silent update.

### CI-018 — Remediation deadlines are defined by severity and exposure

A finding from CI-017 carries a **fix deadline set by its severity and exposure** (a
critical vuln on an internet-facing service is not the same clock as a low on an internal
tool). The windows live in the per-repo contract (GV-030); this rule mandates that they exist,
are owned, and are tracked — an ageing critical with no owner is the defect.

### CI-019 — Publish only from controlled CI; sign artefacts, images & provenance

Artefacts and images are published **only from a controlled CI pipeline**, never a laptop, and
are **signed** with their **provenance attestation** (SLSA-style: what commit, which builder,
which inputs) where the toolchain allows (Sigstore/cosign, `pypa/gh-action-pypi-publish` OIDC).
Builds are **reproducible, or at minimum traceable** to the commit, the standards profile and
the resolved dependencies that produced them.

______________________________________________________________________

## 3. Least privilege

### CI-020 — Every workflow declares `permissions:`

Read-only at the top; elevated on the single job that needs it (`contents: write`,
`packages: write`, `id-token: write`). The default token is far broader than most jobs need,
and an undeclared permission set is an undeclared blast radius.

### CI-021 — `secrets: inherit` is banned

A reusable workflow receives only the secrets it uses, named one by one:

```yaml
secrets:
    SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
    REGISTRY_PASSWORD: ${{ secrets.REGISTRY_PASSWORD }}
```

`inherit` hands the callee the caller's entire secret store — deploy credentials reaching a
workflow that only needed a registry password. Beyond the security argument, the call site
becomes readable: you can tell what a workflow touches without opening it.

### CI-022 — Untrusted input never reaches a shell through `${{ }}`

PR titles, branch names, commit messages, issue and comment bodies, and any
`repository_dispatch` payload are attacker-controlled. They pass through `env:` and are quoted:

```yaml
env:
    TITLE: ${{ github.event.pull_request.title }}
run: echo "$TITLE"
```

Direct interpolation is shell injection with the repository token in scope. The same applies to
`ref:` in a checkout — never build one from unvalidated input.

### CI-023 — Deployments are gated by an environment

A deploy job declares an `environment:`, which scopes its credentials and carries the required
reviewers. A deployment anyone with write access can trigger, with secrets in scope, is not a
deployment — it is an incident waiting for a bad day.

### CI-024 — A workflow triggered by an outside contributor gets no secrets

`pull_request_target` and workflows running on forks either run without secrets, or do not run.
Treat the fork's code as untrusted input, because it is.

______________________________________________________________________

## 4. Cost, latency, attention

### CI-030 — Every job declares `timeout-minutes:`

Set slightly above the observed p99, never left to the platform default. Without it a hung job
holds a runner for hours; on self-hosted capacity it blocks everyone else's queue.

### CI-031 — Every PR-triggered workflow declares a concurrency group

```yaml
concurrency:
    group: ${{ github.workflow }}-${{ github.ref }}
    cancel-in-progress: true
```

Superseded runs are cancelled. **Deploy and release workflows use the same grouping with
`cancel-in-progress: false`** — cancelling a deployment mid-flight is worse than queueing it.

### CI-032 — Skip by measured change, never by faith

Path filters gate expensive jobs on what actually changed. A filter may cause a job to be
**skipped visibly**; it must never make a required check *pass* without running. A green tick
that means "not executed" is the single most effective way to destroy trust in a pipeline.

### CI-033 — Cache dependencies and layers

Language toolchain caches (built into the setup actions) and build-layer caching are the
cheapest latency win available; a pipeline that reinstalls the same dependency tree on every
run pays for it hundreds of times a day. Cache keys are content-derived (lockfile hash), never
time-derived.

### CI-034 — A matrix replaces duplicated jobs

Two jobs differing by one value (version, target, platform) are one job with a matrix. Copies
diverge; the matrix is the single edit point.

### CI-035 — The runner is chosen by workload, and stated

Hosted runners for short, isolated, or externally-triggered work; larger or self-hosted
capacity for heavy builds and test suites. One exception is deliberate and documented inline:
**a workflow whose job is to detect that the self-hosted fleet is down must run on a hosted
runner** — a monitor that shares its subject's failure mode is not a monitor.

______________________________________________________________________

## 5. What the gate must prove

### CI-040 — A red check means the code is wrong

A gate that fails because a repository is not onboarded, a tool is missing, a lockfile is
absent, or billing lapsed teaches everyone to ignore red — and the next real failure is ignored
too. Such a gate is fixed or removed the day it appears. A permanently red check is worse than
no check.

### CI-041 — Quality is a set of named, independent gates

Linting and typing, security linting, dependency audit, container linting, tests with a
coverage floor, static analysis, secret scanning. Each is its own job with its own name, so the
failure is self-describing.

### CI-042 — The coverage floor only ratchets upward

The floor is an explicit input at the call site, visible in review. It is raised, never lowered
in the pull request that breaks it — a floor that follows the code down measures nothing.

### CI-043 — Integration tests get real services, isolated per run

Databases, caches and brokers are declared as services, and every run gets its own namespace
(database name derived from the commit SHA and job id). Parallel jobs sharing one database
produce failures that are indistinguishable from flakiness.

### CI-044 — CI runs the commit gate over the whole tree

The local hook covers the diff; CI covers everything, from **the same configuration file**. A
second, CI-only list of checks drifts from the local one and turns "it passed on my machine"
into a legitimate complaint.

### CI-045 — The version is computed, never typed

Semantic version derived from the git graph, images and artefacts tagged with it in the same
run, changelog generated. A hand-edited version string is a merge conflict with a release
attached.

The two tools are settled, not a per-repo choice — a fleet where each repo derives its
version differently cannot answer "which of these is newer" without reading three configs:

| Concern | Tool | Config |
| --- | --- | --- |
| Compute the semantic version | [**GitVersion**](https://gitversion.net/) | `GitVersion.yml` |
| Generate the changelog | [**git-cliff**](https://git-cliff.org/) | `cliff.toml` |

Both config files are **canonical**: one source of truth in `shared-standards`, byte-identical
in every consumer, drift blocked by a `repo: local` pre-commit hook. A repo that tunes its own
`GitVersion.yml` has opted out of the fleet's version ordering.

The release job wires them in this order — compute, then describe, then tag:

```yaml
- uses: gittools/actions/gitversion/setup@<sha>   # v4
  with:
      versionSpec: 6.x
- id: gitversion
  uses: gittools/actions/gitversion/execute@<sha> # v4

- uses: taiki-e/install-action@<sha>              # git-cliff
- id: changelog
  run: |
      CURRENT_TAG="v${{ steps.gitversion.outputs.semVer }}"
      git cliff --output CHANGELOG_RELEASE.md --tag "$CURRENT_TAG" 2>/dev/null || \
        git cliff --unreleased --output CHANGELOG_RELEASE.md
```

Three details that are not decoration:

1. **`fetch-depth: 0` on the checkout.** GitVersion reads the commit graph and the tags; a
   shallow clone makes it compute a wrong version rather than fail, which is worse.
2. **git-cliff is fed the tag GitVersion computed**, not the last tag it can find — the
   changelog then describes the release actually being cut.
3. **The same version tags the images built in that run** (`CI-046`), so an artefact, its
   changelog entry and its git tag are one fact rather than three that drift apart.

git-cliff reads Conventional Commits, which is why the commit convention is enforced at the
commit gate: a non-conventional message is silently absent from the changelog, and nobody
notices until a user asks what changed.

### CI-046 — Build once, promote the artefact

The artefact tested is the artefact deployed — the same image digest moves through the
environments. Rebuilding per environment means production runs something no test ever saw.

### CI-047 — Every deployable product ships continuous delivery

Where a product is meant to run somewhere, its deployment is a **pipeline, not a person**. A
**deployable product** (`runtime: container` — a service or an app) has a **CD workflow** that,
on the release of `main` (or a tagged release), deploys the already-tested promoted artefact
(`CI-046`) to its environment automatically — gated by an `environment:` with its reviewers
(`CI-023`) and using the deploy concurrency group that never cancels a deploy mid-flight
(`CI-031`). No manual deploy from a laptop, no hand-copied image tag. A **distributable library**
delivers by **publishing its package** (GHCR / PyPI via OIDC Trusted Publishing) as its CD;
`exempt:config` and `exempt:native` repos have no CD. "When needed" is the test: a product that
is *released* but reaches production by a human running commands is missing its CD. What CD puts
in production **announces its version** — the deployed service and frontend surface the running
application version, image digest and environment, as already required by the socle's *the
container is versioned separately … an admin can see what is actually deployed* rule — so a
deploy is observable, never a silent swap.

______________________________________________________________________

## 6. Feedback

### CI-050 — Notify on what people act on

Failures on the integration and production branches, failed deployments, releases. Not every
green run: a channel that pings on success is a channel nobody reads, and the failure notice
lands in a stream people have learned to ignore.

### CI-051 — The bot writes to the pull request

Labels, size, conflict detection, dependency links, generated summaries — small dedicated
workflows whose output lands where the decision is made. This is the part of CI developers
actually feel.

### CI-052 — Artefacts are named and their retention is deliberate

Retention matches the debugging window, not the platform default. Unowned artefacts are a
storage bill nobody reads and a search that returns forty identically named files.

### CI-053 — Performance and cost budgets

Each profile declares explicit **budgets** — frontend bundle, Docker image size, startup
time, memory, CPU, latency, throughput, storage, and log volume — and the pipeline measures
them and **blocks significant regressions** (`info` → `warning` → `error`, like every other
gate). AI paths additionally budget **tokens, cost, latency, concurrency, and cache**. A
budget overrun is never silently accepted: it carries a justification, an impact measurement,
and a reduction plan.

______________________________________________________________________

## 7. Review checklist

A workflow change is reviewable against this list in under a minute:

1. Do all jobs declare `permissions:` and `timeout-minutes:`? (CI-020, CI-030)
2. Third-party actions pinned by SHA, internal by tag — no `@main`? (CI-010, CI-011)
3. Are secrets an explicit list rather than `inherit`? (CI-021)
4. Does any `run:` interpolate untrusted `${{ github.event.* }}`? (CI-022)
5. Concurrency group present — cancelling on PRs, *not* on deploys? (CI-031)
6. Is the logic in YAML, or in an action / tested script? (CI-002)
7. Is the runner choice justified by the workload? (CI-035)
8. New gate: does a failure mean the code is wrong? (CI-040)
9. Does a skipped job report as skipped, never as passed? (CI-032)
10. Are the profile's performance and cost budgets measured, with regressions blocked? (CI-053)

______________________________________________________________________

## 8. Enforcement

| Rule | Mechanism |
| --- | --- |
| CI-010, CI-011 | `actionlint` + a pin check in the commit gate; Dependabot for updates |
| CI-020, CI-021, CI-022 | reviewed in pull request; grep-able patterns, candidates for a hook |
| CI-030, CI-031 | reviewed in pull request |
| CI-004, CI-003 | fleet audit script over the workflow corpus |
| CI-006, CI-047 | fleet audit: every repo has a CI workflow; every `runtime: container` repo has a CD workflow |
| CI-040 | any permanently red check is an issue with an owner |
| CI-053 | per-profile budget file; CI measures and blocks significant regressions |

Rules not yet mechanised are declared as manually reviewed — a rule claiming automation with no
check behind it is misdeclared (`GOVERNANCE.md` GV-012).
