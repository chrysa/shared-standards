#!/usr/bin/env bash
# check-skills-agents.sh — repo-agnostic linter for SKILL & AGENT reference integrity.
#
# No hard-coded repo names or layout. Discovers repos, the canonical shared skills dir, and agent
# registries by convention, all overridable by flags/env.
#
# Checks (each can be toggled):
#   SKILLS
#     [ERROR] broken reference  — a `<name>/SKILL.md` cited in a CLAUDE.md but the module exists
#                                 neither in that repo's .claude/skills/<name>/ nor in the canonical
#                                 shared skills dir.
#     [WARN]  orphan skill      — a canonical skill module that no CLAUDE.md references.
#   AGENTS
#     [WARN]  unpaired agent    — an agent with a .json but no .md (or vice-versa) in a registry.
#     [WARN]  drift (not deployed) — an agent in the SOURCE registry but absent from a mirror.
#     [WARN]  drift (untracked) — an agent in a mirror but absent from the SOURCE registry.
#     [WARN]  unknown @ref      — (opt-in --agent-refs) an `@name` in a CLAUDE.md that matches no
#                                 agent and is not a known routing/framework token.
#
# Source of truth: per Notion ("agent-config = le registre de l'écosystème"), the SOURCE registry
# defaults to the dir ending in agent-config/agents (else the first detected). Drift is reported
# DIRECTIONALLY against it. Agent types: native (.md, invocable @name) vs reference-only (.json).
#
# Usage:
#   check-skills-agents.sh [ROOT]                 # scan everything under ROOT (default: .)
#   check-skills-agents.sh --skills-only
#   check-skills-agents.sh --agents-only
#   check-skills-agents.sh --agent-refs           # also lint @agent references (noisier)
#   check-skills-agents.sh --pairing              # also report json/md unpaired agents
#   check-skills-agents.sh --sync                 # DEPLOY agents from source into mirror registries
#                                                 # (additive; mirrors become dirty — commit via PR)
#   check-skills-agents.sh --strict               # warnings also fail (exit 1)
#   check-skills-agents.sh --exclude '*_archived*' (repeatable)
#   check-skills-agents.sh --skills-dir DIR        # canonical shared skills dir (else auto-detect)
#   check-skills-agents.sh --agents-dir DIR        # an agent registry dir (repeatable; else auto)
#   check-skills-agents.sh --agent-source DIR      # source-of-truth registry (else auto agent-config)
#
# Env: SKILL_GLOB (default '*/.claude/skills'), known-token allowlist via AGENT_REF_ALLOW (space-sep).
# Exit: 0 ok, 1 error (broken ref, or any warn under --strict), 2 usage.

set -uo pipefail
export LC_ALL=C   # deterministic byte-order collation so sort/comm/grep agree across locales

ROOT="."
EXCLUDES=()
SKILLS_DIR=""
AGENT_DIRS=()
AGENT_SOURCE=""
DO_SKILLS=1; DO_AGENTS=1; DO_AGENT_REFS=0; DO_PAIRING=0; DO_SYNC=0; STRICT=0
ERR=0; WARN=0
PRUNE=(node_modules .venv venv dist build out vendor target .next .cache worktrees)
# tokens that look like @agent but are routing/frameworks/models, not agents:
ALLOW="fast code best judge clean loop strict compact CAGEERF ReACT DEVIL DECIDE chrysa ${AGENT_REF_ALLOW:-}"

log()  { printf '%s\n' "$*"; }
err()  { printf '❌ %s\n' "$*"; ERR=$((ERR+1)); }
warn() { printf '⚠️  %s\n' "$*"; WARN=$((WARN+1)); }
ok()   { printf '✅ %s\n' "$*"; }

is_excluded() { local p="$1" pat; for pat in "${EXCLUDES[@]:-}"; do [ -n "$pat" ] || continue; case "$p" in $pat) return 0;; esac; done; return 1; }

prune_find() { # $1=root, rest=find predicates after the prune block
  local root="$1"; shift
  local pe=() d first=1
  for d in "${PRUNE[@]}"; do
    if [ $first -eq 1 ]; then pe+=( -name "$d" ); first=0; else pe+=( -o -name "$d" ); fi
  done
  find "$root" \( "${pe[@]}" \) -prune -o "$@" 2>/dev/null
}

discover_repos() { prune_find "$ROOT" -name .git -print | while IFS= read -r g; do dirname "$g"; done | sort -u; }

detect_skills_dir() {
  local cands; cands="$(prune_find "$ROOT" -type d -path "${SKILL_GLOB:-*/.claude/skills}" -print)"
  # prefer a path containing 'shared-standards', else first that holds a */SKILL.md
  local pref; pref="$(printf '%s\n' "$cands" | grep -m1 'shared-standards' || true)"
  [ -n "$pref" ] && { printf '%s\n' "$pref"; return; }
  local c; while IFS= read -r c; do [ -z "$c" ] && continue; if compgen -G "$c/*/SKILL.md" >/dev/null 2>&1; then printf '%s\n' "$c"; return; fi; done <<< "$cands"
}

