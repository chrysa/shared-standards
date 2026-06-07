#!/usr/bin/env bash
# audit-repo-standard.sh · Per-repo compliance against the full chrysa standard.
# Source: chrysa/shared-standards/scripts/audit-repo-standard.sh
#
# Columns: CI (ci.yml uses chrysa actions) · PC (pre-commit §8) · EC (.editorconfig)
#          GA (.gitattributes) · CO (CONTRIBUTING) · LI (LICENSE, public only) ·
#          DB (dependabot) · OW (CODEOWNERS)
# Legend: ✓ present/compliant · ✗ missing · – n/a
#
# Usage: bash audit-repo-standard.sh [--all | <repo_path>]
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STD_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CHRYSA_ROOT="${CHRYSA_ROOT:-$(cd "$STD_ROOT/.." && pwd)}"
REPOS_YML="$STD_ROOT/repos.yml"
BASELINE="$STD_ROOT/.pre-commit-config.yaml"

mark() { [[ "$1" == "true" ]] && printf '✓' || printf '✗'; }

repo_public() {
    awk -v n="$1" '$1=="-" && $2=="name:"{c=$3} c==n && $1=="public:"{print $2; exit}' "$REPOS_YML"
}

detect_pc_stacks() {
    local repo="$1" s=""
    { [[ -f "$repo/pyproject.toml" ]] || ls "$repo"/requirements*.txt &>/dev/null; } && s+="python,"
    { [[ -f "$repo/Dockerfile" ]] || ls "$repo"/docker/Dockerfile* &>/dev/null; } && s+="docker,"
    if [[ -f "$repo/package.json" ]]; then
        s+="jsts,"
        grep -q '"react"' "$repo/package.json" 2>/dev/null && s+="react,"
    fi
    { grep -riqs 'fastapi' "$repo/pyproject.toml" "$repo"/requirements*.txt 2>/dev/null; } && s+="fastapi,"
    echo "${s%,}"
}

audit_one() {
    local repo="$1" name; name="$(basename "$repo")"
    [[ -d "$repo/.git" ]] || return 0
    local ci=false pc=false ec=false ga=false co=false li="–" db=false ow=false
    [[ -f "$repo/.github/workflows/ci.yml" ]] && grep -q 'chrysa/github-actions' "$repo/.github/workflows/ci.yml" 2>/dev/null && ci=true
    local stacks; stacks="$(detect_pc_stacks "$repo")"
    if python3 "$SCRIPT_DIR/pre-commit-merge.py" "$BASELINE" "$repo/.pre-commit-config.yaml" --check --stacks "$stacks" >/dev/null 2>&1; then pc=true; fi
    [[ -f "$repo/.editorconfig" ]] && ec=true
    [[ -f "$repo/.gitattributes" ]] && ga=true
    [[ -f "$repo/CONTRIBUTING.md" ]] && co=true
    [[ -f "$repo/.github/dependabot.yml" ]] && db=true
    { [[ -f "$repo/.github/CODEOWNERS" ]] || [[ -f "$repo/CODEOWNERS" ]]; } && ow=true
    if [[ "$(repo_public "$name")" == "true" ]]; then
        [[ -f "$repo/LICENSE" ]] && li="✓" || li="✗"
    fi
    printf '%-34s %s  %s  %s  %s  %s  %s  %s  %s\n' \
        "$name" "$(mark $ci)" "$(mark $pc)" "$(mark $ec)" "$(mark $ga)" "$(mark $co)" "$li" "$(mark $db)" "$(mark $ow)"
}

header() {
    printf '%-34s %s\n' "repo" "CI PC EC GA CO LI DB OW"
    printf '%s\n' "--------------------------------------------------------------"
}

if [[ "${1:-}" == "--all" || -z "${1:-}" ]]; then
    header
    awk '$1=="-" && $2=="name:"{n=$3} $1=="status:"{print n, $2}' "$REPOS_YML" \
    | while read -r name st; do
        [[ "$st" == "dev" ]] || continue
        audit_one "$CHRYSA_ROOT/$name"
    done
else
    header
    audit_one "$1"
fi
