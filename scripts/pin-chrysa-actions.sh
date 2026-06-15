#!/usr/bin/env bash
# pin-chrysa-actions.sh · Pin chrysa's own reusable workflows from @main/@master to a fixed ref.
# Source: chrysa/shared-standards/scripts/pin-chrysa-actions.sh
#
# Rewrites ONLY `chrysa/github-actions/...@main|master` -> `...@<ref>` in a repo's workflow
# files. Third-party actions are never touched (pinning them blindly is unsafe). Idempotent.
#
# Why safe: chrysa/github-actions is a single owner with release tags, so pinning the org's
# own reusable workflows to a tag/SHA hardens the supply chain without guessing third-party refs.
#
# Required:
#   CHRYSA_ACTIONS_REF   the tag or 40-char SHA to pin to (e.g. v1.2.0). No default on purpose.
# Optional:
#   CHRYSA_ACTIONS_REPO  owner/repo to match (default: chrysa/github-actions)
#
# Usage:
#   CHRYSA_ACTIONS_REF=v1.2.0 pin-chrysa-actions.sh <repo_path>
#   CHRYSA_ACTIONS_REF=v1.2.0 pin-chrysa-actions.sh --dry-run <repo_path>
#   CHRYSA_ACTIONS_REF=v1.2.0 pin-chrysa-actions.sh --all
#
# Exit: 0 ok · 1 error · 2 missing input
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STD_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CHRYSA_ROOT="${CHRYSA_ROOT:-$(cd "$STD_ROOT/.." && pwd)}"
ACTIONS_REPO="${CHRYSA_ACTIONS_REPO:-chrysa/github-actions}"
REF="${CHRYSA_ACTIONS_REF:-}"

DRY_RUN=false
TARGET_ALL=false
TARGET=""
for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN=true ;;
        --all)     TARGET_ALL=true ;;
        -h|--help) sed -n '2,24p' "$0" | sed 's/^# \?//'; exit 0 ;;
        *)         [[ -z "$TARGET" ]] && TARGET="$arg" ;;
    esac
done

ok()   { echo -e "  \033[32m✓\033[0m $*"; }
warn() { echo -e "  \033[33m⚠\033[0m $*"; }
err()  { echo -e "  \033[31m✗\033[0m $*" >&2; }
info() { echo -e "  \033[34m→\033[0m $*"; }

[[ -n "$REF" ]] || { err "set CHRYSA_ACTIONS_REF=<tag-or-sha> (e.g. v1.2.0)"; exit 2; }
[[ "$REF" =~ ^(main|master)$ ]] && { err "CHRYSA_ACTIONS_REF must not be main/master"; exit 2; }

# Escape repo for regex (slashes/dots).
re_repo="$(printf '%s' "$ACTIONS_REPO" | sed 's/[.[\*^$/]/\\&/g')"

pin_one() {
    local repo="$1" name; name="$(basename "$repo")"
    local wfdir="$repo/.github/workflows"
    [[ -d "$wfdir" ]] || { info "$name · no workflows · skip"; return 0; }
    local total=0 f hits
    while IFS= read -r -d '' f; do
        hits="$(grep -cE "${re_repo}[^@[:space:]]*@(main|master)\b" "$f" 2>/dev/null || true)"
        [[ "${hits:-0}" -gt 0 ]] || continue
        total=$((total + hits))
        if $DRY_RUN; then
            info "[dry-run] $name/$(basename "$f") · $hits ref(s) → @$REF"
        else
            sed -E -i "s#(${re_repo}[^@[:space:]]*)@(main|master)([[:space:]\"']|\$)#\1@${REF}\3#g" "$f"
        fi
    done < <(find "$wfdir" -maxdepth 1 -type f \( -name '*.yml' -o -name '*.yaml' \) -print0)
    if [[ "$total" -eq 0 ]]; then
        info "$name · already pinned (no @main/@master on $ACTIONS_REPO)"
    elif $DRY_RUN; then
        info "$name · would pin $total ref(s)"
    else
        ok "$name · pinned $total ref(s) → @$REF"
    fi
}

if $TARGET_ALL; then
    while read -r r; do
        [[ -n "$r" ]] && pin_one "$CHRYSA_ROOT/$r"
    done < <(bash "$SCRIPT_DIR/list-dev-repos.sh" --lines)
elif [[ -n "$TARGET" ]]; then
    pin_one "$TARGET"
else
    err "Usage: CHRYSA_ACTIONS_REF=<ref> $0 [--all | <repo_path>] [--dry-run]"
    exit 1
fi