detect_agent_dirs() {
  # Top-level agent registries only. Skill-scoped sub-agents (under .../skills/.../agents)
  # are NOT mirror registries, so they are excluded to avoid drift noise.
  prune_find "$ROOT" -type d -name agents -print | while IFS= read -r d; do
    case "$d" in */skills/*) continue;; esac
    if compgen -G "$d/*.json" >/dev/null 2>&1 || compgen -G "$d/*.md" >/dev/null 2>&1; then printf '%s\n' "$d"; fi
  done | sort -u
}

reg_label() { echo "$(basename "$(dirname "$1")")/$(basename "$1")"; }
reg_names() { # sorted unique agent base names in a registry dir
  local d="$1" n
  for n in "$d"/*.json "$d"/*.md; do [ -e "$n" ] || continue; n="$(basename "$n")"; echo "${n%.*}"; done | sort -u
}

# ---------------- SKILLS ----------------
declare -A REFERENCED   # skill name -> 1 (seen referenced anywhere)
check_skills() {
  log "── SKILLS ──────────────────────────────────────────────"
  [ -n "$SKILLS_DIR" ] || SKILLS_DIR="$(detect_skills_dir)"
  if [ -n "$SKILLS_DIR" ]; then log "canonical skills dir: $SKILLS_DIR"; else warn "no canonical shared skills dir detected"; fi

  local repo rel name ref f resolved any=0
  while IFS= read -r repo; do
    rel="${repo#./}"; is_excluded "$rel" && continue
    f="$repo/CLAUDE.md"; [ -f "$f" ] || continue
    # extract referenced skill names: `<name>/SKILL.md`
    while IFS= read -r ref; do
      [ -z "$ref" ] && continue
      name="$ref"; REFERENCED["$name"]=1; any=1
      resolved=0
      [ -f "$repo/.claude/skills/$name/SKILL.md" ] && resolved=1
      [ -n "$SKILLS_DIR" ] && [ -f "$SKILLS_DIR/$name/SKILL.md" ] && resolved=1
      if [ $resolved -eq 0 ]; then err "$rel → references '$name/SKILL.md' but module not found (repo-local nor canonical)"; fi
    done < <(grep -oE '`[A-Za-z0-9_.-]+/SKILL\.md`' "$f" 2>/dev/null | tr -d '`' | sed 's#/SKILL\.md##' | sort -u)
  done < <(discover_repos)
  [ $any -eq 0 ] && warn "no skill references found in any CLAUDE.md"

  # orphans: canonical skills referenced by nobody
  if [ -n "$SKILLS_DIR" ]; then
    local s sname
    for s in "$SKILLS_DIR"/*/SKILL.md; do
      [ -e "$s" ] || continue
      sname="$(basename "$(dirname "$s")")"
      if [ -z "${REFERENCED[$sname]:-}" ]; then warn "orphan skill '$sname' — present in canonical dir, referenced by no project"; fi
    done
  fi
  [ $ERR -eq 0 ] && ok "skill references resolve"
}

