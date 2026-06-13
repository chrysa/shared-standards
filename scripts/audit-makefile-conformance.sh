#!/usr/bin/env bash
# audit-makefile-conformance.sh · Read-only fleet audit of Makefile derivation
# from Forge-Stack-Workshop/base-makefile and conformance to EXECUTION_STANDARD.md §1.
#
# Source: chrysa/shared-standards/scripts/audit-makefile-conformance.sh
#
# Per dev repo (repos.yml) it reports:
#   MK   has a ./Makefile
#   TIER classified tier (lib | python-app | fullstack | infra)
#   TPL  base-makefile template it should derive from
#   MRK  '# makefile-tier:' marker present
#   GATE makefile-check (chrysa/pre-commit-tools) result: ok | warn | FAIL | -
#   HOOK makefile-check wired into .pre-commit-config.yaml
#   CIPC a workflow runs pre-commit (so the hook fires in CI)
#
# Emits a TSV table to stdout AND persists a machine-readable ledger at
# shared-standards/compliance/makefile-conformance.json.
#
# Usage: bash audit-makefile-conformance.sh [--all | <repo_path>]
# Env:   CHRYSA_ROOT (default: parent of shared-standards)
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STD_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CHRYSA_ROOT="${CHRYSA_ROOT:-$(cd "$STD_ROOT/.." && pwd)}"
REPOS_YML="$STD_ROOT/repos.yml"
LEDGER_DIR="$STD_ROOT/compliance"
LEDGER="$LEDGER_DIR/makefile-conformance.json"
MAKEFILE_CHECK="$CHRYSA_ROOT/pre-commit-tools/pre_commit_hooks/makefile_check.py"

# shellcheck source=lib/makefile-classify.sh
source "$SCRIPT_DIR/lib/makefile-classify.sh"

# Run the canonical gate (chrysa/pre-commit-tools makefile-check) against a
# Makefile, as a plain file — no install needed. Echoes: ok | warn | FAIL | -
run_gate() {
    local mk="$1" out rc
    [[ -f "$mk" ]] || { echo "-"; return; }
    [[ -f "$MAKEFILE_CHECK" ]] || { echo "?"; return; }
    out="$(python3 "$MAKEFILE_CHECK" "$mk" 2>&1)"; rc=$?
    if [[ $rc -ne 0 ]]; then echo "FAIL"
    elif grep -q 'warning:' <<<"$out"; then echo "warn"
    else echo "ok"; fi
}

# True when any workflow invokes pre-commit (hook fires in CI).
ci_runs_precommit() {
    local repo="$1" wf
    wf="$repo/.github/workflows"
    [[ -d "$wf" ]] || return 1
    grep -rqsE 'pre-commit|pre_commit' "$wf" 2>/dev/null
}

JSON_ROWS=()

audit_one() {
    local repo="$1" name; name="$(basename "$repo")"
    [[ -d "$repo/.git" ]] || return 0

    local tier template
    IFS=$'\t' read -r tier template < <(classify_makefile "$repo")

    local mk="$repo/Makefile"
    local has_mk=false mrk=false gate hook=false cipc=false
    [[ -f "$mk" ]] && has_mk=true
    [[ -f "$mk" ]] && grep -qsE '^#\s*makefile-tier:' "$mk" && mrk=true
    gate="$(run_gate "$mk")"
    grep -qs 'makefile-check' "$repo/.pre-commit-config.yaml" 2>/dev/null && hook=true
    ci_runs_precommit "$repo" && cipc=true

    printf '%-34s %-3s %-11s %-24s %-3s %-5s %-4s %-4s\n' \
        "$name" "$($has_mk && echo ✓ || echo ✗)" "$tier" "$template" \
        "$($mrk && echo ✓ || echo ✗)" "$gate" \
        "$($hook && echo ✓ || echo ✗)" "$($cipc && echo ✓ || echo ✗)"

    JSON_ROWS+=("$(printf '{"repo":"%s","tier":"%s","template":"%s","has_makefile":%s,"tier_marker":%s,"gate":"%s","hook_wired":%s,"ci_runs_precommit":%s}' \
        "$name" "$tier" "$template" "$has_mk" "$mrk" "$gate" "$hook" "$cipc")")
}

write_ledger() {
    mkdir -p "$LEDGER_DIR"
    {
        printf '{\n  "rows": [\n'
        local i n=${#JSON_ROWS[@]}
        for ((i = 0; i < n; i++)); do
            printf '    %s%s\n' "${JSON_ROWS[$i]}" "$([[ $i -lt $((n - 1)) ]] && echo ,)"
        done
        printf '  ]\n}\n'
    } >"$LEDGER"
    echo "→ ledger: $LEDGER (${#JSON_ROWS[@]} repos)" >&2
}

header() {
    printf '%-34s %-3s %-11s %-24s %-3s %-5s %-4s %-4s\n' \
        "repo" "MK" "TIER" "TPL" "MRK" "GATE" "HOOK" "CIPC"
    printf '%s\n' "-------------------------------------------------------------------------------------------"
}

main() {
    [[ -f "$MAKEFILE_CHECK" ]] || \
        echo "warning: makefile-check not found at $MAKEFILE_CHECK — GATE column will be '?'" >&2
    header
    if [[ "${1:-}" == "--all" || -z "${1:-}" ]]; then
        while read -r name st; do
            [[ "$st" == "dev" ]] || continue
            audit_one "$CHRYSA_ROOT/$name"
        done < <(awk '$1=="-" && $2=="name:"{n=$3} $1=="status:"{print n, $2}' "$REPOS_YML")
        write_ledger
    else
        audit_one "$1"
    fi
}

main "$@"
