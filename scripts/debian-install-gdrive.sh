#!/usr/bin/env bash
# debian-install-gdrive.sh · installe gdrive v3 (glotlabs/gdrive) sur Debian
# Source : chrysa/shared-standards/scripts/
#
# Contexte : Google Drive CLI pour sync/upload/download depuis terminal.
# Projet : https://github.com/glotlabs/gdrive (successeur de prasmussen/gdrive archivé).
# Binaire pré-compilé · pas d'apt repo officiel · install dans /usr/local/bin/.
#
# Usage :
#   sudo bash debian-install-gdrive.sh              # install dernière release
#   sudo bash debian-install-gdrive.sh --version 3.9.1   # pin version
#   sudo bash debian-install-gdrive.sh --uninstall  # supprime
#   bash debian-install-gdrive.sh --account-setup   # lance le OAuth add (non-sudo)
#
# Prérequis post-install : création Google Cloud OAuth client (manuel · doc UI-only) :
#   https://console.cloud.google.com/apis/credentials
#   → Create Credentials → OAuth client ID → Desktop app → récupère client_id + secret
#   Puis : gdrive account add  (colle ces valeurs)
#
# Exit : 0 OK · 1 erreur · 2 prérequis

set -uo pipefail

GDRIVE_REPO="glotlabs/gdrive"
INSTALL_PATH="/usr/local/bin/gdrive"
ARCH=$(dpkg --print-architecture 2>/dev/null || uname -m)
VERSION=""
UNINSTALL=false
ACCOUNT_SETUP=false

# ─── Args ─────────────────────────────────────────────
for arg in "$@"; do
    case "$arg" in
        --version) shift; VERSION="$1" ;;
        --version=*) VERSION="${arg#--version=}" ;;
        --uninstall) UNINSTALL=true ;;
        --account-setup) ACCOUNT_SETUP=true ;;
        -h|--help)
            sed -n '2,22p' "$0" | sed 's/^# \?//'
            exit 0
            ;;
    esac
    shift 2>/dev/null || true
done

log()  { echo "[$(date +%H:%M:%S)] $*"; }
ok()   { echo -e "  \033[32m✓\033[0m $*"; }
warn() { echo -e "  \033[33m⚠\033[0m $*" >&2; }
err()  { echo -e "  \033[31m✗\033[0m $*" >&2; }
info() { echo -e "  \033[34m→\033[0m $*"; }

# ─── Uninstall ───────────────────────────────────────
if $UNINSTALL; then
    if [[ $EUID -ne 0 ]]; then err "--uninstall nécessite sudo"; exit 2; fi
    [[ -f "$INSTALL_PATH" ]] && rm -f "$INSTALL_PATH" && ok "Binaire supprimé : $INSTALL_PATH"
    ok "gdrive désinstallé (config utilisateur préservée dans ~/.config/gdrive3/)"
    exit 0
fi

# ─── Account setup mode ──────────────────────────────
if $ACCOUNT_SETUP; then
    if ! command -v gdrive &>/dev/null; then
        err "gdrive pas installé · lance d'abord : sudo bash $0"
        exit 2
    fi
    log "Lancement de : gdrive account add"
    info "Tu vas être invité à coller un OAuth client_id + secret."
    info "Doc création credentials : https://github.com/glotlabs/gdrive/blob/main/docs/create_google_api_credentials.md"
    exec gdrive account add
fi

# ─── Prérequis ───────────────────────────────────────
if [[ $EUID -ne 0 ]]; then err "Install nécessite sudo"; exit 2; fi
for cmd in curl tar; do
    command -v "$cmd" &>/dev/null || { err "$cmd requis"; exit 2; }
done

# ─── Mapping arch Debian → release asset ─────────────
case "$ARCH" in
    amd64|x86_64) ASSET_ARCH="x86_64-unknown-linux-musl" ;;
    arm64|aarch64) ASSET_ARCH="aarch64-unknown-linux-musl" ;;
    *) err "Arch non supportée : $ARCH"; exit 2 ;;
esac

# ─── Résolution version ──────────────────────────────
if [[ -z "$VERSION" ]]; then
    log "Résolution dernière release de $GDRIVE_REPO…"
    VERSION=$(curl -sL "https://api.github.com/repos/${GDRIVE_REPO}/releases/latest" \
        | grep -oP '"tag_name":\s*"\K[^"]+' | head -1)
    if [[ -z "$VERSION" ]]; then
        err "Impossible de récupérer la dernière version (API GitHub rate limit ?)"
        exit 1
    fi
fi
info "Version cible : $VERSION"

# ─── Téléchargement ──────────────────────────────────
# Format asset : gdrive_X.Y.Z_linux_x86_64.tar.gz (selon tag convention glotlabs)
VERSION_NO_V="${VERSION#v}"
ASSET_NAME="gdrive_${ASSET_ARCH}.tar.gz"
URL="https://github.com/${GDRIVE_REPO}/releases/download/${VERSION}/${ASSET_NAME}"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

log "Téléchargement depuis $URL"
if ! curl -sL -o "$TMP/gdrive.tar.gz" "$URL"; then
    err "Échec téléchargement · URL : $URL"
    exit 1
fi
[[ -s "$TMP/gdrive.tar.gz" ]] || { err "Fichier vide"; exit 1; }

# ─── Extract + install ──────────────────────────────
log "Extraction…"
tar -xzf "$TMP/gdrive.tar.gz" -C "$TMP" || { err "tar extract fail"; exit 1; }
BIN=$(find "$TMP" -name "gdrive" -type f -executable | head -1)
[[ -z "$BIN" ]] && { err "Binaire introuvable dans l'archive"; exit 1; }

install -m 0755 "$BIN" "$INSTALL_PATH"
ok "Installé : $INSTALL_PATH ($("$INSTALL_PATH" version 2>/dev/null | head -1))"

# ─── Next steps ──────────────────────────────────────
cat <<EOF

─── Étapes suivantes (manuelles · UI-only) ──────────────────────────
  1. Crée un OAuth client Google Cloud :
       https://github.com/glotlabs/gdrive/blob/main/docs/create_google_api_credentials.md
     TL;DR : console.cloud.google.com → APIs & Services → Credentials →
             Create Credentials → OAuth client ID → type Desktop app

  2. Ajoute le compte dans gdrive :
       gdrive account add
     (colle client_id + secret · navigateur s'ouvre pour valider)

  3. Vérifie :
       gdrive account list
       gdrive files list

  Raccourci : bash $0 --account-setup
─────────────────────────────────────────────────────────────────────

EOF

exit 0
