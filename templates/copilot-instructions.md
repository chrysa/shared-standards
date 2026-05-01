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

## Automation & Industrialization (NON-NEGOTIABLE)

- Projects must be **maximally automated and industrialized**.
- Every repetitive task must be covered by one of: CI/CD pipeline, Makefile target, pre-commit hook, GitHub Actions workflow, or a bot/script.
- Required automation baseline for any project:
  - **CI/CD**: automated lint, type-check, tests, build on every push/PR.
  - **Formatting**: auto-applied via pre-commit or CI (no manual `ruff`/`prettier` runs).
  - **Releases**: automated versioning and changelog generation (e.g. `cliff`, `semantic-release`).
  - **Dependency updates**: automated via Dependabot or Renovate.
  - **Secret scanning**: automated on every commit (pre-commit hook + CI step).
- When proposing or implementing a feature, always include the automation layer (tests, CI step, Makefile target) — not just the code.
- Any manual step that could be automated is considered **technical debt** and must be tracked.

## Canonical Templates & Shared Tooling

### React applications
- All new React apps **must** be bootstrapped from `Forge-Stack-Workshop/react-app-generator`.
- Never scaffold from scratch or from `create-react-app`/`vite` directly.

### Makefiles
- All project Makefiles **must** extend or be derived from `Forge-Stack-Workshop/base-makefile`.
- Do not duplicate targets that already exist in the base — inherit instead.

### Pre-commit hooks
- If a required hook is missing from `chrysa/pre-commit-tools`, **open an issue** on that repo describing the hook needed before proceeding.
- In the requesting repo, open a matching issue/PR and mark it as dependent (`Depends on chrysa/pre-commit-tools#<N>`).
- Do not implement a workaround locally — wait for the hook to land in the shared repo.

### Issue resolution automation (desired workflow)
- When a blocking issue is opened (e.g. missing hook, missing template), an agent should:
  1. Analyse the issue and propose a solution on the upstream repo.
  2. Once the solution is validated (human approval), automatically unblock the dependent issue/PR in the requesting repo.
- This workflow is aspirational — track automation gaps as issues on the relevant repos.

## Project-Specific Rules

[Add project-specific patterns, architecture decisions, and conventions here.]

---

All contributors and automation must comply with these rules.
