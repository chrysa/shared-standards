#!/usr/bin/env bash
# gh-device-token.sh · Generate a GitHub token via the OAuth Device Flow.
# Source: chrysa/shared-standards/scripts/gh-device-token.sh
#
# Generates a fresh user access token interactively — no client secret, nothing pre-stored.
# You open a URL and type a one-time code; the script polls until you approve, then prints
# the token on STDOUT (all human output goes to STDERR, so it is safe to capture):
#
#   token="$(scripts/gh-device-token.sh)"
#
# The default OAuth client is GitHub CLI's public client id (zero setup). To use your own
# OAuth App, enable "Device Flow" on it and pass GH_OAUTH_CLIENT_ID. The token acts as YOU
# and carries the requested scopes (repo + workflow by default), enough to push branches and
# open PRs across the repos your account can write to.
#
# Config (env):
#   GH_OAUTH_CLIENT_ID   OAuth App client id with Device Flow enabled (default: gh CLI's).
#   GH_OAUTH_SCOPES      space- or comma-separated scopes (default: "repo workflow").
#
# PROCESS — how to get the token (step by step):
#   1. Run it, capturing stdout:        token="$(./scripts/gh-device-token.sh)"
#      (or, to set the GitHub secret in one go:  ./scripts/setup-org-secrets.sh --release --gen-device)
#   2. The script prints a URL + an 8-char code on screen, e.g.:
#         Open:  https://github.com/login/device
#         Code:  ABCD-1234
#   3. Open that URL in your browser (already logged into the right GitHub account).
#   4. Type the code, click Continue.
#   5. Review the requested scopes (repo + workflow) and click "Authorize".
#      First time only: if GitHub asks, grant the OAuth app access to the chrysa org.
#   6. Back in the terminal the script prints "token generated" and emits the token.
#      The value is now in $token (or set as RELEASE_TOKEN by setup-org-secrets.sh).
#   The code expires after ~15 min — if it lapses, just re-run.
#
# Exit: 0 token printed · 1 denied/expired/error · 2 missing dependency
set -uo pipefail

CLIENT_ID="${GH_OAUTH_CLIENT_ID:-178c6fc778ccc68e1d6a}"   # GitHub CLI public OAuth client id
SCOPES="${GH_OAUTH_SCOPES:-repo workflow}"
SCOPES="${SCOPES//,/ }"

command -v curl >/dev/null || { echo "curl required" >&2; exit 2; }
command -v jq   >/dev/null || { echo "jq required" >&2; exit 2; }

req() { curl -sS -H 'Accept: application/json' "$@"; }

# 1. Request a device + user code.
resp="$(req -X POST https://github.com/login/device/code \
    -d "client_id=$CLIENT_ID" --data-urlencode "scope=$SCOPES")"
device_code="$(echo "$resp"      | jq -r '.device_code // empty')"
user_code="$(echo "$resp"        | jq -r '.user_code // empty')"
verification_uri="$(echo "$resp" | jq -r '.verification_uri // empty')"
interval="$(echo "$resp"         | jq -r '.interval // 5')"

if [[ -z "$device_code" ]]; then
    echo "device code request failed: $(echo "$resp" | jq -r '.error_description // .error // "unknown"')" >&2
    echo "(if 'Device Flow' is disabled on the OAuth app, enable it or set GH_OAUTH_CLIENT_ID)" >&2
    exit 1
fi

{
    echo "────────────────────────────────────────────"
    echo "  1. Open:  $verification_uri"
    echo "  2. Code:  $user_code"
    echo "  3. Approve the requested scopes ($SCOPES)"
    echo "  …waiting for approval (Ctrl-C to abort)"
    echo "────────────────────────────────────────────"
} >&2

# 2. Poll for the access token.
while true; do
    sleep "$interval"
    poll="$(req -X POST https://github.com/login/oauth/access_token \
        -d "client_id=$CLIENT_ID" -d "device_code=$device_code" \
        -d 'grant_type=urn:ietf:params:oauth:grant-type:device_code')"
    error="$(echo "$poll" | jq -r '.error // empty')"
    case "$error" in
        "")
            token="$(echo "$poll" | jq -r '.access_token // empty')"
            if [[ -n "$token" ]]; then
                echo "  ✓ token generated (scopes: $SCOPES)" >&2
                printf '%s' "$token"
                exit 0
            fi
            echo "unexpected response: $poll" >&2; exit 1 ;;
        authorization_pending) : ;;                    # not approved yet — keep polling
        slow_down)             interval=$((interval + 5)) ;;
        expired_token)         echo "  ✗ the code expired · re-run" >&2; exit 1 ;;
        access_denied)         echo "  ✗ access denied" >&2; exit 1 ;;
        *) echo "  ✗ $error: $(echo "$poll" | jq -r '.error_description // empty')" >&2; exit 1 ;;
    esac
done
