#!/usr/bin/env bash
# verify-config.sh — single pass/fail gate for Claude config "dump" across a repo fleet.
#
# Composes three checks into one report + exit code:
#   1. AGENTS + SKILLS integrity      — delegates to check-skills-agents.sh (drift, broken refs).
#   2. Per-repo config presence       — .claude/agents, .claude/skills, .claude/settings.json,
#                                       CLAUDE.md, .mcp.json. Reported as a coverage table.
#   3. Committed-secret guard (.mcp.json) — HARD FAIL if any git-tracked .mcp.json has an `env`
#                                       value that is not a `${PLACEHOLDER}` (i.e. a real secret).
#
# Repo-agnostic: discovers repos by .git, no hard-coded names.
#
# Usage:
#   verify-config.sh [ROOT]              # scan everything under ROOT (default: .)
#   verify-config.sh --strict            # missing settings/CLAUDE.md/agents also fail (exit 1)
#   verify-config.sh --skills-agents     # also delegate to check-skills-agents.sh (agent drift,
#                                        #   broken refs). OFF by default: local git worktrees under
#                                        #   .claude/worktrees inflate that linter; clean in CI.
#   verify-config.sh --exclude '<glob>'  # repeatable; default excludes *_archived* *graphify-out*
#
# Exit: 0 ok · 1 hard fail (secret in .mcp.json, or skills/agents errors, or --strict gaps) · 2 usage.
set -uo pipefail
export LC_ALL=C

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="."
STRICT=0
DO_SA=0
EXCLUDES=('*_archived*' '*graphify-out*' '*/dumps/*' '*/node_modules/*' '*/.claude/worktrees/*' '*/worktrees/*' '*/.git/*')

while [ $# -gt 0 ]; do
  case "$1" in
    --strict)           STRICT=1; shift ;;
    --skills-agents)    DO_SA=1; shift ;;
    --no-skills-agents) DO_SA=0; shift ;;
    --exclude)          shift; EXCLUDES+=("${1:?--exclude needs a glob}"); shift ;;
    -h|--help)          sed -n '2,22p' "$0"; exit 0 ;;
    --*)                echo "unknown flag: $1" >&2; exit 2 ;;
    *)                  ROOT="$1"; shift ;;
  esac
done

ERR=0; WARN=0
red()  { printf '\033[31m%s\033[0m' "$*"; }
grn()  { printf '\033[32m%s\033[0m' "$*"; }
fail() { printf '❌ %s\n' "$*"; ERR=$((ERR+1)); }
warn() { printf '⚠️  %s\n' "$*"; WARN=$((WARN+1)); }
ok()   { printf '✅ %s\n' "$*"; }

is_excluded() { local p="$1" pat; for pat in "${EXCLUDES[@]}"; do case "$p" in $pat) return 0;; esac; done; return 1; }

discover_repos() {
  find "$ROOT" -name node_modules -prune -o -name .git -print 2>/dev/null \
    | while IFS= read -r g; do dirname "$g"; done | sort -u
}

# ---------------- 1. agents + skills integrity ----------------
if [ "$DO_SA" -eq 1 ] && [ -x "$HERE/check-skills-agents.sh" ]; then
  echo "──── AGENTS + SKILLS (check-skills-agents.sh) ────"
  sa_args=("$ROOT")
  for e in "${EXCLUDES[@]}"; do sa_args+=(--exclude "$e"); done
  if bash "$HERE/check-skills-agents.sh" "${sa_args[@]}"; then
    ok "skills/agents integrity passed"
  else
    fail "skills/agents integrity reported errors (see above)"
  fi
  echo
fi

# ---------------- 3. committed-secret guard (.mcp.json) ----------------
# Any env value not of the form ${...} (after trimming) is treated as a hardcoded secret.
scan_mcp_secret() {
  local f="$1"
  if command -v python3 >/dev/null 2>&1; then
    python3 - "$f" <<'PY'
import json, sys
f = sys.argv[1]
try:
    data = json.load(open(f))
except Exception as e:
    print(f"PARSE_ERROR {e}"); sys.exit(0)
bad = []
for name, srv in (data.get("mcpServers") or {}).items():
    for k, v in (srv.get("env") or {}).items():
        if not isinstance(v, str):
            continue
        # OK if every non-literal piece is a ${...} placeholder; flag a bare value with no ${}
        if "${" not in v:
            bad.append(f"{name}.{k}")
if bad:
    print("SECRET " + ", ".join(bad))
PY
  else
    # fallback: crude — flag env lines with no ${ and a long token-ish value
    grep -nE '"[A-Z_]+"[[:space:]]*:[[:space:]]*"[^"$]*"' "$f" | grep -vi 'http' || true
  fi
}

