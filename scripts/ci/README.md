# scripts/ci

**Role.** Shell entrypoints called by this repo's workflows. A workflow step is a `uses:`
or a one-line `run:`; anything longer lives here (see the GitHub Actions standard).

## Structure

| Path                        | Purpose                                                     |
| --------------------------- | ----------------------------------------------------------- |
| `build-repo-matrix.sh`      | Emit the distribute-standards job matrix to `$GITHUB_OUTPUT` |
| `resolve-target-branch.sh`  | Resolve a target repo's default branch, skip archived repos  |

## Should contain

- Bash entrypoints called by exactly one workflow step, taking their inputs from
  environment variables the step declares.

## Should NOT contain

- Fleet-wide automation — that belongs in `scripts/` at the repo root, which is
  distributed and runnable locally.
- Logic another repo would want: extract it to `chrysa/github-actions` instead.

## Rules

- `set -euo pipefail`, `shellcheck --severity=error` clean, `shfmt -i 4`.
- Inputs are env vars with defaults (`${VAR:-}`), never positional args, so the step's
  `env:` block documents the contract.
