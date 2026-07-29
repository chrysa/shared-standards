#!/usr/bin/env bash
# sync-makefile.sh · Scaffold or reconcile a repo's Makefile against the
# Forge-Stack-Workshop/base-makefile templates, by classified tier.
#
# Source: chrysa/shared-standards/scripts/sync-makefile.sh
#
# Templates are pulled from base-makefile at a PINNED ref (single source of
# truth — no vendored copy). Source resolution order:
#   1. local sibling checkout  $CHRYSA_ROOT/../Forge-Stack-Workshop/base-makefile (git show <ref>)
#   2. shallow clone of the remote at <ref> into a temp dir
#
# Modes (auto-detected per repo):
#   scaffold  — repo has NO Makefile → instantiate the template (writes ./Makefile)
#   reconcile — repo HAS a Makefile → never overwrite; run the gate, report missing
#               §1 pieces, and (with --write) drop a ./Makefile.base-suggested for
#               human merge.
#
# Usage:
#   bash sync-makefile.sh [--write] [--repo <path>]
#     no --repo : dry-run over all dev repos in repos.yml
#     no --write: dry-run (prints what would happen; writes nothing)
# Env: CHRYSA_ROOT (default: parent of shared-standards)
set -uo pipefail

# Pinned to the first gate-conformant base-makefile release (v0.1.0-29,
# Forge-Stack-Workshop/base-makefile#29): every template carries a
# '# makefile-tier:' marker + its tier's required targets, so scaffolds pass
# chrysa/pre-commit-tools makefile-check out of the box. Bump this when a newer
# conformant release lands.
BASE_MAKEFILE_REF="${BASE_MAKEFILE_REF:-v0.1.0-29}"
BASE_MAKEFILE_REMOTE="https://github.com/Forge-Stack-Workshop/base-makefile.git"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STD_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CHRYSA_ROOT="${CHRYSA_ROOT:-$(cd "$STD_ROOT/.." && pwd)}"
REPOS_YML="$STD_ROOT/repos.yml"
LOCAL_BASE="$CHRYSA_ROOT/../Forge-Stack-Workshop/base-makefile"
MAKEFILE_CHECK="$CHRYSA_ROOT/pre-commit-tools/pre_commit_hooks/makefile_check.py"

# shellcheck source=lib/makefile-classify.sh
source "$SCRIPT_DIR/lib/makefile-classify.sh"

WRITE=0
TARGET_REPO=""
_CLONE_DIR=""

cleanup() { [[ -n "$_CLONE_DIR" && -d "$_CLONE_DIR" ]] && rm -rf "$_CLONE_DIR"; }
trap cleanup EXIT

# Echo the pinned content of a base-makefile template ($1 = filename).
fetch_template() {
    local file="$1"
    if [[ -d "$LOCAL_BASE/.git" ]] && git -C "$LOCAL_BASE" cat-file -e "$BASE_MAKEFILE_REF:$file" 2>/dev/null; then
        git -C "$LOCAL_BASE" show "$BASE_MAKEFILE_REF:$file"
        return
    fi
    if [[ -z "$_CLONE_DIR" ]]; then
        _CLONE_DIR="$(mktemp -d)"
        git clone --quiet --depth 1 --branch "$BASE_MAKEFILE_REF" \
            "$BASE_MAKEFILE_REMOTE" "$_CLONE_DIR" 2>/dev/null \
            || { echo "error: cannot fetch base-makefile@$BASE_MAKEFILE_REF" >&2; return 1; }
    fi
    cat "$_CLONE_DIR/$file"
}

# Rewrite the '# makefile-tier:' marker and PROJECT_NAME default in-stream.
# $1 = template content, $2 = tier, $3 = project name.
instantiate() {
    local content="$1" tier="$2" name="$3"
    if grep -qE '^#[[:space:]]*makefile-tier:' <<<"$content"; then
        content="$(sed -E "s/^#[[:space:]]*makefile-tier:.*/# makefile-tier: $tier/" <<<"$content")"
    else
        # Pinned template predates the marker convention — prepend it so the
        # scaffolded Makefile passes makefile-check.
        content="# makefile-tier: $tier"$'\n'"$content"
    fi
    content="$(sed -E "s/^(PROJECT_NAME[[:space:]]*\??=)[[:space:]]*.*/\1 $name/" <<<"$content")"
    printf '%s\n' "$content"
}

