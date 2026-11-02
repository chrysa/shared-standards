#!/usr/bin/env bash
# Build plugins/chrysa-standards/ from the canon (agents, commands, skills).
# The plugin directory is generated: edit templates/claude/* or .claude/skills/*, then rerun.
#   scripts/build-claude-plugin.sh          # regenerate
#   scripts/build-claude-plugin.sh --check  # exit 1 when the committed plugin drifted
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/plugins/chrysa-standards"
VERSION="${PLUGIN_VERSION:-0.1.0}"
build() {
  local dst="$1"
  mkdir -p "$dst/.claude-plugin" "$dst/agents" "$dst/commands" "$dst/skills"
  cp "$ROOT"/templates/claude/agents/*.md "$dst/agents/"
  local f n
  for f in "$ROOT"/templates/claude/commands/*.md; do
    n="$(basename "$f" .md)"
    # A command that also exists as a skill would load twice under the same name.
    [ -d "$ROOT/.claude/skills/$n" ] && continue
    cp "$f" "$dst/commands/"
  done
  for f in "$ROOT"/.claude/skills/*/; do cp -R "$f" "$dst/skills/"; done
  cat > "$dst/.claude-plugin/plugin.json" <<JSON
{
  "name": "chrysa-standards",
  "version": "$VERSION",
  "description": "Shared chrysa agents, commands and skills, generated from shared-standards",
  "author": { "name": "chrysa" },
  "repository": "https://github.com/chrysa/shared-standards",
  "license": "MIT"
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
