#!/usr/bin/env bash
# setup-branch-protection.sh · Require the CI checks before merge (OPS-188).
# Source: chrysa/shared-standards/scripts/setup-branch-protection.sh
#
# Required status check CONTEXTS = the check-run names GitHub reports, which equal
# the workflow job `name:` values (NOT the job ids) and differ per stack
# (python: "Pre-commit checks","Ruff + Mypy","Docker tests","SonarCloud";
#  node:   "Pre-commit checks","Lint + Typecheck","Tests","SonarCloud").
# To avoid the name-vs-id footgun, by default we AUTO-DETECT contexts from the
# latest check-runs on the default branch — so CI must have run there at least once.
#
# Usage:
#   ./setup-branch-protection.sh <repo>                 # owner defaults to chrysa, auto contexts
#   ./setup-branch-protection.sh chrysa/<repo>          # explicit owner
#   ./setup-branch-protection.sh <repo> --contexts "Pre-commit checks,Ruff + Mypy,Docker tests,SonarCloud"
#   ./setup-branch-protection.sh <repo> --dry-run
#
# Exit: 0 ok · 1 failure
set -euo pipefail

if [ $# -lt 1 ]; then
    echo "Usage: $0 <[owner/]repo> [--contexts \"A,B,C\"] [--dry-run]"
    echo "Example: $0 django-pytest"
    exit 1
fi

REPO_ARG=""
CONTEXTS_CSV=""
DRY_RUN=false
while [ $# -gt 0 ]; do
    case "$1" in
        --contexts) CONTEXTS_CSV="$2"; shift 2 ;;
        --dry-run)  DRY_RUN=true; shift ;;
        *)          [ -z "$REPO_ARG" ] && REPO_ARG="$1"; shift ;;
    esac
done

# Normalize to owner/repo (default owner: chrysa)
if [[ "$REPO_ARG" == */* ]]; then
    OWNER="${REPO_ARG%%/*}"; REPO_NAME="${REPO_ARG##*/}"
else
    OWNER="chrysa"; REPO_NAME="$REPO_ARG"
fi
FULL="$OWNER/$REPO_NAME"

gh auth switch -u chrysa >/dev/null 2>&1 || true

DEFAULT_BRANCH="$(gh api "repos/$FULL" --jq .default_branch 2>/dev/null || echo main)"

# Build contexts JSON array
if [ -n "$CONTEXTS_CSV" ]; then
    CONTEXTS_JSON="$(printf '%s' "$CONTEXTS_CSV" | tr ',' '\n' | jq -R . | jq -s .)"
else
    echo "🔎 Auto-detecting check contexts from $FULL@$DEFAULT_BRANCH ..."
    CONTEXTS_JSON="$(gh api "repos/$FULL/commits/$DEFAULT_BRANCH/check-runs" \
        --jq '[.check_runs[].name] | unique' 2>/dev/null || echo '[]')"
fi

if [ "$CONTEXTS_JSON" = "[]" ] || [ -z "$CONTEXTS_JSON" ]; then
    echo "❌ No status check contexts found. Run CI on $DEFAULT_BRANCH first, or pass --contexts."
    exit 1
fi

echo "🔐 $FULL · branch=$DEFAULT_BRANCH"
echo "   required checks: $(echo "$CONTEXTS_JSON" | jq -c .)"

PAYLOAD="$(jq -n --argjson ctx "$CONTEXTS_JSON" '{
  required_status_checks: { strict: true, contexts: $ctx },
  required_pull_request_reviews: {
    dismiss_stale_reviews: true,
    require_code_owner_reviews: false,
    required_approving_review_count: 1
  },
  restrictions: null,
  enforce_admins: true
}')"

if $DRY_RUN; then
    echo "[dry-run] would PUT branches/$DEFAULT_BRANCH/protection with:"
    echo "$PAYLOAD" | jq .
    exit 0
fi

echo "$PAYLOAD" | gh api "repos/$FULL/branches/$DEFAULT_BRANCH/protection" -X PUT --input - >/dev/null
echo "✅ Branch protection applied to $FULL@$DEFAULT_BRANCH"
