#!/usr/bin/env bash
# chrysa-init.sh — installer interactif pour nouveau repo ou repo existant
# Installe les standards chrysa (templates + workflows + hooks) en mode question/réponse
#
# Agnostique stack : détecte auto (Python/Node/Go/Rust) et adapte les templates appliqués.
# Non destructif : n'écrase pas les fichiers existants sans confirmation.
#
# Usage (dans un nouveau repo) :
#   curl -sSL https://raw.githubusercontent.com/chrysa/shared-standards/main/scripts/chrysa-init.sh | bash
#
# Usage (repo existant local) :
#   bash ~/Documents/perso/projects/chrysa/shared-standards/scripts/chrysa-init.sh

set -uo pipefail

CHRYSA_ROOT="${CHRYSA_ROOT:-/home/anthony/Documents/perso/projects/chrysa}"
TEMPLATES="$CHRYSA_ROOT/shared-standards/templates"
CURRENT_DIR="$(pwd)"

# Lib commune (couleurs + info/ok/warn/err + ask_yn/ask_choice/ask_string + confirm)
SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"
source "$SCRIPT_DIR/_lib.sh" || { echo "❌ _lib.sh introuvable"; exit 1; }

banner() {
    echo -e "${c_cyan}"
    cat <<'BANNER'
╔═══════════════════════════════════════════════╗
║     chrysa-init · installer interactif        ║
║     Standards dev · CI · hooks · docs         ║
╚═══════════════════════════════════════════════╝
BANNER
    echo -e "${c_reset}"
}

# ─── Détection contexte ──────────────────────────────
banner
info "Répertoire cible : $CURRENT_DIR"
echo ""

# Git init si nécessaire
if [[ ! -d ".git" ]]; then
    if ask_yn "Ce dossier n'est pas un repo git. Initialiser avec 'git init' ?" y; then
        git init -b main
        ok "git init OK"
    else
        err "Abandon · lancer chrysa-init dans un repo git"
        exit 1
    fi
fi

# Stack
DETECTED_STACK="unknown"
[[ -f "pyproject.toml" || -f "setup.py" || -f "requirements.txt" ]] && DETECTED_STACK="python"
[[ -f "package.json" ]] && DETECTED_STACK="node"
[[ -f "go.mod" ]] && DETECTED_STACK="go"
[[ -f "Cargo.toml" ]] && DETECTED_STACK="rust"

if [[ "$DETECTED_STACK" == "unknown" ]]; then
    STACK=$(ask_choice "Stack principale du projet ?" python node go rust mixed skip)
else
    info "Stack détectée : $DETECTED_STACK"
    if ask_yn "Confirmer ?" y; then
        STACK=$DETECTED_STACK
    else
        STACK=$(ask_choice "Stack à utiliser ?" python node go rust mixed skip)
    fi
fi

# Métadonnées projet
echo ""
info "Métadonnées projet"
REPO_NAME=$(ask_string "Nom du repo" "$(basename "$CURRENT_DIR")")
PURPOSE=$(ask_string "Rôle en 1 ligne" "TODO: décrire")
ROLE=$(ask_choice "Rôle dans le portefeuille ?" "Socle" "Actif" "Opportuniste" "Gelé" "Vision")

# ─── Application des templates ───────────────────────
echo ""
info "Installation des templates chrysa"

apply() {
    local src=$1 dst=$2 label=$3
    if [[ ! -f "$src" ]]; then
        warn "$label : template source absent · skip"
        return
    fi
    mkdir -p "$(dirname "$dst")"
    if [[ -f "$dst" ]]; then
        if ask_yn "$label existe déjà, écraser ?" n; then
            cp "$src" "$dst"; ok "$label écrasé"
        else
            info "$label conservé"
        fi
    else
        cp "$src" "$dst"; ok "$label créé"
    fi
}

# Communs
apply "$TEMPLATES/GitVersion.yml"                "GitVersion.yml"                        "GitVersion.yml"
# gitignore adapté au stack (patch plus bas selon STACK)

# Docs
apply "$TEMPLATES/docs/README.template.md"       "README.md"                             "README.md"
apply "$TEMPLATES/docs/CLAUDE.template.md"       "CLAUDE.md"                             "CLAUDE.md"
apply "$TEMPLATES/docs/DECISIONS.template.md"    "DECISIONS.md"                          "DECISIONS.md"
apply "$TEMPLATES/docs/ROADMAP.template.md"      "ROADMAP.md"                            "ROADMAP.md"
apply "$TEMPLATES/docs/ARCHITECTURE.template.md" "docs/ARCHITECTURE.md"                  "ARCHITECTURE.md"

# GitHub files
apply "$TEMPLATES/dependabot.yml"                ".github/dependabot.yml"                "dependabot.yml"
apply "$TEMPLATES/CODEOWNERS"                    ".github/CODEOWNERS"                    "CODEOWNERS"
apply "$TEMPLATES/pr-template.md"                ".github/pull_request_template.md"      "PR template"
apply "$TEMPLATES/labeler.yml"                   ".github/labeler.yml"                   "labeler"
apply "$TEMPLATES/github-workflows/dependabot-auto-merge.yml" ".github/workflows/dependabot-auto-merge.yml" "dependabot-auto-merge workflow"
apply "$TEMPLATES/github-workflows/branch-auto-update.yml"    ".github/workflows/branch-auto-update.yml"    "branch-auto-update workflow"
apply "$TEMPLATES/github-workflows/enforce-issue-link.yml"    ".github/workflows/enforce-issue-link.yml"    "enforce-issue-link workflow"
apply "$TEMPLATES/github-workflows/_reusable-ci.yml"          ".github/workflows/_reusable-ci.yml"          "_reusable-ci workflow"
apply "$TEMPLATES/github-workflows/labeler.yml"               ".github/workflows/labeler.yml"               "labeler workflow"
apply "$TEMPLATES/github-workflows/sync-labels.yml"           ".github/workflows/sync-labels.yml"           "sync-labels workflow"
apply "$TEMPLATES/github-workflows/pr-size-label.yml"         ".github/workflows/pr-size-label.yml"         "pr-size-label workflow"
apply "$TEMPLATES/labels.yml"                                 ".github/labels.yml"                          "labels palette"

