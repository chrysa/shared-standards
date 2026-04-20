#!/usr/bin/env bash
# generate-docs-index.sh
# Produit un index Markdown de toutes les docs (*.md) par repo
# Output : shared-standards/docs/DOCS-INDEX.md

set -uo pipefail

CHRYSA_ROOT="${CHRYSA_ROOT:-/home/anthony/Documents/perso/projects/chrysa}"
OUTPUT="$CHRYSA_ROOT/shared-standards/docs/DOCS-INDEX.md"

cd "$CHRYSA_ROOT" || exit 1

{
    echo "# DOCS INDEX — chrysa"
    echo ""
    echo "> Généré $(date +%Y-%m-%d\ %H:%M). Scan de tous les .md dans chaque repo actif."
    echo ""
    echo "---"
    echo ""

    total=0
    for d in */; do
        d="${d%/}"
        [[ "$d" == "_archived" ]] && continue
        [[ ! -d "$d/.git" ]] && continue

        # Cherche les fichiers .md de premier niveau + docs/
        mapfile -t docs < <(find "$d" -maxdepth 2 -name "*.md" -not -path "*/node_modules/*" -not -path "*/.venv/*" 2>/dev/null | sort)

        if [[ ${#docs[@]} -gt 0 ]]; then
            echo "## $d (${#docs[@]} docs)"
            echo ""
            for doc in "${docs[@]}"; do
                rel="${doc#$d/}"
                # Extrait la 1re ligne de titre
                title=$(grep -m1 "^# " "$doc" 2>/dev/null | sed 's/^# //' | head -c 80)
                [[ -z "$title" ]] && title="(sans titre)"
                echo "- \`$rel\` — $title"
                total=$((total + 1))
            done
            echo ""
        fi
    done

    echo ""
    echo "---"
    echo ""
    echo "**Total** : $total fichiers .md indexés"
    echo ""
    echo "## Structure recommandée (à tendre pour chaque repo)"
    echo ""
    echo "\`\`\`"
    echo "<repo>/"
    echo "├── README.md          # Quickstart + rôle + stack"
    echo "├── CLAUDE.md          # Instructions Claude scope repo"
    echo "├── DECISIONS.md       # D-XXXX local à ce repo"
    echo "├── ROADMAP.md         # Now / Next / Later"
    echo "├── CHANGELOG.md       # Keep a Changelog"
    echo "└── docs/"
    echo "    ├── ARCHITECTURE.md"
    echo "    ├── API.md         # si service"
    echo "    ├── OPERATIONS.md  # runbook"
    echo "    └── CONTRIBUTING.md"
    echo "\`\`\`"
} > "$OUTPUT"

echo "✅ Index généré : $OUTPUT"
echo "   Total : $(grep -c '^- ' "$OUTPUT") docs indexées"
