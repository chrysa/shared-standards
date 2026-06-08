#!/usr/bin/env bash
# setup-branch-protection.sh · Apply branch protection on a repo's default branch (OPS-188).
# Source: chrysa/shared-standards/scripts/setup-branch-protection.sh
#
# Two modes:
#   --review-only (DEFAULT): protect WITHOUT required status checks. This is the
#     fleet baseline applied during OPS-190 — 1 approving review + no force-push/
#     deletion. Use this while CI is billing-red (see chrysa-ci-billing): requiring
#     checks that never run would deadlock every merge.
#     NOTE: enforce_admins is FALSE on purpose. With a solo owner account you cannot
#     approve your own PR, and enforce_admins=true also disables the `gh pr merge
#     --admin` override — so enforce_admins=true + 1 review = no merge is ever
#     possible. enforce_admins=false keeps the review gate for the UI / non-admins
#     while letting the owner merge via --admin (the chrysa-pr-merge-policy workflow).
#   --checks: also require status checks. CONTEXTS = the check-run names GitHub
#     reports, which equal the workflow job `name:` values (NOT the job ids). The
#     canonical release-gated CI (ci-python.yml / ci-node.yml) exposes only:
#       "Docker tests"  (job: test)   and   "SonarCloud"  (job: sonar)
#     By default in --checks mode we AUTO-DETECT contexts from the latest check-runs
#     on the default branch (CI must have run there at least once), or pass --contexts.
#
# Usage:
#   ./setup-branch-protection.sh <repo>                       # review-only (default), owner=chrysa
#   ./setup-branch-protection.sh chrysa/<repo>                # explicit owner
#   ./setup-branch-protection.sh <repo> --checks              # + required checks (auto-detected)
#   ./setup-branch-protection.sh <repo> --checks --contexts "Docker tests,SonarCloud"
#   ./setup-branch-protection.sh <repo> --dry-run
#
# Exit: 0 ok · 1 failure
set -euo pipefail

if [ $# -lt 1 ]; then
    echo "Usage: $0 <[owner/]repo> [--review-only|--checks] [--contexts \"A,B,C\"] [--dry-run]"
    echo "Example: $0 django-pytest            # review-only (default)"
    echo "Example: $0 django-pytest --checks   # also require Docker tests + SonarCloud"
    exit 1
fi

REPO_ARG=""
CONTEXTS_CSV=""
DRY_RUN=false
REQUIRE_CHECKS=false
while [ $# -gt 0 ]; do
    case "$1" in
        --contexts)    CONTEXTS_CSV="$2"; REQUIRE_CHECKS=true; shift 2 ;;
        --checks)      REQUIRE_CHECKS=true; shift ;;
        --review-only) REQUIRE_CHECKS=false; shift ;;
        --dry-run)     DRY_RUN=true; shift ;;
        *)             [ -z "$REPO_ARG" ] && REPO_ARG="$1"; shift ;;
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

# Required status checks: null in review-only mode, otherwise a strict context set.
CHECKS_JSON="null"
if $REQUIRE_CHECKS; then
    if [ -n "$CONTEXTS_CSV" ]; then
        CTX="$(printf '%s' "$CONTEXTS_CSV" | tr ',' '\n' | jq -R . | jq -s .)"
    else
        echo "🔎 Auto-detecting check contexts from $FULL@$DEFAULT_BRANCH ..."
        CTX="$(gh api "repos/$FULL/commits/$DEFAULT_BRANCH/check-runs" \
            --jq '[.check_runs[].name] | unique' 2>/dev/null || echo '[]')"
    fi
    if [ "$CTX" = "[]" ] || [ -z "$CTX" ]; then
        echo "❌ No status check contexts found. Run CI on $DEFAULT_BRANCH first, or pass --contexts."
        exit 1
    fi
    CHECKS_JSON="$(jq -n --argjson ctx "$CTX" '{ strict: true, contexts: $ctx }')"
fi

MODE="review-only"; $REQUIRE_CHECKS && MODE="with-checks"
echo "🔐 $FULL · branch=$DEFAULT_BRANCH · mode=$MODE"
[ "$CHECKS_JSON" != "null" ] && echo "   required checks: $(echo "$CHECKS_JSON" | jq -c .contexts)"

PAYLOAD="$(jq -n --argjson checks "$CHECKS_JSON" '{
  required_status_checks: $checks,
  required_pull_request_reviews: {
    dismiss_stale_reviews: true,
    require_code_owner_reviews: false,
    required_approving_review_count: 1
  },
  restrictions: null,
  enforce_admins: false,
  allow_force_pushes: false,
  allow_deletions: false
}')"

if $DRY_RUN; then
    echo "[dry-run] would PUT branches/$DEFAULT_BRANCH/protection with:"
    echo "$PAYLOAD" | jq .
    exit 0
fi

echo "$PAYLOAD" | gh api "repos/$FULL/branches/$DEFAULT_BRANCH/protection" -X PUT --input - >/dev/null
echo "✅ Branch protection applied to $FULL@$DEFAULT_BRANCH ($MODE)"
