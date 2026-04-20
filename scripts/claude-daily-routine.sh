#!/usr/bin/env bash
# claude-daily-routine.sh
# Routine quotidienne Claude Code solo dev chrysa
# À lancer chaque matin (08h-10h)
#
# Actions :
#   1. Pull tous les repos (repos-pull-all.sh)
#   2. Status portfolio (git status)
#   3. Rappel priorités du jour (chrysa-lib Sprint 0, PR #1 doc-gen)
#   4. Check scheduled tasks running
#   5. Log dans journal quotidien
#
# Usage : ./claude-daily-routine.sh

set -uo pipefail

CHRYSA_ROOT="${CHRYSA_ROOT:-/home/anthony/Documents/perso/projects/chrysa}"
JOURNAL="$HOME/.chrysa/journal/$(date +%Y-%m-%d).md"
SCRIPTS_DIR="$CHRYSA_ROOT/shared-standards/scripts"

mkdir -p "$(dirname "$JOURNAL")"

echo "╔══════════════════════════════════════════════════════════╗"
echo "║ 🌅 Routine quotidienne chrysa · $(date +%A\ %d\ %B\ %Y)"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

# 1. Pull all repos
echo "══ 1. Synchronisation repos ══"
if [[ -x "$SCRIPTS_DIR/repos-pull-all.sh" ]]; then
    "$SCRIPTS_DIR/repos-pull-all.sh" | tail -20
else
    echo "⚠️  repos-pull-all.sh absent"
fi
echo ""

# 2. Status portfolio
echo "══ 2. Repos dirty (non committés) ══"
DIRTY_COUNT=0
cd "$CHRYSA_ROOT"
for d in */; do
    d="${d%/}"
    [[ "$d" == "_archived" ]] && continue
    [[ ! -d "$d/.git" ]] && continue
    changes=$(cd "$d" && git status --porcelain | wc -l)
    if [[ "$changes" -gt 0 ]]; then
        echo "  🟠 $d : $changes fichiers modifiés"
        DIRTY_COUNT=$((DIRTY_COUNT + 1))
    fi
done
[[ "$DIRTY_COUNT" -eq 0 ]] && echo "  ✅ Tous repos clean"
echo ""

# 3. Priorités du jour (rappel hardcodé, à adapter selon avancement)
echo "══ 3. Priorités du jour ══"
cat <<PRIO
  🔴 P0 · chrysa-lib Sprint 0 (bloque 8 projets aval)
  🔴 P0 · doc-gen PR #1 (python-jose → joserfc) — bloque doc-gen Actif
  🟠 P1 · FridgeAI V1 (en attente chrysa-lib)
  🟠 P1 · DEV Nexus V1.x (Guardrails AI + GuardRails.io)
  🟡 P2 · Travaux structurants (énergie solaire H2)

Rappel règle 1+2 · max 1 Socle actif + 2 Actifs simultanés
PRIO
echo ""

# 4. Scheduled tasks status (si on a un moyen de les lister)
echo "══ 4. Scheduled tasks (rappel) ══"
cat <<TASKS
  ⏰ daily-briefing          · 09h05 · MCP GCal+Notion+Gmail
  ⏰ ci-sweep                · 08h30 · MCP GitHub
  ⏰ pr-aging                · 09h00 · MCP GitHub+Notion
  ⏰ habits-check            · quotidien · Notion
  ⏰ daily-wrap-up           · 22h00 · Notion (inclut XP engine)
  ⏰ monthly-travel-expenses · 20-25 du mois · MCP GCal+Gmail+Drive
  ⏰ notion-comments-processor · toutes les 2h · MCP Notion
TASKS
echo ""

# 5. Journal du jour
echo "══ 5. Journal du jour ══"
if [[ ! -f "$JOURNAL" ]]; then
    cat > "$JOURNAL" <<JRN
# Journal $(date +%Y-%m-%d)

## Priorités du jour
- [ ]
- [ ]
- [ ]

## Rencontres / décisions

## Blocages

## Résolu aujourd'hui

## Demain
JRN
    echo "  ✅ Journal créé : $JOURNAL"
else
    echo "  ✓ Journal existe : $JOURNAL"
fi
echo ""

# 6. Sentinelles critiques
echo "══ 6. Sentinelles critiques ══"
# Espace disque
DISK_FREE=$(df -h / | awk 'NR==2 {print $4}')
echo "  💾 Disque libre : $DISK_FREE"
# Swap usage
SWAP_USED=$(free -h | awk '/Échange|Swap/ {print $3"/"$2}')
echo "  🔄 Swap         : $SWAP_USED"
# RAM disponible
RAM_AVAIL=$(free -h | awk '/Mem/ {print $7}')
echo "  🧠 RAM dispo    : $RAM_AVAIL"

echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║ Routine terminée · bonne journée !                       ║"
echo "╚══════════════════════════════════════════════════════════╝"
