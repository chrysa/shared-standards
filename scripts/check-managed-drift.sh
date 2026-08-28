#!/usr/bin/env bash
# check-managed-drift.sh · Fail if a managed skill/agent copy diverges from its canonical source.
#
# Source: chrysa/shared-standards/scripts/check-managed-drift.sh
#
# The transverse skills (`.claude/skills/<name>/`) and the generic agents
# (`.claude/agents/<name>.md`) are a SINGLE source fanned out to every repo as managed
# copies by distribute-standards.sh. They must never be hand-edited in a copy: an edit
# there drifts silently and Claude then loads a copy that no longer matches the canon.
# This hook makes "the copy equals the source" a machine fact, not discipline.
#
# Canonical sources (overridable by env):
#   skills  -> $STD_ROOT/.claude/skills            (shared-standards)
#   agents  -> $AGENTS_REGISTRY/.claude/agents     (agent-config registry)
#
# Source resolution (first hit wins), so it works from any repo in the fleet layout:
#   1. explicit env (STD_ROOT / AGENTS_REGISTRY)
#   2. the current repo itself, when it IS the source (self-compare is skipped)
#   3. a sibling checkout next to the repo root (../shared-standards, ../agent-config)
#
# Host-native & graceful: if a source cannot be located, the corresponding check is
# SKIPPED with a message (best-effort locally; enforced in CI where the fleet is checked
# out) — it never spins up a container and never blocks on a missing sibling.
#
# Exit: 0 = every managed copy matches its source (or was skipped) · 1 = drift found.
set -uo pipefail

repo_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
repo_name="$(basename "$repo_root")"
parent="$(dirname "$repo_root")"

resolve() { # name env_override -> echoes path or empty
    local name="$1" override="$2"
    if [[ -n "$override" && -d "$override" ]]; then echo "$override"; return; fi
    if [[ "$repo_name" == "$name" ]]; then echo "$repo_root"; return; fi
    [[ -d "$parent/$name" ]] && { echo "$parent/$name"; return; }
    echo ""
}

std_root="$(resolve shared-standards "${STD_ROOT:-}")"
agents_root="$(resolve agent-config "${AGENTS_REGISTRY:-}")"

rc=0

diff_tree() { # label copy_dir src_dir
    local label="$1" copy="$2" src="$3"
    # only compare entries that exist on BOTH sides (a copy is managed only if the source has it)
    local name
    for path in "$copy"/*/; do
        [[ -d "$path" ]] || continue
        name="$(basename "$path")"
        [[ -d "$src/$name" ]] || continue          # not a managed item — repo-local, ignore
        if ! diff -rq "$src/$name" "$path" >/dev/null 2>&1; then
            echo "drift [$label]: $path differs from source $src/$name" >&2
            rc=1
        fi
    done
}

diff_files() { # label copy_dir src_dir  (flat *.md)
    local label="$1" copy="$2" src="$3" f name
    for f in "$copy"/*.md; do
        [[ -f "$f" ]] || continue
        name="$(basename "$f")"
        [[ -f "$src/$name" ]] || continue
        if ! diff -q "$src/$name" "$f" >/dev/null 2>&1; then
            echo "drift [$label]: $f differs from source $src/$name" >&2
            rc=1
        fi
    done
}

# --- skills ---
if [[ -d "$repo_root/.claude/skills" ]]; then
    if [[ -z "$std_root" ]]; then
        echo "skip [skills]: canonical source (shared-standards) not found — enforced in CI" >&2
    elif [[ "$std_root" != "$repo_root" ]]; then
        diff_tree skills "$repo_root/.claude/skills" "$std_root/.claude/skills"
    fi
fi

# --- agents (managed generic roster) ---
for adir in "$repo_root/.claude/agents" "$repo_root/templates/claude/agents"; do
    [[ -d "$adir" ]] || continue
    if [[ -z "$agents_root" ]]; then
        echo "skip [agents]: registry (agent-config) not found — enforced in CI" >&2
        break
    fi
    src="$agents_root/.claude/agents"
    [[ -d "$src" ]] || src="$agents_root/agents"
    [[ -d "$src" ]] || { echo "skip [agents]: registry has no agents dir" >&2; break; }
    [[ "$src" == "$adir" ]] && continue            # self, skip
    diff_files agents "$adir" "$src"
done

if [[ $rc -ne 0 ]]; then
    echo "" >&2
    echo "A managed copy was edited instead of its source." >&2
    echo "Edit the SOURCE (shared-standards/.claude/skills or agent-config/.claude/agents)," >&2
    echo "then re-run: shared-standards/scripts/distribute-standards.sh   (or check-skills-agents.sh --sync)" >&2
fi
exit "$rc"
