#!/usr/bin/env bash
# purge-worktrees.sh · Reclaim disk from accumulated .claude/worktrees across the
# fleet. Worktrees pile up to GBs (fleet audit 2026-07-18: 40 repos). Centralizes
# the worktree-hygiene lever.
# Source: chrysa/shared-standards/scripts/purge-worktrees.sh
#
# For each git repo under <root>, this:
#   1. runs `git worktree prune` (drops stale administrative refs), then
#   2. removes leftover checkouts under .claude/worktrees/ by ABSOLUTE path
#      (some are root-owned by container runs → sudo fallback).
#
# SAFETY:
#   - Only ever touches paths under <repo>/.claude/worktrees/. Nothing else.
#   - NEVER runs `docker volume prune` or deletes any docker volume — the fleet's
#     "dangling" volumes are live databases (see memory docker-volumes-hold-fleet-dbs).
#   - A worktree with uncommitted changes is reported and SKIPPED unless --force.
#
# Usage:
#   bash purge-worktrees.sh --dry-run --all <root>    # preview (default)
#   bash purge-worktrees.sh --apply   --all <root>    # remove clean worktrees
#   bash purge-worktrees.sh --apply --force --all <root>  # remove even dirty ones
#
# Exit: 0 ok · 2 root absent
set -uo pipefail

APPLY=0; FORCE=0; ROOT=""
while [ $# -gt 0 ]; do
  case "$1" in
    --apply) APPLY=1 ;;
    --dry-run) APPLY=0 ;;
    --force) FORCE=1 ;;
    --all) : ;;
    -h|--help) grep '^#' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) ROOT="$1" ;;
  esac
  shift
done
[ -d "$ROOT" ] || { echo "root absent: $ROOT" >&2; exit 2; }

total=0
while IFS= read -r gitdir; do
  repo="$(dirname "$gitdir")"
  wt="$repo/.claude/worktrees"
  (cd "$repo" && git worktree prune 2>/dev/null)
  [ -d "$wt" ] || continue
  for d in "$wt"/*/; do
    [ -d "$d" ] || continue
    dirty=""
    (cd "$d" && [ -n "$(git status --porcelain 2>/dev/null)" ]) && dirty=" [DIRTY]"
    sz=$(du -sh "$d" 2>/dev/null | cut -f1)
    if [ -n "$dirty" ] && [ $FORCE -eq 0 ]; then
      echo "  KEEP (dirty, use --force)  $sz  $d"
      continue
    fi
    if [ $APPLY -eq 1 ]; then
      rm -rf "$d" 2>/dev/null || sudo rm -rf "$d" 2>/dev/null
      echo "  removed  $sz  $d$dirty"
    else
      echo "  would remove  $sz  $d$dirty"
    fi
    total=$((total + 1))
  done
done < <(find "$ROOT" -maxdepth 3 -type d -name .git 2>/dev/null | sort)

echo
[ $APPLY -eq 1 ] && echo "Done — $total worktree(s) removed." \
                 || echo "Dry-run — $total worktree(s) would be removed. Re-run with --apply."
exit 0
