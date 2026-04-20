#!/usr/bin/env bash
# generate-roadmap-rollup.sh
# Agrège tous les ROADMAP.md et DECISIONS.md des repos chrysa en un document unique
# Output : shared-standards/docs/ROADMAP-ROLLUP.md (à committer manuellement)

set -uo pipefail

CHRYSA_ROOT="${CHRYSA_ROOT:-/home/anthony/Documents/perso/projects/chrysa}"
OUTPUT="$CHRYSA_ROOT/shared-standards/docs/ROADMAP-ROLLUP.md"

cd "$CHRYSA_ROOT" || exit 1

{
    echo "# ROADMAP ROLLUP — chrysa"
    echo ""
    echo "> Généré $(date +%Y-%m-%d\ %H:%M) par generate-roadmap-rollup.sh"
    echo "> Aggrégation des ROADMAP.md + DECISIONS.md des repos actifs"
    echo ""
    echo "---"
    echo ""
    echo "## Sommaire"
    echo ""

    for d in */; do
        d="${d%/}"
        [[ "$d" == "_archived" ]] && continue
        [[ ! -d "$d/.git" ]] && continue
        has_content=false
        [[ -f "$d/ROADMAP.md" ]] && has_content=true
        [[ -f "$d/DECISIONS.md" ]] && has_content=true
        $has_content && echo "- [$d](#$d)"
    done

    echo ""
    echo "---"
    echo ""

    for d in */; do
        d="${d%/}"
        [[ "$d" == "_archived" ]] && continue
        [[ ! -d "$d/.git" ]] && continue

        roadmap_f="$d/ROADMAP.md"
        decisions_f="$d/DECISIONS.md"

        if [[ -f "$roadmap_f" || -f "$decisions_f" ]]; then
            echo "## $d"
            echo ""
            last_commit=$(cd "$d" && git log -1 --format="%cr" 2>/dev/null || echo "never")
            branch=$(cd "$d" && git branch --show-current 2>/dev/null || echo "-")
            echo "*Dernière activité : $last_commit · branche : $branch*"
            echo ""

            if [[ -f "$roadmap_f" ]]; then
                echo "### Roadmap"
                echo ""
                # Ignore le titre principal + insère
                tail -n +2 "$roadmap_f" | head -60
                echo ""
            fi

            if [[ -f "$decisions_f" ]]; then
                echo "### Décisions (extrait)"
                echo ""
                # Extraire uniquement les entêtes D-XXXX et date/état
                grep -E "^## D-[0-9]+ — |^\*\*Date\*\*|^\*\*État\*\*" "$decisions_f" | head -30
                echo ""
            fi

            echo "---"
            echo ""
        fi
    done

    echo ""
    echo "## Règle 1+2 — statut actuel"
    echo ""
    echo "Max 1 Socle actif + 2 Actifs simultanés."
    echo ""
    echo "Voir portfolio-metadata.yml pour le rôle officiel de chaque projet."

} > "$OUTPUT"

echo "✅ Rollup généré : $OUTPUT"
echo "   Taille : $(wc -l < "$OUTPUT") lignes"
