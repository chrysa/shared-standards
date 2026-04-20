#!/usr/bin/env bash
# apply-standards.sh
# Applique les templates shared-standards/templates/ aux repos actifs
# Détecte le stack, choisit les bons templates, propose ajout/MAJ non destructif
#
# Usage :
#   bash apply-standards.sh                  # interactif sur tous les actifs
#   bash apply-standards.sh --repo=doc-gen   # cible un repo
#   bash apply-standards.sh --dry-run        # preview
#   bash apply-standards.sh --yes            # auto-confirm
#   bash apply-standards.sh --force          # overwrite même si fichier existe

set -uo pipefail

CHRYSA_ROOT="${CHRYSA_ROOT:-/home/anthony/Documents/perso/projects/chrysa}"
TEMPLATES="$CHRYSA_ROOT/shared-standards/templates"

DRY_RUN=false
AUTO_YES=false
FORCE=false
TARGET_REPO=""

for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN=true ;;
        --yes|-y) AUTO_YES=true ;;
        --force) FORCE=true ;;
        --repo=*) TARGET_REPO="${arg#--repo=}" ;;
        -h|--help)
            sed -n '2,11p' "$0" | sed 's/^# \{0,1\}//'
            exit 0
            ;;
        *) echo "⚠️  flag ignoré : $arg" ;;
    esac
done

# Lib commune (couleurs + info/ok/warn/err + confirm)
SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"
source "$SCRIPT_DIR/_lib.sh" || { echo "❌ _lib.sh introuvable"; exit 1; }
export AUTO_YES

# ─── Skip list ─────────────────────────────────────────────
# Repos à ne jamais standardiser (archives, tooling, etc.)
SKIP_REPOS=(
    _archived shared-standards
    42_save DJango-CustomeCommands
    linkendin-resume my-resume
    skills standards-updates
)

is_skipped() {
    local r=$1
    for s in "${SKIP_REPOS[@]}"; do [[ "$r" == "$s" ]] && return 0; done
    return 1
}

# ─── Détection stack ───────────────────────────────────────
detect_stack() {
    local repo=$1
    cd "$CHRYSA_ROOT/$repo" 2>/dev/null || { echo "unknown"; return; }
    if [[ -f "pyproject.toml" || -f "setup.py" || -f "requirements.txt" ]]; then
        echo "python"
    elif [[ -f "package.json" ]]; then
        echo "node"
    else
        echo "unknown"
    fi
}

# ─── Application d'un fichier ─────────────────────────────
apply_file() {
    local repo=$1
    local src=$2
    local dst=$3
    local label=$4
    local target="$CHRYSA_ROOT/$repo/$dst"

    if [[ ! -f "$src" ]]; then
        warn "template absent : $src"
        return 1
    fi

    mkdir -p "$(dirname "$target")"

    if [[ -f "$target" ]] && ! $FORCE; then
        echo "  ${c_gray}=${c_reset} $label déjà présent · skip (utilise --force pour écraser)"
        return 0
    fi

    if $DRY_RUN; then
        echo "  ${c_yellow}[DRY-RUN]${c_reset} copier $src → $target"
        return 0
    fi

    cp "$src" "$target"
    ok "$label appliqué"
}

