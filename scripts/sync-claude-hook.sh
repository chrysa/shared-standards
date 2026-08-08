#!/usr/bin/env bash
# sync-claude-hook.sh — install/refresh ONE transverse Claude hook into a target repo.
#
# distribute-standards.sh fans out the CLAUDE.md block + skills + agents + workflows, but
# NOT `.claude/hooks/`. This script fills that gap for a single hook, idempotently: it copies
# the hook file from shared-standards and wires it into the repo's settings.json under the
# right lifecycle event, without disturbing the repo's other hooks or settings.
#
# Scope kept to one hook on purpose — a blocking commit hook is fanned out canary-first, not
# in a fleet-wide sweep. Once validated it can be called per-repo by the distribute Action.
#
# Usage:
#   sync-claude-hook.sh <repo_path> [--hook NAME] [--event EVENT] [--matcher M] [--dry-run]
#
#   defaults: --hook check-no-env-files  --event PreToolUse  --matcher Bash
#
# Exit: 0 ok / no change · 1 error · 2 repo or hook source missing
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STD_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
HOOKS_SRC="$STD_ROOT/.claude/hooks"

REPO=""
HOOK="check-no-env-files"
EVENT="PreToolUse"
MATCHER="Bash"
DRY=0

die() { printf '\033[31merror:\033[0m %s\n' "$*" >&2; exit "${2:-1}"; }
info() { printf '\033[36m•\033[0m %s\n' "$*"; }
ok() { printf '\033[32m✓\033[0m %s\n' "$*"; }

while [ $# -gt 0 ]; do
  case "$1" in
    --hook) shift; HOOK="${1:?}" ;;
    --event) shift; EVENT="${1:?}" ;;
    --matcher) shift; MATCHER="${1:?}" ;;
    --dry-run) DRY=1 ;;
    -h|--help) sed -n '2,16p' "$0" | sed 's/^# \?//'; exit 0 ;;
    -*) die "unknown flag: $1" 2 ;;
    *) REPO="$1" ;;
  esac
  shift
done

[ -n "$REPO" ] || die "missing <repo_path>" 2
[ -d "$REPO/.git" ] || die "not a git repo: $REPO" 2
command -v jq >/dev/null || die "jq required" 1

SRC="$HOOKS_SRC/$HOOK.cjs"
[ -f "$SRC" ] || die "hook source not found: $SRC" 2

SETTINGS="$REPO/.claude/settings.json"
[ -f "$SETTINGS" ] || die "no settings.json in $REPO/.claude (bootstrap the repo first)" 2

DEST="$REPO/.claude/hooks/$HOOK.cjs"
CMD="sh -c 'f=\"\$CLAUDE_PROJECT_DIR/.claude/hooks/$HOOK.cjs\"; [ ! -f \"\$f\" ] || node \"\$f\"'"

info "repo=$REPO  hook=$HOOK  event=$EVENT  matcher=$MATCHER  dry-run=$DRY"

# 1) hook file — copy if absent or changed.
file_action="up-to-date"
if [ ! -f "$DEST" ] || ! cmp -s "$SRC" "$DEST"; then
  file_action="copy"
fi

# 2) settings.json — is the hook already wired under EVENT/MATCHER?
already_wired=$(jq --arg e "$EVENT" --arg m "$MATCHER" --arg n "$HOOK" '
  [.hooks[$e][]? | select(.matcher==$m) | .hooks[]? | select(.name==$n)] | length > 0
' "$SETTINGS")

settings_action="present"
[ "$already_wired" = "true" ] || settings_action="add-entry"

# Guard: the target event/matcher block must exist to append into.
block_exists=$(jq --arg e "$EVENT" --arg m "$MATCHER" '
  [.hooks[$e][]? | select(.matcher==$m)] | length > 0
' "$SETTINGS")
if [ "$settings_action" = "add-entry" ] && [ "$block_exists" != "true" ]; then
  die "no $EVENT block with matcher=$MATCHER in $SETTINGS — repo settings shape differs, wire manually" 1
fi

info "plan: hook-file=$file_action  settings=$settings_action"

if [ "$DRY" -eq 1 ]; then
  ok "dry-run — nothing written"
  exit 0
fi

# Apply file.
if [ "$file_action" = "copy" ]; then
  mkdir -p "$REPO/.claude/hooks"
  cp "$SRC" "$DEST"
  ok "hook file synced: $DEST"
fi

# Apply settings (idempotent append into the matching block).
if [ "$settings_action" = "add-entry" ]; then
  tmp="$(mktemp)"
  jq --arg e "$EVENT" --arg m "$MATCHER" --arg n "$HOOK" --arg cmd "$CMD" '
    .hooks[$e] |= (map(
      if .matcher==$m
      then .hooks += [{command:$cmd, name:$n, timeout:5000, type:"command"}]
      else . end
    ))
  ' "$SETTINGS" > "$tmp" && mv "$tmp" "$SETTINGS"
  ok "settings.json wired: $EVENT/$MATCHER += $HOOK"
fi

ok "done: $REPO"
