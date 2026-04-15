# CLAUDE.md — [PROJECT_NAME]

> Replace [PROJECT_NAME] and all [PLACEHOLDER] values before committing.
> @[claude-sonnet-4-6]

## Project

**Name:** [PROJECT_NAME]
**Stack:** [Python 3.14 / Node.js LTS / React / ...]
**Purpose:** [One sentence description]

## Conventions

- Language: English (code, comments, docs, issues, PRs)
- Commits: Conventional Commits (`feat`, `fix`, `chore`, `docs`, `refactor`, `test`, `ci`)
- Branch naming: `feature/`, `bugfix/`, `chore/`, `hotfix/`, `release/`
- Default branch: `develop`

## Standards

- Max function lines: 50
- Max file lines: 500
- Max complexity (heuristic): 10
- Lint warnings: 0
- Test coverage: [X]%

## Setup

```bash
make install   # Install dependencies
make lint      # Run linter
make test      # Run tests
make build     # Build (if applicable)
```

## CI

- CI runs on push to `develop`/`main` and on PRs to those branches
- CI must pass before merging
- SonarQube analysis is configured in CI (not via sonar-project.properties)

## Repository-specific rules

[Add project-specific rules here. E.g.:]
- [ ] Describe any project-specific allowlists for secret scanner
- [ ] Describe custom thresholds vs shared defaults
- [ ] Note any hooks that are disabled for this repo and why

## Model-specific notes (@[claude-sonnet-4-6])

[Add any rules or instructions that apply only when using a specific model.]

## Skills

Shared skills from `shared-standards/.claude/skills/`:
- `testing-pytest/SKILL.md` — pytest DDD + pytest-mock + constants (load when writing tests)
- `dockerfile-multistage/SKILL.md` — 4-stage Python 3.14 containers (load when editing Dockerfile)
- `api-design/SKILL.md` — REST standards + FastAPI patterns (load when designing endpoints)
