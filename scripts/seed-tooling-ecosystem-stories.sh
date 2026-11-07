#!/usr/bin/env bash
# seed-tooling-ecosystem-stories.sh · Create the tooling-ecosystem rollout stories in Shortcut.
# Source: chrysa/shared-standards/scripts/seed-tooling-ecosystem-stories.sh
#
# Standard (standards/annexes/TOOLING-ECOSYSTEM.md, "Rollout order"):
#   One truth per tool, native integrations before custom glue, `sc-<id>` as the single
#   cross-tool thread. This script seeds the P0->P2 rollout stories once, idempotently.
#
# Shortcut is reached through the chrysa-portfolio-viz gateway (ADR-PVIZ-063), never
# directly: no Shortcut token here. The gateway's story creation is idempotent (an open
# story with the same name and labels is returned, not duplicated).
#
# Usage:
#   PORTFOLIO_VIZ_URL=... PORTFOLIO_VIZ_TOKEN=... [STATE="Backlog"] ./seed-tooling-ecosystem-stories.sh [--dry-run]
#
# PORTFOLIO_VIZ_TOKEN is a service token granted the shortcut.story.create scope (or an
# admin session). Both values come from the environment only.
set -euo pipefail

DRY_RUN="${1:-}"
LABEL="tooling-ecosystem"

: "${PORTFOLIO_VIZ_URL:?set PORTFOLIO_VIZ_URL in the environment}"
: "${PORTFOLIO_VIZ_TOKEN:?set PORTFOLIO_VIZ_TOKEN in the environment}"
GATEWAY="${PORTFOLIO_VIZ_URL%/}/api/gateway/shortcut"

create_story() { # json-body
  curl -sf -X POST "$GATEWAY/stories" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $PORTFOLIO_VIZ_TOKEN" \
    -d "$1"
}

# name|type|description  — one story per line, keyed by name for idempotency.
STORIES='P0 · GitHub<->Shortcut state event handlers|feature|Add event handlers in Shortcut (Settings -> Integrations -> GitHub): PR opened -> In Review, PR merged -> Done. Ref TE-030.
P0 · Sentry->GitHub issue alert rule|feature|Per-project Sentry issue alert: FirstSeen -> Create GitHub issue (labels sentry, bug). One-to-one, no relay. Ref OBSERVABILITY norm + TE-010.
P0 · Slack apps + channel roles|chore|Shortcut + GitHub Slack apps connected; one role per channel; -alerts = red only (CI down, incidents, P0/P1). Ref TE-001, TE-040.
P0 · sc-<id> convention enforced|chore|Branch feature/sc-<id>-slug, commit/PR Conventional + Fixes sc-<id>. Ref TE-020.
P1 · Sentry<->Shortcut native link|feature|Enable Sentry Shortcut integration (Team plan). If greyed out: webhook fallback. Ref TE-010.
P1 · Notion<->Shortcut linking|chore|Epic <-> Notion idea page native link on the four canonical journeys. Ref TE-030.
P2 · Objective->Notion state sync|feature|Custom webhook syncing Shortcut Objective progress to the Notion governance view (Objective granularity, not per story). Ref TE-000, TE-010.'

while IFS='|' read -r name type desc; do
  [ -z "$name" ] && continue
  body="$(python3 -c 'import json,sys;n,t,d,l,s=sys.argv[1:6];p={"name":n,"type":t,"description":d,"labels":[l]};s and p.update(state=s);print(json.dumps(p))' \
    "$name" "$type" "$desc" "$LABEL" "${STATE:-}")"
  if [ "$DRY_RUN" = "--dry-run" ]; then
    echo "DRY: would create [$type] $name"
  else
    create_story "$body" | python3 -c 'import sys,json;r=json.load(sys.stdin);print(("created" if r["created"] else "skip (exists)"), "sc-%s" % r["story"]["id"], "·", r["story"]["name"])'
  fi
done <<< "$STORIES"
