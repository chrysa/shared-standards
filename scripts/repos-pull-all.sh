#!/usr/bin/env bash
# repos-pull-all.sh
# Pull latest tous les repos chrysa, signale les conflits/échecs
# Safe : utilise --rebase pour éviter les merges spontanés
# Usage : ./repos-pull-all.sh [--dry-run] [--force]

set -uo pipefail

CHRYSA_ROOT="${CHRYSA_ROOT:-/home/anthony/Documents/perso/projects/chrysa}"
DRY_RUN=false
FORCE=false

for arg in "$@"; do
    case $arg in
        --dry-run) DRY_RUN=true ;;
        --force) FORCE=true ;;
    esac
done

cd "$CHRYSA_ROOT" || exit 1

SUCCESS=0
SKIPPED=0
FAILED=0
DIRTY=0
FAILED_REPOS=()

for d in */; do
    d="${d%/}"
    [[ "$d" == "_archived" ]] && continue
    [[ ! -d "$d/.git" ]] && continue

    (
        cd "$d" || exit 1

        branch=$(git branch --show-current 2>/dev/null)
        remote=$(git remote get-url origin 2>/dev/null || echo "")

        if [[ -z "$remote" ]]; then
            echo "⏭️  $d · pas de remote, skip"
            exit 3
        fi

        # Check dirty
        if [[ -n "$(git status --porcelain)" ]]; then
            if $FORCE; then
                echo "⚠️  $d · dirty, stash puis pull (--force)"
                git stash push -m "auto-stash-pull-all-$(date +%Y%m%d)" >/dev/null 2>&1
            else
                echo "🟠 $d · DIRTY · skip (utilise --force pour stash+pull)"
                exit 4
            fi
        fi

        if $DRY_RUN; then
            echo "[DRY-RUN] $d · would pull --rebase on $branch"
            exit 0
        fi

        # Pull rebase
        output=$(git pull --rebase origin "$branch" 2>&1)
        if [ $? -eq 0 ]; then
            changes=$(echo "$output" | grep -E "Fast-forward|Successfully rebased" | head -1)
            if [[ -z "$changes" ]]; then
                echo "✓ $d · up to date"
            else
                echo "✅ $d · $changes"
            fi
            exit 0
        else
            echo "❌ $d · pull échoué"
            echo "    $(echo "$output" | head -2 | tail -1)"
            exit 1
        fi
    )

    case $? in
        0) SUCCESS=$((SUCCESS + 1)) ;;
        1) FAILED=$((FAILED + 1)); FAILED_REPOS+=("$d") ;;
        3) SKIPPED=$((SKIPPED + 1)) ;;
        4) DIRTY=$((DIRTY + 1)) ;;
    esac
done

echo ""
echo "═══════════════════════════"
echo "✅ Success : $SUCCESS"
echo "🟠 Dirty   : $DIRTY (non pull)"
echo "⏭️  Skipped : $SKIPPED"
echo "❌ Failed  : $FAILED"
[[ ${#FAILED_REPOS[@]} -gt 0 ]] && {
    echo ""
    echo "Repos en échec :"
    printf '  - %s\n' "${FAILED_REPOS[@]}"
}
