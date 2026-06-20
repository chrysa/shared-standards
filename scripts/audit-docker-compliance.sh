#!/usr/bin/env bash
# audit-docker-compliance.sh · Container-runtime policy conformance (EXECUTION_STANDARD §6.1).
# Source: chrysa/shared-standards/scripts/audit-docker-compliance.sh
#
# "A project runs ONLY in a container unless its nature forbids it." Reads the `runtime:`
# classification in repos.yml and verifies each repo per its class.
#
#   container     -> FAIL if it cannot run containerized at all (no Dockerfile AND no compose).
#                    WARN if it runs in a container but misses §6 polish
#                    (compose / HEALTHCHECK / docker-up / docker-down / docker-test targets).
#   exempt:lib    -> WARN if neither docker-test target nor Dockerfile.test (suite would run on host).
#   exempt:config -> EXEMPT (nothing to run).
#   exempt:native -> EXEMPT (host/device/cloud/editor bound; a container cannot give host access).
#   pending       -> PENDING (pre-code scaffold; warn-only, never fails).
#
# FAIL is reserved for actual runtime-policy violations (a service that cannot run in a container).
# WARN surfaces standard gaps already owned by audit-makefile-conformance.sh / §6.
# Read-only: never mutates any repo. Writes compliance/docker-conformance.json.
#
# Usage:
#   bash audit-docker-compliance.sh            # audit every repo in repos.yml
#   bash audit-docker-compliance.sh <repo>     # audit one repo name
#   CHRYSA_ROOT=/path bash audit-docker-compliance.sh   # override checkout root
#
# Exit: 0 no FAIL (warnings allowed) · 1 one or more FAIL · 2 repos.yml missing
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STD_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CHRYSA_ROOT="${CHRYSA_ROOT:-$(cd "$STD_ROOT/.." && pwd)}"
REPOS_YML="${REPOS_YML:-$STD_ROOT/repos.yml}"
OUT_DIR="$STD_ROOT/compliance"
OUT_JSON="$OUT_DIR/docker-conformance.json"

[[ -f "$REPOS_YML" ]] || { echo "repos.yml not found: $REPOS_YML" >&2; exit 2; }
mkdir -p "$OUT_DIR"

# ── checks ──────────────────────────────────────────────────────────────────────
# All file lookups prune .claude (worktrees), .git and node_modules to avoid false
# positives from active campaign worktrees (see memory: skills/agents-audit pollution).
PRUNE=(-path '*/.claude' -prune -o -path '*/.git' -prune -o -path '*/node_modules' -prune -o)

has_runtime_dockerfile() {  # a Dockerfile that is NOT exclusively a *.test variant
    find "$1" "${PRUNE[@]}" -type f -iname 'Dockerfile*' ! -iname '*.test' -print 2>/dev/null | grep -q .
}
has_test_dockerfile() {
    find "$1" "${PRUNE[@]}" -type f \( -iname 'Dockerfile*.test' -o -iname 'Dockerfile.test' \) -print 2>/dev/null | grep -q .
}
has_compose() {
    find "$1" "${PRUNE[@]}" -type f \( -iname 'docker-compose*.y*ml' -o -iname 'compose*.y*ml' \) -print 2>/dev/null | grep -q .
}
has_make_target() {  # has_make_target <repo> <target>
    [[ -f "$1/Makefile" ]] && grep -qE "^$2:" "$1/Makefile" 2>/dev/null
}
has_healthcheck() {
    find "$1" "${PRUNE[@]}" -type f -iname 'Dockerfile*' -exec grep -qiE 'HEALTHCHECK' {} + 2>/dev/null && return 0
    find "$1" "${PRUNE[@]}" -type f \( -iname 'docker-compose*.y*ml' -o -iname 'compose*.y*ml' \) \
        -exec grep -qiE '^[[:space:]]*healthcheck:' {} + 2>/dev/null
}

