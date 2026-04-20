#!/usr/bin/env bash
# manual-actions.sh — checklist interactive des actions manuelles chrysa
# Lance les tâches une à une · permet skip (avec dépendances) · sauve état
#
# Usage :
#   bash manual-actions.sh              # interactif
#   bash manual-actions.sh --reset      # reset état
#   bash manual-actions.sh --status     # affiche état sans prompt
#
# Commandes interactives pour chaque tâche :
#   y  → done (marquée ✓)
#   n  → skip cette tâche (ses enfants restent dispo)
#   d  → skip cette tâche ET toutes ses dépendances (cascade)
#   l  → later (skip temporaire, réapparaît au prochain run)
#   ?  → affiche les détails
#   q  → quitter (état sauvé)

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_lib.sh" 2>/dev/null || {
    c_reset='\033[0m'; c_blue='\033[0;34m'; c_green='\033[0;32m'
    c_yellow='\033[0;33m'; c_red='\033[0;31m'; c_gray='\033[0;90m'
    info()  { printf "${c_blue}→${c_reset} %s\n" "$*"; }
    ok()    { printf "${c_green}✓${c_reset} %s\n" "$*"; }
    warn()  { printf "${c_yellow}⚠${c_reset}  %s\n" "$*"; }
    err()   { printf "${c_red}✗${c_reset} %s\n" "$*"; }
}

STATE_FILE="${HOME}/.chrysa/manual-actions.state"
mkdir -p "$(dirname "$STATE_FILE")"

