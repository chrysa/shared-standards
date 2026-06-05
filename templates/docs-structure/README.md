# docs-structure — standardized project documentation skeleton

Canonical documentation tree copied into every new repo by `/chrysa-init`
(`chrysa/claude-config/claude/commands/chrysa-init.md`). Existing repos are
backfilled gradually.

## Layout
- `docs/` — product/architecture/process docs (app-spec, architecture, security, deployment, observability, …)
- `ai/` — AI-feature assets (`CLAUDE.md` is a pointer to repo-root canon; prompt-library, evaluation-datasets)
- `prompts/` — agent system prompts
- `schemas/` — JSON Schema (draft 2020-12) data contracts
- `workflows/` — end-to-end flow docs
- `decisions/` — `_TEMPLATE.md` + DEC-NNN records (ADR canon stays in `docs/adr/`)
- `postmortems/` — `_TEMPLATE.md` + incident records
- `tests/` — test scenario catalogues
- `examples/` — “perfect” reference implementations, one variant per stack (`python/`, `node/`)

## Usage in /chrysa-init
Copy the tree, then keep only the `examples/<stack>` matching the project type and drop the rest:
```bash
cp -r "$_SHARED/templates/docs-structure/." .
# keep python OR node examples depending on project type, then:
#   mv examples/python/* examples/ && rm -rf examples/python examples/node   (python projects)
#   mv examples/node/*   examples/ && rm -rf examples/python examples/node   (frontend/node projects)
```

## Reconciliation (do not duplicate existing canon)
- Never overwrite an existing root `CLAUDE.md`, `AGENTS.md`, `README.md`, `CHANGELOG.md`, `DECISIONS.md`, or `docs/adr/`.
- `ai/CLAUDE.md`, `docs/changelog.md` are pointers; `docs/decision-log.md` indexes `docs/adr/`.
- Stub files carry `status: stub` — remove once populated.
