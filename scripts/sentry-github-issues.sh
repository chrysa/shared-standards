#!/usr/bin/env bash
# sentry-github-issues.sh · Make "new Sentry issue -> open a GitHub issue" the norm.
# Source: chrysa/shared-standards/scripts/sentry-github-issues.sh
#
# Provisions, on every Sentry project, an issue alert rule whose action creates a GitHub
# issue via Sentry's native GitHub integration. Idempotent (skips projects that already
# have such a rule) and --dry-run aware (prints the exact JSON it would POST).
#
# Prerequisites:
#   - Sentry GitHub integration installed once at org level (Settings -> Integrations).
#   - SENTRY_TOKEN (or SENTRY_AUTH_TOKEN): Sentry auth token with scopes
#     `org:read`, `project:read`, `alerts:write`.
#   - curl + jq on PATH.
#
# Token sources: env (SENTRY_TOKEN / SENTRY_AUTH_TOKEN) · --secrets-file=PATH (KEY=value)
#   · --secrets-dir=PATH (file sentry_auth_token / sentry_token) · hidden prompt.
#
# Config via env:
#   SENTRY_ORG   org slug          (default: chrysa)
#   SENTRY_URL   base API host     (default: https://sentry.io)
#   GH_OWNER     GitHub owner/org  (default: chrysa)  -> rule targets GH_OWNER/<project-slug>
#
# Usage:
#   sentry-github-issues.sh --dry-run                 # preview payloads, no writes
#   sentry-github-issues.sh                            # apply to all projects missing the rule
#   sentry-github-issues.sh --only=dev-nexus,chrysa-lib
#   sentry-github-issues.sh --force                    # add the rule even if one exists
#   sentry-github-issues.sh --secrets-file=~/.secrets
#
# Exit: 0 ok · 1 error · 2 missing dependency / token
set -uo pipefail

SENTRY_ORG="${SENTRY_ORG:-chrysa}"
SENTRY_URL="${SENTRY_URL:-https://sentry.io}"
GH_OWNER="${GH_OWNER:-chrysa}"
GITHUB_ACTION_ID='sentry.integrations.github.notify_action.GitHubCreateTicketAction'
FIRST_SEEN='sentry.rules.conditions.first_seen_event.FirstSeenEventCondition'

DRY_RUN=false
FORCE=false
ONLY=""
SECRETS_FILE=""
SECRETS_DIR=""

for arg in "$@"; do
    case "$arg" in
        --dry-run)        DRY_RUN=true ;;
        --force)          FORCE=true ;;
        --only=*)         ONLY="${arg#--only=}" ;;
        --only)           echo "use --only=a,b (no space)" >&2; exit 1 ;;
        --secrets-file=*) SECRETS_FILE="${arg#--secrets-file=}" ;;
        --secrets-file)   echo "use --secrets-file=PATH (no space)" >&2; exit 1 ;;
        --secrets-dir=*)  SECRETS_DIR="${arg#--secrets-dir=}" ;;
        --secrets-dir)    echo "use --secrets-dir=PATH (no space)" >&2; exit 1 ;;
        -h|--help)        sed -n '2,33p' "$0" | sed 's/^# \?//'; exit 0 ;;
        *)                echo "unknown arg: $arg" >&2; exit 1 ;;
    esac
done

ok()   { echo -e "  \033[32m✓\033[0m $*"; }
warn() { echo -e "  \033[33m⚠\033[0m $*"; }
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

API="$SENTRY_URL/api/0"
api() {  # api METHOD PATH [json-body]
    local method="$1" path="$2" body="${3:-}"
    if [[ -n "$body" ]]; then
        curl -sS -X "$method" "$API$path" \
            -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' -d "$body"
    else
        curl -sS -X "$method" "$API$path" -H "Authorization: Bearer $TOKEN"
    fi
}

# 1. GitHub integration id (the link Sentry uses to open issues).
echo "── Resolving GitHub integration (org=$SENTRY_ORG) ──"
integrations="$(api GET "/organizations/$SENTRY_ORG/integrations/?provider_key=github")"
INTEGRATION_ID="$(echo "$integrations" | jq -r 'if type=="array" then .[0].id else empty end')"
if [[ -z "$INTEGRATION_ID" || "$INTEGRATION_ID" == "null" ]]; then
    err "no GitHub integration found for org '$SENTRY_ORG' · install it in Sentry first"
    echo "$integrations" | jq -r '.detail? // empty' >&2
    exit 1
fi
ok "integration id = $INTEGRATION_ID"

# 2. Projects (optionally filtered by --only).
projects_json="$(api GET "/organizations/$SENTRY_ORG/projects/")"
mapfile -t SLUGS < <(echo "$projects_json" | jq -r '.[].slug' 2>/dev/null | sort)
[[ "${#SLUGS[@]}" -gt 0 ]] || { err "no projects returned · check token scopes (org:read, project:read)"; exit 1; }

want() {  # true if slug passes the --only filter
    [[ -z "$ONLY" ]] && return 0
    local s="$1" w; IFS=',' read -r -a arr <<< "$ONLY"
    for w in "${arr[@]}"; do [[ "$s" == "${w// /}" ]] && return 0; done
    return 1
}

# Build the rule payload for a project slug.
rule_payload() {
    local slug="$1"
    jq -n \
        --arg cond "$FIRST_SEEN" \
        --arg action "$GITHUB_ACTION_ID" \
        --arg integ "$INTEGRATION_ID" \
        --arg repo "$GH_OWNER/$slug" \
        --arg title "[Sentry] {{ issue.title }}" \
        '{
            name: "Auto: open GitHub issue on new Sentry issue",
            actionMatch: "all",
            filterMatch: "all",
            frequency: 1440,
            conditions: [ { id: $cond } ],
            filters: [],
            actions: [ {
                id: $action,
                integration: $integ,
                repo: $repo,
                title: $title,
                labels: ["sentry","bug"]
            } ]
        }'
}

echo "── Provisioning rules (${#SLUGS[@]} projects, filter='${ONLY:-none}') ──"
created=0; skipped=0; failed=0
for slug in "${SLUGS[@]}"; do
    want "$slug" || continue

    existing="$(api GET "/projects/$SENTRY_ORG/$slug/rules/")"
    has_rule="$(echo "$existing" | jq -r --arg a "$GITHUB_ACTION_ID" \
        '[ .[]? | select(.actions[]?.id == $a) ] | length' 2>/dev/null || echo 0)"

    if ! $FORCE && [[ "${has_rule:-0}" -gt 0 ]]; then
        info "$slug · GitHub-issue rule already present · skip"; ((skipped++)); continue
    fi

    payload="$(rule_payload "$slug")"
    if $DRY_RUN; then
        info "[dry-run] $slug -> POST /projects/$SENTRY_ORG/$slug/rules/"
        echo "$payload" | jq -c .
        ((created++)); continue
    fi

    resp="$(api POST "/projects/$SENTRY_ORG/$slug/rules/" "$payload")"
    if echo "$resp" | jq -e '.id' >/dev/null 2>&1; then
        ok "$slug · rule created (id $(echo "$resp" | jq -r .id))"; ((created++))
    else
        err "$slug · failed: $(echo "$resp" | jq -r '.detail? // tostring' | head -c 200)"; ((failed++))
    fi
done

echo "── Done · created/would-create=$created · skipped=$skipped · failed=$failed ──"
[[ "$failed" -eq 0 ]]
