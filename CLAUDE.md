# shared-standards

## Project Overview
Shared GitHub Copilot instructions, Claude Code DevEx hooks, reusable CI templates,
and standards for the chrysa ecosystem.

## Repository Structure
```
.claude/hooks/          # Claude Code DevEx hooks (circuit breaker, secret scanner, etc.)
.claude/settings.json   # Claude Code hook configuration
copilot-instructions/   # GitHub Copilot instruction templates
templates/              # Bootstrap file templates (CLAUDE.md, .gitignore, dependabot.yml, etc.)
workflows/              # Reusable GitHub Actions workflow templates
```

## Development Setup
```bash
make install  # Install pre-commit hooks
make lint     # Run pre-commit on all files
```

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

## Key Hooks
| Hook | Event | Purpose |
|------|-------|---------|
| secret-scanner.cjs | PreToolUse (git commit) | Block secrets from being committed |
| circuit-breaker.cjs | PreToolUse (API calls) | Prevent repeated failing API calls |
| frustration-detection.cjs | UserPromptSubmit | Inject context on frustrating prompts |
| verifiable-thresholds.cjs | PostToolUse (file writes) | Warn on quality threshold violations |
| memory-consolidation.cjs | CLI | Consolidate and compress memory files |
| model-debt-inventory.cjs | CLI | Audit model-specific tagged rules |
