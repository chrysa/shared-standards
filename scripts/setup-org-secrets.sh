#!/usr/bin/env bash
# setup-org-secrets.sh · Provision CI secrets across chrysa repos with gh.
# Source: chrysa/shared-standards/scripts/setup-org-secrets.sh
#
# Runs locally on your machine using your authenticated `gh` CLI. Token values are
# read from env vars or a hidden prompt and piped straight to `gh secret set` —
# they are never printed, logged, or stored.
#
# Secrets handled:
#   RELEASE_TOKEN   on chrysa/shared-standards — drives the distribute-standards fan-out.
#                   Needs a PAT with write access to ALL target repos (Contents +
#                   Pull requests + Workflows). Classic: `repo` + `workflow`.
#   SONAR_TOKEN       on every status:dev repo that is missing it.
#   SONAR_HOST_URL    on every status:dev repo that is missing it (self-hosted SonarQube;
#                     omit to let workflows default to https://sonarcloud.io).
#   SENTRY_AUTH_TOKEN on every status:dev repo that is missing it (releases / sourcemaps).
#
# By default only repos WITHOUT the secret are touched (idempotent). Use --force to overwrite.
#
# Usage:
#   setup-org-secrets.sh --all --secrets-file=~/.secrets  # read all tokens from one KEY=value file
#   setup-org-secrets.sh --all --secrets-dir=~/secrets    # read all tokens from per-token files
#   setup-org-secrets.sh --release --gen-device     # GENERATE RELEASE_TOKEN via device flow, then set it
#   setup-org-secrets.sh --release [--from-gh]      # set RELEASE_TOKEN (paste, or reuse gh token)
#   setup-org-secrets.sh --sonar                    # add SONAR_TOKEN where missing
#   setup-org-secrets.sh --sonarqube               # add SONAR_HOST_URL where missing
#   setup-org-secrets.sh --sentry                   # add SENTRY_AUTH_TOKEN where missing
#   setup-org-secrets.sh --all                      # everything
#   setup-org-secrets.sh --sonar --org             # set once at org level (all repos)
#   setup-org-secrets.sh --sonar --only=a,b        # subset of repos
#   setup-org-secrets.sh --sonar --dry-run         # preview, no writes
#
# Token sources (checked in order): env var · --secrets-file (KEY=value) · --secrets-dir files ·
#   `gh auth token` (RELEASE only, --from-gh) · hidden prompt.
#   Names — env / dir-file:
#     RELEASE_TOKEN/release_token  (aliases GH_TOKEN, GITHUB_TOKEN, GITHUB_PAT)
#     SONAR_TOKEN/sonar_token · SONAR_HOST_URL/sonar_host_url
#     SENTRY_AUTH_TOKEN/sentry_auth_token  (alias SENTRY_TOKEN)
#
# Exit: 0 ok · 1 error · 2 missing dependency
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ORG="${CHRYSA_ORG:-chrysa}"
SOURCE_REPO="$ORG/shared-standards"

DO_RELEASE=false
DO_SONAR=false
DO_SONARQUBE=false
DO_SENTRY=false
FROM_GH=false
GEN_DEVICE=false
FORCE=false
DRY_RUN=false
ORG_LEVEL=false
ONLY=""
SECRETS_DIR=""
SECRETS_FILE=""

for arg in "$@"; do
    case "$arg" in
        --release)        DO_RELEASE=true ;;
        --sonar)          DO_SONAR=true ;;
        --sonarqube)      DO_SONARQUBE=true ;;
        --sentry)         DO_SENTRY=true ;;
        --all)            DO_RELEASE=true; DO_SONAR=true; DO_SONARQUBE=true; DO_SENTRY=true ;;
        --from-gh)        FROM_GH=true ;;
        --gen-device)     GEN_DEVICE=true ;;
        --force)          FORCE=true ;;
        --dry-run)        DRY_RUN=true ;;
        --org)            ORG_LEVEL=true ;;
        --only=*)         ONLY="${arg#--only=}" ;;
        --only)           echo "use --only=a,b (no space)" >&2; exit 1 ;;
        --secrets-dir=*)  SECRETS_DIR="${arg#--secrets-dir=}" ;;
        --secrets-dir)    echo "use --secrets-dir=PATH (no space)" >&2; exit 1 ;;
        --secrets-file=*) SECRETS_FILE="${arg#--secrets-file=}" ;;
        --secrets-file)   echo "use --secrets-file=PATH (no space)" >&2; exit 1 ;;
        -h|--help)        sed -n '2,40p' "$0" | sed 's/^# \?//'; exit 0 ;;
        *)                echo "unknown arg: $arg" >&2; exit 1 ;;
    esac
