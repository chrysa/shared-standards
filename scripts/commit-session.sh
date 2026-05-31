#!/usr/bin/env bash
# commit-session.sh — branch + commit (+ optional push + PR) this session's changes, one repo
# at a time. Safe-by-default: NOTHING happens without --apply. Run from the chrysa root.
#
# Lifecycle per repo: ensure session branch (from base) -> commit pending paths -> push -> open PR.
# Base branch = develop || main || master (chrysa convention: PRs target develop).
#
# Categories:
#   ui-ux repos       any repo with the ui-ux CLAUDE.md change -> chore/ui-ux-skill-ref
#   shared-standards  docs/ scripts/ workflows/ template/ skill -> feat/ui-ux-standard
#   claude-config     claude/agents/*                           -> feat/deploy-validated-agents
#
# Usage:
#   ./commit-session.sh                       # dry-run plan
#   ./commit-session.sh --apply               # commit only (no push, no PR)
#   ./commit-session.sh --apply --push        # commit + push
#   ./commit-session.sh --apply --pr ...      # commit + push + open PR (needs gh auth + issue strategy)
#
# PR issue strategy (pick ONE with --pr; enforce-issue-link blocks PRs otherwise):
#   --issue N        link every PR to one umbrella issue   (body: "Refs #N")
#   --new-issues     create one issue per repo             (body: "Closes #<n>")
#   --hotfix         add the "hotfix" label (documented enforce-issue-link exemption)
#
#   --remote NAME    push remote (default: origin)
#   --exclude GLOB   skip repos matching glob (repeatable)
#
# WARNING: --push/--pr fire CI on every repo and trigger notion-branch-sync. --pr can also create
# issues and PRs in bulk. Requires `gh` authenticated (gh auth login). Exit: 0 ok, 2 usage.

set -uo pipefail

APPLY=0; PUSH=0; PR=0; MK_ISSUE=0; HOTFIX=0; ISSUE=""; REMOTE="origin"; EXCLUDES=()
while [ $# -gt 0 ]; do
  case "$1" in
    --apply) APPLY=1; shift ;;
    --push)  PUSH=1; shift ;;
    --pr)    PR=1; shift ;;
    --new-issues) MK_ISSUE=1; shift ;;
    --hotfix) HOTFIX=1; shift ;;
    --issue) shift; ISSUE="${1:?--issue needs a number}"; shift ;;
    --remote) shift; REMOTE="${1:?--remote needs a name}"; shift ;;
    --exclude) shift; EXCLUDES+=("${1:?}"); shift ;;
    -h|--help) sed -n '2,33p' "$0"; exit 0 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

# --pr/--push do nothing without --apply (safe-by-default preview)
[ $PR -eq 1 ] && PUSH=1   # opening a PR requires the branch to be pushed first

is_excluded() { local p="$1" pat; for pat in "${EXCLUDES[@]:-}"; do case "$p" in $pat) return 0;; esac; done; return 1; }
trailer() { [ -n "$ISSUE" ] && printf 'Refs #%s' "$ISSUE" || true; }
base_branch() { local r="$1" b; for b in develop main master; do git -C "$r" show-ref --verify --quiet "refs/heads/$b" && { echo "$b"; return; }; done; }

# Pre-flight: if PR requested for real, gh must be authenticated, and an issue strategy chosen.
if [ $APPLY -eq 1 ] && [ $PR -eq 1 ]; then
  command -v gh >/dev/null 2>&1 || { echo "❌ --pr needs the GitHub CLI (gh). Install it first." >&2; exit 2; }
  gh auth status >/dev/null 2>&1 || { echo "❌ --pr needs gh authenticated. Run: gh auth login" >&2; exit 2; }
  if [ -z "$ISSUE" ] && [ $MK_ISSUE -eq 0 ] && [ $HOTFIX -eq 0 ]; then
    echo "❌ --pr needs an issue strategy: --issue N | --new-issues | --hotfix" >&2; exit 2
  fi
fi