echo "──── .mcp.json SECRET GUARD ────"
mcp_count=0
while IFS= read -r f; do
  [ -n "$f" ] || continue
  is_excluded "$f" && continue
  mcp_count=$((mcp_count+1))
  out="$(scan_mcp_secret "$f")"
  case "$out" in
    SECRET*) fail "${f#./}: hardcoded secret in env → ${out#SECRET }" ;;
    PARSE_ERROR*) warn "${f#./}: invalid JSON → ${out#PARSE_ERROR }" ;;
    "") : ;;
    *) warn "${f#./}: suspicious env value → $out" ;;
  esac
done < <(find "$ROOT" -name node_modules -prune -o -name '.mcp.json' -print 2>/dev/null)
[ "$mcp_count" -eq 0 ] && echo "(no .mcp.json found)" || ok "$mcp_count .mcp.json scanned"
echo

# ---------------- 2. per-repo presence table ----------------
echo "──── CONFIG COVERAGE ────"
printf '%-38s %-7s %-7s %-9s %-9s %-7s\n' REPO AGENTS SKILLS SETTINGS CLAUDE.md .mcp.json
printf '%-38s %-7s %-7s %-9s %-9s %-7s\n' "$(printf '%.38s' '--------------------------------------')" ------ ------ -------- --------- ---------
n_repo=0; n_ag=0; n_sk=0; n_set=0; n_cl=0; n_mcp=0
while IFS= read -r repo; do
  rel="${repo#./}"
  is_excluded "$rel/" && continue
  [ "$rel" = "$ROOT" ] && continue
  base="$(basename "$rel")"
  n_repo=$((n_repo+1))
  ag=$(ls "$repo/.claude/agents/"*.md 2>/dev/null | wc -l | tr -d ' ')
  sk=$(ls -d "$repo/.claude/skills/"*/ 2>/dev/null | wc -l | tr -d ' ')
  set=$([ -f "$repo/.claude/settings.json" ] && echo Y || echo -)
  cl=$([ -f "$repo/CLAUDE.md" ] && echo Y || echo -)
  mcp=$([ -f "$repo/.mcp.json" ] && echo Y || echo -)
  [ "$ag" -gt 0 ] && n_ag=$((n_ag+1))
  [ "$sk" -gt 0 ] && n_sk=$((n_sk+1))
  [ "$set" = Y ] && n_set=$((n_set+1))
  [ "$cl" = Y ] && n_cl=$((n_cl+1))
  [ "$mcp" = Y ] && n_mcp=$((n_mcp+1))
  printf '%-38s %-7s %-7s %-9s %-9s %-7s\n' "$base" "$ag" "$sk" "$set" "$cl" "$mcp"
  if [ "$STRICT" -eq 1 ]; then
    [ "$ag" -eq 0 ] && warn "$base: no .claude/agents"
    [ "$set" = - ] && warn "$base: no .claude/settings.json"
    [ "$cl"  = - ] && warn "$base: no CLAUDE.md"
  fi
done < <(discover_repos)
echo
echo "coverage: repos=$n_repo  agents=$n_ag  skills=$n_sk  settings=$n_set  CLAUDE.md=$n_cl  .mcp.json=$n_mcp"
echo

# ---------------- verdict ----------------
echo "────────────────────────────────────────────"
echo "errors=$ERR  warnings=$WARN"
if [ "$ERR" -gt 0 ]; then echo "$(red FAIL)"; exit 1; fi
if [ "$STRICT" -eq 1 ] && [ "$WARN" -gt 0 ]; then echo "$(red 'FAIL (strict)')"; exit 1; fi
echo "$(grn PASS)"; exit 0
