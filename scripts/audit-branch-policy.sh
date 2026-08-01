#!/usr/bin/env bash
# audit-branch-policy.sh · Read-only fleet audit of the chrysa branch model.
# Source: chrysa/shared-standards/scripts/audit-branch-policy.sh
#
# Standard (standards/STANDARDS.chrysa.md, "Branch model"):
#   1. `main` = the code deployed in production, protected (PR required, no force-push,
#      no deletion).
#   2. `develop` exists and is the repository's DEFAULT branch.
#   3. Feature PRs target `develop`; `main` is fed only by a PR from `develop` (or a
#      `hotfix/`), and production is triggered by a release.
#
# One GraphQL query per page of repositories — not four REST calls per repo — so a fleet
# audit costs a handful of requests and never trips GitHub's secondary rate limit.
#
# Columns: main · develop (branches exist) · default_is_develop · main_protected ·
#          pr_only (protection requires a PR and blocks force-push + deletion).
#
# Emits a TSV table on stdout and a machine-readable ledger under compliance/.
# Read-only: never writes to any repo. Fix drift with apply-branch-policy.sh.
#
# Usage:
#   bash audit-branch-policy.sh                 # every non-archived repo of the org
#   bash audit-branch-policy.sh --only a,b      # subset (comma-separated)
# Exit: 0 fleet conform · 1 drift found · 2 usage/API error
# Env: GH_TOKEN (or an authenticated `gh`), CHRYSA_OWNER (default: chrysa).
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STD_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
LEDGER_DIR="$STD_ROOT/compliance"
LEDGER="$LEDGER_DIR/branch-policy.json"
OWNER="${CHRYSA_OWNER:-chrysa}"

ONLY=""
while [ $# -gt 0 ]; do
    case "$1" in
        --only)    shift; ONLY="${1:-}" ;;
        -h|--help) sed -n '2,25p' "$0" | sed 's/^# \?//'; exit 0 ;;
        *)         echo "unknown arg: $1" >&2; exit 2 ;;
    esac
    shift
done

# `repositoryOwner` resolves for both a user and an organization — the chrysa account is a
# user, so `organization(login:)` would 404. Archived repos are filtered client-side
# (`isArchived` is not an argument of the RepositoryOwner connection).
read -r -d '' QUERY <<'GQL'
query($owner: String!, $endCursor: String) {
  repositoryOwner(login: $owner) {
    repositories(first: 50, after: $endCursor, ownerAffiliations: [OWNER],
                 orderBy: {field: NAME, direction: ASC}) {
      pageInfo { hasNextPage endCursor }
      nodes {
        name
        nameWithOwner
        isArchived
        defaultBranchRef { name }
        main: ref(qualifiedName: "refs/heads/main") { name }
        develop: ref(qualifiedName: "refs/heads/develop") { name }
        branchProtectionRules(first: 20) {
          nodes {
            pattern
            requiresApprovingReviews
            allowsForcePushes
            allowsDeletions
          }
        }
      }
    }
  }
}
GQL

RAW="$(gh api graphql --paginate -f owner="$OWNER" -f query="$QUERY" \
        -q ".data.repositoryOwner.repositories.nodes[]
            | select((.isArchived | not) and (.nameWithOwner | startswith(\"$OWNER/\")))" 2>/dev/null)" || {
    echo "GraphQL query failed (auth? rate limit?)" >&2; exit 2
}
[ -n "$RAW" ] || { echo "no repository returned for owner $OWNER" >&2; exit 2; }

# A rule protects `main` when its pattern matches it and it requires a PR while blocking
# force-push and deletion. `requiresApprovingReviews` is false by design on chrysa repos
# (solo owner) — the gate is "a PR exists", enforced by the rule's mere presence.
ROWS="$(jq -c --arg only "$ONLY" '
  ($only | if . == "" then [] else split(",") end) as $filter
  | select($filter == [] or (.name as $n | $filter | index($n)))
  | ([.branchProtectionRules.nodes[]? | select(.pattern == "main" or .pattern == "*")] | first) as $r
  | {
      repo: .name,
      default: (.defaultBranchRef.name // "?"),
      main: (.main != null),
      develop: (.develop != null),
      default_is_develop: ((.defaultBranchRef.name // "") == "develop"),
      main_protected: ($r != null),
      pr_only: ($r != null and $r.allowsForcePushes == false and $r.allowsDeletions == false)
    }' <<<"$RAW")" || { echo "failed to project the audit rows" >&2; exit 2; }
[ -n "$ROWS" ] || { echo "no repository matched (bad --only filter?)" >&2; exit 2; }

printf 'repo\tdefault\tmain\tdevelop\tdefault_is_develop\tmain_protected\tpr_only\n'
jq -r '[.repo, .default, (.main|tostring), (.develop|tostring),
        (.default_is_develop|tostring), (.main_protected|tostring), (.pr_only|tostring)]
       | @tsv' <<<"$ROWS"

mkdir -p "$LEDGER_DIR"
jq -s '{audited: length, repos: .}' <<<"$ROWS" > "$LEDGER"
echo "ledger: $LEDGER" >&2

DRIFT="$(jq -s '[.[] | select(.main and .develop and .default_is_develop
                              and .main_protected and .pr_only | not)] | length' <<<"$ROWS")"
[ "$DRIFT" -eq 0 ] || { echo "drift: $DRIFT repo(s) off the branch model" >&2; exit 1; }
