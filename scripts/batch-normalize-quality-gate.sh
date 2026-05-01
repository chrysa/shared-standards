#!/bin/bash
# Batch normalize quality gate setup across multiple repos
# Usage: ./scripts/batch-normalize-quality-gate.sh [--repos=repo1,repo2] [--force]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_SCRIPT="$SCRIPT_DIR/normalize-quality-gate.sh"
CHRYSA_DIR="/home/anthony/Documents/perso/projects/chrysa"

# Parse arguments
REPOS_TO_DEPLOY=""
FORCE_FLAG=""

for arg in "$@"; do
    if [[ "$arg" == --repos=* ]]; then
        REPOS_TO_DEPLOY="${arg#--repos=}"
    elif [[ "$arg" == --force ]]; then
        FORCE_FLAG="--force"
    fi
done

echo "═══════════════════════════════════════════════════════════════"
echo "Batch Quality Gate Normalization"
echo "═══════════════════════════════════════════════════════════════"
echo ""

# If no specific repos provided, target key ones (partial setup)
if [ -z "$REPOS_TO_DEPLOY" ]; then
    echo "No repos specified. Using default key repos for normalization:"
    REPOS_TO_DEPLOY="lifeos,server,coach,mediavault,chrysa-lib,container-webview"
fi

IFS=',' read -ra REPO_LIST <<< "$REPOS_TO_DEPLOY"

echo "Target repos: ${REPO_LIST[@]}"
echo ""

SUCCESS_COUNT=0
FAILED_COUNT=0
FAILED_REPOS=()

for repo_name in "${REPO_LIST[@]}"; do
    repo_path="$CHRYSA_DIR/$repo_name"

    if [ ! -d "$repo_path" ]; then
        echo "❌ Repo not found: $repo_name"
        FAILED_COUNT=$((FAILED_COUNT + 1))
        FAILED_REPOS+=("$repo_name")
        continue
    fi

    echo "📦 Processing: $repo_name"

    if "$REPO_SCRIPT" "$repo_path" $FORCE_FLAG > /dev/null 2>&1; then
        echo "   ✅ Done"
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
    else
        echo "   ❌ Failed"
        FAILED_COUNT=$((FAILED_COUNT + 1))
        FAILED_REPOS+=("$repo_name")
    fi
done

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "SUMMARY"
echo "───────────────────────────────────────────────────────────────"
echo "✅ Successful:  $SUCCESS_COUNT"
echo "❌ Failed:      $FAILED_COUNT"

if [ "$FAILED_COUNT" -gt 0 ]; then
    echo ""
    echo "Failed repos:"
    for failed in "${FAILED_REPOS[@]}"; do
        echo "  • $failed"
    done
fi

echo "═══════════════════════════════════════════════════════════════"
echo ""

if [ "$SUCCESS_COUNT" -gt 0 ]; then
    echo "📝 Next steps for each repo:"
    echo "   1. cd <repo-path>"
    echo "   2. Review .quality-gate.json and adjust Make commands"
    echo "   3. make quality-gate-baseline"
    echo "   4. git add -A && git commit -m 'chore: add quality gate setup'"
    echo "   5. git push"
    echo ""
fi

exit "$FAILED_COUNT"
