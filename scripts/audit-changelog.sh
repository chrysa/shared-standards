#!/usr/bin/env bash
# audit-changelog.sh · Read-only fleet audit: every dev repo ships a CHANGELOG.md.
#
# Source: chrysa/shared-standards/scripts/audit-changelog.sh
#
# Backs the canon rule "Every repo ships a CHANGELOG.md" (Release & changelog config).
# Per dev repo it classifies:
#   ok       CHANGELOG.md present at the repo root
#   missing  no CHANGELOG.md (or API 404)
# Content is not judged here: the file is git-cliff output, never hand-edited.
#
# Usage: bash audit-changelog.sh [--strict]
#   --strict  exit 1 when at least one repo is missing its CHANGELOG.md
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STD_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
REPOS_YML="$STD_ROOT/repos.yml"

# shellcheck source=lib/canonical.sh
source "$SCRIPT_DIR/lib/canonical.sh"

main() {
    local strict=0 missing=0 repo status
    case "${1:-}" in
        "") ;;
        --strict) strict=1 ;;
        *) echo "usage: $0 [--strict]" >&2; exit 2 ;;
    esac
    printf '%-34s %s\n' "repo" "STATUS"
    while read -r repo; do
        if [[ -n "$(remote_blob_sha "$repo" "CHANGELOG.md")" ]]; then
            status="ok"
        else
            status="missing"
            missing=$((missing + 1))
        fi
        printf '%-34s %s\n' "$repo" "$status"
    done < <(dev_repos "$REPOS_YML")
    echo "→ $missing repo(s) without CHANGELOG.md" >&2
    [[ $strict -eq 1 && $missing -gt 0 ]] && exit 1
    exit 0
}

main "$@"
