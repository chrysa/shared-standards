#!/usr/bin/env bash
# containerisation-audit.sh
# Audit portfolio-wide · compliance containerisation per directive chrysa
# « rien ne doit être lancé en local sauf pre-commit et CI · tout doit être containerisé »
#
# Vérifie pour chaque repo :
#   - Dockerfile présent ?
#   - docker-compose.yml présent ?
#   - Makefile avec cibles docker-* ?
#   - CI workflow contenant docker build/push ?
#   - README mentionne instructions docker ?
#
# Usage : ./containerisation-audit.sh [--repo=<name>] [--json] [--fix-suggest]

set -uo pipefail

CHRYSA_ROOT="${CHRYSA_ROOT:-/home/anthony/Documents/perso/projects/chrysa}"
OUTPUT_JSON=false
FIX_SUGGEST=false
SINGLE_REPO=""

for arg in "$@"; do
    case $arg in
        --json) OUTPUT_JSON=true ;;
        --fix-suggest) FIX_SUGGEST=true ;;
        --repo=*) SINGLE_REPO="${arg#*=}" ;;
    esac
done

cd "$CHRYSA_ROOT" || exit 1

check_repo() {
    local repo=$1
    [[ ! -d "$repo/.git" ]] && return

    local dockerfile=0
    local compose=0
    local makefile_docker=0
    local ci_docker=0
    local readme_docker=0

    [[ -f "$repo/Dockerfile" || -f "$repo/docker/Dockerfile" ]] && dockerfile=1
    [[ -f "$repo/docker-compose.yml" || -f "$repo/docker-compose.yaml" || -f "$repo/compose.yml" ]] && compose=1
    [[ -f "$repo/Makefile" ]] && grep -qE "^docker-" "$repo/Makefile" 2>/dev/null && makefile_docker=1
    find "$repo/.github/workflows" -type f 2>/dev/null | xargs grep -lE "docker.*build|docker.*push" 2>/dev/null | head -1 >/dev/null && ci_docker=1
    [[ -f "$repo/README.md" ]] && grep -qiE "docker|container" "$repo/README.md" 2>/dev/null && readme_docker=1

    local score=$((dockerfile + compose + makefile_docker + ci_docker + readme_docker))

    # Détection type projet
    local type="unknown"
    [[ -f "$repo/pyproject.toml" || -f "$repo/setup.py" ]] && type="python"
    [[ -f "$repo/package.json" ]] && type="node"
    [[ -f "$repo/go.mod" ]] && type="go"
    [[ -f "$repo/Cargo.toml" ]] && type="rust"

    if $OUTPUT_JSON; then
        cat <<EOF
{"repo":"$repo","type":"$type","dockerfile":$dockerfile,"compose":$compose,"makefile_docker":$makefile_docker,"ci_docker":$ci_docker,"readme_docker":$readme_docker,"score":$score}
EOF
    else
        printf "%-40s %-10s D:%d C:%d M:%d CI:%d R:%d  = %d/5\n" \
            "$repo" "$type" "$dockerfile" "$compose" "$makefile_docker" "$ci_docker" "$readme_docker" "$score"

        if $FIX_SUGGEST && [ $score -lt 3 ]; then
            echo "  → Fixes suggérés :"
            [ $dockerfile -eq 0 ] && echo "    - Créer Dockerfile (template dans shared-standards/templates/)"
            [ $compose -eq 0 ] && echo "    - Créer docker-compose.yml avec service + volumes"
            [ $makefile_docker -eq 0 ] && echo "    - Include shared-standards/makefiles/base/docker.Makefile"
            [ $ci_docker -eq 0 ] && echo "    - Ajouter job CI 'docker build' dans .github/workflows/"
            [ $readme_docker -eq 0 ] && echo "    - Section README : ## Docker avec commandes make docker-*"
        fi
    fi
}

echo "╔══════════════════════════════════════════════════════════╗"
echo "║ Audit containerisation portfolio chrysa                   ║"
echo "╚══════════════════════════════════════════════════════════╝"
$OUTPUT_JSON || printf "%-40s %-10s  %-30s\n" "REPO" "TYPE" "D:Dockerfile C:Compose M:Makefile CI:Workflow R:README"
$OUTPUT_JSON || echo "---"

if [[ -n "$SINGLE_REPO" ]]; then
    check_repo "$SINGLE_REPO"
else
    for d in */; do
        d="${d%/}"
        [[ "$d" == "_archived" ]] && continue
        check_repo "$d"
    done
fi

echo ""
echo "Légende · score /5 · 5 = full compliance · <3 = intervention requise"
echo "Relancer avec --fix-suggest pour obtenir les recommandations par repo"
