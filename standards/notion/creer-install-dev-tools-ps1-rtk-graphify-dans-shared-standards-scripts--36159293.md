---
fka_managed: true
source: notion
notion_id: 36159293-e35e-8171-acd3-dcced0c3cb01
notion_url: https://app.notion.com/p/Cr-er-install-dev-tools-ps1-sh-rtk-graphify-dans-shared-standards-scripts-36159293e35e8171acd3dcced0c3cb01
notion_last_edited_time: 2026-07-06T16:48:00.000Z
---
## Contexte
Scripts symétriques Windows + Debian pour bootstrap dev workstation chrysa.
**Stack confirmée (décidée)** : `rtk` (Rust Token Killer, cargo) + `graphify` (pipx install graphifyy, CLI = graphify).
**Optionnel (pending arbitrage P1)** : `repomix` — section commentée dans les deux scripts, à décommenter UNIQUEMENT après décision OUI sur la tâche P1 "Arbitrer : repomix dans standard dev tooling ?".
**Exclu explicitement** : Aider (overlap agent ecosystem chrysa), Qdrant + Claude context loader custom (overlap JARVIS + Knowledge RAG, violation switching cost strategic cap), open-interpreter, gitingest, toute "AI Dev OS V3+" de la conv source.
## Cible repo
`shared-standards/scripts/setup/install-dev-tools.ps1`
`shared-standards/scripts/setup/install-dev-tools.sh`
Mention dans `shared-standards/README.md` section setup workstation + template `project-init` si pertinent.
## Patterns techniques validés
Extraits de la conv ChatGPT-Correction_script_[PowerShell.md](http://PowerShell.md), kernel utile :
1. **PATH persistant Windows** : `[Environment]::SetEnvironmentVariable("Path", ..., "User")` plutôt que `$env:Path = ...` qui ne persiste pas entre sessions.
2. **Fenêtre persistante en cas d'erreur** : `try { ... } catch { Write-Host $_ } finally { Read-Host "Appuyer sur Entrée" }` — sinon double-clic = fermeture brutale sur exception.
3. **VS Build Tools** : `Start-Process -FilePath $vsInstaller -Wait -ArgumentList @(...)` évite le file lock sur `vs_buildtools.exe` en cas de relance.
4. **CLI Python isolées** : `pipx` plutôt que `pip --user` (pas de pollution du venv système, pas de PEP 668 sur Debian récent).
5. **rtk sur Windows** : nécessite VS Build Tools workload VCTools + Windows10SDK avant `cargo install rtk`, sinon link.exe absent → build échoue.
## [install-dev-tools.ps](http://install-dev-tools.ps)1
```powershell
# install-dev-tools.ps1
# Bootstrap dev tooling Windows pour stack chrysa : rtk + graphify
# Source canonique : shared-standards/scripts/setup/
# repomix : optionnel, pending arbitrage P1 — section commentée en bas

#Requires -Version 5.1
$ErrorActionPreference = "Stop"

# ============================================================
# Helpers
# ============================================================

function Info($m) { Write-Host "→ $m" -ForegroundColor Cyan }
function Ok($m)   { Write-Host "✓ $m" -ForegroundColor Green }
function Warn($m) { Write-Host "⚠ $m" -ForegroundColor Yellow }
function Die($m)  { Write-Host "✗ $m" -ForegroundColor Red; throw $m }
function Has-Cmd($c) { return [bool](Get-Command $c -ErrorAction SilentlyContinue) }

function Add-UserPath($path) {
    $current = [Environment]::GetEnvironmentVariable("Path", "User")
    if ($current -notlike "*$path*") {
        [Environment]::SetEnvironmentVariable("Path", "$current;$path", "User")
        Info "PATH user mis à jour : +$path"
    }
    if ($env:Path -notlike "*$path*") {
        $env:Path = "$path;$env:Path"
    }
}

# ============================================================
# Logging
# ============================================================

$logFile = "$env:TEMP\install-dev-tools.log"
Start-Transcript -Path $logFile -Append | Out-Null

try {

    Write-Host ""
    Write-Host "=============================================" -ForegroundColor Magenta
    Write-Host "  CHRYSA DEV TOOLS - WINDOWS" -ForegroundColor Magenta
    Write-Host "  rtk + graphify" -ForegroundColor Magenta
    Write-Host "=============================================" -ForegroundColor Magenta
    Write-Host ""

    # 1. Python (prérequis graphify)
    if (-not (Has-Cmd "python")) {
        Die "Python introuvable. Installer : winget install Python.Python.3.12"
    }
    Ok "Python détecté"

    # 2. pipx
    if (-not (Has-Cmd "pipx")) {
        Info "Installation pipx..."
        & python -m pip install --user pipx
        & python -m pipx ensurepath
    }
    Add-UserPath "$env:USERPROFILE\.local\bin"
    Ok "pipx prêt"

    # 3. Visual Studio Build Tools (requis pour cargo install rtk)
    if (-not (Has-Cmd "link.exe")) {
        Info "Installation Visual Studio Build Tools (workload C++, 5-15 min)..."

        $vsInstaller = Join-Path $env:TEMP "vs_buildtools.exe"
        if (Test-Path $vsInstaller) {
            Remove-Item $vsInstaller -Force -ErrorAction SilentlyContinue
        }

        Get-Process -Name "*vs_buildtools*" -ErrorAction SilentlyContinue `
            | Stop-Process -Force -ErrorAction SilentlyContinue

        Invoke-WebRequest `
            -Uri "https://aka.ms/vs/17/release/vs_BuildTools.exe" `
            -OutFile $vsInstaller

        Start-Process -FilePath $vsInstaller -Wait -ArgumentList @(
            "--quiet", "--wait", "--norestart", "--nocache",
            "--add", "Microsoft.VisualStudio.Workload.VCTools",
            "--add", "Microsoft.VisualStudio.Component.VC.Tools.x86.x64",
            "--add", "Microsoft.VisualStudio.Component.Windows10SDK",
            "--includeRecommended"
        )

        Ok "VS Build Tools installés"
    } else {
        Ok "VS Build Tools déjà présents"
    }

    # 4. Rust / cargo
    if (-not (Has-Cmd "cargo")) {
        Info "Installation Rust via rustup..."
        $rustup = Join-Path $env:TEMP "rustup-init.exe"
        Invoke-WebRequest "https://win.rustup.rs/x86_64" -OutFile $rustup
        & $rustup -y --default-toolchain stable --profile minimal
    }
    Add-UserPath "$env:USERPROFILE\.cargo\bin"

    if (-not (Has-Cmd "cargo")) {
        Die "cargo introuvable après installation Rust"
    }
    Ok "Rust / cargo prêt"

    # 5. rtk
    Info "Installation rtk via cargo (peut prendre quelques minutes)..."
    & cargo install rtk

    if (-not (Has-Cmd "rtk")) {
        Die "rtk introuvable après installation cargo"
    }
    Ok "rtk installé"

    # 6. graphify
    Info "Installation graphify (PyPI=graphifyy, CLI=graphify)..."
    & pipx install graphifyy

    if (-not (Has-Cmd "graphify")) {
        Warn "graphify pas détecté immédiatement — redémarrer le terminal puis tester 'graphify --help'"
    } else {
        Ok "graphify installé"
    }

    # 7. repomix (optionnel — pending arbitrage P1)
    # Décommenter UNIQUEMENT après décision OUI sur l'arbitrage
    #
    # Info "Installation repomix..."
    # & pipx install repomix
    # if (Has-Cmd "repomix") { Ok "repomix installé" }

    # Récap
    Write-Host ""
    Write-Host "============== RÉCAP ==============" -ForegroundColor DarkGray

    function Status($name, $cmd) {
        if (Has-Cmd $cmd) {
            Write-Host "  ✓ $name" -ForegroundColor Green
        } else {
            Write-Host "  ✗ $name (non détecté — redémarrer le terminal ?)" -ForegroundColor Red
        }
    }

    Status "python"   "python"
    Status "pipx"     "pipx"
    Status "cargo"    "cargo"
    Status "rtk"      "rtk"
    Status "graphify" "graphify"

    Write-Host ""
    Write-Host "Log : $logFile" -ForegroundColor Gray
    Write-Host ""
    Write-Host "IMPORTANT :" -ForegroundColor Yellow
    Write-Host "  → Fermer et rouvrir le terminal pour rafraîchir le PATH" -ForegroundColor Gray
    Write-Host "  → Tests : rtk --help  ·  graphify --help" -ForegroundColor Gray
    Write-Host ""

}
catch {
    Write-Host ""
    Write-Host "============== ERREUR ==============" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host "Log complet : $logFile" -ForegroundColor Yellow
    Write-Host ""
}
finally {
    Stop-Transcript | Out-Null
    Read-Host "Appuyer sur Entrée pour fermer"
}
```
## [install-dev-tools.sh](http://install-dev-tools.sh)
```bash
#!/usr/bin/env bash
# install-dev-tools.sh
# Bootstrap dev tooling Debian/Ubuntu pour stack chrysa : rtk + graphify
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
echo "  rtk + graphify"
echo "============================================="
echo ""

