#!/usr/bin/env bash
# sentry-github-issues.sh · Make "new Sentry issue -> open a GitHub issue" the norm.
# Source: chrysa/shared-standards/scripts/sentry-github-issues.sh
#
# Sentry retired the per-project issue alert rules API (/projects/{org}/{slug}/rules/ now
# answers 404). Alerts are "workflows" attached to each project's issue-stream detector,
# served by the organization's region host (e.g. https://de.sentry.io), while integrations
# stay on the control host (https://sentry.io).
#
# The workflow payload for a GitHub action is not guessed. Create ONE workflow by hand in
# the Sentry UI (Alerts > Create alert: "A new issue is created" -> "Create a GitHub issue"
# in the project's repo, labels sentry + bug), name it like TEMPLATE_NAME below, then this
# script copies it to every other project: same triggers and actions, the repo swapped for
# GH_OWNER/<repo of the project>, attached to that project's issue-stream detector.
# Idempotent: a project whose detector already has a workflow with a GitHub action is
# skipped. --dry-run makes only GET calls and prints the exact payload it would POST.
#
# Prerequisites:
#   - Sentry GitHub integration installed once at org level (Settings -> Integrations).
#   - The template workflow described above.
#   - SENTRY_TOKEN (or SENTRY_AUTH_TOKEN): scopes `org:read`, `project:read`, `alerts:write`.
#   - curl + jq on PATH.
#
# Token sources: env (SENTRY_TOKEN / SENTRY_AUTH_TOKEN) · --secrets-file=PATH (KEY=value)
#   · --secrets-dir=PATH (file sentry_auth_token / sentry_token) · hidden prompt.
#
# Config via env:
#   SENTRY_ORG     org slug                       (default: chrysa)
#   SENTRY_URL     control host                   (default: https://sentry.io)
#   SENTRY_REGION  region host (else read from the org's links.regionUrl)
#   GH_OWNER       GitHub owner                   (default: chrysa)
#   TEMPLATE_NAME  name of the template workflow  (default: Auto: open GitHub issue on new Sentry issue)
#
# Usage:
#   sentry-github-issues.sh --dry-run                  # preview, GET calls only
#   sentry-github-issues.sh                            # apply to every project missing it
#   sentry-github-issues.sh --only=dev-nexus,chrysa-lib
#   sentry-github-issues.sh --map=my-assistant=lifeos,server=-   # slug=repo, '-' skips
#   sentry-github-issues.sh --keep-going               # do not stop at the first failure
#   sentry-github-issues.sh --secrets-file=~/.secrets
#
# Exit: 0 ok · 1 error · 2 missing dependency / token / template
set -uo pipefail

SENTRY_ORG="${SENTRY_ORG:-chrysa}"
SENTRY_URL="${SENTRY_URL:-https://sentry.io}"
SENTRY_REGION="${SENTRY_REGION:-}"
GH_OWNER="${GH_OWNER:-chrysa}"
TEMPLATE_NAME="${TEMPLATE_NAME:-Auto: open GitHub issue on new Sentry issue}"

DRY_RUN=false
KEEP_GOING=false
ONLY=""
MAP=""
SECRETS_FILE=""
SECRETS_DIR=""

for arg in "$@"; do
    case "$arg" in
        --dry-run)        DRY_RUN=true ;;
        --keep-going)     KEEP_GOING=true ;;
        --only=*)         ONLY="${arg#--only=}" ;;
        --map=*)          MAP="${arg#--map=}" ;;
        --secrets-file=*) SECRETS_FILE="${arg#--secrets-file=}" ;;
        --secrets-dir=*)  SECRETS_DIR="${arg#--secrets-dir=}" ;;
        --only|--map|--secrets-file|--secrets-dir)
                          echo "use $arg=VALUE (no space)" >&2; exit 1 ;;
        -h|--help)        sed -n '2,43p' "$0" | sed 's/^# \?//'; exit 0 ;;
        *)                echo "unknown arg: $arg" >&2; exit 1 ;;
    esac
done

ok()   { echo -e "  \033[32m✓\033[0m $*"; }
err()  { echo -e "  \033[31m✗\033[0m $*" >&2; }
info() { echo -e "  \033[34m→\033[0m $*"; }

command -v curl >/dev/null || { err "curl not found"; exit 2; }
command -v jq   >/dev/null || { err "jq not found"; exit 2; }