# ---------------- AGENTS ----------------
check_agents() {
  log "── AGENTS ──────────────────────────────────────────────"
  [ ${#AGENT_DIRS[@]} -gt 0 ] || while IFS= read -r d; do AGENT_DIRS+=("$d"); done < <(detect_agent_dirs)
  if [ ${#AGENT_DIRS[@]} -eq 0 ]; then warn "no agent registry detected"; return; fi
  local dir
  for dir in "${AGENT_DIRS[@]}"; do log "registry: $(reg_label "$dir") ($(reg_names "$dir" | grep -c . ) agents)"; done

  declare -A SET_ALL
  local n base
  for dir in "${AGENT_DIRS[@]}"; do
    while IFS= read -r base; do [ -n "$base" ] && SET_ALL["$base"]=1; done < <(reg_names "$dir")
  done

  # Source-of-truth registry (Notion: agent-config is "le registre de l'écosystème").
  # Drift is reported DIRECTIONALLY against this source, not as O(n²) all-pairs noise.
  local SOURCE="$AGENT_SOURCE"
  if [ -z "$SOURCE" ]; then
    for dir in "${AGENT_DIRS[@]}"; do case "$dir" in */agent-config/agents) SOURCE="$dir"; break;; esac; done
    [ -z "$SOURCE" ] && SOURCE="${AGENT_DIRS[0]}"
  fi
  log "source of truth: $(reg_label "$SOURCE")"

  # Type breakdown of the source: native (.md, invocable @name) vs reference-only (.json, session prompt)
  local nat=0 refonly=0
  while IFS= read -r base; do
    [ -z "$base" ] && continue
    if [ -f "$SOURCE/$base.md" ]; then nat=$((nat+1)); else refonly=$((refonly+1)); fi
  done < <(reg_names "$SOURCE")
  log "source types: $nat native (.md) · $refonly reference-only (.json)"

  # pairing (opt-in: many agents are intentionally .json-only or .md-only)
  if [ $DO_PAIRING -eq 1 ]; then
    for dir in "${AGENT_DIRS[@]}"; do
      while IFS= read -r base; do
        [ -z "$base" ] && continue
        [ -f "$dir/$base.json" ] || warn "$(reg_label "$dir"): '$base' has .md but no .json"
        [ -f "$dir/$base.md" ]   || warn "$(reg_label "$dir"): '$base' has .json but no .md"
      done < <(reg_names "$dir")
    done
  fi

  # drift: compare every other (mirror) registry against the source, both directions.
  # With --sync, "not deployed" agents are COPIED from source into the mirror (additive only,
  # never deletes "extra"). Mirror repos become dirty — commit them via your normal PR flow.
  local dl sl only
  sl="$(reg_label "$SOURCE")"
  for dir in "${AGENT_DIRS[@]}"; do
    [ "$dir" = "$SOURCE" ] && continue
    dl="$(reg_label "$dir")"
    only="$(comm -23 <(reg_names "$SOURCE") <(reg_names "$dir"))"
    if [ -n "$only" ]; then while IFS= read -r n; do
      [ -z "$n" ] && continue
      if [ $DO_SYNC -eq 1 ]; then
        if cp "$SOURCE/$n".* "$dir/" 2>/dev/null; then log "↪ synced '$n' → $dl"; else warn "failed to sync '$n' → $dl"; fi
      else
        warn "drift: '$n' in source $sl but NOT deployed to $dl  (run --sync to deploy)"
      fi
    done <<< "$only"; fi
    only="$(comm -13 <(reg_names "$SOURCE") <(reg_names "$dir"))"
    [ -n "$only" ] && while IFS= read -r n; do warn "drift: '$n' in $dl but NOT in source $sl (untracked / extra — left untouched)"; done <<< "$only"
  done

  # optional: unknown @agent references
  if [ $DO_AGENT_REFS -eq 1 ]; then
    local repo rel f tok
    declare -A SEEN_UNKNOWN
    while IFS= read -r repo; do
      rel="${repo#./}"; is_excluded "$rel" && continue
      f="$repo/CLAUDE.md"; [ -f "$f" ] || continue
      while IFS= read -r tok; do
        tok="${tok#@}"; [ -z "$tok" ] && continue
        grep -qiwF "$tok" <<< "$ALLOW" && continue
        [ -n "${SET_ALL[$tok]:-}" ] && continue
        [ -n "${SEEN_UNKNOWN[$tok]:-}" ] && continue
        SEEN_UNKNOWN[$tok]=1
        warn "unknown @ref '@$tok' (first seen in $rel) — no matching agent/token"
      done < <(grep -oE '@[A-Za-z][A-Za-z0-9_-]+' "$f" 2>/dev/null | sort -u)
    done < <(discover_repos)
  fi
  ok "agent registry checked (${#AGENT_DIRS[@]} dir(s), ${#SET_ALL[@]} agents)"
}

# ---------------- args ----------------
while [ $# -gt 0 ]; do
  case "$1" in
    --skills-only) DO_AGENTS=0; shift ;;
    --agents-only) DO_SKILLS=0; shift ;;
    --agent-refs)  DO_AGENT_REFS=1; shift ;;
    --pairing)     DO_PAIRING=1; shift ;;
    --sync)        DO_SYNC=1; shift ;;
    --strict)      STRICT=1; shift ;;
    --exclude)     shift; EXCLUDES+=("${1:?--exclude needs pattern}"); shift ;;
    --skills-dir)  shift; SKILLS_DIR="${1:?}"; shift ;;
    --agents-dir)  shift; AGENT_DIRS+=("${1:?}"); shift ;;
    --agent-source) shift; AGENT_SOURCE="${1:?}"; shift ;;
    -h|--help)     sed -n '2,40p' "$0"; exit 0 ;;
    --*)           echo "unknown flag: $1" >&2; exit 2 ;;
    *)             ROOT="$1"; shift ;;
  esac
done

[ $DO_SKILLS -eq 1 ] && check_skills
[ $DO_AGENTS -eq 1 ] && check_agents

log "────────────────────────────────────────────────────────"
log "errors=$ERR  warnings=$WARN"
if [ $ERR -gt 0 ]; then exit 1; fi
if [ $STRICT -eq 1 ] && [ $WARN -gt 0 ]; then exit 1; fi
exit 0
