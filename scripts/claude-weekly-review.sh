#!/usr/bin/env bash
# claude-weekly-review.sh
# Review hebdo chrysa · à lancer dimanche soir (17h-19h)
#
# Actions :
#   1. Commits cette semaine par repo
#   2. PRs ouvertes vs fermées
#   3. État Socle + Actifs (chrysa-lib, DEV Nexus, FridgeAI)
#   4. Checklist review 5 min
#   5. Questions goals semaine prochaine
#
# Usage : ./claude-weekly-review.sh

set -uo pipefail

CHRYSA_ROOT="${CHRYSA_ROOT:-/home/anthony/Documents/perso/projects/chrysa}"
WEEK_START=$(date -d "last sunday" +%Y-%m-%d 2>/dev/null || date -v-6d +%Y-%m-%d)
WEEK_NUM=$(date +%V)

echo "╔══════════════════════════════════════════════════════════╗"
echo "║ 📅 Review hebdo · Semaine $WEEK_NUM · depuis $WEEK_START "
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

# 1. Commits cette semaine
echo "══ 1. Activité cette semaine ══"
cd "$CHRYSA_ROOT"
TOTAL_COMMITS=0
for d in */; do
    d="${d%/}"
    [[ "$d" == "_archived" ]] && continue
    [[ ! -d "$d/.git" ]] && continue
    commits=$(cd "$d" && git log --since="$WEEK_START" --oneline 2>/dev/null | wc -l)
    if [[ "$commits" -gt 0 ]]; then
        echo "  📝 $d : $commits commits"
        TOTAL_COMMITS=$((TOTAL_COMMITS + commits))
    fi
done
echo "  ───"
echo "  Total : $TOTAL_COMMITS commits"
echo ""

# 2. Focus Socle + Actifs
echo "══ 2. Socle + Actifs · état de santé ══"
for proj in chrysa-lib dev-nexus my-fridge doc-gen; do
    if [[ -d "$proj/.git" ]]; then
        last=$(cd "$proj" && git log -1 --format="%cr" 2>/dev/null)
        ahead=$(cd "$proj" && git fetch --quiet 2>/dev/null && git rev-list --count "@{u}..HEAD" 2>/dev/null || echo "?")
        printf "  %-20s last: %-20s ahead: %s\n" "$proj" "$last" "$ahead"
    fi
done
echo ""

# 3. PRs / issues (nécessite gh auth)
echo "══ 3. PRs ouvertes (via gh CLI) ══"
if command -v gh &>/dev/null && gh auth status &>/dev/null; then
    gh search prs --author=@me --state=open --limit 20 --json title,repository,createdAt --template '{{range .}}  🔍 {{.repository.nameWithOwner}} · {{.title}}{{"\n"}}{{end}}' 2>/dev/null || echo "  (gh search failed)"
else
    echo "  ⚠️  gh CLI non authentifié · gh auth login pour activer"
fi
echo ""

# 4. Checklist review 5 min
echo "══ 4. Checklist review 5 min ══"
cat <<CHECK
  Pour chaque point, noter rapidement :

  ✅ Ce qui a marché cette semaine (max 3)
    -
    -
    -

  ❌ Ce qui n'a pas marché (max 3)
    -
    -
    -

  🎯 3 objectifs semaine prochaine
    -
    -
    -

  🧹 Nettoyage backlog (archive tâches > 21j sans mouvement)

  📈 Mise à jour progression 6 écosystèmes (0-100)
    Personnel : __
    Maison    : __
    Padam AV  : __
    Chrysa Dev: __
    Management: __
    Système   : __
CHECK
echo ""

# 5. Alertes
echo "══ 5. Alertes semaine ══"
# Check chrysa-lib still inactive
CHRYSA_LIB_LAST=$(cd "$CHRYSA_ROOT/chrysa-lib" 2>/dev/null && git log -1 --format="%ct" 2>/dev/null || echo 0)
NOW=$(date +%s)
if [[ "$CHRYSA_LIB_LAST" -gt 0 ]]; then
    DAYS_SINCE=$(( (NOW - CHRYSA_LIB_LAST) / 86400 ))
    if [[ "$DAYS_SINCE" -gt 3 ]]; then
        echo "  🔴 chrysa-lib : $DAYS_SINCE jours sans commit · Sprint 0 non démarré ?"
    else
        echo "  ✅ chrysa-lib : actif ($DAYS_SINCE jours)"
    fi
fi

# Check doc-gen PR #1 status (if gh auth)
if command -v gh &>/dev/null && gh auth status &>/dev/null; then
    PR_STATUS=$(gh pr view 1 --repo chrysa/doc-gen --json state -q .state 2>/dev/null || echo "?")
    echo "  📌 doc-gen PR #1 : $PR_STATUS"
fi

echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║ Review finalisée · ouvrir Notion pour compléter review   ║"
echo "╚══════════════════════════════════════════════════════════╝"
