#!/usr/bin/env bash
# standardize-repo-settings.sh v2
# Applique les settings GitHub standards chrysa sur un ou plusieurs repos.
#
# Usage:
#   ./standardize-repo-settings.sh chrysa/dev-nexus
#   ./standardize-repo-settings.sh chrysa/dev-nexus chrysa/fridgeai
#   ./standardize-repo-settings.sh --all
#   ./standardize-repo-settings.sh --all --dry-run
#
# Prérequis: gh CLI authentifié (`gh auth status`) + jq
#
# v2 fixes :
#   - Détection `archived: true` upfront → skip propre
#   - Fallback sans has_discussions sur HTTP 422
#   - Capture stderr réelle pour diagnostic
#   - Summary final détaillé par catégorie d'échec

set -uo pipefail

DRY_RUN=false
TARGETS=()
OWNER="chrysa"

# Compteurs
SUCCESS_COUNT=0
SUCCESS_NO_DISCUSSIONS_COUNT=0
ARCHIVED_SKIP_COUNT=0
CORE_FAIL_COUNT=0
PROTECT_SKIP_COUNT=0

ARCHIVED_REPOS=()
FAILED_REPOS=()
PROTECT_SKIPPED_REPOS=()

while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run) DRY_RUN=true; shift ;;
        --all)
            echo "→ Fetching all repos for org/user $OWNER..."
            mapfile -t REPOS < <(gh repo list "$OWNER" --limit 200 --json nameWithOwner --jq '.[].nameWithOwner')
            TARGETS+=("${REPOS[@]}"); shift ;;
        -*) echo "Unknown option: $1" >&2; exit 1 ;;
        *) TARGETS+=("$1"); shift ;;
    esac
done

