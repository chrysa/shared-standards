#!/usr/bin/env bash
# fix-all.sh
# Master script · exécute séquentiellement tout ce qui est scriptable pour mettre le portefeuille chrysa en ordre
#
# Portée :
#   - Portfolio chrysa/ interne (inclut travaux + aménagement Notion, exclut padam)
#   - La vue externe (portfolio.html --external) filtre travaux/aménagement
#   - ADRs en vigueur : 0010, 0011/0025, 0024, 0026
#
# Ordre d'exécution (chaque étape demande confirmation) :
#   1. standardize-repo-settings.sh --all      Settings GitHub (visibility, topics, merge rules, branch protection best-effort)
#   2. repos-push-pending.sh                   Commit + push sur repos ACTIFS (skip archive targets)
#   3. archive-obsolete-repos.sh               Archive projets Gelés (auto-rollback dirty avant mv)
#   4. archive-merged-repos.sh                 Archive fusions (auto-rollback dirty avant mv)
#   5. cleanup-my-assistant-zombie.sh          Nettoyage ancien dossier my-assistant zombie
#   6. repos-pull-all.sh                       Pull tous les repos actifs
#   7. generate-portfolio-html.sh              Régénère portfolio.html (interne + version publique)
#
# IMPORTANT : lancer avec bash explicite pour éviter les soucis zsh (read -p, autocorrect)
#   bash ./fix-all.sh                 # interactif avec confirmations
#   bash ./fix-all.sh --dry-run       # simulation sans écriture
#   bash ./fix-all.sh --yes           # non-interactif (auto-confirm toutes les étapes)
#
# ⚠️  Prérequis :
#   - gh auth login (sinon étapes 1/2/3 échouent)
#   - CHRYSA_ROOT ou cwd = /home/anthony/Documents/perso/projects/chrysa

set -uo pipefail

# ─── Parse args ────────────────────────────────────────────
DRY_RUN=false
AUTO_YES=false
for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN=true ;;
        --yes|-y)  AUTO_YES=true ;;
        -h|--help)
            sed -n '2,22p' "$0" | sed 's/^# \{0,1\}//'
            exit 0
            ;;
        *) echo "❌ Flag inconnu : $arg"; exit 1 ;;
    esac
done

# ─── Paths + lib commune ────────────────────────────────────
CHRYSA_ROOT="${CHRYSA_ROOT:-/home/anthony/Documents/perso/projects/chrysa}"
SCRIPTS_DIR="$CHRYSA_ROOT/shared-standards/scripts"
source "$SCRIPTS_DIR/_lib.sh" || { echo "❌ _lib.sh introuvable"; exit 1; }

cd "$CHRYSA_ROOT" || { err "CHRYSA_ROOT introuvable : $CHRYSA_ROOT"; exit 1; }

# Propager AUTO_YES dans _lib.sh (confirm l'exploite)
export AUTO_YES

run_step() {
    local label=$1
    local script=$2
    shift 2
    local args=("$@")

    step "$label"

    if [[ ! -x "$SCRIPTS_DIR/$script" ]]; then
        if [[ -f "$SCRIPTS_DIR/$script" ]]; then
            warn "$script non exécutable, chmod +x..."
            chmod +x "$SCRIPTS_DIR/$script"
        else
            err "$script introuvable dans $SCRIPTS_DIR"
            return 1
        fi
    fi

    # Construit la commande pour affichage
    local cmd="bash $SCRIPTS_DIR/$script"
    $DRY_RUN && cmd="$cmd --dry-run"
    for a in "${args[@]}"; do cmd="$cmd $a"; done

    echo -e "${c_gray}Commande : $cmd${c_reset}"

    if confirm "Exécuter cette étape ?"; then
        if $DRY_RUN; then
            bash "$SCRIPTS_DIR/$script" --dry-run "${args[@]}" || warn "step returned non-zero (non-bloquant)"
        else
            bash "$SCRIPTS_DIR/$script" "${args[@]}" || warn "step returned non-zero (non-bloquant)"
        fi
        ok "Étape terminée"
    else
        warn "Étape ignorée"
    fi
}

# ─── Preflight ──────────────────────────────────────────────
step "Preflight checks"

# gh CLI
if ! command -v gh &>/dev/null; then
    err "gh CLI absent · installer : sudo apt install gh"
    exit 1
fi
if ! gh auth status &>/dev/null; then
    err "gh non authentifié · exécute : gh auth login"
    exit 1
fi
ok "gh CLI authentifié"

# Working dir
ok "CHRYSA_ROOT = $CHRYSA_ROOT"

# Git tree dirty check (avertissement seulement)
DIRTY=0
for d in */; do
    d="${d%/}"
    [[ "$d" == "_archived" ]] && continue
    [[ ! -d "$d/.git" ]] && continue
    changes=$(cd "$d" && git status --porcelain 2>/dev/null | wc -l)
    [[ "$changes" -gt 0 ]] && { DIRTY=$((DIRTY+1)); warn "$d : $changes fichiers modifiés (non committés)"; }
done
if [[ "$DIRTY" -gt 0 ]]; then
    warn "$DIRTY repos dirty — recommandé de committer ou stash avant de continuer"
    confirm "Continuer quand même ?" || { err "Abandon utilisateur"; exit 1; }
fi

# Mode summary
if $DRY_RUN; then
    warn "DRY-RUN activé · aucune écriture réelle"
fi
if $AUTO_YES; then
    warn "AUTO-YES activé · toutes les étapes seront confirmées automatiquement"
fi

# ─── Étapes ────────────────────────────────────────────────
run_step "1/7 · Standardize GitHub settings (all repos)" \
    standardize-repo-settings.sh --all

run_step "2/7 · Commit + push pending sur repos ACTIFS (skip archive targets)" \
    repos-push-pending.sh

run_step "3/7 · Archive obsolete repos (auto-rollback dirty)" \
    archive-obsolete-repos.sh

run_step "4/7 · Archive merged repos (ADR-0010, ADR-0011/0025 · ADR-0014 révoqué)" \
    archive-merged-repos.sh

run_step "5/7 · Cleanup my-assistant zombie folder" \
    cleanup-my-assistant-zombie.sh

run_step "6/7 · Pull all active repos" \
    repos-pull-all.sh

run_step "7a/10 · Regenerate portfolio.html (interne, tout inclus)" \
    generate-portfolio-html.sh

run_step "7b/10 · Regenerate portfolio-public.html (externe, filtré)" \
    generate-portfolio-html.sh --external

run_step "8/10 · Appliquer templates standards aux repos actifs" \
    apply-standards.sh --dry-run

run_step "9/10 · Générer rollup roadmap + graphe dépendances + index docs" \
    generate-roadmap-rollup.sh

run_step "10/10 · Graphe dépendances + index docs" \
    generate-deps-graph.sh

# ─── Summary ───────────────────────────────────────────────
step "✅ fix-all terminé"

cat <<EOF

Récapitulatif :
  - Settings GitHub standardisés (hors 403 GitHub Free)
  - Repos obsolètes archivés
  - Fusions ADRs appliquées (hors ADR-0014 révoqué par ADR-0026)
  - Dossier zombie my-assistant nettoyé
  - Repos synchronisés (pull)
  - portfolio.html régénéré

📌 Actions NON scriptables restantes :
   Voir shared-standards/docs/remaining-manual-actions.md

EOF
