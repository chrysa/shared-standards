#!/usr/bin/env bash
# debian-gui-apps-autoupdate.sh · automatise les mises à jour de VS Code, Docker Desktop, GitKraken
# Source : chrysa/shared-standards/scripts/
#
# Stratégie :
#   · VS Code        → apt repo Microsoft + unattended-upgrades (auto hebdo)
#   · Docker Desktop → apt repo Docker + unattended-upgrades (auto hebdo)
#   · GitKraken      → pas d'apt repo officiel · systemd timer custom (check version + download .deb)
#
# ⚠️ RAPPEL CLAUDE.md § Alertes :
#   · GitKraken est flaggé en remplacement par lazygit
#   · Docker Desktop est flaggé en migration vers Docker Engine
#   Ce script automatise les updates en PHASE TRANSITOIRE uniquement.
#
# Usage :
#   sudo bash debian-gui-apps-autoupdate.sh              # setup complet (tous les 3)
#   sudo bash debian-gui-apps-autoupdate.sh --only=vscode
#   sudo bash debian-gui-apps-autoupdate.sh --only=docker
#   sudo bash debian-gui-apps-autoupdate.sh --only=gitkraken
#   sudo bash debian-gui-apps-autoupdate.sh --dry-run
#   sudo bash debian-gui-apps-autoupdate.sh --disable    # retire les automatisations
#
# Exit : 0 OK · 1 erreur · 2 prérequis

set -uo pipefail

ONLY=""
DRY_RUN=false
DISABLE=false

for arg in "$@"; do
    case "$arg" in
        --only=*) ONLY="${arg#--only=}" ;;
        --dry-run) DRY_RUN=true ;;
        --disable) DISABLE=true ;;
        -h|--help) sed -n '2,22p' "$0" | sed 's/^# \?//'; exit 0 ;;
    esac
done

log()  { echo "[$(date +%H:%M:%S)] $*"; }
ok()   { echo -e "  \033[32m✓\033[0m $*"; }
warn() { echo -e "  \033[33m⚠\033[0m $*" >&2; }
err()  { echo -e "  \033[31m✗\033[0m $*" >&2; }
info() { echo -e "  \033[34m→\033[0m $*"; }

run() {
    if $DRY_RUN; then
        info "[dry-run] $*"
    else
        eval "$@"
    fi
}

should_run() { [[ -z "$ONLY" || "$ONLY" == "$1" ]]; }

# ─── Prérequis ───────────────────────────────────────
if [[ $EUID -ne 0 ]] && ! $DRY_RUN; then err "Nécessite sudo (--dry-run OK en user)"; exit 2; fi
for cmd in apt-get curl gpg; do
    command -v "$cmd" &>/dev/null || { err "$cmd requis"; exit 2; }
done

# ═══ DISABLE mode ═══
if $DISABLE; then
    log "Mode --disable · retire les automatisations"
    run "systemctl disable --now gitkraken-update.timer 2>/dev/null || true"
    run "rm -f /etc/systemd/system/gitkraken-update.service /etc/systemd/system/gitkraken-update.timer"
    run "rm -f /usr/local/bin/gitkraken-update.sh"
    run "sed -i '/^Unattended-Upgrade::Allowed-Origins.*chrysa-gui/d' /etc/apt/apt.conf.d/50unattended-upgrades 2>/dev/null || true"
    ok "Automatisations retirées (repos apt conservés · utilise apt remove pour les désinstaller complètement)"
    exit 0
fi

# ═══ VS Code ═══
if should_run "vscode"; then
    log "═══ 1. VS Code · apt repo Microsoft + unattended-upgrades ═══"

    if ! [[ -f /etc/apt/sources.list.d/vscode.list ]]; then
        info "Ajout repo Microsoft…"
        run "install -d -m 0755 /etc/apt/keyrings"
        run "curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor -o /etc/apt/keyrings/packages.microsoft.gpg"
        run "echo 'deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main' > /etc/apt/sources.list.d/vscode.list"
        run "apt-get update -y"
    else
        ok "Repo Microsoft déjà présent"
    fi

    if ! dpkg -l code 2>/dev/null | grep -q '^ii'; then
        info "Installation VS Code…"
        run "apt-get install -y code"
    else
        ok "VS Code déjà installé"
    fi
fi

# ═══ Docker Desktop ═══
if should_run "docker"; then
    log "═══ 2. Docker Desktop · apt repo Docker + unattended-upgrades ═══"
    warn "Rappel : Docker Desktop = ~156€/an · migration Docker Engine recommandée (voir CLAUDE.md alertes)"

    if ! [[ -f /etc/apt/sources.list.d/docker.list ]]; then
        info "Ajout repo Docker (pour Engine ET Desktop)…"
        run "install -d -m 0755 /etc/apt/keyrings"
        run "curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg"
        run "chmod a+r /etc/apt/keyrings/docker.gpg"
        # Auto-detect codename
        CODENAME=$(lsb_release -cs 2>/dev/null || echo "bookworm")
        run "echo 'deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian $CODENAME stable' > /etc/apt/sources.list.d/docker.list"
        run "apt-get update -y"
    else
        ok "Repo Docker déjà présent"
    fi

    if ! dpkg -l docker-desktop 2>/dev/null | grep -q '^ii'; then
        warn "Docker Desktop n'est pas installé via apt · télécharge manuellement le .deb : https://docs.docker.com/desktop/install/debian/"
        info "Une fois le .deb installé, ce script configure les updates auto au prochain run."
    else
        ok "Docker Desktop déjà installé"
    fi
