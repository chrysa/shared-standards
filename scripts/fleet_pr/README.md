# fleet_pr

**Role.** Fleet-wide pull-request triage tool. Scans every open PR across the
owner's repos, classifies each into a bucket, and — only on explicit request —
squash-merges the one safe class (`BILLING`: private repos whose CI is red purely
because GitHub Actions minutes are exhausted, i.e. jobs that never started).

## Structure

| Path              | Purpose                                                            |
| ----------------- | ----------------------------------------------------------------- |
| `bucket.py`       | `Bucket` enum — the five triage outcomes.                         |
| `pull_request.py` | `PullRequest` — the typed, I/O-free view the classifier reasons on.|
| `classifier.py`   | `classify_pr()` — the pure decision (the safety core).            |
| `issues.py`       | `classify_issue()` — label-based issue categorisation.            |
| `gateway.py`      | `GhGateway` — the only impure edge (shells out to `gh`).          |
| `report.py`       | `render()` — triage result → text report.                        |
| `fleet_pr.py`     | `FleetPr` — orchestrator composing gateway + classifier.          |
| `__main__.py`     | CLI: `python -m scripts.fleet_pr`.                                |

## Usage

```bash
python -m scripts.fleet_pr                         # read-only triage report (all repos)
python -m scripts.fleet_pr --repos a,b             # restrict to some repos
python -m scripts.fleet_pr --merge                 # dry-run: what BILLING would merge
python -m scripts.fleet_pr --merge --yes           # actually squash-merge the BILLING bucket
```

## Should contain

- Pure classification/reporting logic (unit-tested against fixtures).
- The single `gh` gateway; add new GitHub reads/writes there, nowhere else.

## Should NOT contain

- Any network call outside `gateway.py`.
- Any merge path that touches a non-`BILLING` bucket — that is a safety
  violation. Public repos, real (steps>0) failures, conflicts and blocked PRs
  are report-only, by construction, forever.

## Rules

- The classifier is one-directional: any doubt resolves to `REAL_RED` so a human
  looks. Never widen `BILLING` without a test proving the new input is billing.
- `gh` runs with the operator's own auth (no Claude permission classifier, no
  `--admin`, no branch-protection edits). See [[fleet-ci-red-is-actions-billing]].
- Tests mock the gateway; zero network in the suite.
