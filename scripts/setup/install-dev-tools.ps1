#Requires -Version 5.1
# install-dev-tools.ps1
# Bootstrap dev tooling Windows pour stack chrysa : rtk + graphify + gh + pre-commit
# Source canonique : shared-standards/scripts/setup/
# Usage: pwsh -ExecutionPolicy Bypass -File install-dev-tools.ps1

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ============================================================
# Helpers
# ============================================================

function info($msg) { Write-Host "-> $msg" -ForegroundColor Cyan }
function ok($msg)   { Write-Host "v $msg" -ForegroundColor Green }
function warn($msg) { Write-Host "! $msg" -ForegroundColor Yellow }
function die($msg)  { Write-Host "x $msg" -ForegroundColor Red; Stop-Transcript; exit 1 }
function has_cmd([string]$cmd) { $null -ne (Get-Command $cmd -ErrorAction SilentlyContinue) }

# ============================================================
# Logging
# ============================================================

$LOG_FILE = "$env:TEMP\install-dev-tools.log"
Start-Transcript -Path $LOG_FILE -Append

Write-Host ""
Write-Host "============================================="
Write-Host "  CHRYSA DEV TOOLS - WINDOWS"
Write-Host "  rtk + graphify + gh + pre-commit"
Write-Host "============================================="
Write-Host ""

# 1. winget
if (-not (has_cmd "winget")) {
    die "winget non disponible — installer 'App Installer' depuis le Microsoft Store"
}
ok "winget pret"

# 2. Python (requis pour pipx / graphify / pre-commit)
if (-not (has_cmd "python")) {
    info "Installation Python via winget..."
    winget install --id Python.Python.3.12 -e --silent --accept-source-agreements
    $env:PATH = "$env:LOCALAPPDATA\Programs\Python\Python312;$env:LOCALAPPDATA\Programs\Python\Python312\Scripts;$env:PATH"
}
ok "python pret"

# 3. GitHub CLI
if (-not (has_cmd "gh")) {
    info "Installation GitHub CLI..."
    winget install --id GitHub.cli -e --silent --accept-source-agreements
}
ok "gh pret"

# 4. jq
if (-not (has_cmd "jq")) {
    info "Installation jq..."
    winget install --id jqlang.jq -e --silent --accept-source-agreements
}
ok "jq pret"

# 5. pipx
if (-not (has_cmd "pipx")) {
    info "Installation pipx..."
    python -m pip install --user pipx
    python -m pipx ensurepath
}
$pipxBin = "$env:USERPROFILE\.local\bin"
if ($env:PATH -notlike "*$pipxBin*") {
    $env:PATH = "$pipxBin;$env:PATH"
}
ok "pipx pret"

# 6. rtk — depuis GitHub Releases (rtk-ai/rtk)
# WARNING: NE PAS utiliser `cargo install rtk` — installe Rust Type Kit (mauvais paquet)
#          Le rtk chrysa vient de github.com/rtk-ai/rtk
info "Installation rtk depuis github.com/rtk-ai/rtk..."

$RTK_VERSION = (Invoke-RestMethod "https://api.github.com/repos/rtk-ai/rtk/releases/latest").tag_name
if (-not $RTK_VERSION) {
    die "Impossible de recuperer la version rtk depuis GitHub API"
}

$RTK_DIR = "$env:USERPROFILE\.local\bin"
New-Item -ItemType Directory -Force -Path $RTK_DIR | Out-Null

$RTK_URL = "https://github.com/rtk-ai/rtk/releases/download/$RTK_VERSION/rtk-x86_64-pc-windows-msvc.exe"
try {
    Invoke-WebRequest -Uri $RTK_URL -OutFile "$RTK_DIR\rtk.exe" -UseBasicParsing
} catch {
    die "Telechargement rtk echoue — verifier les assets sur github.com/rtk-ai/rtk/releases"
}

if ($env:PATH -notlike "*$RTK_DIR*") {
    $env:PATH = "$RTK_DIR;$env:PATH"
}

if (-not (has_cmd "rtk")) { die "rtk introuvable apres installation" }
ok "rtk $RTK_VERSION installe"

info "Initialisation rtk (hook global Claude Code)..."
rtk init -g --auto-patch
ok "rtk init done"

# 7. graphify
info "Installation graphify (PyPI=graphifyy, CLI=graphify)..."
try { pipx install graphifyy 2>&1 | Out-Null } catch { pipx upgrade graphifyy }
if (has_cmd "graphify") { ok "graphify installe" } else { warn "graphify non detecte — relancer le terminal" }

# 8. pre-commit
info "Installation pre-commit..."
try { pipx install pre-commit 2>&1 | Out-Null } catch { pipx upgrade pre-commit }
if (has_cmd "pre-commit") { ok "pre-commit installe" } else { warn "pre-commit non detecte" }

# repomix (optionnel — pending arbitrage P1)
# Decommenter UNIQUEMENT apres decision OUI sur l'arbitrage
#
# info "Installation repomix..."
# try { pipx install repomix } catch { pipx upgrade repomix }

# Ajouter ~/.local/bin au PATH permanent (user scope)
$userPath = [Environment]::GetEnvironmentVariable("PATH", "User")
if ($userPath -notlike "*$RTK_DIR*") {
    info "Ajout de $RTK_DIR au PATH permanent (user)..."
    [Environment]::SetEnvironmentVariable("PATH", "$RTK_DIR;$userPath", "User")
    ok "PATH mis a jour — ouvrir un nouveau terminal pour prendre effet"
}

# Recap
Write-Host ""
Write-Host "============== RECAP =============="

function status($name, $cmd) {
    if (has_cmd $cmd) {
        Write-Host "  v $name" -ForegroundColor Green
    } else {
        Write-Host "  x $name (non detecte — relancer le terminal ?)" -ForegroundColor Red
    }
}

status "python"      "python"
status "pipx"        "pipx"
status "gh"          "gh"
status "jq"          "jq"
status "rtk"         "rtk"
status "graphify"    "graphify"
status "pre-commit"  "pre-commit"

Write-Host ""
Write-Host "Log : $LOG_FILE"
Write-Host ""
Write-Host "Tests :"
Write-Host "  rtk --help"
Write-Host "  graphify --help"
Write-Host "  gh --version"
Write-Host "  pre-commit --version"
Write-Host ""
Write-Host "Auth GitHub :"
Write-Host "  gh auth login"
Write-Host "  gh auth switch -u chrysa"
Write-Host ""

Stop-Transcript