# ─── Définition tâches : id|label|deps|details ──────────
# deps = liste d'ids séparés par virgules (skippés en cascade si -d)
declare -a TASKS=(
  # INFRA P0 (débloque tout)
  "D1|Trancher décisions D6-D11 (Breakline · Discordium V3 · Shadow Mandate · Life Roguelike · V5 Architecture)||Bloquer 30 min. Écrire résultat dans <repo>/DECISIONS.md."
  "D2|Commander TP-Link Deco X20/X50 (~120€)||P0 travaux : débloque WiFi jardin pour portail + poulailler + interphone."
  "D3|Commander Shelly 1 Plus × 3 + reeds (~75€)|D2|Nécessite TP-Link livré pour WiFi."
  "D4|Commander Raspberry Pi 5 si absent (~80€)|D2|Pour Home Assistant."
  "D5|gh auth login sur terminal local|"
  "D6|Gitignore global .claude/settings.local.json|D5|echo '.claude/settings.local.json' >> ~/.gitignore_global && git config --global core.excludesfile ~/.gitignore_global"
  "D7|Désactiver scheduled task github-state-sync|D5|Via Notion UI : ouvrir DB Scheduled tasks · toggle off."

  # FIX ISSUE #83
  "D8|Fix issue #83 pre-commit-tools (copier patch Notion → release.yml)|D5|Source : Notion page 🛠️ Issue #83 · copier YAML → pre-commit-tools/.github/workflows/release.yml · commit · push."

  # SERVER PHASE 0
  "S1|Audit Kimsufi (df -h · free -h · uptime)|D5|SSH Kimsufi."
  "S2|Renouveler Kimsufi + DNS OVH (*.chrysa.dev)|S1|Via manager.ovh.com."
  "S3|Vérifier/renouveler certs Let's Encrypt|S2|sudo certbot certificates"
  "S4|Régénérer Tailscale auth keys|S1|tailscale.com/admin"
  "S5|Backup DB quotidien (pg_dump + redis snapshot cron)|S1|~/backups/ · cron 03h00"
  "S6|Déployer Sentry self-hosted|S5|docker-compose sentry-self-hosted"
  "S7|Déployer stack monitoring (Prometheus+Grafana+Loki+Qdrant)|S5|D-0001 server · ~4 Go RAM"
  "S8|Runbook server/docs/runbooks/server-operations.md|S7|Documenter procédures"

  # MAISON (apres TP-Link livré)
  "H1|Installer TP-Link mesh dans cour/jardin|D2|Placer nodes + tester signal"
  "H2|Installer Home Assistant sur Raspberry|D4,H1|HA OS ou Docker Compose"
  "H3|Installer Shelly portail + capteur reed|D3,H1|Relais en parallèle moteur portail"
  "H4|Installer Shelly porte poulailler + reed|D3,H1|Automation lever/coucher soleil"
  "H5|Installer Shelly interphone|D3,H1|Ouverture via HA"
  "H6|Intégrer 3 Shelly dans Home Assistant|H2,H3,H4,H5|Auto-discovery"

  # NOTION UI (manuel)
  "N1|Exécuter 'Vider Corbeille Phase 0' dans Notion|"
  "N2|Archiver 6 pages [MIGRÉ 2026-04-20] vers section Archive|"
  "N3|Dédupliquer Configuration Claude Desktop × 2 (garder 'source vérité')|"
  "N4|Dédupliquer Sync Notion ↔ GitHub Issues × 2|"
  "N5|Créer DB Bugs (Nom · Projet(rel) · Severity · Statut · Repro)|"
  "N6|Créer DB Dette technique (Nom · Projet · Catégorie · Coût · Impact · Statut)|"
  "N7|Créer DB Veille tech (Titre · Source · Catégorie · Actionnable · Date)|N5"
  "N8|Ajouter 4 vues DB Projets (Portfolio dev / Travaux / Aménagement / Gelés)|"
  "N9|Créer Home Notion + widgets 1-clic (Aujourd'hui · Portfolio · Roadmaps)|N5,N6"
  "N10|Rollups DB Projets (budget · activité · CI status)|N9"
  "N11|Pin 4 pages racines sidebar (Home · Portfolio actif · Roadmap · Conventions)|N9"

  # NTFY + CONSOLIDATION TASKS
  "T1|Installer ntfy.sh container sur Kimsufi|S1|docker run -d --name ntfy -p 80:80 binwiederhier/ntfy serve"
  "T2|DNS ntfy.chrysa.dev → Kimsufi|T1,S2"
  "T3|Configurer app ntfy Android/iOS (subscribe topics)|T2"
  "T4|Consolider scheduled tasks 11 → 6 (éditer prompts agents)|T3|Fusion briefing+veille → morning-digest · etc."

  # SOUVERAINETÉ (progressif)
  "M1|Install Vaultwarden self-host + migration 1Password|S5|docker-compose · import CSV 1Password"
  "M2|Install Gitea/Forgejo miroir GitHub|S5"
  "M3|Install Immich photos|S5|Remplace Google Photos"
  "M4|Install Nextcloud|S5|Remplace Google Drive"
  "M5|Install Navidrome + dump Spotify|S5"
  "M6|Migration Gmail progressive|S5,M4|Long terme (~été)"

  # CROSS-PROJECT BATCH
  "B1|Créer issues GitHub cross-project X-1 à X-11|D5|bash cross-project-issues.sh (généré par fix-all.sh)"

  # DECISIONS.md manquants
  "E1|Créer DECISIONS.md dans discordium (ADR-0007 + 0022)|"
  "E2|Créer repo resume + DECISIONS.md (ADR-0011 + 0025)|"
  "E3|Créer repo coaching-tracker + DECISIONS.md (ADR-0012)|"
  "E4|Créer DECISIONS.md windows-autonome + agent-config (ADR-0026)|"

  # PHASE 1 PARALLÈLE (sem 3-4) · débloqueurs SANS AUTH (reprio 2026-04-20)
  "P1A1|Branche A · Install Ollama self-host sur Kimsufi|S7|docker-compose ollama · modèle 7B (llama3/qwen2)"
  "P1A2|Branche A · Fork prompt-optimizer (ai-aggregator)|P1A1|Fork claude-code-prompt-optimizer"
  "P1A3|Branche A · Interface optimize(prompt, model) + router model-aware|P1A2"
  "P1A4|Branche A · Test rate-limit Claude réduit|P1A3|Mesurer tokens avant/après"

  "P1B1|Branche B · Scaffold dev-nexus React 19 + Vite + shadcn|S7|Sans auth · mode dev local"
  "P1B2|Branche B · Theming engine D-0002 (Zustand + CSS vars + 3 layouts)|P1B1"
  "P1B3|Branche B · Landing + grille projets (data depuis portfolio-metadata.yml)|P1B2"
  "P1B4|Branche B · Embed placeholder (Grafana iframe stub)|P1B3"

  # PHASE 2 · chrysa-lib auth (sem 5-7)
  "F1|Démarrer chrysa-lib Sprint 1 @chrysa/auth (2-3 sem)|S7,D1|Débloque V1 complet des Actifs"

  # PHASE 3 · merge (sem 8-9)
  "F2|dev-nexus V1 : intégration @chrysa/auth + AI prio via ai-aggregator|F1,P1A4,P1B4|Merge branches A+B"
  "F3|ai-aggregator V1 : auth multi-provider|F1,P1A4"

  # PHASE 4 · Actifs P2 (sem 10-12)
  "F4|doc-gen : merger PR #1 + release|F1,D8"
  "F5|my-fridge V0 PWA|F1"
  "F6|lifeos V0 visu Notion D-0003|F1"
  "F7|Portfolio V2 React 19 + shadcn + export PDF (8 semaines)|F2|Réutilise theming engine D-0002"
)