scaffold() {
    local repo="$1" tier="$2" template="$3" name; name="$(basename "$repo")"
    local content; content="$(fetch_template "$template")" || return 1
    content="$(instantiate "$content" "$tier" "$name")"

    if [[ "$WRITE" -eq 1 ]]; then
        printf '%s\n' "$content" >"$repo/Makefile"
        echo "  ✏️  wrote $repo/Makefile  (tier=$tier, template=$template@$BASE_MAKEFILE_REF)"
        if [[ "$template" == "Makefile.with-sub-folder" && ! -d "$repo/makefiles" ]]; then
            mkdir -p "$repo/makefiles"
            printf '# development.Makefile\n\ndev: ## Start dev server\n\t@echo "TODO: wire dev"\n' \
                >"$repo/makefiles/development.Makefile"
            echo "  ✏️  wrote $repo/makefiles/development.Makefile (skeleton)"
        fi
    else
        echo "  [dry-run] would scaffold $repo/Makefile (tier=$tier, template=$template@$BASE_MAKEFILE_REF)"
        echo "  --- preview (first 12 lines) ---"
        sed -n '1,12p' <<<"$content" | sed 's/^/  | /'
    fi
}

reconcile() {
    local repo="$1" tier="$2" template="$3"
    local mk="$repo/Makefile"
    echo "  reconcile (Makefile exists — not overwritten)"

    # Gate diagnostics (reuse the canonical checker — no duplicated logic).
    if [[ -f "$MAKEFILE_CHECK" ]]; then
        local out; out="$(python3 "$MAKEFILE_CHECK" "$mk" 2>&1)"
        [[ -n "$out" ]] && sed 's/^/  gate: /' <<<"$out" || echo "  gate: clean"
    fi

    # Derivation markers expected from base-makefile.
    grep -qsE '^#\s*makefile-tier:' "$mk" || echo "  missing: '# makefile-tier:' marker (expected: $tier)"
    grep -qs '\.DEFAULT_GOAL := help' "$mk" || echo "  missing: '.DEFAULT_GOAL := help'"
    grep -qs 'MAKEFILE_LIST' "$mk" || echo "  missing: self-documenting help recipe using \$(MAKEFILE_LIST)"
    local declared; declared="$(grep -oE '^#\s*makefile-tier:\s*[A-Za-z-]+' "$mk" 2>/dev/null | grep -oE '[A-Za-z-]+$' | tail -1)"
    [[ -n "$declared" && "$declared" != "$tier" ]] && \
        echo "  note: declared tier '$declared' ≠ classified '$tier' (review)"

    if [[ "$WRITE" -eq 1 ]]; then
        local content; content="$(fetch_template "$template")" || return 1
        content="$(instantiate "$content" "$tier" "$(basename "$repo")")"
        printf '%s\n' "$content" >"$repo/Makefile.base-suggested"
        echo "  ✏️  wrote $repo/Makefile.base-suggested for manual merge"
    fi
}

sync_one() {
    local repo="$1" name; name="$(basename "$repo")"
    [[ -e "$repo/.git" ]] || { echo "skip $name (not a repo)"; return 0; }
    local tier template
    IFS=$'\t' read -r tier template < <(classify_makefile "$repo")
    echo "▶ $name  [tier=$tier template=$template]"
    if [[ -f "$repo/Makefile" ]]; then
        reconcile "$repo" "$tier" "$template"
    else
        scaffold "$repo" "$tier" "$template"
    fi
}

main() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --write) WRITE=1; shift ;;
            --repo) TARGET_REPO="$2"; shift 2 ;;
            -h|--help) grep -E '^#( |$)' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
            *) echo "unknown arg: $1" >&2; exit 2 ;;
        esac
    done

    echo "base-makefile ref: $BASE_MAKEFILE_REF   write: $WRITE" >&2
    if [[ -n "$TARGET_REPO" ]]; then
        sync_one "$TARGET_REPO"
    else
        [[ "$WRITE" -eq 1 ]] && { echo "refusing --write over the whole fleet; pass --repo <path>" >&2; exit 2; }
        while read -r name st; do
            [[ "$st" == "dev" ]] || continue
            sync_one "$CHRYSA_ROOT/$name"
        done < <(awk '$1=="-" && $2=="name:"{n=$3} $1=="status:"{print n, $2}' "$REPOS_YML")
    fi
}

main "$@"