# Resolve the Sentry token.
if [[ -n "$SECRETS_FILE" ]]; then
    f="${SECRETS_FILE/#\~/$HOME}"
    [[ -f "$f" ]] || { err "secrets file not found: $f"; exit 2; }
    set -a; # shellcheck disable=SC1090
    source "$f"; set +a
fi
if [[ -n "$SECRETS_DIR" ]]; then
    d="${SECRETS_DIR/#\~/$HOME}"
    [[ -f "$d/sentry_auth_token" ]] && SENTRY_AUTH_TOKEN="$(tr -d '[:space:]' < "$d/sentry_auth_token")"
    [[ -f "$d/sentry_token" && -z "${SENTRY_AUTH_TOKEN:-}" ]] && SENTRY_AUTH_TOKEN="$(tr -d '[:space:]' < "$d/sentry_token")"
fi
TOKEN="${SENTRY_AUTH_TOKEN:-${SENTRY_TOKEN:-}}"
if [[ -z "$TOKEN" && -e /dev/tty ]]; then
    read -rs -p "Enter SENTRY_TOKEN: " TOKEN </dev/tty; echo >&2
fi
[[ -n "$TOKEN" ]] || { err "no Sentry token · set SENTRY_TOKEN or use --secrets-file"; exit 2; }

call() {  # call METHOD URL [json-body] -> body on stdout, HTTP code in $HTTP_CODE
    local method="$1" url="$2" body="${3:-}" out
    out="$(mktemp)"
    if [[ -n "$body" ]]; then
        HTTP_CODE="$(curl -sS -o "$out" -w '%{http_code}' -X "$method" "$url" \
            -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' -d "$body")"
    else
        HTTP_CODE="$(curl -sS -o "$out" -w '%{http_code}' -X "$method" "$url" \
            -H "Authorization: Bearer $TOKEN")"
    fi
    cat "$out"; rm -f "$out"
}

get_all() {  # get_all URL -> one JSON array with every page (cursor pagination)
    local url="$1" cursor="" page all='[]' hdr
    hdr="$(mktemp)"
    while :; do
        page="$(curl -sS -D "$hdr" -H "Authorization: Bearer $TOKEN" "${url}${cursor:+&cursor=$cursor}")"
        all="$(jq -s '.[0] + (.[1] | if type=="array" then . else [] end)' <(echo "$all") <(echo "$page"))"
        cursor="$(grep -i '^link:' "$hdr" | grep -o '<[^>]*>; rel="next"; results="true"; cursor="[^"]*"' \
            | sed 's/.*cursor="\([^"]*\)".*/\1/')"
        [[ -n "$cursor" ]] || break
    done
    rm -f "$hdr"; echo "$all"
}

# 1. Region host of the organization.
if [[ -z "$SENTRY_REGION" ]]; then
    SENTRY_REGION="$(call GET "$SENTRY_URL/api/0/organizations/$SENTRY_ORG/" | jq -r '.links.regionUrl // empty')"
    [[ -n "$SENTRY_REGION" ]] || { err "cannot read the region of org '$SENTRY_ORG' (HTTP $HTTP_CODE)"; exit 1; }
fi
REGION_API="$SENTRY_REGION/api/0"
echo "── org=$SENTRY_ORG · region=$SENTRY_REGION ──"

# 2. GitHub integration (control host).
integ="$(call GET "$SENTRY_URL/api/0/organizations/$SENTRY_ORG/integrations/?provider_key=github")"
INTEGRATION_ID="$(echo "$integ" | jq -r 'if type=="array" then (.[0].id // empty) else empty end')"
[[ -n "$INTEGRATION_ID" ]] || { err "no GitHub integration for org '$SENTRY_ORG' (HTTP $HTTP_CODE) · install it first"; exit 1; }
ok "GitHub integration id = $INTEGRATION_ID"

# 3. Workflows: template + detectors that already open GitHub issues.
WORKFLOWS="$(get_all "$REGION_API/organizations/$SENTRY_ORG/workflows/?per_page=100")"
TEMPLATE="$(echo "$WORKFLOWS" | jq --arg n "$TEMPLATE_NAME" '[.[] | select(.name == $n)] | .[0] // empty')"
if [[ -z "$TEMPLATE" ]]; then
    err "template workflow '$TEMPLATE_NAME' not found · create it once in the Sentry UI (see --help)"
    exit 2
