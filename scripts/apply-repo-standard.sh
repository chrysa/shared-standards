#!/usr/bin/env bash
# apply-repo-standard.sh · Apply the FULL chrysa repo standard to a repo.
# Source: chrysa/shared-standards/scripts/apply-repo-standard.sh
#
# Composes, idempotently:
#   1. Hygiene files   .editorconfig, .gitattributes, CONTRIBUTING.md, LICENSE (public only)
#   1b. Governance     .github/CODEOWNERS (create-if-absent)
#   2. Stack CI        .github/workflows/ci.yml from workflows/ci-{python,node}.yml (+ token sub)
#   3. Pre-commit      merge Full §8 baseline into .pre-commit-config.yaml (scripts/pre-commit-merge.py)
#   4. Process layer   delegates to apply-ci-process.sh (process workflows + dependabot + github-config)
#
# Token substitution for CI (auto-detected, override via env):
#   PACKAGE, SOURCES, TESTS, REPO_NAME, PROJECT_KEY
#
# Usage:
#   bash apply-repo-standard.sh <repo_path>          # one repo
#   bash apply-repo-standard.sh --all                # all status:dev repos in repos.yml
#   bash apply-repo-standard.sh --dry-run <path>     # preview, no writes
#   bash apply-repo-standard.sh --check <path>       # report pre-commit drift only
#
# Exit: 0 ok · 1 error · 2 repo absent
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STD_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CHRYSA_ROOT="${CHRYSA_ROOT:-$(cd "$STD_ROOT/.." && pwd)}"
TPL="$STD_ROOT/templates"
WF="$STD_ROOT/workflows"
REPOS_YML="$STD_ROOT/repos.yml"
YEAR="${YEAR:-2026}"

DRY_RUN=false
CHECK=false
TARGET_ALL=false
NO_CI=false
TARGET_REPO=""

for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN=true ;;
        --check)   CHECK=true ;;
        --all)     TARGET_ALL=true ;;
        --no-ci)   NO_CI=true ;;
        -h|--help) sed -n '2,30p' "$0" | sed 's/^# \?//'; exit 0 ;;
        *)         [[ -z "$TARGET_REPO" ]] && TARGET_REPO="$arg" ;;
    esac
done

log()  { echo "[$(date +%H:%M:%S)] $*"; }
ok()   { echo -e "  \033[32m✓\033[0m $*"; }
warn() { echo -e "  \033[33m⚠\033[0m $*"; }
err()  { echo -e "  \033[31m✗\033[0m $*" >&2; }
info() { echo -e "  \033[34m→\033[0m $*"; }

# repos.yml lookups (flat list of `- name:`/`status:`/`public:` triples).
repo_field() {
    local name="$1" field="$2"
    awk -v n="$name" -v f="$field" '
        $1=="-" && $2=="name:" { cur=$3 }
        cur==n && $1==f":" { print $2; exit }
    ' "$REPOS_YML"
}

repo_is_public() { [[ "$(repo_field "$1" public)" == "true" ]]; }

