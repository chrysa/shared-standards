#!/usr/bin/env bash
# install-dev-tools.sh
# Bootstrap dev tooling Debian/Ubuntu pour stack chrysa : rtk + graphify + gh + pre-commit
# Source canonique : shared-standards/scripts/setup/
# repomix : optionnel, pending arbitrage P1 — section commentée en bas

set -euo pipefail

# ============================================================
# Helpers
# ============================================================

info() { echo -e "\033[36m→\033[0m $1"; }
ok()   { echo -e "\033[32m✓\033[0m $1"; }
warn() { echo -e "\033[33m⚠\033[0m $1"; }
die()  { echo -e "\033[31m✗\033[0m $1" >&2; exit 1; }
has_cmd() { command -v "$1" >/dev/null 2>&1; }

# ============================================================
# Logging
# ============================================================

LOG_FILE="/tmp/install-dev-tools.log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo ""
echo "============================================="
echo "  CHRYSA DEV TOOLS - DEBIAN/UBUNTU"
echo "  rtk + graphify + gh + pre-commit"
echo "============================================="
echo ""

# 1. Prérequis système
info "Mise à jour apt + paquets système..."
sudo apt update
sudo apt install -y \
    curl git build-essential \
    pkg-config libssl-dev \
    python3 python3-pip python3-venv \
    ca-certificates jq
ok "Paquets système prêts"

# 2. GitHub CLI (gh)
if ! has_cmd gh; then
    info "Installation GitHub CLI..."
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
        | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
    sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
        | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    sudo apt update
    sudo apt install -y gh
fi
ok "gh prêt"

# 3. pipx
if ! has_cmd pipx; then
    info "Installation pipx..."
    python3 -m pip install --user pipx --break-system-packages \
        || python3 -m pip install --user pipx
    python3 -m pipx ensurepath
fi

export PATH="$HOME/.local/bin:$PATH"
ok "pipx prêt"

# 4. rtk — depuis GitHub Releases (rtk-ai/rtk)
# ⚠️  NE PAS utiliser `cargo install rtk` : installe Rust Type Kit (mauvais paquet)
#     Le rtk chrysa vient de github.com/rtk-ai/rtk
info "Installation rtk depuis github.com/rtk-ai/rtk..."

RTK_VERSION=$(curl -sSf https://api.github.com/repos/rtk-ai/rtk/releases/latest \
    | python3 -c "import sys, json; print(json.load(sys.stdin)['tag_name'])")

if [[ -z "${RTK_VERSION}" ]]; then
    die "Impossible de récupérer la version rtk depuis GitHub API"
fi

# Normalise x86_64 → amd64 si nécessaire selon les assets GitHub
case "$(uname -m)" in
    x86_64)  RTK_ARCH="x86_64" ;;
    aarch64) RTK_ARCH="aarch64" ;;
    *)       RTK_ARCH="$(uname -m)" ;;
esac
RTK_URL="https://github.com/rtk-ai/rtk/releases/download/${RTK_VERSION}/rtk-${RTK_ARCH}-unknown-linux-musl"

curl -sSfL "$RTK_URL" -o "$HOME/.local/bin/rtk" \
    || die "Téléchargement rtk échoué — vérifier les assets sur github.com/rtk-ai/rtk/releases"
chmod +x "$HOME/.local/bin/rtk"

if ! has_cmd rtk; then
    die "rtk introuvable après installation"
fi
ok "rtk ${RTK_VERSION} installé"

info "Initialisation rtk (hook global Claude Code)..."
rtk init -g --auto-patch
ok "rtk init done"

# 5. graphify
info "Installation graphify (PyPI=graphifyy, CLI=graphify)..."
pipx install graphifyy 2>/dev/null || pipx upgrade graphifyy

if ! has_cmd graphify; then
    warn "graphify pas détecté — relancer le shell puis tester 'graphify --help'"
else
    ok "graphify installé"
fi

# 6. pre-commit
info "Installation pre-commit..."
pipx install pre-commit 2>/dev/null || pipx upgrade pre-commit

has_cmd pre-commit && ok "pre-commit installé" || warn "pre-commit non détecté"

# 7. repomix (optionnel — pending arbitrage P1)
# Décommenter UNIQUEMENT après décision OUI sur l'arbitrage
#
# info "Installation repomix..."
# pipx install repomix
# has_cmd repomix && ok "repomix installé"

# Récap
echo ""
echo "============== RÉCAP =============="

status() {
    if has_cmd "$2"; then
        echo -e "  \033[32m✓\033[0m $1"
    else
        echo -e "  \033[31m✗\033[0m $1 (non détecté — relancer le shell ?)"
    fi
}

status "python3"     "python3"
status "pipx"        "pipx"
status "gh"          "gh"
status "jq"          "jq"
status "rtk"         "rtk"
status "graphify"    "graphify"
status "pre-commit"  "pre-commit"

echo ""
echo "Log : $LOG_FILE"
echo ""
echo "Tests :"
echo "  rtk --help"
echo "  graphify --help"
echo "  gh --version"
echo "  pre-commit --version"
echo ""
echo "Auth GitHub :"
echo "  gh auth login"
echo "  gh auth switch -u chrysa"
echo ""
