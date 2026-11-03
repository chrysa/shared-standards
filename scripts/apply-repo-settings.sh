#!/usr/bin/env bash
# apply-repo-settings.sh · Bring a repo (or the fleet) onto the chrysa repository settings.
# Source: chrysa/shared-standards/scripts/apply-repo-settings.sh
#
# A GitHub template repository copies FILES only — merge options, features and labels
# are NOT carried over. This script is the settings layer of the repo template; it
# complements apply-branch-policy.sh (protection of main/develop) and
# distribute-standards.sh (versioned files).
#
# Sources of truth (shared-standards):
#   templates/github-config/repo-settings.json   repository settings (PATCH /repos payload)
#   templates/github-config/labels.yml           canonical labels (upsert, never deleted)
#
# Why these values (standards/STANDARDS.chrysa.md, "Merge" + "Branch model"):
#   squash on + merge commit on   feature PRs are squashed; the develop → main promotion
#                                 is a merge commit (squashing it diverges the branches)
#   rebase off                    a third merge style breaks the history contract
#   auto-merge on                 dependabot-auto-merge.yml runs `gh pr merge --auto`
#   delete branch on merge        protected/default branches are never auto-deleted
#   squash title/body = PR        the squash commit carries the Conventional Commit title
#   projects/wiki off             Shortcut is the planning surface, docs live in-repo/Notion
#
# Usage:
#   bash apply-repo-settings.sh <repo> [...]          # named repos
#   bash apply-repo-settings.sh --all-remote          # every non-archived, non-fork repo
#   bash apply-repo-settings.sh --all-remote --check  # read-only audit, exit 1 on drift
#   bash apply-repo-settings.sh <repo> --dry-run      # print what would change
#   --no-labels                                       # settings only
# Env: GH_TOKEN (or an authenticated `gh`), CHRYSA_OWNER (default: chrysa).
# Exit: 0 conform/applied · 1 drift (--check) or failure · 2 usage
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STD_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SETTINGS_FILE="$STD_ROOT/templates/github-config/repo-settings.json"
LABELS_FILE="$STD_ROOT/templates/github-config/labels.yml"
OWNER="${CHRYSA_OWNER:-chrysa}"
DRY_RUN=false
CHECK=false
ALL_REMOTE=false
WITH_LABELS=true
REPOS=()

while [ $# -gt 0 ]; do
    case "$1" in
        --dry-run)    DRY_RUN=true ;;
        --check)      CHECK=true ;;
        --all-remote) ALL_REMOTE=true ;;
        --no-labels)  WITH_LABELS=false ;;
        -h|--help)    sed -n '2,30p' "$0" | sed 's/^# \?//'; exit 0 ;;
        -*)           echo "unknown arg: $1" >&2; exit 2 ;;
        *)            REPOS+=("$1") ;;
    esac
    shift
done

if $ALL_REMOTE; then
    mapfile -t REPOS < <(gh repo list "$OWNER" --limit 300 --no-archived --source \
                             --json name -q '.[].name' | sort)
fi
[ "${#REPOS[@]}" -gt 0 ] || { echo "usage: $0 <repo>... | --all-remote [--check|--dry-run]" >&2; exit 2; }

DESIRED="$(jq -c . "$SETTINGS_FILE")" || { echo "invalid $SETTINGS_FILE" >&2; exit 2; }
# Canonical labels as compact JSON lines {name,color,description}; colors are compared
# lower-cased on both sides (the API echoes back whatever case a label was created with).
CANON_LABELS="$(python3 - "$LABELS_FILE" <<'PY'
import json, sys
import yaml
for label in yaml.safe_load(open(sys.argv[1], encoding="utf-8")):
    print(json.dumps({"name": label["name"], "color": str(label["color"]).lower(),
                      "description": label.get("description", "")}))
PY
)" || { echo "cannot parse $LABELS_FILE" >&2; exit 2; }

# GitHub's edge times out under load; retry read calls instead of reporting false drift.
gh_retry() {
    local out attempt
    for attempt in 1 2 3 4; do
        if out="$(gh "$@" 2>/dev/null)"; then printf '%s' "$out"; return 0; fi
        sleep $((attempt * 2))
    done
    return 1
}

# Keys of DESIRED whose current value differs → JSON object of the desired values.
settings_drift() {
    jq -c --argjson want "$DESIRED" \
        '. as $cur | $want | with_entries(select($cur[.key] != .value))'
}

sync_settings() {
    local full="$1" current drift
    current="$(gh_retry api "repos/$full")" || { echo "   ❌ settings · unreachable"; return 1; }
    drift="$(settings_drift <<<"$current")"
    if [ "$drift" = "{}" ]; then echo "   settings · conform"; return 0; fi
    if $CHECK || $DRY_RUN; then echo "   settings · drift: $drift"; $CHECK && return 1; return 0; fi
    if gh_retry api "repos/$full" -X PATCH --input - <<<"$drift" >/dev/null; then
        echo "   settings · applied: $(jq -r 'keys|join(",")' <<<"$drift")"
    else
        echo "   ❌ settings · PATCH failed"; return 1
    fi
}

sync_labels() {
    local full="$1" current line name color desc have missing=0 failed=0
    current="$(gh_retry api --paginate "repos/$full/labels?per_page=100" \
                   -q '.[] | {name, color: (.color | ascii_downcase), description: (.description // "")} | @json')" \
        || { echo "   ❌ labels · unreachable"; return 1; }
    while IFS= read -r line; do
        name="$(jq -r .name <<<"$line")"; color="$(jq -r .color <<<"$line")"
        desc="$(jq -r .description <<<"$line")"
        have="$(jq -c --arg n "$name" 'select((.name|ascii_downcase) == ($n|ascii_downcase))' <<<"$current")"
        [ -n "$have" ] && [ "$(jq -r .color <<<"$have")" = "$color" ] \
            && [ "$(jq -r .description <<<"$have")" = "$desc" ] && continue
        missing=$((missing + 1))
        $CHECK || $DRY_RUN && { echo "   labels · drift: $name"; continue; }
        gh_retry label create "$name" --color "$color" --description "$desc" --force -R "$full" >/dev/null \
            || { echo "   ❌ labels · $name"; failed=$((failed + 1)); }
    done <<<"$CANON_LABELS"
    if [ "$missing" -eq 0 ]; then echo "   labels · conform"
    elif $CHECK; then return 1
    elif ! $DRY_RUN; then echo "   labels · upserted $((missing - failed))/$missing"; fi
    [ "$failed" -eq 0 ]
}

drifted=0
for repo in "${REPOS[@]}"; do
    full="$OWNER/$repo"
    echo "── $full"
    sync_settings "$full" || drifted=$((drifted + 1))
    if $WITH_LABELS; then sync_labels "$full" || drifted=$((drifted + 1)); fi
done

if [ "$drifted" -gt 0 ]; then
    echo "done · ${#REPOS[@]} repo(s) · $drifted drift/failure(s)" >&2
    exit 1
fi
echo "done · ${#REPOS[@]} repo(s) conform"
