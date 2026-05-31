#!/usr/bin/env bash
# wire-ui-ux-skill.sh — back-fill the `ui-ux` skill reference into project CLAUDE.md files.
# Idempotent. DRY-RUN by default. Respects the "1 PR per issue" rule: run it scoped to a
# batch of projects, review the diff, open one PR, repeat.
#
# Usage:
#   ./wire-ui-ux-skill.sh                      # dry-run, all front+surface projects under chrysa/
#   ./wire-ui-ux-skill.sh --apply             # actually edit files
#   ./wire-ui-ux-skill.sh --apply dev-nexus doc-gen   # only these projects
#   ./wire-ui-ux-skill.sh --install-module    # also place the skill module in shared-standards
#
# Run from the chrysa/ root (the folder that contains shared-standards/ and the projects).

set -euo pipefail

ROOT="$(pwd)"
APPLY=0
INSTALL_MODULE=0
TARGETS=()

REF_LINE='- `ui-ux/SKILL.md` — UX/UI/ergonomics across ALL surfaces (web, CLI, VS Code, Discord, desktop, game, agent) + WCAG 2.1 AA + dark mode + i18n FR+EN (load when building any human-facing surface)'
SKILLS_HEADER='## Skills'
SKILLS_BLOCK="$SKILLS_HEADER

Shared skills from \`shared-standards/.claude/skills/\`:
$REF_LINE"

for arg in "$@"; do
  case "$arg" in
    --apply) APPLY=1 ;;
    --install-module) INSTALL_MODULE=1 ;;
    --*) echo "unknown flag: $arg" >&2; exit 2 ;;
    *) TARGETS+=("$arg") ;;
  esac
done

# Default project set: every immediate subdir with a CLAUDE.md, excluding archives/infra-only.
if [ ${#TARGETS[@]} -eq 0 ]; then
  while IFS= read -r d; do TARGETS+=("$d"); done < <(
    find . -mindepth 2 -maxdepth 2 -name CLAUDE.md \
      ! -path "./_archived/*" -printf '%h\n' | sed 's#^\./##' | sort -u
  )
fi

install_module() {
  local dest="shared-standards/.claude/skills/ui-ux"
  if [ ! -f ui-ux.SKILL.md ]; then
    echo "!! ui-ux.SKILL.md not found in $(pwd) — place it here first." >&2; return 1
  fi
  if [ $APPLY -eq 1 ]; then
    mkdir -p "$dest"
    cp ui-ux.SKILL.md "$dest/SKILL.md"
    echo "++ installed $dest/SKILL.md"
  else
    echo "DRY  would install $dest/SKILL.md (from ./ui-ux.SKILL.md)"
  fi
}

wire_one() {
  local proj="$1"
  local file="$proj/CLAUDE.md"
  [ -f "$file" ] || { echo "--  skip $proj (no CLAUDE.md)"; return; }
  if grep -q 'ui-ux/SKILL.md' "$file"; then
    echo "==  ok   $proj (already references ui-ux)"; return
  fi
  if grep -qE "^## Skills[[:space:]]*$" "$file"; then
    # Append the ref line right after the existing "## Skills" header line.
    if [ $APPLY -eq 1 ]; then
      awk -v line="$REF_LINE" '
        {print}
        /^## Skills[[:space:]]*$/ && !done {print ""; print line; done=1}
      ' "$file" > "$file.tmp" && mv "$file.tmp" "$file"
      echo "++  add  $proj (into existing ## Skills)"
    else
      echo "DRY  would add ref into existing ## Skills of $proj"
    fi
  else
    if [ $APPLY -eq 1 ]; then
      printf '\n%s\n' "$SKILLS_BLOCK" >> "$file"
      echo "++  add  $proj (new ## Skills section)"
    else
      echo "DRY  would append new ## Skills section to $proj"
    fi
  fi
}

echo "ROOT=$ROOT  APPLY=$APPLY  projects=${#TARGETS[@]}"
[ $INSTALL_MODULE -eq 1 ] && install_module
for p in "${TARGETS[@]}"; do wire_one "$p"; done
echo "done. Review with: git -C <repo> diff   then commit on a branch + open one PR per issue."
