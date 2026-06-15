#!/usr/bin/env bash
# file-compliance-issues.sh · Open one consolidated standards-compliance issue per repo.
# Source: chrysa/shared-standards/scripts/file-compliance-issues.sh
#
# Reads a findings JSON ({ "<repo>": {title, body, counts}, ... }) produced by the audit
# and opens ONE issue per repo via gh. Idempotent: skips a repo that already has an issue
# (any state) whose title matches. Run locally with an authenticated gh + jq.
#
# Usage:
#   file-compliance-issues.sh --dry-run                 # preview, create nothing
#   file-compliance-issues.sh                            # open the issues
#   file-compliance-issues.sh --only=dev-nexus,coach
#   file-compliance-issues.sh --findings=docs/audits/findings-20260615.json
#   file-compliance-issues.sh --labels=chore,standards-sync
#
# Exit: 0 ok · 1 error · 2 missing dependency
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STD_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ORG="${CHRYSA_ORG:-chrysa}"

DRY_RUN=false
ONLY=""
LABELS="chore"
FINDINGS=""

for arg in "$@"; do
    case "$arg" in
        --dry-run)     DRY_RUN=true ;;
        --only=*)      ONLY="${arg#--only=}" ;;
        --labels=*)    LABELS="${arg#--labels=}" ;;
        --findings=*)  FINDINGS="${arg#--findings=}" ;;
        -h|--help)     sed -n '2,22p' "$0" | sed 's/^# \?//'; exit 0 ;;
        *)             echo "unknown arg: $arg" >&2; exit 1 ;;
    esac
done

ok()   { echo -e "  \033[32m✓\033[0m $*"; }
warn() { echo -e "  \033[33m⚠\033[0m $*"; }
err()  { echo -e "  \033[31m✗\033[0m $*" >&2; }
info() { echo -e "  \033[34m→\033[0m $*"; }

command -v jq >/dev/null || { err "jq not found"; exit 2; }
command -v gh >/dev/null || { err "gh not found"; exit 2; }
$DRY_RUN || gh auth status >/dev/null 2>&1 || { err "gh not authenticated · run: gh auth login"; exit 2; }

# Default to the newest findings-*.json under docs/audits.
if [[ -z "$FINDINGS" ]]; then
    FINDINGS="$(ls -1t "$STD_ROOT"/docs/audits/findings-*.json 2>/dev/null | head -1)"
fi
[[ -n "$FINDINGS" && -f "$FINDINGS" ]] || { err "findings JSON not found (pass --findings=PATH)"; exit 1; }
info "findings: $FINDINGS"

want() {
    [[ -z "$ONLY" ]] && return 0
    local s="$1" w; IFS=',' read -r -a arr <<< "$ONLY"
    for w in "${arr[@]}"; do [[ "$s" == "${w// /}" ]] && return 0; done
    return 1
}

# True if repo already has an issue (any state) with this exact title.
issue_exists() {
    local repo="$1" title="$2" hit
    hit="$(gh issue list --repo "$ORG/$repo" --state all --search "in:title \"$title\"" \
            --json title --jq "[.[] | select(.title==\"$title\")] | length" 2>/dev/null || echo 0)"
    [[ "${hit:-0}" -gt 0 ]]
}

created=0; skipped=0; failed=0
mapfile -t REPOS < <(jq -r 'keys[]' "$FINDINGS")

for repo in "${REPOS[@]}"; do
    want "$repo" || continue
    title="$(jq -r --arg r "$repo" '.[$r].title' "$FINDINGS")"
    body="$(jq -r --arg r "$repo" '.[$r].body' "$FINDINGS")"
    counts="$(jq -r --arg r "$repo" '.[$r].counts | "crit=\(.critical) high=\(.high) med=\(.medium) low=\(.low)"' "$FINDINGS")"

    if $DRY_RUN; then
        info "[dry-run] $repo · would open \"$title\" ($counts)"; ((created++)); continue
    fi

    if issue_exists "$repo" "$title"; then
        info "$repo · issue already exists · skip"; ((skipped++)); continue
    fi

    bf="$(mktemp)"; printf '%s\n' "$body" > "$bf"
    # Try with labels; if a label is missing on the repo, retry without labels.
    label_args=(); IFS=',' read -r -a larr <<< "$LABELS"
    for l in "${larr[@]}"; do [[ -n "$l" ]] && label_args+=(--label "$l"); done

    url="$(gh issue create --repo "$ORG/$repo" --title "$title" --body-file "$bf" "${label_args[@]}" 2>/dev/null)" \
        || url="$(gh issue create --repo "$ORG/$repo" --title "$title" --body-file "$bf" 2>/dev/null)"
    rm -f "$bf"

    if [[ -n "$url" ]]; then ok "$repo · $url ($counts)"; ((created++)); else err "$repo · failed"; ((failed++)); fi
done

echo "── Done · created/would-create=$created · skipped=$skipped · failed=$failed ──"
[[ "$failed" -eq 0 ]]