# do_repo <repo> <branch> <commit-msg> <issue-title> <path...>
do_repo() {
  local repo="$1" br="$2" msg="$3" ititle="$4"; shift 4
  local paths=( "$@" ) rel="${repo#./}"
  [ -d "$repo/.git" ] || { echo "--  skip $rel (not a git repo)"; return; }
  local base; base="$(base_branch "$repo")"
  [ -z "$base" ] && { echo "!!  $rel: no develop/main/master base — skip"; return; }

  local pending; pending="$(git -C "$repo" status --porcelain -- "${paths[@]}" 2>/dev/null)"
  local exists=0 ahead=0
  if git -C "$repo" show-ref --verify --quiet "refs/heads/$br"; then
    exists=1; ahead="$(git -C "$repo" rev-list --count "$base..$br" 2>/dev/null || echo 0)"
  fi
  if [ -z "$pending" ] && [ "$ahead" = "0" ] && [ "$exists" = "0" ]; then echo "==  $rel: nothing to do"; return; fi

  if [ $APPLY -eq 0 ]; then
    printf "DRY %s: base=%s branch=%s pending=%s ahead=%s%s%s\n" "$rel" "$base" "$br" \
      "$([ -n "$pending" ] && echo yes || echo no)" "$ahead" \
      "$([ $PUSH -eq 1 ] && echo ' +push')" "$([ $PR -eq 1 ] && echo ' +PR')"
    return
  fi

  git -C "$repo" -c core.hooksPath= switch -c "$br" 2>/dev/null \
    || git -C "$repo" -c core.hooksPath= switch "$br" 2>/dev/null \
    || { echo "!!  $rel: cannot switch to $br"; return; }
  if [ -n "$pending" ]; then
    git -C "$repo" add -- "${paths[@]}" 2>/dev/null
    git -C "$repo" diff --cached --quiet || { local t; t="$(trailer)"; git -C "$repo" commit -q -m "$msg${t:+

$t}"; }
  fi
  ahead="$(git -C "$repo" rev-list --count "$base..$br" 2>/dev/null || echo 0)"
  [ "$ahead" = "0" ] && { echo "==  $rel: no commits ahead of $base — skip push/PR"; return; }
  echo "++  $rel: $ahead commit(s) on '$br' (base $base)"

  if [ $PUSH -eq 1 ]; then
    git -C "$repo" push -u "$REMOTE" "$br" >/dev/null 2>&1 \
      && echo "↑   $rel: pushed '$br' -> $REMOTE" || { echo "!!  $rel: push failed (remote/auth)"; return; }
  fi

  if [ $PR -eq 1 ]; then
    local existing_pr; existing_pr="$( cd "$repo" && timeout 30 gh pr list --head "$br" --state open --json number --jq 'length' 2>/dev/null )"
    if [ "${existing_pr:-0}" -gt 0 ] 2>/dev/null; then echo "==  $rel: PR already open"; return; fi
    local iref="" label_args=()
    if [ -n "$ISSUE" ]; then iref="Refs #$ISSUE"
    elif [ $MK_ISSUE -eq 1 ]; then
      local iurl; iurl="$( cd "$repo" && timeout 30 gh issue create --title "$ititle" --body "$msg" 2>/dev/null )"
      local inum="${iurl##*/}"; [ -n "$inum" ] && iref="Closes #$inum" && echo "•   $rel: issue #$inum created"
    fi
    if [ $HOTFIX -eq 1 ]; then
      ( cd "$repo" && timeout 20 gh label create hotfix --color E4E669 --description "Hotfix — no issue required" >/dev/null 2>&1 ) || true
      label_args=(--label hotfix)
    fi
    local pr_err
    if pr_err="$( cd "$repo" && timeout 60 gh pr create --base "$base" --head "$br" --title "$msg" \
           --body "${msg}${iref:+

$iref}" ${label_args[@]+"${label_args[@]}"} 2>&1 )"; then
      echo "PR  $rel: opened ($br -> $base)${iref:+, $iref}"
    else
      echo "!!  $rel: gh pr create failed: ${pr_err%%$'\n'*}"
    fi
  fi
}

echo "APPLY=$APPLY PUSH=$PUSH PR=$PR  issue=${ISSUE:-$([ $MK_ISSUE -eq 1 ] && echo per-repo || ([ $HOTFIX -eq 1 ] && echo hotfix-label || echo none))}  remote=$REMOTE"
echo "── ui-ux repos (CLAUDE.md) ─────────────────────────────"
while IFS= read -r g; do
  repo="$(dirname "$g")"; rel="${repo#./}"
  case "$rel" in shared-standards|claude-config) continue;; esac
  is_excluded "$rel" && continue
  do_repo "$repo" "chore/ui-ux-skill-ref" \
    "chore(ui-ux): reference ui-ux skill in CLAUDE.md" \
    "Reference the ui-ux skill in CLAUDE.md" "CLAUDE.md"
done < <(find . -mindepth 2 -maxdepth 2 -name .git ! -path '*_archived*' | sort)

echo "── shared-standards ────────────────────────────────────"
do_repo "./shared-standards" "feat/ui-ux-standard" \
  "feat(ui-ux): UX/UI ergonomics standard, skill module + audit tooling" \
  "Add UX/UI standard, ui-ux skill module and audit tooling" \
  "docs/UX-UI-GUIDELINES.md" "docs/UX-UI-SKILLS-AUDIT.md" "docs/ui-ux.SKILL.md" \
  "docs/wire-ui-ux-skill.sh" ".claude/skills/ui-ux" "templates/CLAUDE.md" \
  "scripts/check-ui-ux-skill.sh" "scripts/check-skills-agents.sh" \
  "scripts/gen-skills-agents-audit.sh" "scripts/commit-session.sh" \
  "workflows/ui-ux-skill-check.yml" "workflows/skills-agents-audit.yml"

echo "── claude-config (deployed agents) ─────────────────────"
do_repo "./claude-config" "feat/deploy-validated-agents" \
  "feat(agents): deploy 12 validated agents from agent-config" \
  "Deploy 12 validated agents from agent-config" \
  "claude/agents"

echo "────────────────────────────────────────────────────────"
echo "done."
[ $PR -eq 0 ] && echo "No PRs opened (pass --apply --pr with an issue strategy to open them)."
