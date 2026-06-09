# Claude Code `.mcp.json` templates

Project-scoped MCP server config for Claude Code. Copy ONE archetype into a repo root as `.mcp.json`.

| Template | Servers | Use for |
|---|---|---|
| `mcp.base.json` | github, notion | any shareable repo (default) |
| `mcp.web.json`  | github, notion, playwright | full-stack / web apps (browser E2E) |
| `mcp.lib.json`  | github, notion, context7 | reusable libs (Django/FastAPI — live docs) |

## Hard rule: NO SECRETS

These files are git-tracked. They MUST contain only `${ENV_VAR}` placeholders — never a real
token. Claude Code expands `${...}` from the environment at launch. Required env vars:

- `GITHUB_TOKEN` — GitHub PAT (repo, read:org)
- `NOTION_API_KEY` — Notion integration token

Set them in your shell / `~/.config/claude-config/secrets.env` (gitignored), not in `.mcp.json`.

`verify-config.sh` fails the build if any committed `.mcp.json` has a non-`${...}` value in `env`.

## Apply

```bash
cp shared-standards/templates/mcp/mcp.base.json <repo>/.mcp.json   # pick archetype
```
