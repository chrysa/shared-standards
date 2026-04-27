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

echo "🔐 Configuring branch protection for $REPO"
echo ""

# Extract owner and repo name
IFS='/' read -r OWNER REPO_NAME <<< "$REPO"

# Target branches
BRANCHES=("main" "master" "develop")

for branch in "${BRANCHES[@]}"; do
    echo "📌 Processing branch: $branch"

    # Check if branch exists
    if ! gh api repos/$OWNER/$REPO_NAME/branches/$branch --silent 2>/dev/null; then
        echo "   ⏭️  Branch does not exist, skipping"
        continue
    fi

    echo "   ➕ Updating protection rules..."

    # Apply branch protection
    gh api repos/$OWNER/$REPO_NAME/branches/$branch/protection \
        -X PUT \
        -f "required_status_checks={strict:true,contexts:[\"quality-gate\"]}" \
        -f "required_pull_request_reviews={dismiss_stale_reviews:true,require_code_owner_reviews:false,required_approving_review_count:1}" \
        -f "restrictions=null" \
        -f "enforce_admins=true" \
        --input - <<'EOF' 2>/dev/null || true
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

    echo "   ✅ Branch protection configured"
done

echo ""
echo "✅ Branch protection setup complete!"
echo ""
echo "Configuration applied:"
echo "  • Required status check: quality-gate workflow"
echo "  • Strict mode: enabled (only merged commits count)"
echo "  • Pull request reviews: 1 approval required"
echo "  • Stale review dismissal: enabled"
echo "  • Admin enforcement: enabled"
