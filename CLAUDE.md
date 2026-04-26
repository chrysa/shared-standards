# shared-standards

> @[claude-sonnet-4-6]
## Project Overview
Shared GitHub Copilot instructions, Claude Code DevEx hooks, reusable CI templates,
and standards for the ecosystem.


## Language Rules

- Language: English — all code, comments, documentation, instructions, and configuration files must be in English.
## Repository Structure
```
.claude/hooks/          # Claude Code DevEx hooks (circuit breaker, secret scanner, etc.)
.claude/settings.json   # Claude Code hook configuration
.claude/skills/         # On-demand skill modules (auto-invoked SKILL.md per domain)
  testing-pytest/       # pytest DDD + pytest-mock + constants pattern
  dockerfile-multistage/# 4-stage base/builder/production/dev — Python 3.14
  api-design/           # REST standards + FastAPI patterns + status codes
copilot-instructions/   # GitHub Copilot instruction templates (base.md = ecosystem-wide)
templates/              # Bootstrap file templates (CLAUDE.md, opencode.json, settings.json, copilot-instructions.md, .gitignore, dependabot.yml, etc.)
workflows/              # Reusable GitHub Actions workflow templates
```

## Development Setup
```bash
make install  # Install pre-commit hooks
make lint     # Run pre-commit on all files
```

## Adding a new skill
1. Create `.claude/skills/<name>/SKILL.md`
2. Define: when to auto-invoke, concrete rules, code patterns, forbidden patterns
3. Reference it from the project's CLAUDE.md under `## Skills`

## Adding a new hook
1. Create `hooks/<name>.cjs` in `.claude/hooks/`
2. Add it to `.claude/settings.json` under the correct lifecycle event
3. Document it in `.claude/HOOKS_README.md`
4. Tag model-specific rules with `@[MODEL_NAME]`

## Adding a new template
1. Create the file in `templates/` (or `workflows/`)
2. Use `${REPO_NAME}`, `${DESCRIPTION}` placeholders for project-init substitution
3. Update `README.md` with the new template reference

## CI/CD
- Pre-commit: `.pre-commit-config.yaml`
- CI validation: `.github/workflows/ci.yml`
- PR labeler: `.github/workflows/labeler.yml`
- PR dependency check: `.github/workflows/dependencies.yml`

## Code Standards
- All commit messages: Conventional Commits format
- All YAML files sorted (via yaml-sorter) except `.github/` workflows
- Templates must be valid YAML/JSON (validated in CI)
- **No nested named functions > 5 lines** (cross-repo · Notion ADR 2026-04-26).
  Extract to top-level. Lambdas/arrows inline (callbacks `map`/`filter`/`reduce`,
  predicates 1-3 lines) and private 1-call closure factories are OK.
  Lints to enforce:
  - Python (Ruff): `PLR0915` + custom `def-inside-def` check
  - TypeScript (ESLint): `max-nested-callbacks: ["error", 2]` + `func-style: ["error", "declaration"]`
  - Bash: shellcheck `SC2317` + manual review on 5+ line nested helpers
  See: https://www.notion.so/34e59293e35e816396f0ce86102953e8

## Key Hooks
| Hook | Event | Purpose |
|------|-------|---------|
| secret-scanner.cjs | PreToolUse (git commit) | Block secrets from being committed |
| circuit-breaker.cjs | PreToolUse (API calls) | Prevent repeated failing API calls |
| frustration-detection.cjs | UserPromptSubmit | Inject context on frustrating prompts |
| verifiable-thresholds.cjs | PostToolUse (file writes) | Warn on quality threshold violations |
| memory-consolidation.cjs | CLI | Consolidate and compress memory files |
| model-debt-inventory.cjs | CLI | Audit model-specific tagged rules |

## Compact instructions

When compacting, always preserve:
1. List of all files modified this session (with paths)
2. Current task description and next steps
3. Any uncommitted / unpushed changes
4. Open blockers and errors not yet resolved