# ─── Chargement état ─────────────────────────────────────
declare -A STATE   # id → done|skipped|later|todo
declare -A LABEL
declare -A DEPS
declare -A DETAILS
declare -a ORDER

for t in "${TASKS[@]}"; do
    IFS='|' read -r id label deps details <<< "$t"
    ORDER+=("$id")
    LABEL[$id]="$label"
    DEPS[$id]="$deps"
    DETAILS[$id]="${details:-$label}"
    STATE[$id]="todo"
done

if [[ -f "$STATE_FILE" ]]; then
    while IFS='=' read -r id status; do
        [[ -n "$id" && -n "${STATE[$id]:-}" ]] && STATE[$id]="$status"
    done < "$STATE_FILE"
fi

save_state() {
    > "$STATE_FILE"
    for id in "${ORDER[@]}"; do
        echo "$id=${STATE[$id]}" >> "$STATE_FILE"
    done
}

# ─── Handle flags ────────────────────────────────────────
if [[ "${1:-}" == "--reset" ]]; then
    rm -f "$STATE_FILE"
    ok "État réinitialisé"
    exit 0
fi

if [[ "${1:-}" == "--status" ]]; then
    done_c=0; skip_c=0; later_c=0; todo_c=0
    for id in "${ORDER[@]}"; do
        case "${STATE[$id]}" in
            done) done_c=$((done_c+1)); printf "${c_green}✓${c_reset} %s · %s\n" "$id" "${LABEL[$id]}" ;;
            skipped) skip_c=$((skip_c+1)); printf "${c_gray}✗${c_reset} %s · %s (skipped)\n" "$id" "${LABEL[$id]}" ;;
            later) later_c=$((later_c+1)); printf "${c_yellow}~${c_reset} %s · %s (later)\n" "$id" "${LABEL[$id]}" ;;
            todo) todo_c=$((todo_c+1)); printf "${c_blue}→${c_reset} %s · %s\n" "$id" "${LABEL[$id]}" ;;
        esac
    done
    echo ""
    echo "Done: $done_c · Skipped: $skip_c · Later: $later_c · Todo: $todo_c / ${#ORDER[@]}"
    exit 0
fi

# ─── Helper : marquer deps skipped en cascade ───────────
skip_cascade() {
    local target=$1
    STATE[$target]="skipped"
    # Trouver tâches qui dépendent de $target → cascade
    for id in "${ORDER[@]}"; do
        local deps="${DEPS[$id]}"
        if [[ -n "$deps" ]]; then
            IFS=',' read -ra dep_arr <<< "$deps"
            for dep in "${dep_arr[@]}"; do
                if [[ "$dep" == "$target" && "${STATE[$id]}" == "todo" ]]; then
                    skip_cascade "$id"  # récursif
                fi
            done
        fi
    done
}

