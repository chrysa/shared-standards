#!/usr/bin/env bash
# purge-artifacts.sh · Remove regenerable machine artifacts across the fleet and
# stop tracking any that slipped into git. Centralizes the fleet-wide cleanup
# lever (audit 2026-07-18: ~440 cleanup candidates, ~219 machine cruft).
# Source: chrysa/shared-standards/scripts/purge-artifacts.sh
#
# What it removes (SAFE tier, default): purely regenerable caches/build output —
#   __pycache__, *.pyc, *.egg-info, build/, dist/, .venv-less caches
#   (.mypy_cache .ruff_cache .pytest_cache .benchmarks), coverage.xml .coverage
#   htmlcov/, test-results/ playwright-report/ .playwright-mcp/,
#   graphify-out/ .codegraph/ .import_linter_cache/, .svelte-kit/ .turbo/.
# HEAVY tier (--heavy): also node_modules/ and .venv/ (costly to reinstall).
#
# NEVER touched: .env / .env.*, *.db *.sqlite* outside the caches above, docker
#   volumes, seeds/, anything not on the explicit allowlist. When in doubt it is
#   left alone. This script deletes only names it recognizes as regenerable.
#
# For tracked matches it runs `git rm -r --cached` (with --apply) so the artifact
# stops being committed; on-disk files are then removed too.
#
# Usage:
#   bash purge-artifacts.sh --dry-run <repo_path>     # preview one repo (default)
#   bash purge-artifacts.sh --apply   <repo_path>     # delete for real
#   bash purge-artifacts.sh --dry-run --all <root>    # preview every git repo under <root>
#   bash purge-artifacts.sh --apply --all --heavy <root>
#
# Exit: 0 ok · 1 error · 2 path absent
set -uo pipefail

APPLY=0; ALL=0; HEAVY=0; UNTRACK=0; TARGET=""; ROOT=""
while [ $# -gt 0 ]; do
  case "$1" in
    --apply) APPLY=1 ;;
    --dry-run) APPLY=0 ;;
    --all) ALL=1 ;;
    --heavy) HEAVY=1 ;;
    --untrack) UNTRACK=1 ;;
    -h|--help) grep '^#' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) if [ $ALL -eq 1 ]; then ROOT="$1"; else TARGET="$1"; fi ;;
  esac
  shift
done

# Directory names removed wherever they appear inside a repo.
SAFE_DIRS="__pycache__ .mypy_cache .ruff_cache .pytest_cache .benchmarks
  htmlcov .import_linter_cache graphify-out .codegraph test-results
  playwright-report .playwright-mcp .svelte-kit .turbo build dist"
HEAVY_DIRS="node_modules .venv"
# Glob patterns removed at any depth.
SAFE_GLOBS="*.egg-info *.pyc coverage.xml .coverage .coverage.*"

freed=0; removed=0

purge_repo() {
  repo="$1"
  [ -e "$repo/.git" ] || { echo "  skip (not a git repo): $repo"; return; }
  dirs="$SAFE_DIRS"; [ $HEAVY -eq 1 ] && dirs="$dirs $HEAVY_DIRS"
  # collect matches (prune so we do not descend into a match)
  # shellcheck disable=SC2086
  prune_expr=""
  for d in $dirs; do prune_expr="$prune_expr -name $d -o"; done
  matches=$(cd "$repo" && find . -type d \( ${prune_expr% -o} \) -prune -print 2>/dev/null)
  for g in $SAFE_GLOBS; do
    matches="$matches
$(cd "$repo" && find . -name "$g" -not -path '*/.git/*' 2>/dev/null)"
  done
  matches=$(printf '%s\n' "$matches" | sed '/^$/d' | sort -u)
  [ -z "$matches" ] && return
  echo "── $repo"
  while IFS= read -r m; do
    [ -z "$m" ] && continue
    path="$repo/${m#./}"
    sz=$(du -sh "$path" 2>/dev/null | cut -f1)
    tracked=""
    (cd "$repo" && git ls-files --error-unmatch "${m#./}" >/dev/null 2>&1) && tracked=" [TRACKED]"
    # Tracked artifacts are left alone unless --untrack, so --apply never
    # dirties a repo index by surprise.
    if [ -n "$tracked" ] && [ $UNTRACK -eq 0 ]; then
      echo "  KEEP (tracked, use --untrack)  $sz  ${m#./}"
      continue
    fi
    if [ $APPLY -eq 1 ]; then
      [ -n "$tracked" ] && (cd "$repo" && git rm -r --cached --quiet "${m#./}" 2>/dev/null)
      rm -rf "$path" 2>/dev/null || sudo rm -rf "$path" 2>/dev/null
      echo "  removed  $sz  ${m#./}$tracked"
    else
      echo "  would remove  $sz  ${m#./}$tracked"
    fi
    removed=$((removed + 1))
  done <<EOF
$matches
EOF
}

if [ $ALL -eq 1 ]; then
  [ -d "$ROOT" ] || { echo "root absent: $ROOT" >&2; exit 2; }
  while IFS= read -r gitdir; do purge_repo "$(dirname "$gitdir")"; done \
    < <(find "$ROOT" -maxdepth 3 -type d -name .git 2>/dev/null | sort)
else
  [ -d "$TARGET" ] || { echo "path absent: $TARGET" >&2; exit 2; }
  purge_repo "$TARGET"
fi

echo
[ $APPLY -eq 1 ] && echo "Done — $removed artifact path(s) removed." \
                 || echo "Dry-run — $removed artifact path(s) would be removed. Re-run with --apply."
exit 0