fi

# ═══ Unattended-upgrades pour VS Code + Docker ═══
if should_run "vscode" || should_run "docker"; then
    log "═══ 3. Config unattended-upgrades (auto weekly) ═══"

    if ! dpkg -l unattended-upgrades 2>/dev/null | grep -q '^ii'; then
        run "apt-get install -y unattended-upgrades apt-listchanges"
    fi

    CONF=/etc/apt/apt.conf.d/50unattended-upgrades
    if ! grep -q 'chrysa-gui' "$CONF" 2>/dev/null; then
        info "Ajout des origines GUI à unattended-upgrades…"
        run "cp $CONF ${CONF}.bak-\$(date +%Y%m%d)"
        # Ajoute après la dernière ligne Allowed-Origins (avant le }; de fermeture)
        run "sed -i '/^Unattended-Upgrade::Allowed-Origins/,/^};/{
            /^};/i\\    \"Microsoft:stable\";  // chrysa-gui (VS Code)\\
    \"Docker:stable\";     // chrysa-gui (Docker Desktop/Engine)
        }' $CONF"
    else
        ok "Origins chrysa-gui déjà configurées dans $CONF"
    fi

    # Active le timer systemd apt-daily-upgrade si désactivé
    run "systemctl enable --now apt-daily-upgrade.timer"
    ok "Unattended-upgrades armé (check daily · upgrade si Allowed-Origins match)"
fi

# ═══ GitKraken · systemd timer custom ═══
if should_run "gitkraken"; then
    log "═══ 4. GitKraken · systemd timer custom (pas d'apt repo officiel) ═══"
    warn "Rappel : GitKraken deadline 14/04 · lazygit recommandé (voir CLAUDE.md alertes)"

    # Script de mise à jour (check version puis download .deb si nouvelle)
    UPDATE_SCRIPT=/usr/local/bin/gitkraken-update.sh
    if $DRY_RUN; then
        info "[dry-run] Créerait $UPDATE_SCRIPT"
    else
        cat > "$UPDATE_SCRIPT" <<'GKEOF'
#!/usr/bin/env bash
# gitkraken-update.sh · check + install dernière version GitKraken
# Déployé par debian-gui-apps-autoupdate.sh
set -uo pipefail

URL="https://release.gitkraken.com/linux/gitkraken-amd64.deb"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
DEB="$TMP/gitkraken.deb"

# Version installée (si présente)
CURRENT=$(dpkg-query -W -f='${Version}' gitkraken 2>/dev/null || echo "none")

# Download .deb (GitKraken publie uniquement latest · pas d'API version)
curl -sfL -o "$DEB" "$URL" || { echo "[gitkraken-update] download fail"; exit 1; }
[[ -s "$DEB" ]] || { echo "[gitkraken-update] empty deb"; exit 1; }

# Extract version du .deb
NEW=$(dpkg-deb -f "$DEB" Version 2>/dev/null || echo "unknown")

if [[ "$CURRENT" == "$NEW" ]]; then
    echo "[gitkraken-update] $(date -Iseconds) · déjà à jour ($CURRENT)"
    exit 0
fi

echo "[gitkraken-update] $(date -Iseconds) · upgrade $CURRENT → $NEW"
DEBIAN_FRONTEND=noninteractive apt-get install -y "$DEB" || {
    dpkg -i "$DEB" || { echo "[gitkraken-update] install fail"; exit 1; }
    apt-get install -y -f
}
echo "[gitkraken-update] OK · now $NEW"
GKEOF
        chmod +x "$UPDATE_SCRIPT"
        ok "Script créé : $UPDATE_SCRIPT"
    fi

    # Service + timer systemd
    SERVICE=/etc/systemd/system/gitkraken-update.service
    TIMER=/etc/systemd/system/gitkraken-update.timer

    if $DRY_RUN; then
        info "[dry-run] Créerait $SERVICE et $TIMER"
    else
        cat > "$SERVICE" <<SVCEOF
[Unit]
Description=GitKraken auto-update (chrysa · shared-standards)
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/gitkraken-update.sh
StandardOutput=journal
StandardError=journal
SVCEOF

        cat > "$TIMER" <<TIMEOF
[Unit]
Description=Run gitkraken-update weekly (chrysa · shared-standards)

[Timer]
OnCalendar=Mon 04:00
RandomizedDelaySec=30m
Persistent=true

[Install]
WantedBy=timers.target
TIMEOF
        systemctl daemon-reload
        systemctl enable --now gitkraken-update.timer
        ok "Timer systemd armé · lundi 04:00 (+ jitter 30min)"
        info "Status : systemctl status gitkraken-update.timer · logs : journalctl -u gitkraken-update.service"
    fi
fi

log "═══ FIN ═══"
cat <<EOF

─── Récap des updates automatiques activés ──────────────────────────
  · VS Code        → unattended-upgrades (daily check · apt Microsoft)
  · Docker Desktop → unattended-upgrades (daily check · apt Docker)
  · GitKraken      → systemd timer (weekly lundi 04:00 · download .deb)

  Disable all :   sudo bash $0 --disable
  Logs VS/Docker : journalctl -u apt-daily-upgrade.service
  Logs GitKraken : journalctl -u gitkraken-update.service -n 20
─────────────────────────────────────────────────────────────────────

EOF
