#!/usr/bin/env bash
# Build plugins/chrysa-standards/ from the canon (agents, commands, skills, generic hooks).
# The plugin directory is generated: edit templates/claude/*, .claude/skills/* or the
# hooks listed in HOOKS (from .claude/hooks/), then rerun.
#   scripts/build-claude-plugin.sh          # regenerate
#   scripts/build-claude-plugin.sh --check  # exit 1 when the committed plugin drifted
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/plugins/chrysa-standards"
VERSION="${PLUGIN_VERSION:-0.2.0}"
# Generic session hooks written by prism-ai-lint: one copy in the plugin instead of one per repo.
HOOKS="pre-compact.sh read_guard.py session-context.sh"
build() {
  local dst="$1"
  mkdir -p "$dst/.claude-plugin" "$dst/agents" "$dst/commands" "$dst/hooks" "$dst/skills"
  cp "$ROOT"/templates/claude/agents/*.md "$dst/agents/"
  local f n
  for f in "$ROOT"/templates/claude/commands/*.md; do
    n="$(basename "$f" .md)"
    # A command that also exists as a skill would load twice under the same name.
    [ -d "$ROOT/.claude/skills/$n" ] && continue
    cp "$f" "$dst/commands/"
  done
  for f in "$ROOT"/.claude/skills/*/; do cp -R "$f" "$dst/skills/"; done
  for n in $HOOKS; do cp "$ROOT/.claude/hooks/$n" "$dst/hooks/"; done
  # Exec form: each script path stays one argument, whatever the install directory.
  cat > "$dst/hooks/hooks.json" <<'JSON'
{
  "hooks": {
    "PreCompact": [
      {
        "hooks": [
          {
            "args": [
              "${CLAUDE_PLUGIN_ROOT}/hooks/pre-compact.sh"
            ],
            "command": "bash",
            "timeout": 10,
            "type": "command"
          }
        ]
      }
    ],
    "PreToolUse": [
      {
        "hooks": [
          {
            "args": [
              "${CLAUDE_PLUGIN_ROOT}/hooks/read_guard.py"
            ],
            "command": "python3",
            "timeout": 10,
            "type": "command"
          }
        ],
        "matcher": "Read"
      }
    ],
    "SessionStart": [
      {
        "hooks": [
          {
            "args": [
              "${CLAUDE_PLUGIN_ROOT}/hooks/session-context.sh"
            ],
            "command": "bash",
            "timeout": 10,
            "type": "command"
          }
        ]
      }
    ]
  }
}
JSON
  # Keys sorted: the json-sorter pre-commit hook rewrites this file otherwise.
  cat > "$dst/.claude-plugin/plugin.json" <<JSON
{
  "author": {
    "name": "chrysa"
  },
  "description": "Shared chrysa agents, commands, skills and generic hooks, generated from shared-standards",
  "license": "MIT",
  "name": "chrysa-standards",
  "repository": "https://github.com/chrysa/shared-standards",
  "version": "$VERSION"
}
JSON
}
if [ "${1:-}" = "--check" ]; then
  tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
  build "$tmp/p"
  diff -r "$tmp/p" "$OUT" >/dev/null || { echo "plugins/chrysa-standards drifted: run scripts/build-claude-plugin.sh"; exit 1; }
  echo "plugins/chrysa-standards up to date"
else
  [ -d "$OUT" ] && find "$OUT" -mindepth 1 -delete
  build "$OUT"
  echo "built $OUT"
fi
