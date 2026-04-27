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

<!-- gitnexus:start -->
# GitNexus — Code Intelligence

This project is indexed by GitNexus as **shared-standards** (318 symbols, 312 relationships, 0 execution flows). Use the GitNexus MCP tools to understand code, assess impact, and navigate safely.

> If any GitNexus tool warns the index is stale, run `npx gitnexus analyze` in terminal first.

## Always Do

- **MUST run impact analysis before editing any symbol.** Before modifying a function, class, or method, run `gitnexus_impact({target: "symbolName", direction: "upstream"})` and report the blast radius (direct callers, affected processes, risk level) to the user.
- **MUST run `gitnexus_detect_changes()` before committing** to verify your changes only affect expected symbols and execution flows.
- **MUST warn the user** if impact analysis returns HIGH or CRITICAL risk before proceeding with edits.
- When exploring unfamiliar code, use `gitnexus_query({query: "concept"})` to find execution flows instead of grepping. It returns process-grouped results ranked by relevance.
- When you need full context on a specific symbol — callers, callees, which execution flows it participates in — use `gitnexus_context({name: "symbolName"})`.

## Never Do

- NEVER edit a function, class, or method without first running `gitnexus_impact` on it.
- NEVER ignore HIGH or CRITICAL risk warnings from impact analysis.
- NEVER rename symbols with find-and-replace — use `gitnexus_rename` which understands the call graph.
- NEVER commit changes without running `gitnexus_detect_changes()` to check affected scope.

## Resources

| Resource | Use for |
|----------|---------|
| `gitnexus://repo/shared-standards/context` | Codebase overview, check index freshness |
| `gitnexus://repo/shared-standards/clusters` | All functional areas |
| `gitnexus://repo/shared-standards/processes` | All execution flows |
| `gitnexus://repo/shared-standards/process/{name}` | Step-by-step execution trace |

## CLI

| Task | Read this skill file |
|------|---------------------|
| Understand architecture / "How does X work?" | `.claude/skills/gitnexus/gitnexus-exploring/SKILL.md` |
| Blast radius / "What breaks if I change X?" | `.claude/skills/gitnexus/gitnexus-impact-analysis/SKILL.md` |
| Trace bugs / "Why is X failing?" | `.claude/skills/gitnexus/gitnexus-debugging/SKILL.md` |
| Rename / extract / split / refactor | `.claude/skills/gitnexus/gitnexus-refactoring/SKILL.md` |
| Tools, resources, schema reference | `.claude/skills/gitnexus/gitnexus-guide/SKILL.md` |
| Index, status, clean, wiki CLI commands | `.claude/skills/gitnexus/gitnexus-cli/SKILL.md` |

<!-- gitnexus:end -->
