# D-0016: Require `Docker tests` + `SonarCloud` as branch-protection status checks

- **Status:** Accepted
- **Date:** 2026-09-21
- **Deciders:** chrysa
- **Pillars touched:** engineering-rigor, quality-gate
- **Supersedes / Superseded by:** resolves the open question in ADR-0001; builds on ADR D-0015

## Context

ADR-0001 fixed the canonical CI job names (`pre-commit` / `lint` / `test` / `sonar`)
"as the contract … the branch-protection required status checks", but the gate was
never turned on: `apply-branch-policy.sh` shipped `required_status_checks: null`, and
D-0015 gated `develop` with the PR boundary only. So a PR could be green or red and
still merge — CI was advisory, not a gate.

The blocker was heterogeneity, not intent. The fleet runs three CI shapes: the
canonical template (jobs `test` → context **Docker tests**, `sonar` → **SonarCloud**),
inline custom CI (eka, Unity repos, guardian shell jobs named `check`/`quality`/…),
and repos with no CI. Making `Docker tests` + `SonarCloud` required *fleet-wide* would
gate the non-template repos on a context that never reports, blocking every non-admin
merge on them forever.

## Decision

Require the two canonical contexts — **`Docker tests`** and **`SonarCloud`** — on both
`main` and `develop`, but **only on repos that actually expose both**. Membership is
detected, not assumed: a repo qualifies when both context names appear in the recent
check-runs of its default branch. `apply-branch-policy.sh` performs this detection per
repo and sets `required_status_checks` accordingly (`strict:false` — a stale branch is
not forced to rebase before merge); a repo that does not run both keeps
`required_status_checks: null` and stands on the PR gate alone (D-0015).

The rest of the gate is unchanged: PR required, 0 approvals, no force-push, no deletion,
`enforce_admins: false`.

## Consequences

- On the qualifying repos (39 at adoption, 2026-09-21), a PR must be green on
  `Docker tests` and `SonarCloud` to merge without admin rights. **Admin-merge still
  works** (`enforce_admins: false`) — the escape hatch for a CI outage.
- **Known friction, accepted:** GitHub Actions billing outages make CI go red at job
  start, and the org's SonarCloud is at its free-plan LOC cap — on affected repos those
  contexts can be red for reasons unrelated to the code, and a non-admin merge is then
  blocked until CI is healthy or an admin merges. This is the price of a real gate; the
  admin path keeps it from being a hard stop.
- Detection keeps the gate self-correcting: a repo that migrates its CI onto the
  template starts qualifying on the next `apply-branch-policy.sh` run; one that drops
  the jobs stops being gated on a phantom context.
- `audit-branch-policy.sh` reports `develop_protected`; required-context coverage is
  visible in each repo's protection and can be audited later if a coverage metric is
  wanted.
