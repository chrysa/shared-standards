#!/usr/bin/env bash
# generate-deps-graph.sh
# Construit un graphe Mermaid des dépendances entre repos chrysa
# Lit portfolio-metadata.yml + scanne les repos pour détecter imports chrysa-lib, etc.
# Output : shared-standards/docs/diagrams/dependencies-{date}.mmd + .svg si mmdc dispo

set -uo pipefail

CHRYSA_ROOT="${CHRYSA_ROOT:-/home/anthony/Documents/perso/projects/chrysa}"
TODAY=$(date +%Y-%m-%d)
OUT_MMD="$CHRYSA_ROOT/shared-standards/docs/diagrams/dependencies-${TODAY}.mmd"
mkdir -p "$(dirname "$OUT_MMD")"

cd "$CHRYSA_ROOT" || exit 1

# ─── Détection dépendances simples par grep ────────────────
# Cherche imports ou mentions de chrysa-lib, shared-standards dans chaque repo
declare -A DEPS

for d in */; do
    d="${d%/}"
    [[ "$d" == "_archived" ]] && continue
    [[ ! -d "$d/.git" ]] && continue

    deps=""
    # chrysa-lib
    if grep -rqE "(@chrysa/auth|@chrysa/config|chrysa_lib|chrysa-lib)" "$d" \
        --include="*.py" --include="*.ts" --include="*.tsx" --include="*.js" \
        --include="package.json" --include="pyproject.toml" --include="requirements*.txt" 2>/dev/null; then
        deps="$deps chrysa-lib"
    fi
    # shared-standards (submodule ou usage direct)
    if [[ -f "$d/.gitmodules" ]] && grep -q "shared-standards" "$d/.gitmodules" 2>/dev/null; then
        deps="$deps shared-standards"
    fi
    # ai-aggregator (prompt-optimizer)
    if grep -rqE "prompt_optimizer|ai_aggregator" "$d" \
        --include="*.py" --include="*.ts" 2>/dev/null; then
        deps="$deps ai-aggregator"
    fi
    # lifeos
    if grep -rqE "lifeos|PlanningAgent|MealsAgent" "$d" \
        --include="*.py" --include="*.ts" 2>/dev/null; then
        deps="$deps lifeos"
    fi
    DEPS[$d]="$deps"
done

# ─── Construction Mermaid ──────────────────────────────────
{
    echo "%%{init: {'theme':'dark', 'flowchart':{'curve':'basis'}}}%%"
    echo "graph LR"
    echo ""
    echo "%% Styles par rôle (infos portfolio-metadata.yml)"
    echo "classDef socle fill:#ef4444,stroke:#fff,color:#fff"
    echo "classDef actif fill:#10b981,stroke:#fff,color:#fff"
    echo "classDef opp fill:#3b82f6,stroke:#fff,color:#fff"
    echo "classDef gele fill:#6b7280,stroke:#fff,color:#fff"
    echo ""

    # Noeuds avec rôle
    for d in "${!DEPS[@]}"; do
        id="${d//-/_}"
        id="${id//./_}"
        echo "$id[\"$d\"]"
    done
    echo ""

    # Arêtes
    for d in "${!DEPS[@]}"; do
        id_from="${d//-/_}"
        id_from="${id_from//./_}"
        for dep in ${DEPS[$d]}; do
            [[ "$dep" == "$d" ]] && continue
            id_to="${dep//-/_}"
            id_to="${id_to//./_}"
            echo "$id_from --> $id_to"
        done
    done
    echo ""

    # Application classes via portfolio-metadata.yml si disponible
    META="$CHRYSA_ROOT/shared-standards/portfolio-metadata.yml"
    if [[ -f "$META" ]] && command -v python3 &>/dev/null; then
        python3 -c "
import yaml
m = yaml.safe_load(open('$META'))
if m:
    for k, v in m.items():
        role = v.get('role', '').lower() if isinstance(v, dict) else ''
        kid = k.replace('-','_').replace('.','_')
        cls = {'socle':'socle','actif':'actif','opportuniste':'opp','gelé':'gele','gele':'gele'}.get(role)
        if cls:
            print(f'class {kid} {cls}')
" 2>/dev/null || true
    fi
} > "$OUT_MMD"

echo "✅ Graphe Mermaid généré : $OUT_MMD"
echo "   Pour rendre en SVG : mmdc -i $OUT_MMD -o \${OUT_MMD%.mmd}.svg"

# Rendu SVG si mmdc disponible
if command -v mmdc &>/dev/null; then
    mmdc -i "$OUT_MMD" -o "${OUT_MMD%.mmd}.svg" 2>/dev/null && \
        echo "✅ SVG généré : ${OUT_MMD%.mmd}.svg"
fi
