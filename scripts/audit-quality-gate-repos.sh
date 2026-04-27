#!/bin/bash
# Audit quality gate setup status across repos
# Usage: ./scripts/audit-quality-gate-repos.sh

set -euo pipefail

CHRYSA_DIR="/home/anthony/Documents/perso/projects/chrysa"
PADAM_DIR="/home/anthony/Documents/padam"

echo "═══════════════════════════════════════════════════════════════"
echo "Quality Gate Setup Audit"
echo "═══════════════════════════════════════════════════════════════"
echo ""

REPOS_FOUND=0
REPOS_COMPLETE=0
REPOS_MISSING=0
REPOS_PARTIAL=0

audit_repo() {
    local repo_path=$1
    local repo_name=$(basename "$repo_path")

    if [ ! -d "$repo_path/.git" ]; then
        return  # Skip non-git directories
    fi

    REPOS_FOUND=$((REPOS_FOUND + 1))

    # Check for required files
    local has_makefile=$([[ -f "$repo_path/Makefile" ]] && echo 1 || echo 0)
    local has_config=$([[ -f "$repo_path/.quality-gate.json" ]] && echo 1 || echo 0)
    local has_script=$([[ -f "$repo_path/scripts/quality_gate.py" ]] && echo 1 || echo 0)
    local has_workflow=$([[ -f "$repo_path/.github/workflows/quality-gate-check.yml" ]] && echo 1 || echo 0)
    local has_make_target=$([[ -f "$repo_path/makefiles/quality-gate.Makefile" ]] && echo 1 || echo 0)

    local total=$((has_makefile + has_config + has_script + has_workflow + has_make_target))

    if [ "$total" -eq 5 ]; then
        echo "✅ $repo_name (complete)"
        REPOS_COMPLETE=$((REPOS_COMPLETE + 1))
    elif [ "$total" -gt 0 ]; then
        echo "⚠️  $repo_name (partial: $total/5)"
        REPOS_PARTIAL=$((REPOS_PARTIAL + 1))
        [ "$has_config" -eq 0 ] && echo "    Missing: .quality-gate.json"
        [ "$has_script" -eq 0 ] && echo "    Missing: scripts/quality_gate.py"
        [ "$has_workflow" -eq 0 ] && echo "    Missing: .github/workflows/quality-gate-check.yml"
        [ "$has_make_target" -eq 0 ] && echo "    Missing: makefiles/quality-gate.Makefile"
    else
        echo "❌ $repo_name (not setup)"
        REPOS_MISSING=$((REPOS_MISSING + 1))
    fi
}

echo "📦 CHRYSA REPOS:"
echo "───────────────────────────────────────────────────────────────"

for repo_dir in "$CHRYSA_DIR"/*/; do
    if [ -d "$repo_dir" ]; then
        audit_repo "$repo_dir"
    fi
done

echo ""
echo "📦 PADAM REPOS:"
echo "───────────────────────────────────────────────────────────────"

if [ -d "$PADAM_DIR" ]; then
    for repo_dir in "$PADAM_DIR"/*/; do
        if [ -d "$repo_dir" ]; then
            audit_repo "$repo_dir"
        fi
    done
fi

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "SUMMARY"
echo "───────────────────────────────────────────────────────────────"
echo "Total repos scanned:     $REPOS_FOUND"
echo "✅ Complete:              $REPOS_COMPLETE"
echo "⚠️  Partial:              $REPOS_PARTIAL"
echo "❌ Missing:               $REPOS_MISSING"
echo "═══════════════════════════════════════════════════════════════"
echo ""

if [ "$REPOS_MISSING" -gt 0 ] || [ "$REPOS_PARTIAL" -gt 0 ]; then
    echo "Next steps:"
    echo "1. Run: ./scripts/normalize-quality-gate.sh <repo-path>"
    echo "2. Test with: make quality-gate-baseline"
    echo "3. Verify with: make quality-gate-verify"
    echo ""
fi
