#!/usr/bin/env bash
# chrysa-cli.sh — CLI interactif portfolio chrysa
# Menu interactif pour actions communes sur repos
# Usage: ./chrysa-cli.sh [repo] | sans arg = menu de sélection

set -uo pipefail
CHRYSA_ROOT="${CHRYSA_ROOT:-/home/anthony/Documents/perso/projects/chrysa}"
cd "$CHRYSA_ROOT" || exit 1

# ─── Helpers ────────────────────────────────────────────
c_reset='\033[0m'; c_blue='\033[0;34m'; c_green='\033[0;32m'; c_yellow='\033[0;33m'; c_red='\033[0;31m'
ask() { read -p "$(echo -e "${c_yellow}?${c_reset} $1 (y/n) ")" -n 1 -r; echo; [[ $REPLY =~ ^[Yy]$ ]]; }
info() { echo -e "${c_blue}→${c_reset} $*"; }
ok() { echo -e "${c_green}✓${c_reset} $*"; }
err() { echo -e "${c_red}✗${c_reset} $*"; }

# ─── Select repo ───────────────────────────────────────
select_repo() {
    local repos=()
    for d in */; do
        d="${d%/}"
        [[ "$d" == "_archived" ]] && continue
        [[ -d "$d/.git" ]] && repos+=("$d")
    done

    echo "Repos disponibles :"
    local i=1
    for r in "${repos[@]}"; do
        printf "  %2d) %s\n" $i "$r"
        i=$((i+1))
    done
    read -p "Numéro (ou 'a' pour tous) : " choice
    [[ "$choice" == "a" ]] && { echo "all"; return; }
    [[ "$choice" =~ ^[0-9]+$ ]] && echo "${repos[$((choice-1))]}" || echo ""
}

# ─── Status ────────────────────────────────────────────
status_repo() {
    local r=$1
    cd "$CHRYSA_ROOT/$r" || return
    local branch=$(git branch --show-current 2>/dev/null)
    local dirty=$(git status --porcelain | wc -l)
    local ahead=$(git rev-list --count @{u}..HEAD 2>/dev/null || echo 0)
    local behind=$(git rev-list --count HEAD..@{u} 2>/dev/null || echo 0)
    local last=$(git log -1 --format="%cr" 2>/dev/null)

    echo -e "${c_blue}═══ $r ═══${c_reset}"
    echo "  branch : $branch"
    echo "  last   : $last"
    echo "  ahead  : $ahead · behind : $behind · dirty : $dirty"
    [[ -f ".pre-commit-config.yaml" ]] && ok "pre-commit OK" || err "pre-commit absent"
    [[ -d ".github/workflows" ]] && ok "CI OK" || err "CI absent"
    [[ -f "Dockerfile" || -f "docker-compose.yml" ]] && ok "Docker OK" || err "Docker absent"
    cd "$CHRYSA_ROOT" || return
}

# ─── Actions ────────────────────────────────────────────
install_precommit() {
    local r=$1
    cd "$CHRYSA_ROOT/$r" || return
    if [[ ! -f ".pre-commit-config.yaml" ]]; then
        err "Pas de config pre-commit. Utilise install_precommit_config d'abord."
        return
    fi
    info "pre-commit install..."
    pre-commit install && ok "pre-commit installé"
    if ask "Run sur tous les fichiers ?"; then
        pre-commit run --all-files || err "Erreurs détectées (normal si 1er run)"
    fi
    cd "$CHRYSA_ROOT" || return
}

install_precommit_config() {
    local r=$1
    cd "$CHRYSA_ROOT/$r" || return
    if [[ -f ".pre-commit-config.yaml" ]]; then
        ask "Config existe déjà, overwrite ?" || return
    fi
    # Détection langage
    local lang="python"
    [[ -f "package.json" ]] && lang="node"

    cat > .pre-commit-config.yaml <<PCYAML
# Auto-généré par chrysa-cli · standardisé shared-standards
repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v5.0.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-yaml
      - id: check-added-large-files
      - id: detect-private-key

  - repo: https://github.com/gitleaks/gitleaks
    rev: v8.18.0
    hooks:
      - id: gitleaks
PCYAML

    if [[ "$lang" == "python" ]]; then
        cat >> .pre-commit-config.yaml <<PCPY

  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.6.0
    hooks:
      - id: ruff
        args: [--fix]
      - id: ruff-format

  - repo: https://github.com/pre-commit/mirrors-mypy
    rev: v1.11.0
    hooks:
      - id: mypy
PCPY
    elif [[ "$lang" == "node" ]]; then
        cat >> .pre-commit-config.yaml <<PCNODE

  - repo: https://github.com/pre-commit/mirrors-prettier
    rev: v4.0.0-alpha.8
    hooks:
      - id: prettier

  - repo: https://github.com/pre-commit/mirrors-eslint
    rev: v9.8.0
    hooks:
      - id: eslint
PCNODE
    fi

    ok ".pre-commit-config.yaml créé ($lang)"
    cd "$CHRYSA_ROOT" || return
}