if [[ ${#TARGETS[@]} -eq 0 ]]; then
    echo "Usage: $0 [--dry-run] [--all | <owner/repo>...]" >&2
    exit 1
fi

build_payload() {
    local is_public=$1
    local with_discussions=${2:-true}

    local payload
    payload=$(cat <<JSON
{
  "has_wiki": true,
  "has_issues": true,
  "allow_merge_commit": true,
  "merge_commit_title": "PR_TITLE",
  "merge_commit_message": "PR_BODY",
  "allow_squash_merge": true,
  "squash_merge_commit_title": "PR_TITLE",
  "squash_merge_commit_message": "PR_BODY",
  "allow_rebase_merge": false,
  "allow_update_branch": true,
  "allow_auto_merge": true,
  "delete_branch_on_merge": true,
  "web_commit_signoff_required": false
}
JSON
)

    if $is_public; then
        if $with_discussions; then
            payload=$(jq '. + {"allow_forking": true, "has_discussions": true}' <<<"$payload")
        else
            payload=$(jq '. + {"allow_forking": true}' <<<"$payload")
        fi
    fi

    echo "$payload"
}

apply_core_settings() {
    local repo=$1
    local is_public=$2

    local payload output exit_code
    payload=$(build_payload "$is_public" true)

    if $DRY_RUN; then
        echo "  [DRY-RUN] PATCH /repos/$repo core settings"
        return 0
    fi

    # Première tentative avec has_discussions
    output=$(echo "$payload" | gh api -X PATCH "/repos/$repo" --input - 2>&1)
    exit_code=$?

    if [ $exit_code -eq 0 ]; then
        echo "  ✅ core settings applied"
        return 0
    fi

    # Analyse de l'erreur pour retry adaptatif
    if echo "$output" | grep -qE "(has_discussions|422|Validation Failed)"; then
        echo "  ⚠️  has_discussions rejeté, retry sans..."
        payload=$(build_payload "$is_public" false)
        output=$(echo "$payload" | gh api -X PATCH "/repos/$repo" --input - 2>&1)
        exit_code=$?
        if [ $exit_code -eq 0 ]; then
            echo "  ✅ core settings applied (sans has_discussions)"
            SUCCESS_NO_DISCUSSIONS_COUNT=$((SUCCESS_NO_DISCUSSIONS_COUNT + 1))
            return 0
        fi
    fi

    # Retry sans allow_forking si compte user (Allow forks réservé aux org)
    if echo "$output" | grep -qE "Allow forks can only be changed on org-owned"; then
        echo "  ⚠️  allow_forking rejeté (compte user), retry sans..."
        payload=$(build_payload "$is_public" true | jq 'del(.allow_forking)')
        output=$(echo "$payload" | gh api -X PATCH "/repos/$repo" --input - 2>&1)
        exit_code=$?
        if [ $exit_code -eq 0 ]; then
            echo "  ✅ core settings applied (sans allow_forking)"
            return 0
        fi
        # Re-retry sans has_discussions non plus
        payload=$(build_payload "$is_public" false | jq 'del(.allow_forking)')
        output=$(echo "$payload" | gh api -X PATCH "/repos/$repo" --input - 2>&1)
        exit_code=$?
        if [ $exit_code -eq 0 ]; then
            echo "  ✅ core settings applied (sans allow_forking ni has_discussions)"
            return 0
        fi
    fi

    # Échec réel - afficher l'erreur
    local err_msg
    err_msg=$(echo "$output" | grep -oE '"message":\s*"[^"]*"' | head -1 | sed 's/"message":\s*//; s/^"//; s/"$//')
    [[ -z "$err_msg" ]] && err_msg=$(echo "$output" | head -1)
    echo "  ❌ core settings FAILED: $err_msg"
    FAILED_REPOS+=("$repo: $err_msg")
    return 1
}

apply_branch_protection() {
    local repo=$1
    local branch=$2

    if ! gh api "/repos/$repo/branches/$branch" --silent >/dev/null 2>&1; then
        return 2
    fi

    local payload
    payload=$(cat <<'JSON'
{
  "required_status_checks": null,
  "enforce_admins": false,
  "required_pull_request_reviews": {
    "required_approving_review_count": 1,
    "dismiss_stale_reviews": true,
    "require_code_owner_reviews": false,
    "require_last_push_approval": false
  },
  "restrictions": null,
  "required_linear_history": false,
  "allow_force_pushes": false,
  "allow_deletions": false,
  "required_conversation_resolution": true,
  "lock_branch": false,
  "allow_fork_syncing": true
}
JSON
)

    if $DRY_RUN; then
        echo "  [DRY-RUN] PUT /repos/$repo/branches/$branch/protection"
        return 0
    fi

    local output
    output=$(echo "$payload" | gh api -X PUT "/repos/$repo/branches/$branch/protection" --input - 2>&1)
    if [ $? -eq 0 ]; then
        return 0
    else
        if echo "$output" | grep -q "Upgrade to GitHub Pro"; then
            return 3
        else
            return 1
        fi
    fi
}

# ===== Main loop =====

echo "╔══════════════════════════════════════════════════════════╗"
echo "║ Standardization chrysa GitHub settings (v2)              ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo "Targets: ${#TARGETS[@]} repo(s)"
$DRY_RUN && echo "Mode:    DRY-RUN"
echo ""

for repo in "${TARGETS[@]}"; do
    echo "━━ $repo ━━"

    if ! repo_info=$(gh api "/repos/$repo" 2>/dev/null); then
        echo "  ❌ Repo not accessible, skipping"
        FAILED_REPOS+=("$repo: not accessible")
        continue
    fi

    # DÉTECTION ARCHIVED UPFRONT
    archived=$(echo "$repo_info" | jq -r '.archived // false')
    if [[ "$archived" == "true" ]]; then
        echo "  📦 Repo déjà archivé sur GitHub, skip"
        ARCHIVED_SKIP_COUNT=$((ARCHIVED_SKIP_COUNT + 1))
        ARCHIVED_REPOS+=("$repo")
        continue
    fi

    # DÉTECTION FORK
    is_fork=$(echo "$repo_info" | jq -r '.fork // false')
    if [[ "$is_fork" == "true" ]]; then
        echo "  🔀 Fork détecté"
    fi

    visibility=$(echo "$repo_info" | jq -r '.visibility // "unknown"')
    is_public=false
    [[ "$visibility" == "public" ]] && is_public=true
    echo "  Visibility: $visibility"

    # Core settings
    if ! apply_core_settings "$repo" "$is_public"; then
        CORE_FAIL_COUNT=$((CORE_FAIL_COUNT + 1))
        continue
    fi

    # Branch protection
    protect_result=""
    for branch in master main develop; do
        apply_branch_protection "$repo" "$branch"
        case $? in
            0) protect_result+=" $branch:ok" ;;
            1) protect_result+=" $branch:fail" ;;
            2) : ;;
            3) protect_result+=" $branch:skip(403)"
               PROTECT_SKIP_COUNT=$((PROTECT_SKIP_COUNT + 1))
               PROTECT_SKIPPED_REPOS+=("$repo/$branch") ;;
        esac
    done
    [[ -n "$protect_result" ]] && echo "  Branch protection:$protect_result"

    SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
done

echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║ RÉSUMÉ                                                    ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo "Total repos scannés :                ${#TARGETS[@]}"
echo "✅ Core settings appliqués :          $SUCCESS_COUNT"
echo "   dont sans has_discussions :       $SUCCESS_NO_DISCUSSIONS_COUNT"
echo "📦 Déjà archivés sur GitHub :         $ARCHIVED_SKIP_COUNT"
echo "❌ Core settings échecs :             $CORE_FAIL_COUNT"
echo "⚠️  Branch protect HTTP 403 :         $PROTECT_SKIP_COUNT (repos privés Free)"

if [[ $ARCHIVED_SKIP_COUNT -gt 0 ]]; then
    echo ""
    echo "📦 Repos archivés (pas de modification possible, normal) :"
    printf '  - %s\n' "${ARCHIVED_REPOS[@]}"
fi

if [[ ${#FAILED_REPOS[@]} -gt 0 ]]; then
    echo ""
    echo "❌ Échecs réels à investiguer :"
    printf '  - %s\n' "${FAILED_REPOS[@]}"
fi

echo ""
if [[ $CORE_FAIL_COUNT -eq 0 ]]; then
    echo "✅ Done"
    exit 0
else
    echo "⚠️  Terminé avec $CORE_FAIL_COUNT erreurs réelles"
    exit 1
fi
