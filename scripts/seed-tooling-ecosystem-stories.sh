#!/usr/bin/env bash
# seed-tooling-ecosystem-stories.sh · Create the tooling-ecosystem rollout stories in Shortcut.
# Source: chrysa/shared-standards/scripts/seed-tooling-ecosystem-stories.sh
#
# Standard (standards/annexes/TOOLING-ECOSYSTEM.md, "Rollout order"):
#   One truth per tool, native integrations before custom glue, `sc-<id>` as the single
#   cross-tool thread. This script seeds the P0->P2 rollout stories once, idempotently.
#
# Usage:
#   SHORTCUT_API_TOKEN=... [WORKFLOW_STATE_ID=...] ./seed-tooling-ecosystem-stories.sh [--dry-run]
#
# The token is read from the environment only (never hardcoded — see STANDARDS: "every
# external server addressed through the environment"). Get one at:
#   Shortcut -> Settings -> API Tokens.
set -euo pipefail

API="https://api.app.shortcut.com/api/v3"
DRY_RUN="${1:-}"
LABEL="tooling-ecosystem"

: "${SHORTCUT_API_TOKEN:?set SHORTCUT_API_TOKEN in the environment}"

api() { # method path [json-body]
  curl -sf -X "$1" "$API$2" \
    -H "Content-Type: application/json" \
    -H "Shortcut-Token: $SHORTCUT_API_TOKEN" \
    ${3:+-d "$3"}
}

# Resolve a default workflow state id if not provided (first state of first workflow).
if [ -z "${WORKFLOW_STATE_ID:-}" ]; then
  WORKFLOW_STATE_ID="$(api GET /workflows | python3 -c \
    'import sys,json;w=json.load(sys.stdin);print(w[0]["states"][0]["id"])')"
fi

# name|type|description  — one story per line, keyed by name for idempotency.
STORIES='P0 · GitHub<->Shortcut state event handlers|feature|Add event handlers in Shortcut (Settings -> Integrations -> GitHub): PR opened -> In Review, PR merged -> Done. Ref TE-030.
P0 · Sentry->GitHub issue alert rule|feature|Per-project Sentry issue alert: FirstSeen -> Create GitHub issue (labels sentry, bug). One-to-one, no relay. Ref OBSERVABILITY norm + TE-010.
P0 · Slack apps + channel roles|chore|Shortcut + GitHub Slack apps connected; one role per channel; -alerts = red only (CI down, incidents, P0/P1). Ref TE-001, TE-040.
P0 · sc-<id> convention enforced|chore|Branch feature/sc-<id>-slug, commit/PR Conventional + Fixes sc-<id>. Ref TE-020.
P1 · Sentry<->Shortcut native link|feature|Enable Sentry Shortcut integration (Team plan). If greyed out: webhook fallback. Ref TE-010.
P1 · Notion<->Shortcut linking|chore|Epic <-> Notion idea page native link on the four canonical journeys. Ref TE-030.
P2 · Objective->Notion state sync|feature|Custom webhook syncing Shortcut Objective progress to the Notion governance view (Objective granularity, not per story). Ref TE-000, TE-010.'

echo "workflow_state_id=$WORKFLOW_STATE_ID"
existing="$(api GET "/search/stories?query=label:$LABEL" 2>/dev/null || echo '{}')"

while IFS='|' read -r name type desc; do
  [ -z "$name" ] && continue
  if printf '%s' "$existing" | grep -Fq "$name"; then
    echo "skip (exists): $name"; continue
  fi
  body="$(python3 -c 'import json,sys;n,t,d,s=sys.argv[1:5];print(json.dumps({"name":n,"story_type":t,"description":d,"labels":[{"name":"tooling-ecosystem"}],"workflow_state_id":int(s)}))' \
    "$name" "$type" "$desc" "$WORKFLOW_STATE_ID")"
  if [ "$DRY_RUN" = "--dry-run" ]; then
    echo "DRY: would create [$type] $name"
  else
    id="$(api POST /stories "$body" | python3 -c 'import sys,json;print(json.load(sys.stdin)["id"])')"
    echo "created sc-$id · $name"
  fi
done <<< "$STORIES"