# 1. Prérequis système
info "Mise à jour apt + paquets système..."
sudo apt update -y
sudo apt install -y \
    curl git build-essential \
    pkg-config libssl-dev \
    python3 python3-pip python3-venv \
    ca-certificates
ok "Paquets système prêts"

# 2. pipx
if ! has_cmd pipx; then
    info "Installation pipx..."
    python3 -m pip install --user pipx --break-system-packages 2>/dev/null \
        || python3 -m pip install --user pipx
    python3 -m pipx ensurepath
fi

export PATH="$HOME/.local/bin:$PATH"
ok "pipx prêt"

# 3. Rust / cargo
if ! has_cmd cargo; then
    info "Installation Rust via rustup..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \
        | sh -s -- -y --default-toolchain stable --profile minimal
fi

# shellcheck disable=SC1091
source "$HOME/.cargo/env"
ok "Rust / cargo prêt"

# 4. rtk
info "Installation rtk via cargo (peut prendre quelques minutes)..."
cargo install rtk

if ! has_cmd rtk; then
    die "rtk introuvable après installation cargo"
fi
ok "rtk installé"

# 5. graphify
info "Installation graphify (PyPI=graphifyy, CLI=graphify)..."
pipx install graphifyy

if ! has_cmd graphify; then
    warn "graphify pas détecté — relancer le shell puis tester 'graphify --help'"
