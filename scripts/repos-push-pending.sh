#!/usr/bin/env bash
# repos-push-pending.sh
# Pipeline sync actifs : auto-commit (si dirty) + push des commits en attente
#
# Comportement :
#   - Repos ARCHIVÉS (passés au script d'archivage) : ignorés ici
#   - Repos ACTIFS dirty : git add -A + auto-commit + push
#   - Repos ACTIFS clean + ahead : push uniquement
#   - Repos ACTIFS clean + synced : skip
#
# Safeties :
#   - Skip branches par défaut (main/master/develop) sauf si --include-default
#   - Skip si pas de remote ou detached HEAD
#   - Auto-commit uniquement si AUTO_COMMIT=true (par défaut true)
#   - Commit message : "chore: auto-commit via fix-all $(date +%Y-%m-%d)"
#
# Usage :
#   ./repos-push-pending.sh                         # auto-commit + push, skip branches default
#   ./repos-push-pending.sh --dry-run               # preview
#   ./repos-push-pending.sh --include-default       # push aussi main/master/develop
#   ./repos-push-pending.sh --no-auto-commit        # n'auto-commit pas (ancien comportement)

set -uo pipefail

CHRYSA_ROOT="${CHRYSA_ROOT:-/home/anthony/Documents/perso/projects/chrysa}"
DRY_RUN=false
INCLUDE_DEFAULT=false
AUTO_COMMIT=true
COMMIT_MSG="chore: auto-commit via fix-all $(date +%Y-%m-%d)"

for arg in "$@"; do
    case "$arg" in
        --dry-run)          DRY_RUN=true ;;
        --include-default)  INCLUDE_DEFAULT=true ;;
        --no-auto-commit)   AUTO_COMMIT=false ;;
        --message=*)        COMMIT_MSG="${arg#--message=}" ;;
        *) echo "⚠️  flag ignoré : $arg" ;;
    esac
done

cd "$CHRYSA_ROOT" || exit 1

# ─── Repos destinés à l'archivage : à ignorer ici ──────────────────
# Garder aligné avec archive-obsolete-repos.sh + archive-merged-repos.sh
SKIP_ARCHIVE_TARGETS=(
    # _archived/ local (déjà archivés)
    Al-Cu django_evolve django-struct dj-custom_struct_app foodle-test
    framewok42 gae-toolbox-2 izeberg-test test-figma-to-gh
    # legacy inconnus à archiver
    Balsa django-test unixpackage unixpackage.github.io 42_save
    # obsolètes confirmés user
    DJango-CustomeCommands
    # repos fusionnés à archiver
    pre-commit-hooks-changelog linkendin-resume
)

# Branches par défaut (skip en mode normal)
DEFAULT_BRANCHES=(main master develop)

is_archive_target() {
    local repo=$1
    for pat in "${SKIP_ARCHIVE_TARGETS[@]}"; do
        [[ "$repo" == "$pat" ]] && return 0
    done
    return 1
}

is_default_branch() {
    local branch=$1
    for b in "${DEFAULT_BRANCHES[@]}"; do
        [[ "$branch" == "$b" ]] && return 0
    done
    return 1
}

# ─── Compteurs ─────────────────────────────────────────────────────
AUTO_COMMITTED=0
PUSHED=0
SKIPPED_CLEAN=0
SKIPPED_DEFAULT=0
SKIPPED_ARCHIVE=0
SKIPPED_NO_REMOTE=0
FAILED=0
FAILED_REPOS=()

