#!/usr/bin/env bash
# audit-github-issues.sh
# Audit des issues ouvertes sur tous les repos chrysa
# Règle : ne pas en créer de nouvelles, fermer les obsolètes, prioriser le reste.
#
# Output :
#   - stdout : tableau résumé par repo
#   - shared-standards/docs/issues-audit-{date}.md : rapport détaillé
#
# Usage :
#   bash audit-github-issues.sh              # audit + rapport
#   bash audit-github-issues.sh --close-old  # ferme issues > 180j sans activité
#   bash audit-github-issues.sh --dry-run    # preview fermetures

set -uo pipefail

CHRYSA_ROOT="${CHRYSA_ROOT:-/home/anthony/Documents/perso/projects/chrysa}"
TODAY=$(date +%Y-%m-%d)
OUT="$CHRYSA_ROOT/shared-standards/docs/issues-audit-${TODAY}.md"

CLOSE_OLD=false
DRY_RUN=false
for arg in "$@"; do
    case "$arg" in
        --close-old) CLOSE_OLD=true ;;
        --dry-run)   DRY_RUN=true ;;
    esac
done

if ! command -v gh &>/dev/null; then
    echo "❌ gh CLI absent"
    exit 1
fi
if ! gh auth status &>/dev/null; then
    echo "❌ gh non authentifié · gh auth login"
    exit 1
fi

cd "$CHRYSA_ROOT" || exit 1

TOTAL_OPEN=0
TOTAL_STALE=0
declare -A PER_REPO_OPEN
declare -A PER_REPO_STALE

{
    echo "# Issues audit — ${TODAY}"
    echo ""
    echo "> Généré par audit-github-issues.sh"
    echo ""
    echo "## Par repo (issues ouvertes, triées par nombre)"
    echo ""
    echo "| Repo | Ouvertes | Stale (>180j) | Labels top-3 |"
    echo "|------|----------|---------------|--------------|"
} > "$OUT"

for d in */; do
    d="${d%/}"
    [[ "$d" == "_archived" ]] && continue
    [[ ! -d "$d/.git" ]] && continue

    # Skip repos archive-targets
    case "$d" in
        42_save|DJango-CustomeCommands|linkendin-resume|my-resume) continue ;;
    esac

    # Issues ouvertes
    open_count=$(gh issue list --repo "chrysa/$d" --state open --limit 1000 --json number 2>/dev/null | python3 -c "import sys,json; print(len(json.load(sys.stdin)))" 2>/dev/null || echo "?")
    [[ "$open_count" == "?" ]] && continue
    [[ "$open_count" == "0" ]] && continue

    # Issues stale > 180j
    stale_count=$(gh issue list --repo "chrysa/$d" --state open --limit 1000 --json updatedAt 2>/dev/null | python3 -c "
import sys,json,datetime
data = json.load(sys.stdin)
cutoff = (datetime.datetime.now(datetime.timezone.utc) - datetime.timedelta(days=180))
stale = sum(1 for i in data if datetime.datetime.fromisoformat(i['updatedAt'].replace('Z','+00:00')) < cutoff)
print(stale)
" 2>/dev/null || echo "0")

    # Top 3 labels
    labels_top=$(gh issue list --repo "chrysa/$d" --state open --limit 100 --json labels 2>/dev/null | python3 -c "
import sys,json
from collections import Counter
data = json.load(sys.stdin)
c = Counter()
for i in data:
    for l in i.get('labels', []):
        c[l['name']] += 1
print(' · '.join(f'{n}({k})' for n,k in c.most_common(3)))
" 2>/dev/null || echo "-")

    TOTAL_OPEN=$((TOTAL_OPEN + open_count))
    TOTAL_STALE=$((TOTAL_STALE + stale_count))
    PER_REPO_OPEN[$d]=$open_count
    PER_REPO_STALE[$d]=$stale_count

    echo "| $d | $open_count | $stale_count | $labels_top |" >> "$OUT"

    echo "$d : $open_count ouvertes · $stale_count stale · $labels_top"

    # Close old si demandé
    if $CLOSE_OLD && [[ "$stale_count" -gt 0 ]]; then
        gh issue list --repo "chrysa/$d" --state open --limit 1000 --json number,updatedAt 2>/dev/null | python3 -c "
import sys,json,datetime
data = json.load(sys.stdin)
cutoff = (datetime.datetime.now(datetime.timezone.utc) - datetime.timedelta(days=180))
for i in data:
    if datetime.datetime.fromisoformat(i['updatedAt'].replace('Z','+00:00')) < cutoff:
        print(i['number'])
" | while read n; do
            if $DRY_RUN; then
                echo "  [DRY-RUN] gh issue close --repo chrysa/$d $n --comment 'Closed as stale (>180d, auto-audit)'"
            else
                gh issue close --repo "chrysa/$d" "$n" --comment "Closed as stale (>180d sans activité, audit automatique ${TODAY}). Re-open if still relevant." 2>&1 | tail -1
            fi
        done
    fi
done

{
    echo ""
    echo "## Totaux"
    echo ""
    echo "- **Total issues ouvertes** : $TOTAL_OPEN"
    echo "- **Total stale (>180j)** : $TOTAL_STALE"
    echo ""
    echo "## Recommandations"
    echo ""
    echo "1. **Ne pas créer de nouvelles issues** sauf pour cross-project deps (cf. cross-project-issues.sh)"
    echo "2. **Fermer les stale** : \`bash audit-github-issues.sh --close-old\` (avec \`--dry-run\` pour preview)"
    echo "3. **Dédupliquer** : rechercher titres similaires sur les repos avec >10 issues"
    echo "4. **Prioriser P0/P1** : ajouter labels \`priority/p0\` \`priority/p1\` pour les issues actionnables"
    echo ""
    echo "## Workflow de ménage mensuel"
    echo ""
    echo "- Jour 1 du mois : audit (ce script)"
    echo "- Jour 2 : fermer stale (\`--close-old\` après validation dry-run)"
    echo "- Jour 3 : dédupliquer + prioriser manuellement les top-3 repos avec plus d'issues"
    echo "- Fin du mois : revue portfolio-metadata.yml pour ajuster bloqueurs"
} >> "$OUT"

echo ""
echo "✅ Rapport : $OUT"
echo "Total ouvertes : $TOTAL_OPEN · stale : $TOTAL_STALE"