# ── audit a single repo ──────────────────────────────────────────────────────────
# Globals set: V_STATUS (PASS|WARN|FAIL|EXEMPT|PENDING|ABSENT), V_DETAIL
audit_one() {
    local repo="$1" runtime="$2"
    if [[ ! -d "$repo" ]]; then
        V_STATUS="ABSENT"; V_DETAIL="not checked out locally"; return
    fi
    case "$runtime" in
        container)
            local df=false cf=false
            has_runtime_dockerfile "$repo" && df=true
            has_compose "$repo" && cf=true
            if [[ "$df" == false && "$cf" == false ]]; then
                V_STATUS="FAIL"; V_DETAIL="cannot run in a container — no Dockerfile and no compose"
                return
            fi
            local gaps=()
            [[ "$df" == true ]] || gaps+=("Dockerfile")
            [[ "$cf" == true ]] || gaps+=("compose")
            has_healthcheck "$repo"             || gaps+=("HEALTHCHECK")
            has_make_target "$repo" docker-up   || gaps+=("docker-up")
            has_make_target "$repo" docker-down || gaps+=("docker-down")
            has_make_target "$repo" docker-test || gaps+=("docker-test")
            if [[ ${#gaps[@]} -eq 0 ]]; then
                V_STATUS="PASS"; V_DETAIL="container runtime complete"
            else
                V_STATUS="WARN"; V_DETAIL="runs in container; §6 gaps: ${gaps[*]}"
            fi
            ;;
        exempt:lib)
            if has_make_target "$repo" docker-test || has_test_dockerfile "$repo"; then
                V_STATUS="PASS"; V_DETAIL="lib — tests run in container"
            else
                V_STATUS="WARN"; V_DETAIL="lib — no docker-test / Dockerfile.test (tests would run on host)"
            fi
            ;;
        exempt:config) V_STATUS="EXEMPT";  V_DETAIL="no executable runtime" ;;
        exempt:native) V_STATUS="EXEMPT";  V_DETAIL="host/device/cloud/editor bound" ;;
        pending)       V_STATUS="PENDING"; V_DETAIL="pre-code — container scaffold due before first code" ;;
        *)             V_STATUS="FAIL";    V_DETAIL="unknown runtime class '$runtime'" ;;
    esac
}

# ── drive ────────────────────────────────────────────────────────────────────────
ONLY="${1:-}"
mark() {
    case "$1" in
        PASS)    printf '✓ PASS   ' ;; WARN)    printf '! WARN   ' ;;
        FAIL)    printf '✗ FAIL   ' ;; EXEMPT)  printf '– EXEMPT ' ;;
        PENDING) printf '… PEND   ' ;; ABSENT)  printf '? ABSENT ' ;;
    esac
}

printf '%-36s %-9s %-7s %s\n' "repo" "verdict" "runtime" "detail"
printf '%s\n' "------------------------------------------------------------------------------------"

fails=0 warns=0 passes=0 exempts=0 pendings=0 absents=0
json_items=""

while read -r name status runtime; do
    [[ "$status" == "archived" || "$status" == "alias" ]] && continue
    [[ -n "$ONLY" && "$name" != "$ONLY" ]] && continue
    audit_one "$CHRYSA_ROOT/$name" "$runtime"
    printf '%-36s %s%-7s %s\n' "$name" "$(mark "$V_STATUS")" "$runtime" "$V_DETAIL"
    case "$V_STATUS" in
        PASS) ((passes++)) ;; WARN) ((warns++)) ;; FAIL) ((fails++)) ;;
        EXEMPT) ((exempts++)) ;; PENDING) ((pendings++)) ;; ABSENT) ((absents++)) ;;
    esac
    [[ -n "$json_items" ]] && json_items+=","
    json_items+=$(printf '\n  {"repo":"%s","runtime":"%s","verdict":"%s","detail":"%s"}' \
        "$name" "$runtime" "$V_STATUS" "$V_DETAIL")
done < <(awk '$1=="-"&&$2=="name:"{n=$3} $1=="status:"{st=$2} $1=="runtime:"{print n, st, $2}' "$REPOS_YML")

printf '%s\n' "------------------------------------------------------------------------------------"
printf 'pass=%d warn=%d fail=%d exempt=%d pending=%d absent=%d\n' \
    "$passes" "$warns" "$fails" "$exempts" "$pendings" "$absents"

{
    printf '{\n'
    printf '  "policy": "EXECUTION_STANDARD.md §6.1 — container-runtime",\n'
    printf '  "summary": {"pass":%d,"warn":%d,"fail":%d,"exempt":%d,"pending":%d,"absent":%d},\n' \
        "$passes" "$warns" "$fails" "$exempts" "$pendings" "$absents"
    printf '  "repos": [%s\n  ]\n' "$json_items"
    printf '}\n'
} > "$OUT_JSON"

# Normalize to the json-sorter canonical form (sorted keys, 2-space indent, UTF-8 kept,
# trailing newline) so the pre-commit json-sorter hook is a no-op on the committed file.
python3 - "$OUT_JSON" <<'PY'
import json, sys
p = sys.argv[1]
with open(p, encoding="utf-8") as fh:
    data = json.load(fh)
with open(p, "w", encoding="utf-8") as fh:
    json.dump(data, fh, indent=2, sort_keys=True, ensure_ascii=False)
    fh.write("\n")
PY
echo "report: $OUT_JSON"

[[ "$fails" -eq 0 ]]
