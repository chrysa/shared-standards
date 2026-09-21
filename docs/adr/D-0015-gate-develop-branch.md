# D-0015: Gate the `develop` branch with the same protection as `main`

- **Status:** Accepted
- **Date:** 2026-09-21
- **Deciders:** chrysa
- **Pillars touched:** engineering-rigor, traceability
- **Supersedes / Superseded by:** refines the branch model in `apply-branch-policy.sh` (previously main-only)

## Context

The chrysa branch model protected only `main`: a pull request was required there,
while `develop` — the default branch and shared integration target — was left open
to direct pushes. The rationale (see `apply-branch-policy.sh` header, `setup-branch-protection.sh`)
was solo-owner ergonomics: a single owner cannot approve their own PR, and fast
integration flows (local-sync, automated chore PRs) pushed straight to `develop`.

A 2026-09-21 fleet audit found the practical consequence: every change reached the
integration branch with **no PR boundary at all** — no diff review surface, no
CI-status gate point, no protection against an accidental force-push or history
rewrite on the branch every other branch is cut from. `main` was gated but
`develop`, where the actual work lands first, was not. The owner chose to close
this gap fleet-wide.

This does not change the *review* requirement (still 0 required approvals — the
gate is "a PR exists", not "someone else approved") nor admin ergonomics
(`enforce_admins` stays false, so `gh pr merge --admin` still works). It only moves
the PR boundary onto `develop` as well.

## Decision

Protect **both** `main` and `develop` with the canonical payload:

- `required_pull_request_reviews`: required, `required_approving_review_count: 0`
- `allow_force_pushes: false`, `allow_deletions: false`
- `enforce_admins: false`
- `required_status_checks: null` (unchanged; see ADR-0001 for the open question on
  making `test`/`sonar` required contexts — out of scope here)

`scripts/apply-branch-policy.sh` is extended to apply the payload to `develop` in
addition to `main`, idempotently, on every run (`--all`, `--all-remote`, named
repos). New repos onboarded through the script inherit the gate automatically.

## Consequences

- **Direct pushes to `develop` are blocked fleet-wide.** Integration flows
  (local-sync, automated chore/sync PRs, fast-merge) now go through a PR; the owner
  admin-merges it (`--admin`, enabled by `enforce_admins: false`).
- The protection is **durable and self-reapplying**: it lives in the canonical
  script, not in a one-shot manual run.
- Applied to 79 active repos on 2026-09-21 (main + develop). `status:non-dev`
  exempt repos (e.g. `homeassistant-config`) are unaffected by the doctrine.
- Open, unchanged: ADR-0001's intent to make `test`/`sonar` required status checks
  is still not implemented; the gate here is the PR boundary only.
