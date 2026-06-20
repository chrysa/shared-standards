#!/usr/bin/env bash
# check-canonical-drift.sh · Fail if two canonical copies diverge.
#
# Source: chrysa/shared-standards/scripts/check-canonical-drift.sh
#
# Wired as a `local` pre-commit hook so the root canonical file (the single
# source of truth) can never silently drift from its templates/ copy that the
# distribution machinery hands to the fleet. Backs the drift gate asked for by
# issues #108 (GitVersion.yml) and #109 (cliff.toml).
#
# Usage:  bash check-canonical-drift.sh <fileA> <fileB> [...<fileA> <fileB>]
# Exit:   0 every pair identical · 1 any pair drifts / missing.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/canonical.sh
source "$SCRIPT_DIR/lib/canonical.sh"

[[ $# -ge 2 && $(($# % 2)) -eq 0 ]] || {
    echo "usage: $0 <fileA> <fileB> [...]" >&2; exit 2; }

rc=0
while [[ $# -gt 0 ]]; do
    a="$1"; b="$2"; shift 2
    sa="$(canonical_blob_sha "$a" 2>/dev/null)" || { echo "drift: missing $a" >&2; rc=1; continue; }
    sb="$(canonical_blob_sha "$b" 2>/dev/null)" || { echo "drift: missing $b" >&2; rc=1; continue; }
    if [[ "$sa" != "$sb" ]]; then
        echo "drift: $a ($sa) != $b ($sb)" >&2
        echo "       run: cp $a $b   (or reconcile the canonical source)" >&2
        rc=1
    fi
done
exit "$rc"
