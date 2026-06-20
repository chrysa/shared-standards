#!/usr/bin/env bash
# sync-canonical.sh · Copy a canonical config file from shared-standards into one
# target repo's working tree (single-repo propagation — never a fleet fan-out).
#
# Source: chrysa/shared-standards/scripts/sync-canonical.sh
#
# Backs the migration side of dedup-campaign issues #108 (GitVersion.yml) and
# #109 (cliff.toml): once a repo is flagged `drift`/`incompatible`/`missing` by
# audit-canonical-conformance.sh, run this to align its copy with the single
# source of truth. Deliberately operates on ONE local checkout at a time —
# issue #109 forbids mass-opening 50 PRs, so propagation stays a human-paced,
# one-repo-per-session act (commit/PR is left to the operator).
#
# Modes:
#   dry-run (default)  — print the diff vs canonical; write nothing.
#   --write            — overwrite the target repo's copy with the canonical.
#
# Usage:
#   bash sync-canonical.sh GitVersion.yml --repo ../mirrador
#   bash sync-canonical.sh cliff.toml --repo ../mirrador --write
# Env: CHRYSA_ROOT (default: parent of shared-standards) — used to resolve a
#      bare repo name passed to --repo (e.g. --repo mirrador).
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STD_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CHRYSA_ROOT="${CHRYSA_ROOT:-$(cd "$STD_ROOT/.." && pwd)}"

# shellcheck source=lib/canonical.sh
source "$SCRIPT_DIR/lib/canonical.sh"

CANON_FILE=""
TARGET_REPO=""
WRITE=0

resolve_repo() {
    local r="$1"
    [[ -d "$r/.git" ]] && { printf '%s' "$r"; return; }
    [[ -d "$CHRYSA_ROOT/$r/.git" ]] && { printf '%s' "$CHRYSA_ROOT/$r"; return; }
    return 1
}

main() {
    CANON_FILE="${1:-}"
    [[ -n "$CANON_FILE" && "$CANON_FILE" != --* ]] \
        || { echo "usage: $0 <canonical-file> --repo <path> [--write]" >&2; exit 2; }
    shift
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --write) WRITE=1; shift ;;
            --repo) TARGET_REPO="$2"; shift 2 ;;
            -h|--help) grep -E '^#( |$)' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
            *) echo "unknown arg: $1" >&2; exit 2 ;;
        esac
    done
    [[ -n "$TARGET_REPO" ]] || { echo "error: --repo <path> required" >&2; exit 2; }

    local canon="$STD_ROOT/$CANON_FILE"
    [[ -f "$canon" ]] || { echo "error: canonical not found at $canon" >&2; exit 1; }

    local repo; repo="$(resolve_repo "$TARGET_REPO")" \
        || { echo "error: not a git repo: $TARGET_REPO" >&2; exit 1; }
    local dest="$repo/$CANON_FILE"

    local canon_sha; canon_sha="$(canonical_blob_sha "$canon")"
    echo "canonical: $CANON_FILE  blob=$canon_sha" >&2
    echo "target:    $dest" >&2

    if [[ -f "$dest" ]]; then
        local dest_sha; dest_sha="$(canonical_blob_sha "$dest")"
        if [[ "$dest_sha" == "$canon_sha" ]]; then
            echo "✓ already in sync ($dest_sha)"; return 0
        fi
        echo "drift: target=$dest_sha != canonical=$canon_sha"
        echo "--- diff (target → canonical) ---"
        diff -u "$dest" "$canon" || true
    else
        echo "missing: target has no $CANON_FILE (would create)"
    fi

    if [[ "$WRITE" -eq 1 ]]; then
        cp "$canon" "$dest"
        echo "✏️  wrote $dest  (now $canon_sha)"
        echo "   next: review, commit & open ONE PR in $repo (no fleet fan-out)"
    else
        echo "[dry-run] re-run with --write to overwrite $dest"
    fi
}

main "$@"
