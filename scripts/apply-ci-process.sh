#!/usr/bin/env bash
# apply-ci-process.sh · Déploie les templates CI Tier 1+2+3 sur un repo
# Source : chrysa/shared-standards/scripts/apply-ci-process.sh
#
# Ce que le script fait :
#   Tier 1 · 10 workflows process-only (non stack-specific) dans .github/workflows/
#   Tier 2 · dependabot.yml généré selon stack détectée (pip/npm/docker)
#   Tier 3 · config github (.github/labeler.yml, labels.yml, auto_assign.yml, actionlint.yaml)
#   Bonus · fragment pre-commit common (à fusionner manuellement)
#
# Stack detection auto :
#   pyproject.toml OR requirements*.txt → ecosystem pip
#   package.json                        → ecosystem npm (directory auto-détecté)
#   Dockerfile OR docker/Dockerfile     → ecosystem docker
#   docker-compose*.yml                 → ecosystem docker-compose
#
# Usage :
#   bash apply-ci-process.sh <repo_path>        # déploie sur 1 repo
#   bash apply-ci-process.sh --all              # déploie sur tous les repos chrysa
#   bash apply-ci-process.sh --dry-run <path>   # preview sans écriture
#   bash apply-ci-process.sh --force <path>     # no-op (kept for compat)
#
# Sortie : table résumé des actions
#
# Exit : 0 OK · 1 erreur · 2 repo absent

set -uo pipefail

# ─── Paths & config ───────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHRYSA_ROOT="${CHRYSA_ROOT:-$(cd "$SCRIPT_DIR/../.." && pwd)}"
TEMPLATES_DIR="$CHRYSA_ROOT/shared-standards/templates"
WF_TEMPLATES="$TEMPLATES_DIR/workflows-process"
CFG_TEMPLATES="$TEMPLATES_DIR/github-config"

DRY_RUN=false
FORCE=false
TARGET_ALL=false
TARGET_REPO=""

# ─── Args parsing ────────────────────────────────────
for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN=true ;;
        --force)   FORCE=true ;; # kept for backward compat, no-op
        --all)     TARGET_ALL=true ;;
        -h|--help)
            sed -n '2,25p' "$0" | sed 's/^# \?//'
            exit 0
            ;;
        *)
            [[ -z "$TARGET_REPO" ]] && TARGET_REPO="$arg"
            ;;
    esac
done

# ─── Helpers ─────────────────────────────────────────
log()  { echo "[$(date +%H:%M:%S)] $*"; }
ok()   { echo -e "  \033[32m✓\033[0m $*"; }
warn() { echo -e "  \033[33m⚠\033[0m $*"; }
err()  { echo -e "  \033[31m✗\033[0m $*" >&2; }
info() { echo -e "  \033[34m→\033[0m $*"; }