append_file_if_absent() {
    local repo=$1
    local src=$2
    local dst=$3
    local label=$4
    local target="$CHRYSA_ROOT/$repo/$dst"

    if [[ ! -f "$target" ]]; then
        if $DRY_RUN; then
            echo "  ${c_yellow}[DRY-RUN]${c_reset} créer $target depuis $src"
        else
            cp "$src" "$target"
            ok "$label créé"
        fi
        return 0
    fi
    # Détecter si les lignes principales du template sont présentes
    local missing=0
    while IFS= read -r line; do
        [[ -z "$line" || "$line" =~ ^# ]] && continue
        if ! grep -qF "$line" "$target" 2>/dev/null; then
            missing=$((missing + 1))
        fi
    done < "$src"
    if [[ "$missing" -gt 5 ]]; then
        warn "$label : $missing lignes template absentes dans $dst · envisage merge manuel"
    else
        ok "$label : déjà aligné"
    fi
}

# ─── Traitement d'un repo ──────────────────────────────────
process_repo() {
    local repo=$1
    is_skipped "$repo" && { echo "${c_gray}⊘ $repo · skip-list${c_reset}"; return; }
    [[ ! -d "$CHRYSA_ROOT/$repo/.git" ]] && { warn "$repo · pas un git repo · skip"; return; }

    local stack
    stack=$(detect_stack "$repo")
    echo ""
    echo -e "${c_blue}══ $repo ($stack) ══${c_reset}"

    if [[ "$stack" == "unknown" ]]; then
        warn "stack indétecté · skip templates spécifiques"
    fi

    # Fichiers communs
    apply_file "$repo" "$TEMPLATES/GitVersion.yml" "GitVersion.yml" "GitVersion"
    apply_file "$repo" "$TEMPLATES/docs/README.template.md" "README.md" "README"
    apply_file "$repo" "$TEMPLATES/docs/CLAUDE.template.md" "CLAUDE.md" "CLAUDE.md"
    apply_file "$repo" "$TEMPLATES/docs/DECISIONS.template.md" "DECISIONS.md" "DECISIONS.md"
    apply_file "$repo" "$TEMPLATES/docs/ROADMAP.template.md" "ROADMAP.md" "ROADMAP.md"
    apply_file "$repo" "$TEMPLATES/docs/ARCHITECTURE.template.md" "docs/ARCHITECTURE.md" "ARCHITECTURE.md"
    # gitignore selon stack (dossier gitignore/.gitignore.{python,node})
    case "$stack" in
        python) append_file_if_absent "$repo" "$TEMPLATES/gitignore/.gitignore.python" ".gitignore" ".gitignore (python)" ;;
        node)   append_file_if_absent "$repo" "$TEMPLATES/gitignore/.gitignore.node" ".gitignore" ".gitignore (node)" ;;
    esac

    # Workflow CI réutilisable (partagé python + node) — appliqué pour les 2 stacks
    apply_file "$repo" "$TEMPLATES/github-workflows/_reusable-ci.yml" ".github/workflows/_reusable-ci.yml" "_reusable-ci (shared)"

    # Spécifique stack
    case "$stack" in
        python)
            apply_file "$repo" "$TEMPLATES/pre-commit/python.yaml" ".pre-commit-config.yaml" "pre-commit (python)"
            apply_file "$repo" "$TEMPLATES/github-workflows/ci-python.yml" ".github/workflows/ci.yml" "CI (python)"
            apply_file "$repo" "$TEMPLATES/makefile/Makefile" "Makefile" "Makefile (python)"
            # makefiles modulaires
            apply_file "$repo" "$TEMPLATES/makefile/quality.makefile" "makefiles/quality.makefile" "quality.makefile"
            apply_file "$repo" "$TEMPLATES/makefile/install.makefile" "makefiles/install.makefile" "install.makefile"
            apply_file "$repo" "$TEMPLATES/makefile/docker.makefile" "makefiles/docker.makefile" "docker.makefile"
            apply_file "$repo" "$TEMPLATES/dockerfile/Dockerfile.python" "Dockerfile" "Dockerfile (python)"
            ;;
        node)
            apply_file "$repo" "$TEMPLATES/pre-commit/node.yaml" ".pre-commit-config.yaml" "pre-commit (node)"
            apply_file "$repo" "$TEMPLATES/github-workflows/ci-node.yml" ".github/workflows/ci.yml" "CI (node)"
            apply_file "$repo" "$TEMPLATES/makefile/Makefile" "Makefile" "Makefile (node)"
            apply_file "$repo" "$TEMPLATES/makefile/quality.makefile" "makefiles/quality.makefile" "quality.makefile"
            apply_file "$repo" "$TEMPLATES/makefile/install.makefile" "makefiles/install.makefile" "install.makefile"
            apply_file "$repo" "$TEMPLATES/makefile/docker.makefile" "makefiles/docker.makefile" "docker.makefile"
            apply_file "$repo" "$TEMPLATES/dockerfile/Dockerfile.node" "Dockerfile" "Dockerfile (node)"
            ;;
    esac

    # Fichiers GitHub transverses
    apply_file "$repo" "$TEMPLATES/dependabot.yml" ".github/dependabot.yml" "dependabot"
    apply_file "$repo" "$TEMPLATES/CODEOWNERS" ".github/CODEOWNERS" "CODEOWNERS"
    apply_file "$repo" "$TEMPLATES/pr-template.md" ".github/pull_request_template.md" "PR template"
    apply_file "$repo" "$TEMPLATES/labeler.yml" ".github/labeler.yml" "labeler rules"
    apply_file "$repo" "$TEMPLATES/labels.yml" ".github/labels.yml" "labels palette"

    # Workflows transverses
    apply_file "$repo" "$TEMPLATES/github-workflows/dependabot-auto-merge.yml" ".github/workflows/dependabot-auto-merge.yml" "dependabot-auto-merge"
    apply_file "$repo" "$TEMPLATES/github-workflows/branch-auto-update.yml" ".github/workflows/branch-auto-update.yml" "branch-auto-update"
    apply_file "$repo" "$TEMPLATES/github-workflows/enforce-issue-link.yml" ".github/workflows/enforce-issue-link.yml" "enforce-issue-link"
    apply_file "$repo" "$TEMPLATES/github-workflows/labeler.yml" ".github/workflows/labeler.yml" "labeler workflow"
    apply_file "$repo" "$TEMPLATES/github-workflows/sync-labels.yml" ".github/workflows/sync-labels.yml" "sync-labels workflow"
    apply_file "$repo" "$TEMPLATES/github-workflows/pr-size-label.yml" ".github/workflows/pr-size-label.yml" "pr-size-label workflow"

    # .claude/ hooks locaux
    apply_file "$repo" "$TEMPLATES/claude/config.json" ".claude/config.json" "claude config"
    apply_file "$repo" "$TEMPLATES/claude/settings.json" ".claude/settings.json" "claude settings"
    apply_file "$repo" "$TEMPLATES/claude/secret-scanner-allowlist.json" ".claude/secret-scanner-allowlist.json" "claude secret-allowlist"
    apply_file "$repo" "$TEMPLATES/claude/rules/thresholds.md" ".claude/rules/thresholds.md" "claude thresholds"
    apply_file "$repo" "$TEMPLATES/claude/hooks/quality-check.sh" ".claude/hooks/quality-check.sh" "claude quality-hook"

    # Script pre-commit standards-sync (copié localement pour que pre-commit puisse l'exécuter)
    apply_file "$repo" "$CHRYSA_ROOT/shared-standards/scripts/check-standards-sync.sh" "scripts/check-standards-sync.sh" "check-standards-sync"
    apply_file "$repo" "$CHRYSA_ROOT/shared-standards/scripts/_lib.sh" "scripts/_lib.sh" "_lib.sh"
    # Issue templates
    for it in bug chore feature; do
        apply_file "$repo" "$TEMPLATES/issue-templates/${it}.md" ".github/ISSUE_TEMPLATE/${it}.md" "issue ${it}"
    done
}

# ─── Main ──────────────────────────────────────────────────
cd "$CHRYSA_ROOT" || { err "CHRYSA_ROOT introuvable"; exit 1; }

if [[ ! -d "$TEMPLATES" ]]; then
    err "Templates introuvables : $TEMPLATES"
    exit 1
fi

echo -e "${c_blue}═══════════════════════════════════════${c_reset}"
echo -e "${c_blue}  apply-standards.sh · mode $($DRY_RUN && echo 'DRY-RUN' || echo 'LIVE')${c_reset}"
echo -e "${c_blue}═══════════════════════════════════════${c_reset}"

if [[ -n "$TARGET_REPO" ]]; then
    process_repo "$TARGET_REPO"
else
    for d in */; do
        d="${d%/}"
        process_repo "$d"
    done
fi

echo ""
ok "apply-standards terminé"
$DRY_RUN && warn "mode dry-run · aucune modif réelle" || true

exit 0
