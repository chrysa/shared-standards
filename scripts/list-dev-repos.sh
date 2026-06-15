#!/usr/bin/env bash
# list-dev-repos.sh — emit the list of status:dev repos from repos.yml.
# Source of truth for the distribute-standards workflow matrix.
#
# Usage:
#   list-dev-repos.sh            # JSON array: ["agent-config","ai-aggregator",...]
#   list-dev-repos.sh --lines    # one repo name per line
#   list-dev-repos.sh --only a,b # filter to a comma-separated subset (still must be status:dev)
#
# Exit: 0 ok · 2 repos.yml missing
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STD_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
REPOS_YML="${REPOS_YML:-$STD_ROOT/repos.yml}"

MODE="json"
ONLY=""
while [ $# -gt 0 ]; do
    case "$1" in
        --lines) MODE="lines" ;;
        --json)  MODE="json" ;;
        --only)  shift; ONLY="${1:-}" ;;
        -h|--help) sed -n '2,12p' "$0" | sed 's/^# \?//'; exit 0 ;;
        *) echo "unknown arg: $1" >&2; exit 2 ;;
    esac
    shift
done

[[ -f "$REPOS_YML" ]] || { echo "repos.yml not found: $REPOS_YML" >&2; exit 2; }

# Flat list of `- name:` / `status:` pairs; keep only status == dev.
mapfile -t DEV_REPOS < <(
    awk '$1=="-" && $2=="name:"{n=$3} $1=="status:"{if($2=="dev") print n}' "$REPOS_YML"
)

# Optional subset filter.
if [[ -n "$ONLY" ]]; then
    IFS=',' read -r -a WANT <<< "$ONLY"
    filtered=()
    for r in "${DEV_REPOS[@]}"; do
        for w in "${WANT[@]}"; do
            [[ "$r" == "${w// /}" ]] && filtered+=("$r")
        done
    done
    DEV_REPOS=("${filtered[@]}")
fi

if [[ "$MODE" == "lines" ]]; then
    printf '%s\n' "${DEV_REPOS[@]}"
    exit 0
fi

# JSON array, no external deps.
out="["
for i in "${!DEV_REPOS[@]}"; do
    [[ "$i" -gt 0 ]] && out+=","
    out+="\"${DEV_REPOS[$i]}\""
done
out+="]"
printf '%s\n' "$out"
