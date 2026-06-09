# shared-standards

The single source of truth for cross-cutting standards, templates, CI workflows, and Claude Code / Copilot tooling shared across every repo in the chrysa ecosystem. It exists so a new project can be scaffolded — and stay consistent — without re-deciding architecture, CI, quality gates, or agent configuration each time.

## Who this is for

- **Developers** starting or maintaining a chrysa project who need the canonical conventions (containers, API design, code quality, i18n, a11y, observability).
- **Anyone copying CI/CD, Copilot, or Claude Code setup** into a repo and wanting it to match the rest of the portfolio.
- This is a **documentation + templates repo**: there is no app to run, no build artefact. `make help` lists the few available targets (pre-commit only).

## What it provides

### Standards (read these first)

| File | What it defines |
| --- | --- |
| [CODE_MANIFEST.md](CODE_MANIFEST.md) | Architectural source of truth: containers, API design, security, code quality limits, tests, docs, CI/CD, observability, i18n, a11y, versioning, and the **Ready-to-Dev gate**. |
| [EXECUTION_STANDARD.md](EXECUTION_STANDARD.md) | Mandatory execution conventions: Makefile targets, repo structure, the `git clone && make install && make dev` contract. |
| [AGENTS.md](AGENTS.md) | Standards specific to AI agents and code-intelligence tooling. |
| [DECISIONS.md](DECISIONS.md) | Repo-local ADRs (`D-XXXX`). Any deviation from the manifest is recorded here. |
| [docs/UX-UI-GUIDELINES.md](docs/UX-UI-GUIDELINES.md) | UX/UI/ergonomics source of truth for every human-facing surface (web, CLI/TUI, bots, desktop, game UI). |
| [docs/QUALITY-GATES-SUMMARY.md](docs/QUALITY-GATES-SUMMARY.md) | Quality-gate framework and rollout status. |

### Templates (`templates/`)

Bootstrap files to copy into a consuming repo and adapt: `CLAUDE.md`, `CODEOWNERS`, `pr-template.md`, `settings.json`, `dependabot.yml`, `labeler.yml`, `.gitignore.python`, `.gitignore.node`, `copilot-instructions.md`, `opencode.json`, plus `issue-templates/` (bug/feature/chore), `vscode/` (Python + full-stack `tasks.json`, see [templates/vscode/README.md](templates/vscode/README.md)), and `claude/`, `docs-structure/`, `github-config/`, `workflows-process/`.

### CI workflow templates (`workflows/`)

> ⚠️ **Copy-to-use templates — NOT reusable workflows.** They cannot be called via `uses: chrysa/shared-standards/...`. Composite actions (atomic steps) live in [`chrysa/github-actions`](https://github.com/chrysa/github-actions); call those from inside your copied workflow.

`ci-python.yml`, `ci-node.yml`, `sonar.yml`, `release.yml` (GitVersion + cliff), `labeler.yml`, `pr-size.yml`, `pages.yml`, `secret-scan.yml`, `regression-gate.yml`, `mutation-testing.yml`, `contract-testing.yml`, `enforce-feature-branch.yml`, `notion-roadmap-sync.yml`, `notion-branch-sync.yml`, and more.

### Copilot instructions (`copilot-instructions/`)

Per-stack GitHub Copilot guidance: `base.md`, `fastapi.md`, `react19.md`, `python-library.md`, `monorepo.md`, `gas.md`.

### Claude Code tooling (`.claude/`)

Hooks (`.claude/hooks/*.cjs`: secret scanner, circuit breaker, frustration detection, verifiable thresholds, memory consolidation, model-debt inventory), `settings.json`, `thresholds.json`, and the secret-scanner allowlist. Full reference: [.claude/HOOKS_README.md](.claude/HOOKS_README.md).

### Scripts (`scripts/`)

Maintenance and rollout helpers, e.g. `apply-ci-process.sh`, `setup-branch-protection.sh`, `audit-quality-gate-repos.sh`, `normalize-quality-gate.sh`, `check-skills-agents.sh`, and dev-tools installers under `scripts/setup/`.

## How to apply it

Standards are applied by **copying** the relevant files into your repo and adapting them — these are templates, not a package dependency. Replace `path/to/shared-standards` with your local clone path.

```bash
# CI: add SonarCloud / Python / Node pipelines
cp path/to/shared-standards/workflows/sonar.yml     .github/workflows/sonar.yml
cp path/to/shared-standards/workflows/ci-python.yml .github/workflows/ci.yml
# then edit project key, secrets, and version pins

# Copilot instructions
cp path/to/shared-standards/copilot-instructions/base.md .github/copilot-instructions.md

# Claude Code hooks (merge settings.json manually)
cp -r path/to/shared-standards/.claude/hooks/ .claude/hooks/

# Bootstrap docs
cp path/to/shared-standards/templates/CLAUDE.md ./CLAUDE.md

# VS Code tasks (then drop tasks with no matching make target)
cp path/to/shared-standards/templates/vscode/tasks.python.json    .vscode/tasks.json   # Python
cp path/to/shared-standards/templates/vscode/tasks.fullstack.json .vscode/tasks.json   # Python + TS
```

New repos are normally scaffolded via the `project-init` CLI, which consumes this repo (see CODE_MANIFEST §13, *Ready-to-Dev gate*).

### Model tagging

Model-specific rules/prompts are tagged `@[MODEL_NAME]`. Inventory them:

```bash
node .claude/hooks/model-debt-inventory.cjs --dir .
```

## Evolving the standards

Changes go through a PR on `shared-standards`; every change adds an ADR to [DECISIONS.md](DECISIONS.md). Consumer repos pick up changes via release tags (`manifest-vX.Y`). See CODE_MANIFEST §14.

## Reference

[Local LLM Stack for Software + Data Engineering (Notion)](https://www.notion.so/Local-LLM-Stack-for-Software-Data-Engineering-34459293e35e81c2b5b0f8283640b338) — central knowledge base for fully local, containerized LLM workflows to adopt across the ecosystem.