else
    ok "graphify installé"
fi

# 6. repomix (optionnel — pending arbitrage P1)
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

status "python3"  "python3"
status "pipx"     "pipx"
status "cargo"    "cargo"
status "rtk"      "rtk"
status "graphify" "graphify"

echo ""
echo "Log : $LOG_FILE"
echo ""
echo "Tests :"
echo "  rtk --help"
echo "  graphify --help"
echo ""
```
## Définition de done
- [ ] Arbitrage P1 tranché (repomix oui / non)
- [ ] Si oui : décommenter section repomix dans les deux scripts
- [ ] Si oui : créer ADR cross-repo dans DB Reference (Type=🎯 ADR) + entrée dans `shared-standards/DECISIONS.md`
- [ ] Commit `install-dev-tools.ps1` + `install-dev-tools.sh` dans `shared-standards/scripts/setup/`
- [ ] Test réel sur workstation Windows (Lenovo, win10/11)
- [ ] Test réel sur ThinkPad P53 Debian (idempotence : relancer sur machine déjà setup ne casse rien)
- [ ] Mention dans `shared-standards/README.md` § Setup workstation
- [ ] Évaluer intégration dans `project-init` CLI (option `--with-dev-tools` ?)
## Source / référence
Conversation ChatGPT-Correction_script_[PowerShell.md](http://PowerShell.md) (2026-05-15) : kernel utile = patterns techniques ci-dessus. Le reste (V1 → V14 "AI Dev OS" / "Recursive Universe Generator") est rejeté pour overlap massif avec JARVIS, DEV Nexus, Knowledge RAG, chrysa-lib et violation du gate strategic cap (switching cost near zero).