# ─── Boucle ────────────────────────────────────────────────────────
for d in */; do
    d="${d%/}"
    [[ "$d" == "_archived" ]] && continue
    [[ ! -d "$d/.git" ]] && continue

    if is_archive_target "$d"; then
        echo "⊘ $d · destiné à archivage · skip"
        SKIPPED_ARCHIVE=$((SKIPPED_ARCHIVE + 1))
        continue
    fi

    (
        cd "$d" || exit 1
        branch=$(git branch --show-current 2>/dev/null)
        remote=$(git remote get-url origin 2>/dev/null || echo "")

        if [[ -z "$remote" ]]; then
            echo "⏭️  $d · pas de remote"
            exit 3
        fi
        if [[ -z "$branch" ]]; then
            echo "⏭️  $d · detached HEAD"
            exit 3
        fi

        # Skip branches par défaut sauf si --include-default
        if ! $INCLUDE_DEFAULT && is_default_branch "$branch"; then
            dirty_count=$(git status --porcelain | wc -l)
            ahead_count=$(git rev-list --count "@{u}..HEAD" 2>/dev/null || echo 0)
            if [[ "$dirty_count" -gt 0 || "$ahead_count" -gt 0 ]]; then
                echo "🛑 $d · branche $branch (défaut) · $dirty_count dirty · $ahead_count ahead · skip (utilise --include-default pour forcer)"
            else
                echo "✓ $d · $branch clean"
            fi
            exit 5
        fi

        git fetch --quiet 2>/dev/null || true

        dirty=$(git status --porcelain | wc -l)
        ahead=$(git rev-list --count "@{u}..HEAD" 2>/dev/null || echo 0)

        # Case 1 : clean + synced → rien à faire
        if [[ "$dirty" == "0" && "$ahead" == "0" ]]; then
            echo "✓ $d · $branch · rien à push"
            exit 2
        fi

        # Case 2 : dirty → auto-commit (sauf --no-auto-commit)
        if [[ "$dirty" -gt 0 ]]; then
            if ! $AUTO_COMMIT; then
                echo "🟠 $d · $dirty fichiers dirty · auto-commit désactivé · skip"
                exit 4
            fi
            if $DRY_RUN; then
                echo "[DRY-RUN] $d · would auto-commit $dirty files on $branch with: $COMMIT_MSG"
            else
                git add -A
                if git commit -m "$COMMIT_MSG" --quiet 2>&1 | tail -3; then
                    echo "  💾 $d · auto-committed $dirty fichiers"
                else
                    echo "❌ $d · auto-commit échoué"
                    exit 1
                fi
            fi
            # recompute ahead après commit
            ahead=$(git rev-list --count "@{u}..HEAD" 2>/dev/null || echo 1)
        fi

        # Case 3 : ahead (éventuellement après auto-commit) → push
        if [[ "$ahead" -gt 0 ]]; then
            if $DRY_RUN; then
                echo "[DRY-RUN] $d · would push $ahead commits on $branch"
                exit 0
            fi
            if git push origin "$branch" 2>&1 | tail -3; then
                echo "✅ $d · $ahead commits pushed sur $branch"
                exit 0
            else
                echo "❌ $d · push échoué"
                exit 1
            fi
        fi

        exit 2
    )

    case $? in
        0) PUSHED=$((PUSHED + 1)) ;;
        1) FAILED=$((FAILED + 1)); FAILED_REPOS+=("$d") ;;
        2) SKIPPED_CLEAN=$((SKIPPED_CLEAN + 1)) ;;
        3) SKIPPED_NO_REMOTE=$((SKIPPED_NO_REMOTE + 1)) ;;
        4) SKIPPED_CLEAN=$((SKIPPED_CLEAN + 1)) ;;
        5) SKIPPED_DEFAULT=$((SKIPPED_DEFAULT + 1)) ;;
    esac
done

# ─── Résumé ────────────────────────────────────────────────────────
echo ""
echo "═══════════════════════════════════"
echo "✅ Pushed              : $PUSHED"
echo "✓ Clean/rien à faire   : $SKIPPED_CLEAN"
echo "🛑 Branches défaut skip : $SKIPPED_DEFAULT"
echo "⊘ Archive targets skip : $SKIPPED_ARCHIVE"
echo "⏭️  No remote/detached : $SKIPPED_NO_REMOTE"
echo "❌ Failed              : $FAILED"
[[ ${#FAILED_REPOS[@]} -gt 0 ]] && {
    echo ""
    echo "Repos en échec :"
    printf '  - %s\n' "${FAILED_REPOS[@]}"
}
[[ "$SKIPPED_DEFAULT" -gt 0 && $INCLUDE_DEFAULT == false ]] && {
    echo ""
    echo "ℹ️  Relance avec --include-default pour pousser aussi main/master/develop"
}