# .claude/ local hooks + config
apply "$TEMPLATES/claude/config.json"                         ".claude/config.json"                         "claude config"
apply "$TEMPLATES/claude/settings.json"                       ".claude/settings.json"                       "claude settings"
apply "$TEMPLATES/claude/secret-scanner-allowlist.json"       ".claude/secret-scanner-allowlist.json"       "claude secret-allowlist"
apply "$TEMPLATES/claude/rules/thresholds.md"                 ".claude/rules/thresholds.md"                 "claude thresholds"
apply "$TEMPLATES/claude/hooks/quality-check.sh"              ".claude/hooks/quality-check.sh"              "claude quality-hook"
for it in bug chore feature; do
    apply "$TEMPLATES/issue-templates/${it}.md" ".github/ISSUE_TEMPLATE/${it}.md" "issue-${it}"
done

# Stack-specific
case "$STACK" in
    python)
        apply "$TEMPLATES/gitignore/.gitignore.python"       ".gitignore"               ".gitignore (python)"
        apply "$TEMPLATES/pre-commit/python.yaml"            ".pre-commit-config.yaml" "pre-commit python"
        apply "$TEMPLATES/github-workflows/ci-python.yml"    ".github/workflows/ci.yml" "CI python"
        apply "$TEMPLATES/makefile/Makefile"                 "Makefile"                 "Makefile"
        apply "$TEMPLATES/makefile/quality.makefile"         "makefiles/quality.makefile" "quality.makefile"
        apply "$TEMPLATES/makefile/install.makefile"         "makefiles/install.makefile" "install.makefile"
        apply "$TEMPLATES/makefile/docker.makefile"          "makefiles/docker.makefile"  "docker.makefile"
        apply "$TEMPLATES/dockerfile/Dockerfile.python"      "Dockerfile"               "Dockerfile python"
        ;;
    node)
        apply "$TEMPLATES/gitignore/.gitignore.node"         ".gitignore"               ".gitignore (node)"
        apply "$TEMPLATES/pre-commit/node.yaml"              ".pre-commit-config.yaml" "pre-commit node"
        apply "$TEMPLATES/github-workflows/ci-node.yml"      ".github/workflows/ci.yml" "CI node"
        apply "$TEMPLATES/makefile/Makefile"                 "Makefile"                 "Makefile"
        apply "$TEMPLATES/makefile/quality.makefile"         "makefiles/quality.makefile" "quality.makefile"
        apply "$TEMPLATES/dockerfile/Dockerfile.node"        "Dockerfile"               "Dockerfile node"
        ;;
    go|rust|mixed|skip)
        warn "Stack '$STACK' : pas de template spécifique dans shared-standards · à ajouter manuellement"
        ;;
esac

# ─── Remplacement placeholders ───────────────────────
echo ""
info "Remplacement des placeholders {{…}}"
for f in README.md CLAUDE.md DECISIONS.md ROADMAP.md docs/ARCHITECTURE.md; do
    [[ -f "$f" ]] || continue
    sed -i.bak \
        -e "s|{{REPO_NAME}}|$REPO_NAME|g" \
        -e "s|{{ONE_LINE_DESCRIPTION}}|$PURPOSE|g" \
        -e "s|{{ONE_LINE_PURPOSE}}|$PURPOSE|g" \
        -e "s|{{STACK}}|$STACK|g" \
        -e "s|{{Socle \| Actif \| Opportuniste \| Gelé}}|$ROLE|g" \
        -e "s|{{Socle \| Actif \| Opportuniste \| Gelé \| Vision}}|$ROLE|g" \
        "$f" 2>/dev/null && rm -f "$f.bak"
done
ok "placeholders remplacés"

# ─── Pre-commit install ──────────────────────────────
if [[ -f ".pre-commit-config.yaml" ]] && command -v pre-commit &>/dev/null; then
    if ask_yn "Installer les hooks pre-commit maintenant ?" y; then
        pre-commit install
        ok "pre-commit installé"
    fi
fi

# ─── Bilan ───────────────────────────────────────────
echo ""
echo -e "${c_green}═══════════════════════════════════════${c_reset}"
echo -e "${c_green}  Setup terminé${c_reset}"
echo -e "${c_green}═══════════════════════════════════════${c_reset}"
echo ""
echo "Prochaines étapes :"
echo "  1. Éditer README.md et remplir les sections vides"
echo "  2. Créer ligne dans shared-standards/portfolio-metadata.yml (rôle/valeur/bloqueurs/budget)"
echo "  3. Créer page Notion projet (DB Projets) avec lien GitHub"
echo "  4. git add -A && git commit -m 'chore: bootstrap chrysa standards'"
echo "  5. gh repo create chrysa/$REPO_NAME --private --source=. --push"
echo ""
echo "Utilitaires :"
echo "  bash $CHRYSA_ROOT/shared-standards/scripts/dev-run.sh --list"
echo "  python3 $CHRYSA_ROOT/shared-standards/scripts/validate-prompt.py --pre-commit"
