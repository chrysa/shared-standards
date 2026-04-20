#!/usr/bin/env bash
# dev-run.sh — Runner local unifié pour chrysa
# Détecte le stack du repo courant et lance la commande demandée
# (app/test/lint/format/quality/typecheck/all).
#
# Stacks supportés : Python · Node/TS · Go · Rust · Docker · Django · Rust
# Détecte automatiquement :
#   - pyproject.toml / setup.py / requirements.txt  → Python
#   - package.json                                  → Node
#   - go.mod                                        → Go
#   - Cargo.toml                                    → Rust
#   - manage.py                                     → Django (overlay Python)
#   - docker-compose.yml / Dockerfile               → Docker (overlay ou principal)
#   - Makefile avec cibles communes                 → Makefile-driven (override auto)
#
# Usage :
#   dev-run.sh                    # mode auto (détecte + menu interactif si TTY)
#   dev-run.sh app                # lance l'app / dev server
#   dev-run.sh test               # lance les tests
#   dev-run.sh lint               # lint uniquement
#   dev-run.sh format             # auto-format
#   dev-run.sh typecheck          # vérification types
#   dev-run.sh quality            # lint + typecheck + format check
#   dev-run.sh all                # quality + test (pas app)
#   dev-run.sh --list             # liste les commandes détectées sans rien lancer
#
# Options :
#   --fix                         # pour lint/format : tente de corriger automatiquement
#   --docker                      # force l'exécution via docker (compose run)
#   --verbose                     # affiche les commandes avant de les lancer
#
# Exit codes :
#   0   tout OK
#   1   au moins une commande a échoué
#   2   stack non détecté ou commande inconnue

set -uo pipefail

# ─── Parse args ────────────────────────────────────────────────────
ACTION="${1:-auto}"
FIX=false
VERBOSE=false
FORCE_DOCKER=false

for arg in "$@"; do
    case "$arg" in
        --fix)     FIX=true ;;
        --verbose) VERBOSE=true ;;
        --docker)  FORCE_DOCKER=true ;;
        --list)    ACTION="list" ;;
    esac
done

# ─── Helpers (via lib commune) ─────────────────────────────────────
source "$(dirname "${BASH_SOURCE[0]}")/_lib.sh" 2>/dev/null || {
    # Fallback minimal si _lib.sh absent (dev-run peut être copié hors shared-standards)
    c_reset='\033[0m'; c_blue='\033[0;34m'; c_green='\033[0;32m'
    c_yellow='\033[0;33m'; c_red='\033[0;31m'; c_gray='\033[0;90m'
    info()  { printf "${c_blue}→${c_reset} %s\n" "$*"; }
    ok()    { printf "${c_green}✓${c_reset} %s\n" "$*"; }
    warn()  { printf "${c_yellow}⚠${c_reset}  %s\n" "$*"; }
    err()   { printf "${c_red}✗${c_reset} %s\n" "$*"; }
    step()  { printf "\n${c_blue}── %s ──${c_reset}\n" "$*"; }
}

run() {
    local cmd="$*"
    $VERBOSE && echo "${c_gray}$ $cmd${c_reset}"
    eval "$cmd"
}

# ─── Détection stack ───────────────────────────────────────────────
detect_stack() {
    local stacks=()
    [[ -f "pyproject.toml" || -f "setup.py" || -f "requirements.txt" ]] && stacks+=("python")
    [[ -f "package.json" ]] && stacks+=("node")
    [[ -f "go.mod" ]] && stacks+=("go")
    [[ -f "Cargo.toml" ]] && stacks+=("rust")
    [[ -f "manage.py" ]] && stacks+=("django")
    [[ -f "docker-compose.yml" || -f "docker-compose.yaml" || -f "compose.yml" ]] && stacks+=("compose")
    [[ -f "Dockerfile" ]] && stacks+=("docker")
    [[ -f "Makefile" ]] && stacks+=("make")
    echo "${stacks[@]}"
}

has_make_target() {
    local target=$1
    [[ -f "Makefile" ]] || return 1
    grep -qE "^${target}:" Makefile
}

# ─── Résolutions de commandes par stack ────────────────────────────
declare -A CMDS