done

# Load token values from a single KEY=value file (dotenv / shell). The file is sourced,
# so it may use `export KEY=val` or `KEY=val`. Common aliases fill RELEASE_TOKEN if unset.
load_secrets_file() {
    local f="${1/#\~/$HOME}"
    [[ -f "$f" ]] || { echo "secrets file not found: $f" >&2; exit 2; }
    set -a
    # shellcheck disable=SC1090
    source "$f"
    set +a
    : "${RELEASE_TOKEN:=${GH_TOKEN:-${GITHUB_TOKEN:-${GITHUB_PAT:-}}}}"
    : "${SENTRY_AUTH_TOKEN:=${SENTRY_TOKEN:-}}"
    export RELEASE_TOKEN SONAR_TOKEN SONAR_HOST_URL SENTRY_AUTH_TOKEN
}
[[ -n "$SECRETS_FILE" ]] && load_secrets_file "$SECRETS_FILE"

# Load token values from a secrets dir (files: release_token, sonar_token, sonar_host_url).
# Whitespace/newlines are stripped. Env vars already set take precedence and are left alone.
load_secrets_dir() {
    local d="${1/#\~/$HOME}"
    [[ -d "$d" ]] || { echo "secrets dir not found: $d" >&2; exit 2; }
    local f
    f="$d/release_token";     [[ -z "${RELEASE_TOKEN:-}"     && -f "$f" ]] && RELEASE_TOKEN="$(tr -d '[:space:]' < "$f")"
    f="$d/sonar_token";       [[ -z "${SONAR_TOKEN:-}"       && -f "$f" ]] && SONAR_TOKEN="$(tr -d '[:space:]' < "$f")"
    f="$d/sonar_host_url";    [[ -z "${SONAR_HOST_URL:-}"    && -f "$f" ]] && SONAR_HOST_URL="$(tr -d '[:space:]' < "$f")"
    f="$d/sentry_auth_token"; [[ -z "${SENTRY_AUTH_TOKEN:-}" && -f "$f" ]] && SENTRY_AUTH_TOKEN="$(tr -d '[:space:]' < "$f")"
    export RELEASE_TOKEN SONAR_TOKEN SONAR_HOST_URL SENTRY_AUTH_TOKEN
}
[[ -n "$SECRETS_DIR" ]] && load_secrets_dir "$SECRETS_DIR"

ok()   { echo -e "  \033[32m✓\033[0m $*"; }
warn() { echo -e "  \033[33m⚠\033[0m $*"; }
err()  { echo -e "  \033[31m✗\033[0m $*" >&2; }
info() { echo -e "  \033[34m→\033[0m $*"; }

# --- preflight ---
command -v gh >/dev/null || { err "gh CLI not found · install GitHub CLI first"; exit 2; }
gh auth status >/dev/null 2>&1 || { err "gh not authenticated · run: gh auth login"; exit 2; }
$DO_RELEASE || $DO_SONAR || $DO_SONARQUBE || $DO_SENTRY || { err "nothing to do · pass --release / --sonar / --sonarqube / --sentry / --all"; exit 1; }

# Read a secret value: env var, else hidden prompt. Echoes the value on stdout only.
read_secret() {
    local name="$1" val="${!1:-}"
    if [[ -z "$val" ]]; then
        read -rs -p "Enter value for $name: " val </dev/tty; echo >&2
    fi
    [[ -n "$val" ]] || { err "$name is empty · aborting"; exit 1; }
    printf '%s' "$val"
}

# True if repo already has a named secret.
repo_has_secret() {
    gh secret list --repo "$ORG/$1" 2>/dev/null | awk '{print $1}' | grep -qx "$2"
}
org_has_secret() {
    gh secret list --org "$ORG" 2>/dev/null | awk '{print $1}' | grep -qx "$1"
}

# Set a secret on one repo, skipping if present (unless --force).
set_repo_secret() {
    local repo="$1" secret="$2" value="$3"
    if ! $FORCE && repo_has_secret "$repo" "$secret"; then
        info "$repo · $secret already set · skip"; return 0
    fi
    if $DRY_RUN; then info "[dry-run] would set $secret on $ORG/$repo"; return 0; fi
    if printf '%s' "$value" | gh secret set "$secret" --repo "$ORG/$repo" >/dev/null 2>&1; then
        ok "$repo · $secret set"
    else
        err "$repo · failed to set $secret"
    fi
}