# Assure la présence des templates avant de démarrer
check_templates() {
    local missing=()
    for f in \
        "$WF_TEMPLATES/approved-label.yml" \
        "$WF_TEMPLATES/auto-assign.yml" \
        "$WF_TEMPLATES/detect-conflicts.yml" \
        "$WF_TEMPLATES/labeler.yml" \
        "$WF_TEMPLATES/pr-dependencies.yml" \
        "$WF_TEMPLATES/pull-request-size.yml" \
        "$WF_TEMPLATES/sync-labels.yml" \
        "$WF_TEMPLATES/update-pr-body.yml" \
        "$WF_TEMPLATES/action-check.yml" \
        "$WF_TEMPLATES/auto-update-pre-commit.yml" \
        "$WF_TEMPLATES/dependabot-auto-merge.yml" \
        "$CFG_TEMPLATES/labels.yml" \
        "$CFG_TEMPLATES/labeler.yml" \
        "$CFG_TEMPLATES/auto_assign.yml" \
        "$CFG_TEMPLATES/actionlint.yaml" \
        "$CFG_TEMPLATES/dependabot.yml.tpl" \
        "$CFG_TEMPLATES/pre-commit-common.yaml"
    do
        [[ -f "$f" ]] || missing+=("$f")
    done
    if [[ ${#missing[@]} -gt 0 ]]; then
        err "Templates manquants :"
        for f in "${missing[@]}"; do err "  · $f"; done
        exit 1
    fi
}

# Détecte les ecosystems présents dans un repo
detect_stack() {
    local repo="$1"
    local stacks=""

    # Python
    if [[ -f "$repo/pyproject.toml" ]] || ls "$repo"/requirements*.txt &>/dev/null || [[ -f "$repo/setup.py" ]] || [[ -f "$repo/setup.cfg" ]]; then
        # Préfère pyproject.toml directory
        if [[ -f "$repo/pyproject.toml" ]]; then
            stacks+="python:/;"
        else
            stacks+="python:/;"
        fi
    fi

    # npm (cherche package.json à racine ou app/ ou frontend/ ou web/)
    for npm_dir in "" "app" "frontend" "web" "client"; do
        local full_path="$repo"
        [[ -n "$npm_dir" ]] && full_path="$repo/$npm_dir"
        if [[ -f "$full_path/package.json" ]]; then
            local rel_dir="/"
            [[ -n "$npm_dir" ]] && rel_dir="$npm_dir/"
            stacks+="npm:$rel_dir;"
            break
        fi
    done

    # Docker
    if [[ -f "$repo/Dockerfile" ]]; then
        stacks+="docker:/;"
    elif [[ -d "$repo/docker" ]] && ls "$repo/docker"/Dockerfile* &>/dev/null; then
        stacks+="docker:docker/;"
    fi

    # Docker compose
    if ls "$repo"/docker-compose*.y*ml &>/dev/null; then
        stacks+="docker-compose:/;"
    fi

    echo "$stacks"
}

# Génère dependabot.yml à partir du template + stacks détectées
generate_dependabot() {
    local repo="$1"
    local stacks="$2"
    local dest="$repo/.github/dependabot.yml"
    local tpl="$CFG_TEMPLATES/dependabot.yml.tpl"

    # Start fresh : copie le tpl et retire les blocs non pertinents
    local tmp; tmp=$(mktemp)
    cp "$tpl" "$tmp"

    # Python
    if [[ "$stacks" == *"python:"* ]]; then
        local dir
        dir=$(echo "$stacks" | tr ';' '\n' | grep '^python:' | head -1 | cut -d: -f2)
        sed -i "s|{{PIP_DIR}}|${dir:-/}|" "$tmp"
        sed -i '/{{ECOSYSTEM_PYTHON_START}}/d; /{{ECOSYSTEM_PYTHON_END}}/d' "$tmp"
    else
        sed -i '/{{ECOSYSTEM_PYTHON_START}}/,/{{ECOSYSTEM_PYTHON_END}}/d' "$tmp"
    fi

    # NPM
    if [[ "$stacks" == *"npm:"* ]]; then
        local dir
        dir=$(echo "$stacks" | tr ';' '\n' | grep '^npm:' | head -1 | cut -d: -f2)
        sed -i "s|{{NPM_DIR}}|${dir:-/}|" "$tmp"
        sed -i '/{{ECOSYSTEM_NPM_START}}/d; /{{ECOSYSTEM_NPM_END}}/d' "$tmp"
    else
        sed -i '/{{ECOSYSTEM_NPM_START}}/,/{{ECOSYSTEM_NPM_END}}/d' "$tmp"
    fi

    # Docker
    if [[ "$stacks" == *"docker:"* ]]; then
        local dir
        dir=$(echo "$stacks" | tr ';' '\n' | grep '^docker:' | head -1 | cut -d: -f2)
        sed -i "s|{{DOCKER_DIR}}|${dir:-/}|" "$tmp"
        sed -i '/{{ECOSYSTEM_DOCKER_START}}/d; /{{ECOSYSTEM_DOCKER_END}}/d' "$tmp"
    else
        sed -i '/{{ECOSYSTEM_DOCKER_START}}/,/{{ECOSYSTEM_DOCKER_END}}/d' "$tmp"
    fi

    # Docker compose
    if [[ "$stacks" == *"docker-compose:"* ]]; then
        sed -i '/{{ECOSYSTEM_DOCKER_COMPOSE_START}}/d; /{{ECOSYSTEM_DOCKER_COMPOSE_END}}/d' "$tmp"
    else
        sed -i '/{{ECOSYSTEM_DOCKER_COMPOSE_START}}/,/{{ECOSYSTEM_DOCKER_COMPOSE_END}}/d' "$tmp"
    fi

    # Nettoie lignes vides consécutives multiples
    awk 'NF || prev_nf {print} {prev_nf = NF}' "$tmp" > "${tmp}.clean"
    mv "${tmp}.clean" "$tmp"

    if $DRY_RUN; then
        info "[dry-run] Générerait $dest ($(wc -l < "$tmp") lignes)"
        rm -f "$tmp"
        return 0
    fi

    mkdir -p "$(dirname "$dest")"
    mv "$tmp" "$dest"
    ok "dependabot.yml écrit (stacks : $stacks)"
}

# Déploie sur 1 repo
deploy_one() {
    local repo="$1"
    local repo_name
    repo_name=$(basename "$repo")

    if [[ ! -d "$repo" ]]; then
        err "$repo n'existe pas"
        return 2
    fi
    if [[ ! -d "$repo/.git" ]]; then
        warn "$repo_name : pas un repo git · skip"
        return 0
    fi

    log "═══ Déploiement sur $repo_name ═══"

    # ─── Détection stack ──────────────────
    local stacks
    stacks=$(detect_stack "$repo")
    info "Stack détectée : ${stacks:-aucune (repo config/docs-only)}"

    # ─── Tier 1 : 10 workflows ─────────────
    mkdir -p "$repo/.github/workflows"
    local wf_dest="$repo/.github/workflows"
    local copied=0
    for wf in "$WF_TEMPLATES"/*.yml; do
        local name
        name=$(basename "$wf")
        local dest="$wf_dest/$name"

        if $DRY_RUN; then
            info "[dry-run] Copierait $name → $wf_dest/"
            continue
        fi

        cp "$wf" "$dest"
        copied=$((copied + 1))
    done
    ok "Workflows copiés : $copied/11"

    # ─── Tier 3 : github-config ─────────────
    mkdir -p "$repo/.github"
    for cfg in labeler.yml labels.yml auto_assign.yml actionlint.yaml; do
        local src="$CFG_TEMPLATES/$cfg"
        local dest="$repo/.github/$cfg"

        if $DRY_RUN; then
            info "[dry-run] Copierait .github/$cfg"
            continue
        fi

        cp "$src" "$dest"
    done
    ok "github-config copié (4 fichiers)"

    # ─── Tier 2 : dependabot ────────────────
    generate_dependabot "$repo" "$stacks"

    # ─── Bonus : pre-commit common ──────────
    if [[ -f "$repo/.pre-commit-config.yaml" ]]; then
        info "Repo a déjà .pre-commit-config.yaml · fragment common disponible dans $CFG_TEMPLATES/pre-commit-common.yaml (fusion manuelle)"
    else
        if $DRY_RUN; then
            info "[dry-run] Créerait .pre-commit-config.yaml depuis template common"
        else
            cp "$CFG_TEMPLATES/pre-commit-common.yaml" "$repo/.pre-commit-config.yaml"
            ok "pre-commit-config.yaml créé depuis template common"
        fi
    fi

    log "── $repo_name : terminé"
    echo ""
}

# ═══ Main ═══
check_templates

if $TARGET_ALL; then
    log "Mode --all · scan des repos chrysa dans $CHRYSA_ROOT/"
    for d in "$CHRYSA_ROOT"/*/; do
        [[ -d "$d/.git" ]] || continue
        [[ "$(basename "$d")" == "shared-standards" ]] && continue
        [[ "$(basename "$d")" == "_archived" ]] && continue
        deploy_one "$d"
    done
elif [[ -n "$TARGET_REPO" ]]; then
    deploy_one "$TARGET_REPO"
else
    err "Usage : $0 [--all | <repo_path>] [--dry-run] [--force]"
    exit 1
fi

log "════ FIN ════"
