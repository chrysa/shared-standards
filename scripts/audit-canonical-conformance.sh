#!/usr/bin/env bash
# audit-canonical-conformance.sh · Read-only fleet audit of a canonical config
# file against shared-standards' single source of truth.
#
# Source: chrysa/shared-standards/scripts/audit-canonical-conformance.sh
#
# Backs dedup-campaign issues S11 (GitVersion.yml, #108) and S12 (cliff.toml,
# #109): the canonical file already lives at the repo root; this tool produces
# the *real* drift list across the fleet so migration can be planned instead of
# guessed. Each dev repo's copy is fetched via the GitHub API (no local checkout
# needed) and compared to the canonical by git blob SHA.
#
# Per dev repo it classifies:
#   ok           copy is byte-identical to canonical
#   drift        copy present but differs (for cliff.toml the SHA is the cluster id)
#   incompatible (GitVersion only) copy uses a different branching model
#                (mode: GitHubFlow) — breaks chrysa ContinuousDeployment versioning
#   missing      repo has no such file
#   error        API/network failure (re-run)
#
# Emits a TSV table to stdout AND persists a machine-readable ledger under
# shared-standards/compliance/. Read-only: never writes to any other repo.
#
# Usage:
#   bash audit-canonical-conformance.sh GitVersion.yml
#   bash audit-canonical-conformance.sh cliff.toml
#   bash audit-canonical-conformance.sh <canonical-file> [--ledger <name.json>]
# Env: CHRYSA_ROOT unused (fleet read over the API, not the filesystem).
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STD_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
REPOS_YML="$STD_ROOT/repos.yml"
LEDGER_DIR="$STD_ROOT/compliance"

# shellcheck source=lib/canonical.sh
source "$SCRIPT_DIR/lib/canonical.sh"

CANON_FILE=""
LEDGER_NAME=""

# Classify one repo's copy of $CANON_PATH against the canonical blob SHA.
# Echoes: "<status>\t<sha>\t<note>"
classify_one() {
    local repo="$1" canon_path="$2" canon_sha="$3"
    local sha; sha="$(remote_blob_sha "$repo" "$canon_path")"
    if [[ -z "$sha" ]]; then
        printf 'missing\t-\t-'
        return
    fi
    if [[ "$sha" == "$canon_sha" ]]; then
        printf 'ok\t%s\t-' "$sha"
        return
    fi
    # Differs. For GitVersion, the campaign's real target is the legacy v5
    # "GitHubFlow" schema, recognised by the ABSENCE of a top-level `mode:` line
    # (chrysa's canonical declares `mode: ContinuousDeployment` flat at column 0)
    # or an explicit `mode: GitHubFlow`. That schema breaks chrysa branching →
    # incompatible. A copy that still declares a flat top-level mode is merely
    # cosmetic/version drift on a compatible schema.
    if [[ "$canon_path" == "GitVersion.yml" ]]; then
        local content; content="$(remote_file_content "$repo" "$canon_path")"
        local mode; mode="$(grep -ioE '^mode:[[:space:]]*[A-Za-z]+' <<<"$content" | head -1 | awk -F'[[:space:]]+' '{print $2}')"
        if [[ -z "$mode" ]] || grep -qiE '^mode:[[:space:]]*GitHubFlow' <<<"$content"; then
            printf 'incompatible\t%s\tschema:GitHubFlow-v5' "$sha"
            return
        fi
        printf 'drift\t%s\tmode:%s' "$sha" "$mode"
        return
    fi
    # cliff.toml and others: the differing SHA is the cluster identity.
    printf 'drift\t%s\tcluster:%s' "$sha" "${sha:0:8}"
}

JSON_ROWS=()

main() {
    CANON_FILE="${1:-}"
    [[ -n "$CANON_FILE" ]] || { echo "usage: $0 <canonical-file> [--ledger <name.json>]" >&2; exit 2; }
    shift || true
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --ledger) LEDGER_NAME="$2"; shift 2 ;;
            *) echo "unknown arg: $1" >&2; exit 2 ;;
        esac
    done

    local canon_local="$STD_ROOT/$CANON_FILE"
    local canon_sha; canon_sha="$(canonical_blob_sha "$canon_local")" \
        || { echo "error: canonical not found at $canon_local" >&2; exit 1; }
    if [[ -z "$LEDGER_NAME" ]]; then
        local stem; stem="${CANON_FILE##*/}"; stem="${stem%.*}"
        LEDGER_NAME="$(tr '[:upper:]' '[:lower:]' <<<"$stem")-conformance.json"
    fi
    local ledger="$LEDGER_DIR/$LEDGER_NAME"

    echo "canonical: $CANON_FILE  blob=$canon_sha" >&2
    printf '%-34s %-13s %-10s %s\n' "repo" "STATUS" "SHA" "NOTE"
    printf '%s\n' "-------------------------------------------------------------------------------"

    local repo status sha note
    while read -r repo; do
        IFS=$'\t' read -r status sha note < <(classify_one "$repo" "$CANON_FILE" "$canon_sha")
        printf '%-34s %-13s %-10s %s\n' "$repo" "$status" "${sha:0:8}" "$note"
        JSON_ROWS+=("$(printf '{"repo":"%s","status":"%s","sha":"%s","note":"%s"}' \
            "$repo" "$status" "$sha" "$note")")
    done < <(dev_repos "$REPOS_YML")

    mkdir -p "$LEDGER_DIR"
    {
        printf '{\n  "canonical": "%s",\n  "canonical_sha": "%s",\n  "rows": [\n' "$CANON_FILE" "$canon_sha"
        local i n=${#JSON_ROWS[@]}
        for ((i = 0; i < n; i++)); do
            printf '    %s%s\n' "${JSON_ROWS[$i]}" "$([[ $i -lt $((n - 1)) ]] && echo ,)"
        done
        printf '  ]\n}\n'
    } >"$ledger"
    echo "→ ledger: $ledger (${#JSON_ROWS[@]} repos)" >&2
}

main "$@"
