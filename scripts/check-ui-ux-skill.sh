#!/usr/bin/env bash
# check-ui-ux-skill.sh — repo-agnostic CI/lint guard for the `ui-ux` skill reference.
#
# Policy: every project with a human-facing surface MUST reference the ui-ux skill in its CLAUDE.md.
# A project with no human-facing surface (pure lib / infra) opts out EXPLICITLY by adding this
# marker anywhere in its CLAUDE.md (documented exception):
#     <!-- ui-ux-skill: not-applicable -- reason: <why> -->
#
# Fully portable: no hard-coded repo names, paths, or directory layout. Discovers git repos at any
# depth, prunes build/vendor noise, and treats each repo's top-level CLAUDE.md as the unit checked.
#
# Usage:
#   check-ui-ux-skill.sh                      # CI mode: check the current git repo (or ./CLAUDE.md)
#   check-ui-ux-skill.sh <file-or-dir>        # check a CLAUDE.md file, or a single repo dir
#   check-ui-ux-skill.sh --all [ROOT]         # scan every git repo under ROOT (default: .)
#   check-ui-ux-skill.sh --all --exclude PAT  # repeatable; glob matched against repo path
#
# Config via env (all optional):
#   UIUX_REF       substring that must appear in CLAUDE.md   (default: "ui-ux/SKILL.md")
#   UIUX_OPTOUT    opt-out marker substring                  (default: "ui-ux-skill: not-applicable")
#   UIUX_PRUNE     extra space-separated dir names to prune   (added to the noise defaults)
#
# Exit codes: 0 = all good / no applicable repos, 1 = violation(s), 2 = usage error.
#
# CI (per repo, .github/workflows/ci.yml):
#   - run: bash path/to/check-ui-ux-skill.sh
# Monorepo / batch:
#   - run: bash path/to/check-ui-ux-skill.sh --all

set -euo pipefail

REF="${UIUX_REF:-ui-ux/SKILL.md}"
OPTOUT="${UIUX_OPTOUT:-ui-ux-skill: not-applicable}"
PRUNE_DIRS=(node_modules .venv venv dist build out vendor target .next .nuxt .cache coverage site-packages ${UIUX_PRUNE:-})
EXCLUDES=()
RC=0
CHECKED=0

usage() { sed -n '2,33p' "$0"; }

# Returns 0 if path matches any --exclude glob.
is_excluded() {
  local p="$1" pat
  for pat in "${EXCLUDES[@]:-}"; do
    [ -n "$pat" ] || continue
    # shellcheck disable=SC2053
    case "$p" in $pat) return 0 ;; *) ;; esac
  done
  return 1
}

check_file() {
  local file="$1" label="${2:-$1}"
  if [ ! -f "$file" ]; then
    echo "➖ $label — no CLAUDE.md (skipped)"
    return 0
  fi
  CHECKED=$((CHECKED + 1))
  if grep -qF "$OPTOUT" "$file"; then
    echo "➖ $label — exempt (documented not-applicable)"
    return 0
  fi
  if grep -qF "$REF" "$file"; then
    echo "✅ $label — references $REF"
    return 0
  fi
  echo "❌ $label — MISSING '$REF' reference"
  echo "   fix: add it under '## Skills', or declare an exception in CLAUDE.md:"
  echo "        <!-- $OPTOUT -- reason: <why this repo has no human-facing surface> -->"
  RC=1
  return 0
}

# Print repo root dirs (parents of .git) under $1, pruning noise dirs.
discover_repos() {
  local root="$1"
  local prune_expr=() d first=1
  for d in "${PRUNE_DIRS[@]}"; do
    [ -n "$d" ] || continue
    if [ $first -eq 1 ]; then prune_expr+=( -name "$d" ); first=0
    else prune_expr+=( -o -name "$d" ); fi
  done
  if [ ${#prune_expr[@]} -gt 0 ]; then
    find "$root" \( "${prune_expr[@]}" \) -prune -o -type d -name .git -print 2>/dev/null
  else
    find "$root" -type d -name .git -print 2>/dev/null
  fi | while IFS= read -r g; do dirname "$g"; done | sort -u
}

scan_all() {
  local root="${1:-.}"
  local repo rel
  while IFS= read -r repo; do
    rel="${repo#./}"
    if is_excluded "$rel" || is_excluded "$repo"; then
      echo "➖ $rel — excluded"
      continue
    fi
    check_file "$repo/CLAUDE.md" "$rel"
  done < <(discover_repos "$root")
}

# ---- arg parsing ----
MODE="ci"; ROOT="."; TARGET=""
while [ $# -gt 0 ]; do
  case "$1" in
    --all) MODE="all"; shift; if [ $# -gt 0 ] && [ "${1:0:1}" != "-" ]; then ROOT="$1"; shift; fi ;;
    --exclude) shift; [ $# -gt 0 ] || { echo "--exclude needs a pattern" >&2; exit 2; }; EXCLUDES+=("$1"); shift ;;
    -h|--help) usage; exit 0 ;;
    --*) echo "unknown flag: $1" >&2; exit 2 ;;
    *) TARGET="$1"; shift ;;
  esac
done

if [ "$MODE" = "all" ]; then
  scan_all "$ROOT"
elif [ -n "$TARGET" ]; then
  if [ -d "$TARGET" ]; then check_file "$TARGET/CLAUDE.md" "$TARGET"
  else check_file "$TARGET" "$TARGET"; fi
else
  # CI mode: prefer the enclosing git repo root, fall back to cwd.
  root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  check_file "$root/CLAUDE.md" "$(basename "$root")"
fi

if [ $RC -ne 0 ]; then
  echo
  echo "FAIL: missing '$REF' reference (see UX/UI guidelines)."
else
  echo
  echo "OK: $CHECKED CLAUDE.md checked, no violations."
fi
exit $RC
