# ADR 0001 — Canonical CI templates and repository hygiene baseline

- **Status:** Accepted
- **Date:** 2026-06-06
- **Context:** OPS-190 (normalize repos), Execution Standard v1.3

## Context

The chrysa portfolio (59 repos) had drifted git/CI configuration. A canonical
standard existed in `shared-standards`, but the stack-CI templates
(`workflows/ci-python.yml`, `ci-node.yml`) were stale (Python 3.12,
`actions/checkout@v5`, bare `pip install -e` + `pytest`) while the most evolved
pipeline lived only inside `django-pytest`/`django-traceid`/`django-app-forge`
(Python 3.14, `chrysa/github-actions/*` reusable actions, Docker tests, SonarCloud).
No templates existed for `.gitattributes`, `CONTRIBUTING.md`, or `LICENSE`.

## Decision

1. **Lift the evolved CI into the canonical templates.** `workflows/ci-python.yml`
   now mirrors the django-pytest pipeline with `${...}` placeholders for per-repo
   values (`PACKAGE`, `SOURCES`, `TESTS`, `REPO_NAME`, `PROJECT_KEY`).
   `workflows/ci-node.yml` gets parity job names.
2. **Fix the job names as the contract.** `pre-commit` / `lint` / `test` / `sonar`
   are invariant across repos and are the branch-protection required status checks.
3. **Pre-commit Full §8 baseline is authoritative.** The minimal ruff-only variant
   used by the three django repos is non-compliant and will be upgraded; gitleaks +
   conventional-commits + no-commit-to-branch + `chrysa/pre-commit-tools` are required.
4. **Add hygiene templates** (`.editorconfig`, `.gitattributes`, `CONTRIBUTING.md`,
   `LICENSE.mit`) and codify the mandatory repo-files baseline in Execution Standard §14.
5. **LICENSE is visibility-gated** via `repos.yml` (public repos get MIT; private skip).

## Consequences

- One source of truth; `apply-repo-standard.sh` propagates it idempotently.
- The three "already standardized" django repos must have their pre-commit upgraded.
- Branch protection contexts must match the four job names exactly, or merges block
  forever — locked here to prevent drift.
- Reusable-action version `v1.0.12` is pinned in the canonical CI for reproducibility.
