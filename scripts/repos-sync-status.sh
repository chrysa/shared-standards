#!/usr/bin/env bash
# repos-sync-status.sh
# Vérifie l'état sync local ↔ remote pour tous les repos chrysa
# Output tabulé + résumé

CHRYSA_ROOT="${CHRYSA_ROOT:-/home/anthony/Documents/perso/projects/chrysa}"

cd "$CHRYSA_ROOT" || exit 1

echo "REPO|BRANCH|AHEAD|BEHIND|DIRTY|REMOTE"
echo "---|---|---|---|---|---"

TOTAL=0
DIRTY=0
BEHIND=0
AHEAD=0
NO_REMOTE=0

for d in */; do
  d="${d%/}"
  [[ "$d" == "_archived" ]] && continue
  [[ -d "$d/.git" ]] || continue

  (
    cd "$d" || exit
    branch=$(git branch --show-current 2>/dev/null || echo "detached")

    # Fetch silencieusement pour comparer à jour
    git fetch --quiet 2>/dev/null

    remote=$(git remote get-url origin 2>/dev/null || echo "NO_REMOTE")
    ahead=$(git rev-list --count "@{u}..HEAD" 2>/dev/null || echo "?")
    behind=$(git rev-list --count "HEAD..@{u}" 2>/dev/null || echo "?")
    dirty=$(git status --porcelain | wc -l)

    # Truncate remote pour lisibilité
    remote_short="${remote##*/}"
    remote_short="${remote_short%.git}"

    echo "$d|$branch|$ahead|$behind|$dirty|$remote_short"
  )

  TOTAL=$((TOTAL + 1))
done | column -t -s '|'

echo ""
echo "=== Actions recommandées ==="
echo "- Si AHEAD > 0  : git push"
echo "- Si BEHIND > 0 : git pull --rebase"
echo "- Si DIRTY > 0  : git status pour voir les modifs non commit"
echo "- Si ? partout  : repo sans remote ou branche upstream manquante"
