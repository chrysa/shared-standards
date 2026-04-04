# shared-standards — Copilot Instructions

<!-- @[claude-sonnet-4] -->

## Project purpose

`shared-standards` is the central repository for reusable tooling, Copilot instructions,
workflow templates, Claude Code hooks, and project templates for the chrysa ecosystem.

**This repository is a standards library — not an application.**

## What belongs here

- `copilot-instructions/` — base GitHub Copilot instructions for chrysa projects
- `workflows/` — reusable CI/CD workflow files for Python and Node projects
- `templates/` — CLAUDE.md, .gitignore, dependabot.yml, PR/issue templates
- `.claude/hooks/` — shared Claude Code hooks (circuit breaker, secret scanner, etc.)
- `.github/` — this repo's own CI, labeler, dependabot, and PR templates

## What does NOT belong here

- Project-specific application code
- Secrets or credentials
- Compiled artifacts or build outputs

## Key design rules

- Workflows in `workflows/` must be reusable (`workflow_call`) or clearly labeled as examples
- All templates must be ecosystem-agnostic enough to copy into any chrysa repo
- Claude hooks use `exit code 2` to block, `exit code 0` to pass
- All hooks must handle stdin/stdout/stderr properly with valid JSON
- Tags with `@[MODEL_NAME]` identify model-specific rules

## Development

```bash
# Validate all templates
make validate  # or python3 -c "import yaml; yaml.safe_load(open('workflows/sonar.yml'))"

# Run pre-commit
pre-commit run --all-files

# Test hooks
node .claude/hooks/secret-scanner.cjs
```

## Related repos

- `chrysa/pre-commit-tools` — pre-commit hook implementations
- `chrysa/guideline-checker` — instruction-file compliance checker
- `chrysa/project-init` — project bootstrapper consuming these templates
- `Forge-Stack-Workshop/base-makefile` — shared Makefile patterns