# Set a secret once at org level, visible to all repos.
set_org_secret() {
    local secret="$1" value="$2"
    if ! $FORCE && org_has_secret "$secret"; then
        info "org · $secret already set · skip"; return 0
    fi
    if $DRY_RUN; then info "[dry-run] would set $secret at org level ($ORG, visibility=all)"; return 0; fi
    if printf '%s' "$value" | gh secret set "$secret" --org "$ORG" --visibility all >/dev/null 2>&1; then
        ok "org · $secret set (all repos)"
    else
        err "org · failed to set $secret (need org admin)"
    fi
}

# Resolve the status:dev repo list (honors --only).
target_repos() {
    local lister="$SCRIPT_DIR/list-dev-repos.sh"
    [[ -f "$lister" ]] || { err "list-dev-repos.sh missing"; exit 2; }
    if [[ -n "$ONLY" ]]; then
        bash "$lister" --lines --only "$ONLY"
    else
        bash "$lister" --lines
    fi
}

# --- RELEASE_TOKEN (shared-standards only) ---
if $DO_RELEASE; then
    echo "── RELEASE_TOKEN → $SOURCE_REPO ──"
    if ! $FORCE && repo_has_secret "shared-standards" "RELEASE_TOKEN"; then
        info "shared-standards · RELEASE_TOKEN already set · skip (use --force to replace)"
    elif $DRY_RUN; then
        info "[dry-run] would set RELEASE_TOKEN on $SOURCE_REPO"
    else
        # Only now do we need a value — generate, reuse, or prompt.
        if $GEN_DEVICE && [[ -z "${RELEASE_TOKEN:-}" ]]; then
            info "generating RELEASE_TOKEN via OAuth device flow…"
            RELEASE_TOKEN="$("$SCRIPT_DIR/gh-device-token.sh")" \
                || { err "device flow failed"; exit 1; }
        fi
        if $FROM_GH && [[ -z "${RELEASE_TOKEN:-}" ]]; then
            warn "reusing current gh token · ensure it has 'workflow' + cross-repo 'repo' scope"
            RELEASE_TOKEN="$(gh auth token)"
        fi
        rt="$(RELEASE_TOKEN="${RELEASE_TOKEN:-}" read_secret RELEASE_TOKEN)"
        printf '%s' "$rt" | gh secret set RELEASE_TOKEN --repo "$SOURCE_REPO" >/dev/null 2>&1 \
            && ok "RELEASE_TOKEN set on $SOURCE_REPO" || err "failed to set RELEASE_TOKEN"
    fi
    unset rt RELEASE_TOKEN
fi

# --- SONAR_TOKEN ---
if $DO_SONAR; then
    echo "── SONAR_TOKEN ──"
    st="$(SONAR_TOKEN="${SONAR_TOKEN:-}" read_secret SONAR_TOKEN)"
    if $ORG_LEVEL; then
        set_org_secret SONAR_TOKEN "$st"
    else
        while IFS= read -r repo; do
            [[ -n "$repo" ]] && set_repo_secret "$repo" SONAR_TOKEN "$st"
        done < <(target_repos)
    fi
    unset st SONAR_TOKEN
fi

# --- SONAR_HOST_URL (self-hosted SonarQube) ---
if $DO_SONARQUBE; then
    echo "── SONAR_HOST_URL ──"
    sh="$(SONAR_HOST_URL="${SONAR_HOST_URL:-}" read_secret SONAR_HOST_URL)"
    if $ORG_LEVEL; then
        set_org_secret SONAR_HOST_URL "$sh"
    else
        while IFS= read -r repo; do
            [[ -n "$repo" ]] && set_repo_secret "$repo" SONAR_HOST_URL "$sh"
        done < <(target_repos)
    fi
    unset sh SONAR_HOST_URL
fi

# --- SENTRY_AUTH_TOKEN ---
if $DO_SENTRY; then
    echo "── SENTRY_AUTH_TOKEN ──"
    se="$(SENTRY_AUTH_TOKEN="${SENTRY_AUTH_TOKEN:-}" read_secret SENTRY_AUTH_TOKEN)"
    if $ORG_LEVEL; then
        set_org_secret SENTRY_AUTH_TOKEN "$se"
    else
        while IFS= read -r repo; do
            [[ -n "$repo" ]] && set_repo_secret "$repo" SENTRY_AUTH_TOKEN "$se"
        done < <(target_repos)
    fi
    unset se SENTRY_AUTH_TOKEN
fi

echo "Done."
