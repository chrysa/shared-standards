#!/bin/bash
# Setup branch protection for quality gate enforcement
# Usage: ./scripts/setup-branch-protection.sh <owner/repo> <github_token>

set -euo pipefail

if [ $# -lt 1 ]; then
    echo "Usage: $0 <owner/repo> [token_env_var]"
    echo "Example: $0 anthony/padam-av GH_TOKEN"
    exit 1
fi

REPO=$1
TOKEN_VAR=${2:-"GH_TOKEN"}
TOKEN=${!TOKEN_VAR:-}

if [ -z "$TOKEN" ]; then
    echo "❌ Token not found in environment variable: $TOKEN_VAR"
    echo "Set it: export $TOKEN_VAR=github_pat_..."
    exit 1
fi

export GH_TOKEN="$TOKEN"

echo "🔐 Configuring branch protection for $REPO"
echo ""

# Extract owner and repo name
IFS='/' read -r OWNER REPO_NAME <<< "$REPO"

# Target branches
BRANCHES=("main" "master" "develop")
SUCCESS_COUNT=0
SKIPPED_COUNT=0
FAILED_COUNT=0

for branch in "${BRANCHES[@]}"; do
    echo "📌 Processing branch: $branch"

    # Check if branch exists
    if ! gh api repos/$OWNER/$REPO_NAME/branches/$branch --silent 2>/dev/null; then
        echo "   ⏭️  Branch does not exist, skipping"
      SKIPPED_COUNT=$((SKIPPED_COUNT + 1))
        continue
    fi

    echo "   ➕ Updating protection rules..."

    # Apply branch protection
    set +e
    API_OUTPUT=$(gh api repos/$OWNER/$REPO_NAME/branches/$branch/protection \
        -X PUT \
        --input - <<'EOF' 2>&1 >/dev/null
{
  "required_status_checks": {
    "strict": true,
    "contexts": ["quality-gate"]
  },
  "required_pull_request_reviews": {
    "dismiss_stale_reviews": true,
    "require_code_owner_reviews": false,
    "required_approving_review_count": 1
  },
  "restrictions": null,
  "enforce_admins": true
}
EOF
  )
  API_EXIT=$?
  set -e

  if [ "$API_EXIT" -eq 0 ]; then
      echo "   ✅ Branch protection configured"
      SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
    elif echo "$API_OUTPUT" | grep -q "Branch not found"; then
      echo "   ⏭️  Branch not found, skipping"
      SKIPPED_COUNT=$((SKIPPED_COUNT + 1))
    else
      echo "   ❌ Failed to configure branch protection"
      echo "      $API_OUTPUT"
      FAILED_COUNT=$((FAILED_COUNT + 1))
    fi
done

echo ""
echo "✅ Branch protection setup complete!"
echo ""
echo "Summary:"
echo "  • Success: $SUCCESS_COUNT"
echo "  • Skipped: $SKIPPED_COUNT"
echo "  • Failed : $FAILED_COUNT"
echo ""
echo "Configuration requested:"
echo "  • Required status check: quality-gate workflow"
echo "  • Strict mode: enabled (only merged commits count)"
echo "  • Pull request reviews: 1 approval required"
echo "  • Stale review dismissal: enabled"
echo "  • Admin enforcement: enabled"

if [ "$FAILED_COUNT" -gt 0 ]; then
  exit 1
fi