build_cmd_map() {
    local stacks=($(detect_stack))

    # Priorité 1 : Makefile (si cible existante)
    if has_make_target "tests" || has_make_target "test"; then
        CMDS[test]="make $(has_make_target 'tests' && echo tests || echo test)"
    fi
    has_make_target "lint"         && CMDS[lint]="make lint"
    has_make_target "format"       && CMDS[format]="make format"
    has_make_target "format-code"  && CMDS[format]="make format-code"
    has_make_target "type-check"   && CMDS[typecheck]="make type-check"
    has_make_target "typecheck"    && CMDS[typecheck]="make typecheck"
    has_make_target "quality"      && CMDS[quality]="make quality"
    has_make_target "dev"          && CMDS[app]="make dev"
    has_make_target "run"          && CMDS[app]="make run"
    has_make_target "start"        && CMDS[app]="make start"
    has_make_target "ci"           && CMDS[ci]="make ci"

    # Priorité 2 : stack natif si pas déjà mappé
    for stack in "${stacks[@]}"; do
        case "$stack" in
            python)
                : "${CMDS[lint]:=ruff check .}"
                : "${CMDS[format]:=ruff format .}"
                : "${CMDS[typecheck]:=mypy .}"
                : "${CMDS[test]:=pytest}"
                if $FIX; then
                    CMDS[lint]="ruff check --fix ."
                fi
                ;;
            node)
                : "${CMDS[lint]:=npm run lint 2>/dev/null || npx eslint . --max-warnings=0}"
                : "${CMDS[format]:=npm run format 2>/dev/null || npx prettier --write .}"
                : "${CMDS[typecheck]:=npm run type-check 2>/dev/null || npx tsc --noEmit}"
                : "${CMDS[test]:=npm test}"
                : "${CMDS[app]:=npm run dev 2>/dev/null || npm start}"
                ;;
            go)
                : "${CMDS[lint]:=golangci-lint run || go vet ./...}"
                : "${CMDS[format]:=gofmt -w .}"
                : "${CMDS[typecheck]:=go build ./...}"
                : "${CMDS[test]:=go test ./...}"
                ;;
            rust)
                : "${CMDS[lint]:=cargo clippy -- -D warnings}"
                : "${CMDS[format]:=cargo fmt}"
                : "${CMDS[typecheck]:=cargo check}"
                : "${CMDS[test]:=cargo test}"
                : "${CMDS[app]:=cargo run}"
                ;;
            django)
                : "${CMDS[app]:=python manage.py runserver 0.0.0.0:8000}"
                : "${CMDS[test]:=pytest || python manage.py test}"
                ;;
            compose)
                : "${CMDS[app]:=docker compose up --build}"
                ;;
            docker)
                : "${CMDS[app]:=docker build -t local:dev . && docker run --rm -it local:dev}"
                ;;
        esac
    done

    # Override si --docker forcé
    if $FORCE_DOCKER; then
        local compose_file=""
        for f in docker-compose.yml docker-compose.yaml compose.yml; do
            [[ -f "$f" ]] && { compose_file="$f"; break; }
        done
        if [[ -n "$compose_file" ]]; then
            [[ -n "${CMDS[test]:-}" ]] && CMDS[test]="docker compose run --rm app ${CMDS[test]#make *}"
            [[ -n "${CMDS[lint]:-}" ]] && CMDS[lint]="docker compose run --rm app ${CMDS[lint]#make *}"
        fi
    fi

    # Composite : quality = lint + typecheck + format (check)
    if [[ -z "${CMDS[quality]:-}" ]]; then
        local q_parts=()
        [[ -n "${CMDS[lint]:-}" ]]      && q_parts+=("${CMDS[lint]}")
        [[ -n "${CMDS[typecheck]:-}" ]] && q_parts+=("${CMDS[typecheck]}")
        if [[ ${#q_parts[@]} -gt 0 ]]; then
            local joined=""
            for part in "${q_parts[@]}"; do
                joined+="${joined:+ && }$part"
            done
            CMDS[quality]="$joined"
        fi
    fi

    # Composite : all = quality + test
    local all_parts=()
    [[ -n "${CMDS[quality]:-}" ]] && all_parts+=("${CMDS[quality]}")
    [[ -n "${CMDS[test]:-}"    ]] && all_parts+=("${CMDS[test]}")
    if [[ ${#all_parts[@]} -gt 0 ]]; then
        local joined=""
        for part in "${all_parts[@]}"; do
            joined+="${joined:+ && }$part"
        done
        CMDS[all]="$joined"
    fi
}

# ─── Exécution ─────────────────────────────────────────────────────
print_map() {
    echo -e "${c_blue}Stack détecté :${c_reset} $(detect_stack)"
    echo -e "${c_blue}Commandes disponibles :${c_reset}"
    for key in app test lint format typecheck quality all ci; do
        if [[ -n "${CMDS[$key]:-}" ]]; then
            printf "  %-12s ${c_gray}%s${c_reset}\n" "$key" "${CMDS[$key]}"
        fi
    done
}

run_action() {
    local key=$1
    local cmd="${CMDS[$key]:-}"
    if [[ -z "$cmd" ]]; then
        err "Aucune commande pour l'action '$key' (stack: $(detect_stack))"
        return 2
    fi
    step "Action: $key"
    info "Commande: $cmd"
    if run "$cmd"; then
        ok "$key OK"
        return 0
    else
        err "$key a échoué"
        return 1
    fi
}

interactive_menu() {
    echo -e "${c_blue}Actions disponibles :${c_reset}"
    local opts=()
    local i=1
    for key in app test lint format typecheck quality all; do
        if [[ -n "${CMDS[$key]:-}" ]]; then
            printf "  %2d) %-10s ${c_gray}%s${c_reset}\n" "$i" "$key" "${CMDS[$key]}"
            opts+=("$key")
            i=$((i+1))
        fi
    done
    [[ ${#opts[@]} -eq 0 ]] && { err "aucune commande détectée"; return 2; }
    local choice
    read -r -p "Numéro (ou q) : " choice </dev/tty
    [[ "$choice" =~ ^[Qq]$ ]] && return 0
    if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#opts[@]} )); then
        run_action "${opts[$((choice-1))]}"
    else
        err "choix invalide"
        return 2
    fi
}

# ─── Main ──────────────────────────────────────────────────────────
if [[ ! -d ".git" && ! -f "Makefile" && ! -f "pyproject.toml" && ! -f "package.json" ]]; then
    err "Pas dans un repo git/projet détecté · cd dans un repo avant de lancer dev-run.sh"
    exit 2
fi

build_cmd_map

case "$ACTION" in
    auto)
        if [[ -t 0 ]]; then
            interactive_menu; exit $?
        else
            print_map; exit 0
        fi
        ;;
    list)       print_map; exit 0 ;;
    app|test|lint|format|typecheck|quality|all|ci)
        run_action "$ACTION"; exit $?
        ;;
    *)
        err "Action inconnue: $ACTION"
        echo ""
        print_map
        exit 2
        ;;
esac
