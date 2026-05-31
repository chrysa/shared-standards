#!/usr/bin/env bash
# commit-session.sh — branch + commit this session's changes, one repo at a time. NEVER pushes.
#
# Respects "1 PR per issue": each repo gets its own branch + conventional commit, left local for
# you to push and open a PR. Dry-run by default. Run from the chrysa root.
#
# Categories handled:
#   ui-ux repos       any repo with a dirty CLAUDE.md  -> branch chore/ui-ux-skill-ref
#                                                         commit CLAUDE.md only
#   shared-standards  docs/ scripts/ workflows/ template/ skill module
#                                                       -> branch feat/ui-ux-standard
#   claude-config     claude/agents/*                   -> branch feat/deploy-validated-agents
#
# Usage:
#   ./commit-session.sh                 # dry-run plan
#   ./commit-session.sh --apply         # create branches + commit (no push)
#   ./commit-session.sh --push          # DRY-RUN preview of commit+push (no mutation)
#   ./commit-session.sh --apply --push  # commit AND push each branch (requires --apply)
#   ./commit-session.sh --apply --push --remote upstream   # push to a non-default remote
#   ./commit-session.sh --apply --issue 123   # add "Refs #123" trailer to each commit
#   ./commit-session.sh --exclude '*_archived*'
#
# WARNING: --push fires CI on every repo and triggers notion-branch-sync (push-on-every-branch).
# It still does NOT open PRs — push only. Open one PR per repo and link the issue yourself.
#
# Exit: 0 ok, 2 usage.

set -uo pipefail

APPLY=0; ISSUE=""; EXCLUDES=(); PUSH=0; REMOTE="origin"
while [ $# -gt 0 ]; do
  case "$1" in
    --apply) APPLY=1; shift ;;
    --push)  PUSH=1; shift ;;            # push after commit; REQUIRES --apply to actually run
    --remote) shift; REMOTE="${1:?--remote needs a name}"; shift ;;
    --issue) shift; ISSUE="${1:?--issue needs a number}"; shift ;;
    --exclude) shift; EXCLUDES+=("${1:?}"); shift ;;
    -h|--help) sed -n '2,32p' "$0"; exit 0 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

trailer() { [ -n "$ISSUE" ] && printf '\n\nRefs #%s' "$ISSUE" || true; }
is_excluded() { local p="$1" pat; for pat in "${EXCLUDES[@]:-}"; do case "$p" in $pat) return 0;; esac; done; return 1; }

# commit_repo <repo> <branch> <commit-msg> <path...>
commit_repo() {
  local repo="$1" br="$2" msg="$3"; shift 3
  local paths=( "$@" )
  [ -d "$repo/.git" ] || { echo "--  skip ${repo#./} (not a git repo)"; return; }
  # is there anything to commit among the given paths?
  local dirty; dirty="$(git -C "$repo" status --porcelain -- "${paths[@]}" 2>/dev/null)"
  if [ -z "$dirty" ]; then echo "==  ${repo#./}: nothing to commit"; return; fi
  if [ $APPLY -eq 0 ]; then
    echo "DRY ${repo#./}: branch '$br' + commit $(echo "$dirty" | wc -l | tr -d ' ') path(s): ${paths[*]}$([ $PUSH -eq 1 ] && echo " + push $REMOTE")"
    return
  fi
  git -C "$repo" switch -c "$br" 2>/dev/null || git -C "$repo" switch "$br" 2>/dev/null || {
    echo "!!  ${repo#./}: could not switch to '$br'"; return; }
  git -C "$repo" add -- "${paths[@]}" 2>/dev/null
  if git -C "$repo" diff --cached --quiet; then echo "==  ${repo#./}: nothing staged"; return; fi
  git -C "$repo" commit -q -m "$msg$(trailer)" || { echo "!!  ${repo#./}: commit failed"; return; }
  echo "++  ${repo#./}: committed on '$br'"
  if [ $PUSH -eq 1 ]; then
    if git -C "$repo" push -u "$REMOTE" "$br" 2>/dev/null; then echo "↑   ${repo#./}: pushed '$br' to $REMOTE"; else echo "!!  ${repo#./}: push to $REMOTE failed (check remote/auth)"; fi
  fi
}

echo "APPLY=$APPLY  PUSH=$PUSH  REMOTE=$REMOTE  ISSUE=${ISSUE:-none}"
echo "── ui-ux repos (CLAUDE.md) ─────────────────────────────"
while IFS= read -r g; do
  repo="$(dirname "$g")"; rel="${repo#./}"
  case "$rel" in shared-standards|claude-config) continue;; esac
  is_excluded "$rel" && continue
  commit_repo "$repo" "chore/ui-ux-skill-ref" "chore(ui-ux): reference ui-ux skill in CLAUDE.md" "CLAUDE.md"
done < <(find . -mindepth 2 -maxdepth 2 -name .git ! -path '*_archived*' | sort)

echo "── shared-standards ────────────────────────────────────"
commit_repo "./shared-standards" "feat/ui-ux-standard" \
  "feat(ui-ux): UX/UI ergonomics standard, skill module + audit tooling" \
  "docs/UX-UI-GUIDELINES.md" "docs/UX-UI-SKILLS-AUDIT.md" "docs/ui-ux.SKILL.md" \
  "docs/wire-ui-ux-skill.sh" ".claude/skills/ui-ux" "templates/CLAUDE.md" \
  "scripts/check-ui-ux-skill.sh" "scripts/check-skills-agents.sh" \
  "scripts/gen-skills-agents-audit.sh" "scripts/commit-session.sh" \
  "workflows/ui-ux-skill-check.yml" "workflows/skills-agents-audit.yml"

echo "── claude-config (deployed agents) ─────────────────────"
commit_repo "./claude-config" "feat/deploy-validated-agents" \
  "feat(agents): deploy 12 validated agents from agent-config" \
  "claude/agents"

echo "────────────────────────────────────────────────────────"
echo "done. Push each branch and open one PR per repo (link the issue in the PR)."