install_ci_config() {
    local r=$1
    cd "$CHRYSA_ROOT/$r" || return
    mkdir -p .github/workflows
    if [[ -f ".github/workflows/ci.yml" ]]; then
        ask "CI existe déjà, overwrite ?" || return
    fi
    local lang="python"
    [[ -f "package.json" ]] && lang="node"

    cat > .github/workflows/ci.yml <<CIYAML
name: CI
on:
  push:
    branches: [develop, master, main]
  pull_request:

jobs:
  quality:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: pre-commit
        uses: pre-commit/action@v3.0.1
CIYAML

    if [[ "$lang" == "python" ]]; then
        cat >> .github/workflows/ci.yml <<CIPY

  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        python-version: ["3.12", "3.14"]
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: \${{ matrix.python-version }}
      - name: Install
        run: pip install -e ".[dev]" || pip install -r requirements.txt
      - name: Tests
        run: pytest --cov --cov-report=xml
CIPY
    elif [[ "$lang" == "node" ]]; then
        cat >> .github/workflows/ci.yml <<CINODE

  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: "20"
      - run: npm ci
      - run: npm test
CINODE
    fi

    ok ".github/workflows/ci.yml créé ($lang)"
    cd "$CHRYSA_ROOT" || return
}

run_tests() {
    local r=$1
    cd "$CHRYSA_ROOT/$r" || return
    if [[ -f "Makefile" ]] && grep -q "^tests\?:" Makefile; then
        info "make tests..."
        make tests || make test
    elif [[ -f "pyproject.toml" ]]; then
        info "pytest..."
        pytest
    elif [[ -f "package.json" ]]; then
        info "npm test..."
        npm test
    else
        err "Pas de test runner détecté"
    fi
    cd "$CHRYSA_ROOT" || return
}

build_docker() {
    local r=$1
    cd "$CHRYSA_ROOT/$r" || return
    if [[ -f "docker-compose.yml" ]]; then
        info "docker compose build..."
        docker compose build
    elif [[ -f "Dockerfile" ]]; then
        info "docker build..."
        docker build -t "chrysa/$r:local" .
    else
        err "Pas de Dockerfile ni docker-compose.yml"
    fi
    cd "$CHRYSA_ROOT" || return
}

open_vscode() {
    local r=$1
    if command -v code &>/dev/null; then
        code "$CHRYSA_ROOT/$r"
        ok "Ouvert dans VSCode"
    else
        err "code CLI non trouvé"
    fi
}

commit_config() {
    local r=$1
    cd "$CHRYSA_ROOT/$r" || return
    local changes=$(git status --porcelain .pre-commit-config.yaml .github/workflows/ci.yml 2>/dev/null | wc -l)
    if [[ "$changes" -eq 0 ]]; then
        info "Rien à commit"
        cd "$CHRYSA_ROOT"
        return
    fi
    git add .pre-commit-config.yaml .github/workflows/ci.yml 2>/dev/null
    if ask "Commit 'chore: standardize dev workflow' ?"; then
        git commit -m "chore: standardize dev workflow"
        ok "Commit créé"
        if ask "Push ?"; then
            git push
        fi
    fi
    cd "$CHRYSA_ROOT" || return
}

# ─── Menu ──────────────────────────────────────────────
menu() {
    local r=$1
    while true; do
        echo ""
        echo -e "${c_blue}══ Actions pour $r ══${c_reset}"
        echo "  1) Statut"
        echo "  2) Installer pre-commit (config + hooks)"
        echo "  3) Installer CI workflow"
        echo "  4) Lancer tests"
        echo "  5) Build Docker"
        echo "  6) Ouvrir VSCode"
        echo "  7) Commit config standardisée"
        echo "  8) Tout-en-un (2+3+4+7)"
        echo "  q) Quitter"
        read -p "Action : " a
        case $a in
            1) status_repo "$r" ;;
            2) install_precommit_config "$r" && install_precommit "$r" ;;
            3) install_ci_config "$r" ;;
            4) run_tests "$r" ;;
            5) build_docker "$r" ;;
            6) open_vscode "$r" ;;
            7) commit_config "$r" ;;
            8)
                install_precommit_config "$r"
                install_precommit "$r"
                install_ci_config "$r"
                run_tests "$r"
                commit_config "$r"
                ;;
            q|Q) break ;;
            *) err "Choix invalide" ;;
        esac
    done
}

# ─── Main ──────────────────────────────────────────────
main() {
    local target="${1:-}"
    if [[ -z "$target" ]]; then
        target=$(select_repo)
    fi
    [[ -z "$target" ]] && { err "Aucun repo sélectionné"; exit 1; }

    if [[ "$target" == "all" ]]; then
        for d in */; do
            d="${d%/}"
            [[ "$d" == "_archived" ]] && continue
            [[ ! -d "$d/.git" ]] && continue
            status_repo "$d"
        done
    else
        menu "$target"
    fi
}

main "$@"
