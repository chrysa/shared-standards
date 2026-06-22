#!/usr/bin/env bash
# Audit one app directory for Brand-Themes Design System conformance.
# Usage: audit-design-conformance.sh <app-dir>
# Exit 0 = conformant, 1 = violations found, 2 = usage error.
set -euo pipefail

APP_DIR="${1:-}"
[ -n "$APP_DIR" ] && [ -d "$APP_DIR" ] || { echo "usage: $0 <app-dir>" >&2; exit 2; }

REQUIRED_TOKENS=(--bg --surface --surface-2 --fg --muted --border --accent \
  --accent-ink --signal --warning --danger --ring --radius --border-weight \
  --shadow --font-display --font-body --font-mono --density --motion)

fail=0
note() { echo "FAIL: $1"; fail=1; }

# 1. no data-persona anywhere
if grep -rqs 'data-persona' "$APP_DIR"; then
  note "data-persona present (brand themes have no persona)"
fi

# 2. contract.css imported somewhere
if ! grep -rqs 'contract.css' "$APP_DIR"; then
  note "contract.css not imported"
fi

# 3. every semantic token name defined somewhere in the app's CSS
css_blob="$(grep -rhs -- '--' "$APP_DIR" --include='*.css' 2>/dev/null || true)"
for tok in "${REQUIRED_TOKENS[@]}"; do
  printf '%s\n' "$css_blob" | grep -qs -- "${tok}:" || note "token ${tok} not defined"
done

# 4. required design docs
[ -f "$APP_DIR/DESIGN.md" ]      || note "DESIGN.md missing"
[ -f "$APP_DIR/BRAND-BRIEF.md" ] || note "BRAND-BRIEF.md missing"

if [ "$fail" -eq 0 ]; then echo "conformant: $APP_DIR"; fi
exit "$fail"
