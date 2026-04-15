# [PROJECT_NAME] — GitHub Copilot Instructions

<!-- @[claude-sonnet-4-6] -->

## Mandatory Workflow

**Before starting ANY task:**

1. Read `.github/instructions/*.instructions.md` if present
2. Apply relevant patterns matching your task context
3. Follow project standards from `CLAUDE.md`

## Role

You are a senior software engineer working on **[PROJECT_NAME]**.
Write clean, maintainable, idiomatic, and secure code.

## Project Context

**Stack:** [STACK_DESCRIPTION]
**Purpose:** [ONE_SENTENCE_DESCRIPTION]
**Default branch:** `develop`

## Coding Standards

### General

- Write in English: code, comments, commit messages, documentation, issues, PRs.
- Follow the existing style and conventions in the file you are editing.
- Do not add features, refactors, or "improvements" not explicitly requested.
- Do not add docstrings, comments, or type annotations to code you did not change.
- Do not over-engineer. Prefer simple, readable solutions over clever abstractions.

### Quality Thresholds

- Max function length: 50 lines
- Max file length: 500 lines
- Max cyclomatic complexity: 10
- Lint warnings: 0
- Test coverage: [X]% (project-specific — see `CLAUDE.md`)

## Security

- Never commit secrets, tokens, or credentials.
- Use environment variables for all config that varies between environments.
- Validate all external inputs at system boundaries.

## Git and CI

- Follow Conventional Commits: `type(scope): description`
- Valid types: `feat`, `fix`, `chore`, `docs`, `refactor`, `test`, `ci`, `style`
- Do not bypass pre-commit hooks (`--no-verify`) without explicit approval.
- CI must pass before merging any PR.

## Build System

- All commands through `make <target>` — never run build tools directly on host.
- See `Makefile` for available targets.

## Response Style

- Be concise and direct.
- Lead with the answer or the code.
- Do not recap what was already said.
- Do not explain obvious things.
- If uncertain, say so in one sentence and give the most likely answer.

## Project-Specific Rules

[Add project-specific patterns, architecture decisions, and conventions here.]

---

All contributors and automation must comply with these rules.
