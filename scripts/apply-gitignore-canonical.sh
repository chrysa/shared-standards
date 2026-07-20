#!/usr/bin/env bash
# apply-gitignore-canonical.sh · Append (idempotently) the managed canonical
# .gitignore block into every git repo under a root. Repo-specific ignores are
# preserved ABOVE the managed block; the block itself is replaced in place when
# it already exists, so re-running always converges to the current template.
# Source: chrysa/shared-standards/scripts/apply-gitignore-canonical.sh
#
# Usage:
#   bash apply-gitignore-canonical.sh --dry-run <root>   # preview (default)
#   bash apply-gitignore-canonical.sh --apply   <root>
# Exit: 0 ok · 1 error · 2 template/root absent
set -uo pipefail

APPLY=0; ROOT=""
while [ $# -gt 0 ]; do
  case "$1" in
    --apply) APPLY=1 ;;
    --dry-run) APPLY=0 ;;
    -h|--help) grep '^#' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) ROOT="$1" ;;
  esac
  shift
done

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TEMPLATE="$SCRIPT_DIR/../templates/gitignore.canonical"
[ -f "$TEMPLATE" ] || { echo "template absent: $TEMPLATE" >&2; exit 2; }
[ -n "$ROOT" ] && [ -d "$ROOT" ] || { echo "root absent: $ROOT" >&2; exit 2; }

BEGIN='# ---8<--- chrysa:canonical:begin'
END='--->8---'

changed=0; created=0; scanned=0
while IFS= read -r gitdir; do
  repo="$(dirname "$gitdir")"
  gi="$repo/.gitignore"
  scanned=$((scanned+1))
  if [ ! -f "$gi" ]; then
    echo "  create  $gi"
    [ $APPLY -eq 1 ] && cat "$TEMPLATE" > "$gi"
    created=$((created+1)); continue
  fi
  if grep -qF "$BEGIN" "$gi"; then
    # strip existing managed block, then re-append fresh
    if [ $APPLY -eq 1 ]; then
      awk -v b="$BEGIN" -v e="$END" '
        index($0,b){skip=1}
        skip && index($0,e){skip=0; next}
        !skip{print}
      ' "$gi" > "$gi.tmp"
      # drop trailing blank lines then append
      sed -e :a -e '/^[[:space:]]*$/{$d;N;ba}' "$gi.tmp" > "$gi"
      rm -f "$gi.tmp"
      printf '\n' >> "$gi"; cat "$TEMPLATE" >> "$gi"
    fi
    echo "  refresh $gi"
  else
    echo "  append  $gi"
    if [ $APPLY -eq 1 ]; then printf '\n' >> "$gi"; cat "$TEMPLATE" >> "$gi"; fi
  fi
  changed=$((changed+1))
done < <(find "$ROOT" -type d -name .git -prune 2>/dev/null | sed 's#/\.git$##;s#$#/.git#')

echo "scanned=$scanned created=$created updated=$changed apply=$APPLY"
[ $APPLY -eq 1 ] || echo "(dry-run — re-run with --apply to write)"
