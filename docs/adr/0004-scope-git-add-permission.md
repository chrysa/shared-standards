# 4. Scope `git add` permission to tracked files

Date: 2026-07-17
Status: Accepted

## Context

PR #85 was merged to `main` via `--admin` (CI is billing-blocked fleet-wide), shipping two
findings that propagate to every repo consuming the template:

- `templates/settings.json` granted `Bash(git add:*)`, letting an agent stage arbitrary paths.
- The `/commit` command staged "all modified and new files" with a bare `git add`, which can
  stage untracked files (for example secrets not yet in `.gitignore`).

## Decision

- Scope the template permission to `Bash(git add -u)` — stage tracked modifications only, never
  arbitrary paths.
- The `/commit` command uses `git add -u` and never stages untracked files automatically.

## Consequences

- Agents can no longer stage new or untracked files without an explicit, separately-authorized
  action, reducing the risk of committing secrets.
- Adding a genuinely new file to a commit now requires an explicit `git add <path>` a human
  authorizes, by design.
- Propagates to all consuming repos on the next standards distribution.