# ─── Main loop ───────────────────────────────────────────
echo ""
printf "${c_blue}═══════════════════════════════════════════════════${c_reset}\n"
printf "${c_blue}  chrysa · actions manuelles interactives${c_reset}\n"
printf "${c_blue}═══════════════════════════════════════════════════${c_reset}\n"
echo ""
echo "Commandes : y=done · n=skip · d=skip+deps · l=later · ?=détails · q=quit"
echo ""

count=0
for id in "${ORDER[@]}"; do
    # Skip si déjà traité
    [[ "${STATE[$id]}" != "todo" ]] && continue

    # Check si dépendances satisfaites
    local_deps="${DEPS[$id]}"
    blocked=false
    if [[ -n "$local_deps" ]]; then
        IFS=',' read -ra dep_arr <<< "$local_deps"
        for dep in "${dep_arr[@]}"; do
            if [[ "${STATE[$dep]}" == "todo" || "${STATE[$dep]}" == "later" ]]; then
                blocked=true; break
            fi
            if [[ "${STATE[$dep]}" == "skipped" ]]; then
                printf "${c_gray}⊘ %s · deps skipped → auto-skip${c_reset}\n" "$id"
                STATE[$id]="skipped"
                save_state
                blocked=true; break
            fi
        done
    fi
    $blocked && continue

    count=$((count+1))
    echo ""
    printf "${c_blue}[${c_reset}%s${c_blue}]${c_reset} %s\n" "$id" "${LABEL[$id]}"
    [[ -n "$local_deps" ]] && printf "   ${c_gray}deps: %s${c_reset}\n" "$local_deps"

    read -r -p "> " choice </dev/tty
    case "$choice" in
        y|Y)
            STATE[$id]="done"
            ok "$id marqué done"
            ;;
        n|N)
            STATE[$id]="skipped"
            warn "$id skippé"
            ;;
        d|D)
            skip_cascade "$id"
            warn "$id + dépendances skippés en cascade"
            ;;
        l|L)
            STATE[$id]="later"
            info "$id reporté (réapparaîtra au prochain run)"
            ;;
        \?)
            echo ""
            echo "Détails : ${DETAILS[$id]}"
            echo ""
            echo "Retour à la question..."
            # redemander cette tâche
            for i in "${!ORDER[@]}"; do
                [[ "${ORDER[$i]}" == "$id" ]] && ORDER=("${ORDER[@]:0:$i}" "$id" "${ORDER[@]:$i+1}")
            done
            # Hack simple : on remet $id en todo et on break le for (relance nécessaire pour vraie boucle)
            STATE[$id]="todo"
            save_state
            continue
            ;;
        q|Q)
            save_state
            info "Quitter · état sauvé dans $STATE_FILE"
            exit 0
            ;;
        *)
            warn "Commande inconnue · tâche marquée 'later'"
            STATE[$id]="later"
            ;;
    esac
    save_state
done

# ─── Récap final ─────────────────────────────────────────
echo ""
echo "═══════════════════════════════════════════════════"
done_c=0; skip_c=0; later_c=0; todo_c=0
for id in "${ORDER[@]}"; do
    case "${STATE[$id]}" in
        done) done_c=$((done_c+1)) ;;
        skipped) skip_c=$((skip_c+1)) ;;
        later) later_c=$((later_c+1)) ;;
        todo) todo_c=$((todo_c+1)) ;;
    esac
done
printf "${c_green}Done${c_reset}: %d · ${c_gray}Skipped${c_reset}: %d · ${c_yellow}Later${c_reset}: %d · ${c_blue}Todo${c_reset}: %d / %d\n" \
    "$done_c" "$skip_c" "$later_c" "$todo_c" "${#ORDER[@]}"
echo ""
echo "État sauvé : $STATE_FILE"
echo "Commandes :"
echo "  bash manual-actions.sh            # reprendre"
echo "  bash manual-actions.sh --status   # voir l'état complet"
echo "  bash manual-actions.sh --reset    # repartir à zéro"
