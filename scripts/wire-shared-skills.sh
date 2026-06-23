#!/usr/bin/env bash
# wire-shared-skills.sh — reference the right shared skills in each repo's CLAUDE.md, by tech detection.
# Idempotent. DRY-RUN by default. Adds skill lines under "## Skills" (creating it if absent), never
# duplicates, never removes. Run from the chrysa root.
#
# Detection -> skills (matches each skill's "When to invoke"):
#   pytest/tests           -> testing-pytest
#   Dockerfile             -> dockerfile-multistage
#   FastAPI                -> api-design, async-patterns, clean-architecture, error-handling
#   agents (LangGraph/PydanticAI/Claude API, or known agent repos) -> agent-patterns
#   chrysa-lib or @chrysa/* consumer -> contract-testing
#
# Usage: ./wire-shared-skills.sh [--apply] [--exclude GLOB]...   (run from chrysa root)
set -uo pipefail

APPLY=0; EXCLUDES=()
while [ $# -gt 0 ]; do case "$1" in
  --apply) APPLY=1; shift ;;
  --exclude) shift; EXCLUDES+=("${1:?}"); shift ;;
  -h|--help) sed -n '2,16p' "$0"; exit 0 ;;
  *) echo "unknown arg: $1" >&2; exit 2 ;;
esac; done
is_excluded() { local p="$1" pat; for pat in "${EXCLUDES[@]:-}"; do case "$p" in $pat) return 0;; *) ;; esac; done; return 1; }

# short description per shared skill (used when writing the reference line)
desc() { case "$1" in
  testing-pytest)       echo "pytest DDD + pytest-mock + constants (load when writing tests)";;
  dockerfile-multistage) echo "4-stage Python 3.14 containers (load when editing Dockerfile)";;
  api-design)           echo "REST standards + FastAPI patterns (load when designing endpoints)";;
  async-patterns)       echo "async FastAPI + SQLAlchemy async sessions (load when writing async code)";;
  clean-architecture)   echo "FastAPI module/layer structure (load when adding a domain feature)";;
  error-handling)       echo "FastAPI error handling + Sentry + logging (load when handling errors)";;
  contract-testing)     echo "library contract / breaking-change tests (load when releasing @chrysa/* or adding a consumer)";;
  agent-patterns)       echo "LangGraph + PydanticAI + Claude API agent patterns (load when building agents)";;
  ui-ux)                echo "UX/UI/ergonomics across surfaces + WCAG 2.1 AA + dark mode + i18n (load when building any human-facing surface)";;
  *) echo "shared skill";;
esac; }

AGENT_REPOS=" lifeos ai-aggregator discord-bot-back orchestrator my-assistant coach paperclip floating-agent "

applicable_skills() {  # echo space-separated skill names for repo $1
  local r="$1" out=""
  local pyproj="$r/pyproject.toml" reqs; reqs="$(ls "$r"/requirements*.txt 2>/dev/null)"
  local deps=""; [ -f "$pyproj" ] && deps+="$(cat "$pyproj" 2>/dev/null)"; [ -n "$reqs" ] && deps+="$(cat $reqs 2>/dev/null)"
  local pkg="$r/package.json"; local pkgtxt=""; [ -f "$pkg" ] && pkgtxt="$(cat "$pkg" 2>/dev/null)"

  # testing-pytest
  if [ -d "$r/tests" ] || printf '%s' "$deps" | grep -qiE 'pytest'; then out+=" testing-pytest"; fi
  # dockerfile-multistage
  if find "$r" -maxdepth 2 -iname 'Dockerfile*' 2>/dev/null | grep -q .; then out+=" dockerfile-multistage"; fi
  # FastAPI family — only when the repo's OWN root pyproject/requirements declares fastapi as a
  # dependency. Source-grep was dropped: it false-matched FastAPI sample code in test fixtures and
  # scaffolder templates (e.g. pre-commit-tools, fastapi-app-forge).
  if printf '%s' "$deps" | grep -qiE 'fastapi[[:space:]]*[=>~"]'; then
    out+=" api-design async-patterns clean-architecture error-handling"
  fi
  # agent-patterns
  if printf '%s' "$deps" | grep -qiE 'langgraph|pydantic-ai|pydantic_ai|anthropic|langchain' \
     || printf '%s' "$AGENT_REPOS" | grep -q " $(basename "$r") "; then out+=" agent-patterns"; fi
  # contract-testing
  if [ "$(basename "$r")" = "chrysa-lib" ] || printf '%s' "$pkgtxt" | grep -q '@chrysa/'; then out+=" contract-testing"; fi

  echo "$out" | tr ' ' '\n' | sed '/^$/d' | sort -u | tr '\n' ' '
}

ensure_skill_line() {  # $1=repo $2=skill ; adds the reference line if missing (APPLY), else reports
  local r="$1"; local s="$2"; local f="$r/CLAUDE.md"
  grep -q "\`$s/SKILL.md\`" "$f" 2>/dev/null && return 1   # already present
  local line="- \`$s/SKILL.md\` — $(desc "$s")"
  if [ $APPLY -eq 1 ]; then
    if grep -qE '^## Skills[[:space:]]*$' "$f"; then
      awk -v l="$line" '{print} /^## Skills[[:space:]]*$/ && !d {print ""; print l; d=1}' "$f" > "$f.tmp" && mv "$f.tmp" "$f"
    else
      printf '\n## Skills\n\nShared skills from `shared-standards/.claude/skills/`:\n%s\n' "$line" >> "$f"
    fi
  fi
  return 0
}

added_total=0
for g in $(find . -mindepth 2 -maxdepth 2 -type d -name .git ! -path '*_archived*' 2>/dev/null | sort); do
  repo="$(dirname "$g")"; rel="${repo#./}"
  is_excluded "$rel" && continue
  [ -f "$repo/CLAUDE.md" ] || continue
  skills="$(applicable_skills "$repo")"
  [ -z "$skills" ] && continue
  toadd=""
  for s in $skills; do grep -q "\`$s/SKILL.md\`" "$repo/CLAUDE.md" || toadd+=" $s"; done
  toadd="$(echo "$toadd" | xargs 2>/dev/null)"
  [ -z "$toadd" ] && continue
  if [ $APPLY -eq 1 ]; then
    for s in $toadd; do ensure_skill_line "$repo" "$s" >/dev/null && added_total=$((added_total+1)); done
    echo "++  $rel: + $toadd"
  else
    echo "DRY $rel: would add -> $toadd"
  fi
done
echo "────────────────"
echo "$([ $APPLY -eq 1 ] && echo "added $added_total skill reference(s)" || echo "dry-run; pass --apply to write")"