# Detect the top-level python package dir (has __init__.py, not tests/build/venv).
detect_package() {
    local repo="$1" name; name="${REPO_NAME:-$(basename "$repo")}"
    local d
    for d in "$repo"/*/; do
        d="${d%/}"; local b; b="$(basename "$d")"
        case "$b" in tests|test|build|dist|docs|.*|venv|node_modules) continue ;; esac
        [[ -f "$d/__init__.py" ]] && { basename "$d"; return; }
    done
    echo "${name//-/_}"
}

deploy_file() {
    local src="$1" dest="$2"
    if $DRY_RUN; then info "[dry-run] would write $dest"; return; fi
    mkdir -p "$(dirname "$dest")"
    cp "$src" "$dest"
    ok "$(basename "$dest")"
}

deploy_hygiene() {
    local repo="$1" name; name="${REPO_NAME:-$(basename "$repo")}"
    deploy_file "$TPL/.editorconfig"  "$repo/.editorconfig"
    deploy_file "$TPL/.gitattributes" "$repo/.gitattributes"
    if $DRY_RUN; then
        info "[dry-run] would write $repo/CONTRIBUTING.md (REPO_NAME=$name)"
    else
        sed "s/\${REPO_NAME}/$name/g" "$TPL/CONTRIBUTING.md" > "$repo/CONTRIBUTING.md"
        ok "CONTRIBUTING.md"
    fi
    if repo_is_public "$name"; then
        if $DRY_RUN; then
            info "[dry-run] would write $repo/LICENSE (public, MIT, YEAR=$YEAR)"
        else
            sed "s/\${YEAR}/$YEAR/g" "$TPL/LICENSE.mit" > "$repo/LICENSE"
            ok "LICENSE (MIT)"
        fi
    else
        info "private repo · LICENSE skipped"
    fi
}

# Release tooling + repo meta. Create-if-absent only — never clobber an existing
# CHANGELOG (real history), opencode.json, AGENTS.md, etc.
deploy_release_tooling() {
    local repo="$1" name; name="${REPO_NAME:-$(basename "$repo")}"
    local pairs=(
        "CHANGELOG.md:CHANGELOG.md"
        "cliff.toml:cliff.toml"
        "GitVersion.yml:GitVersion.yml"
        "opencode.json:opencode.json"
        "AGENTS.md:AGENTS.md"
    )
    local p src dest
    for p in "${pairs[@]}"; do
        src="$TPL/${p%%:*}"; dest="$repo/${p##*:}"
        [[ -f "$src" ]] || { warn "template missing: $(basename "$src")"; continue; }
        [[ -e "$dest" ]] && continue                       # no clobber
        if $DRY_RUN; then info "[dry-run] would create $dest"; continue; fi
        mkdir -p "$(dirname "$dest")"
        sed "s/\${REPO_NAME}/$name/g" "$src" > "$dest"
        ok "$(basename "$dest") (created)"
    done
}

# Governance files (create-if-absent): CODEOWNERS. Never clobber a hand-tuned one.
deploy_governance() {
    local repo="$1" dest="$repo/.github/CODEOWNERS" src="$TPL/CODEOWNERS"
    [[ -f "$src" ]] || { warn "template missing: CODEOWNERS"; return; }
    [[ -e "$dest" ]] && { info "CODEOWNERS exists · preserved"; return; }
    if $DRY_RUN; then info "[dry-run] would create $dest"; return; fi
    mkdir -p "$(dirname "$dest")"
    cp "$src" "$dest"
    ok "CODEOWNERS (created)"
}

ci_is_canonical() {
    local f="$1"
    [[ -f "$f" ]] || return 1
    grep -q 'chrysa/github-actions' "$f" \
        && grep -q 'name: Pre-commit checks' "$f" \
        && grep -q 'name: SonarCloud' "$f"
}

deploy_stack_ci() {
    local repo="$1" name; name="${REPO_NAME:-$(basename "$repo")}"
    local tpl dest="$repo/.github/workflows/ci.yml"
    local pkg sources tests project_key
    if ci_is_canonical "$dest"; then
        info "ci.yml already canonical · skip (edit manually to re-template)"
        return
    fi
    if [[ -f "$repo/pyproject.toml" ]] || ls "$repo"/requirements*.txt &>/dev/null; then
        tpl="$WF/ci-python.yml"
        pkg="$(detect_package "$repo")"
        tests="tests"; [[ -d "$repo/tests" ]] || tests="tests"
        sources="$pkg $tests"
    elif [[ -f "$repo/package.json" ]]; then
        tpl="$WF/ci-node.yml"
        pkg=""; sources="src"; tests=""
    else
        warn "no python/node stack detected · CI skipped"
        return
    fi
    project_key="${PROJECT_KEY:-chrysa_${name}}"
    if $DRY_RUN; then
        info "[dry-run] would write ci.yml from $(basename "$tpl") (pkg=$pkg key=$project_key)"
        return
    fi
    mkdir -p "$(dirname "$dest")"
    sed -e "s/\${PACKAGE}/$pkg/g" \
        -e "s/\${SOURCES}/$sources/g" \
        -e "s/\${TESTS}/$tests/g" \
        -e "s/\${REPO_NAME}/$name/g" \
        -e "s/\${PROJECT_KEY}/$project_key/g" \
        "$tpl" > "$dest"
    ok "ci.yml ($(basename "$tpl"))"
}

# Comma list of pre-commit stacks for a repo: python,docker,jsts,react,fastapi
detect_pc_stacks() {
    local repo="$1" s=""
    { [[ -f "$repo/pyproject.toml" ]] || ls "$repo"/requirements*.txt &>/dev/null; } && s+="python,"
    { [[ -f "$repo/Dockerfile" ]] || ls "$repo"/docker/Dockerfile* &>/dev/null; } && s+="docker,"
    if [[ -f "$repo/package.json" ]]; then
        s+="jsts,"
        grep -q '"react"' "$repo/package.json" 2>/dev/null && s+="react,"
    fi
    { grep -riqs 'fastapi' "$repo/pyproject.toml" "$repo"/requirements*.txt 2>/dev/null; } && s+="fastapi,"
    echo "${s%,}"
}

merge_precommit() {
    local repo="$1" baseline="$STD_ROOT/.pre-commit-config.yaml"
    local target="$repo/.pre-commit-config.yaml"
    local stacks; stacks="$(detect_pc_stacks "$repo")"
    if [[ ! -f "$target" ]]; then
        deploy_file "$baseline" "$target"
        $DRY_RUN || info "stacks=$stacks · trim non-applicable blocks from copied baseline"
        return
    fi
    if $CHECK; then
        if python3 "$SCRIPT_DIR/pre-commit-merge.py" "$baseline" "$target" --check --stacks "$stacks"; then
            ok "pre-commit §8 compliant (stacks=$stacks)"
        else
            warn "pre-commit drift (stacks=$stacks, see above)"
        fi
        return
    fi
    if $DRY_RUN; then
        python3 "$SCRIPT_DIR/pre-commit-merge.py" "$baseline" "$target" --check --stacks "$stacks" \
            && info "[dry-run] pre-commit already compliant (stacks=$stacks)" \
            || info "[dry-run] would merge missing baseline hooks (stacks=$stacks)"
        return
    fi
    python3 "$SCRIPT_DIR/pre-commit-merge.py" "$baseline" "$target" --stacks "$stacks" && ok "pre-commit merged (stacks=$stacks)"
}

apply_one() {
    local repo="$1" name; name="${REPO_NAME:-$(basename "$repo")}"
    [[ -d "$repo" ]]      || { err "$repo absent"; return 2; }
    [[ -d "$repo/.git" ]] || { warn "$name: not a git repo · skip"; return 0; }
    log "═══ $name ═══"
    if $CHECK; then merge_precommit "$repo"; return 0; fi
    deploy_hygiene "$repo"
    deploy_release_tooling "$repo"
    deploy_governance "$repo"
    if $NO_CI; then info "ci.yml · skipped (--no-ci)"; else deploy_stack_ci "$repo"; fi
    merge_precommit "$repo"
    local proc="$SCRIPT_DIR/apply-ci-process.sh"
    if [[ -x "$proc" || -f "$proc" ]]; then
        local flags=""; $DRY_RUN && flags="--dry-run"
        bash "$proc" $flags "$repo" || warn "apply-ci-process returned non-zero"
    else
        warn "apply-ci-process.sh missing · process layer skipped"
    fi
}

apply_all() {
    log "Mode --all · status:dev repos from repos.yml"
    local name st
    awk '$1=="-" && $2=="name:"{n=$3} $1=="status:"{print n, $2}' "$REPOS_YML" \
    | while read -r name st; do
        [[ "$st" == "dev" ]] || { info "skip $name ($st)"; continue; }
        apply_one "$CHRYSA_ROOT/$name"
    done
}

if $TARGET_ALL; then
    apply_all
elif [[ -n "$TARGET_REPO" ]]; then
    apply_one "$TARGET_REPO"
else
    err "Usage: $0 [--all | <repo_path>] [--dry-run] [--check]"
    exit 1
fi
