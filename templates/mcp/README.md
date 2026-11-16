# Claude Code `.mcp.json` templates

Project-scoped MCP server config for Claude Code. Copy ONE archetype into a repo root as `.mcp.json`
(only when the repo needs a project server: the base archetype is empty).

| Template | Servers | Use for |
|---|---|---|
| `mcp.base.json` | none (no `.mcp.json` needed) | any repo (default) |
| `mcp.web.json`  | playwright | full-stack / web apps (browser E2E) |
| `mcp.lib.json`  | context7 | reusable libs (Django/FastAPI — live docs) |

## GitHub and Notion come from the user scope

The token-based `github` and `notion` MCP servers are **not** declared per project any more:
they live in the Claude Code user scope (`claude mcp add --scope user …`), next to the
tokens they need. A repo whose `.mcp.json` would only hold them ships no `.mcp.json` at all.

## Hard rule: NO SECRETS

These files are git-tracked. They MUST contain only `${ENV_VAR}` placeholders — never a real
token. Claude Code expands `${...}` from the environment at launch. A server that needs a token
(GitHub, Notion…) belongs in the user scope, not in a versioned `.mcp.json`.

`verify-config.sh` fails the build if any committed `.mcp.json` has a non-`${...}` value in `env`.

## Apply

```bash
cp shared-standards/templates/mcp/mcp.web.json <repo>/.mcp.json   # web or lib; base = no file
```