fi
GH_ACTIONS='[.actionFilters[]?.actions[]? | select(.type == "github")]'
[[ "$(echo "$TEMPLATE" | jq "$GH_ACTIONS | length")" -ge 1 ]] \
    || { err "template '$TEMPLATE_NAME' has no GitHub action"; exit 2; }
mapfile -t TPL_REPOS < <(echo "$TEMPLATE" | jq -r --arg o "$GH_OWNER/" \
    "$GH_ACTIONS | [.. | strings | select(startswith(\$o))] | unique | .[]")
[[ "${#TPL_REPOS[@]}" -eq 1 ]] \
    || { err "template must name exactly one repo '$GH_OWNER/<repo>' (found ${#TPL_REPOS[@]})"; exit 2; }
TPL_REPO="${TPL_REPOS[0]}"
ok "template id $(echo "$TEMPLATE" | jq -r .id) · repo $TPL_REPO"
DONE_DETECTORS="$(echo "$WORKFLOWS" | jq "[.[] | select(($GH_ACTIONS | length) > 0) | .detectorIds[]?] | unique")"

# 4. Projects.
PROJECTS="$(get_all "$REGION_API/organizations/$SENTRY_ORG/projects/?per_page=100")"
[[ "$(echo "$PROJECTS" | jq length)" -gt 0 ]] || { err "no projects returned · check token scopes"; exit 1; }

in_list() {  # in_list needle comma-list
    local w; IFS=',' read -r -a arr <<< "$2"
    for w in "${arr[@]}"; do [[ "$1" == "${w// /}" ]] && return 0; done
    return 1
}
repo_for() {  # repo_for slug -> repo name, or '-' to skip
    local pair; IFS=',' read -r -a pairs <<< "$MAP"
    for pair in "${pairs[@]}"; do
        [[ "${pair%%=*}" == "$1" ]] && { echo "${pair#*=}"; return; }
    done
    echo "$1"
}

payload_for() {  # payload_for repo detector-id
    echo "$TEMPLATE" | jq --arg from "$TPL_REPO" --arg to "$GH_OWNER/$1" --arg det "$2" '
        walk(if type == "object"
             then del(.id, .organizationId, .dateCreated, .dateUpdated, .lastTriggered, .createdBy)
             else . end)
        | walk(if type == "string" and . == $from then $to else . end)
        | .detectorIds = [$det]'
}

echo "── Provisioning (filter='${ONLY:-none}', map='${MAP:-none}') ──"
created=0; skipped=0; failed=0; shown=false
while IFS=$'\t' read -r slug pid; do
    [[ -z "$ONLY" ]] || in_list "$slug" "$ONLY" || continue
    repo="$(repo_for "$slug")"
    [[ "$repo" != "-" ]] || { info "$slug · mapped to '-' · skip"; ((skipped++)); continue; }
    det="$(call GET "$REGION_API/organizations/$SENTRY_ORG/detectors/?project=$pid" \
        | jq -r '[.[]? | select(.type == "issue_stream") | .id] | .[0] // empty')"
    [[ -n "$det" ]] || { err "$slug · no issue-stream detector (HTTP $HTTP_CODE)"; ((failed++)); $KEEP_GOING || break; continue; }
    if echo "$DONE_DETECTORS" | jq -e --arg d "$det" 'index($d) != null' >/dev/null; then
        info "$slug · already opens GitHub issues · skip"; ((skipped++)); continue
    fi
    body="$(payload_for "$repo" "$det")"
    if $DRY_RUN; then
        info "[dry-run] $slug -> $GH_OWNER/$repo (detector $det)"
        $shown || { echo "$body" | jq -c .; shown=true; }
        ((created++)); continue
    fi
    resp="$(call POST "$REGION_API/organizations/$SENTRY_ORG/workflows/" "$body")"
    if [[ "$HTTP_CODE" == 201 || "$HTTP_CODE" == 200 ]]; then
        ok "$slug -> $GH_OWNER/$repo · workflow $(echo "$resp" | jq -r .id)"; ((created++))
    else
        err "$slug · HTTP $HTTP_CODE: $(echo "$resp" | jq -c . 2>/dev/null | head -c 300)"; ((failed++))
        $KEEP_GOING || break
    fi
done < <(echo "$PROJECTS" | jq -r '.[] | [.slug, .id] | @tsv' | sort)

echo "── Done · created/would-create=$created · skipped=$skipped · failed=$failed ──"
[[ "$failed" -eq 0 ]]
