# shared-standards

Shared GitHub Copilot instructions, generic workflows, templates, and Claude Code DevEx tooling for the ecosystem.

## Structure

```
.claude/
  hooks/
    circuit-breaker.cjs         # Circuit breaker for API calls
    secret-scanner.cjs          # Secret detection before git commit
    frustration-detection.cjs   # Prompt context injection
    verifiable-thresholds.cjs   # Code quality threshold warnings
    memory-consolidation.cjs    # Context hygiene CLI tool
    model-debt-inventory.cjs    # Model-specific rule inventory CLI
  settings.json                 # Claude Code hook configuration
  thresholds.json               # Configurable quality thresholds
  secret-scanner-allowlist.json # Allowlist for secret scanner
  HOOKS_README.md               # Full hooks documentation

copilot-instructions/
  base.md                       # Base GitHub Copilot instructions

workflows/                        # ⚠️ COPY-TO-USE templates — NOT callable via `uses: chrysa/shared-standards/...`
  ci-python.yml                 # Full CI pipeline template for Python projects (copy to .github/workflows/ci.yml)
  ci-node.yml                   # Full CI pipeline template for Node/React projects
  sonar.yml                     # SonarCloud workflow template (workflow_call-compatible after copy)
  release.yml                   # Semantic release template (GitVersion + cliff)
  labeler.yml                   # PR auto-labeler template (actions/labeler@v6)
  pr-size.yml                   # PR size label template (codelytv/pr-size-labeler)
  pages.yml                     # GitHub Pages deploy template
  notion-roadmap-sync.yml       # Notion roadmap sync template
  notion-branch-sync.yml        # Per-branch Notion docs template
  regression-gate.yml           # Regression gate (coverage + test count delta)
  mutation-testing.yml          # Mutation testing template (mutmut)
  contract-testing.yml          # Consumer-driven contract testing template
  enforce-feature-branch.yml    # Block PRs from non-conventional branch names
  secret-scan.yml               # Secret scanning with gitleaks

templates/
  CLAUDE.md                     # Bootstrap CLAUDE.md template
  CODEOWNERS                    # CODEOWNERS template (copy and adapt)
  .gitignore.python             # Python .gitignore
  .gitignore.node               # Node .gitignore
  dependabot.yml                # Dependabot config template
  pr-template.md                # Pull request template
  vscode/
    tasks.python.json           # VS Code tasks template for Python projects
    tasks.fullstack.json        # VS Code tasks template for full-stack projects (Python + TS)
    README.md                   # Documentation and keyboard shortcuts
  e2e/                          # Playwright E2E scaffold for fullstack repos (local dev, see EXECUTION_STANDARD §1.3b)
    playwright.config.ts
    tests/e2e/smoke.spec.ts     # auth-free smoke + optional fixtures.ts.example
  issue-templates/
    bug.md
    feature.md
    chore.md
```

## Usage

### Claude Code hooks

See [.claude/HOOKS_README.md](.claude/HOOKS_README.md) for full documentation.

Quick install in any repo:
```bash
cp -r path/to/shared-standards/.claude/hooks/ .claude/hooks/
# Merge .claude/settings.json manually
```

### Copilot instructions

Copy `copilot-instructions/base.md` to `.github/copilot-instructions.md` in your repo and adjust.
Then append the per-stack guide that matches the repo: `fastapi.md`, `django.md`, `react19.md`,
`python-library.md`, `monorepo.md`, or `gas.md`. Each extends `base.md` and overrides it on conflict.

### Workflows

Copy the relevant template from `workflows/` to `.github/workflows/` in your repo and adapt.
These are **copy-to-use templates**, not reusable workflows callable via `uses:`.
Composite actions (atomic steps) live in [`chrysa/github-actions`](https://github.com/chrysa/github-actions) — use them from inside your copied workflows.

```bash
# Example: add SonarCloud CI to your project
cp path/to/shared-standards/workflows/sonar.yml .github/workflows/sonar.yml
# Then edit to set your project key and secrets
```

### Templates

Use `templates/CLAUDE.md` as a starting point for repo-specific `CLAUDE.md` files.

### VS Code Tasks

Copy the appropriate `tasks.json` template to `.vscode/tasks.json` in your project.
See [templates/vscode/README.md](templates/vscode/README.md) for the full task catalog and keyboard shortcut setup.

```bash
# Python project
cp path/to/shared-standards/templates/vscode/tasks.python.json .vscode/tasks.json

# Full-stack project (Python backend + TS frontend)
cp path/to/shared-standards/templates/vscode/tasks.fullstack.json .vscode/tasks.json
```

Then remove tasks that do not have a corresponding `make` target.

### PII (GDPR) detection

Microsoft Presidio scans for personal data — emails, IBAN, phone numbers, credit
cards, IP addresses and French NIR (with control-key validation) — as a blocking
`pii-scan` pre-commit hook and in CI (`workflows/pii-scan.yml`).

```bash
python -m scripts.pii_scan --all          # scan the whole repo
python -m scripts.pii_scan --selftest     # verify recognizers load
python -m scripts.pii_scan --print-fingerprint path/to/file   # list fingerprints
```

- Config: `.pii-scan.toml` (entities, score threshold, excluded globs).
- Allowlist a reviewed false positive by adding its `--print-fingerprint` value to
  the `allow` array in `.pii-allowlist.json`.
- `PERSON` and `FR_CNI` are excluded by default (spaCy NER is too noisy on code,
  and FR_CNI is a bare 12-digit pattern — see `DECISIONS.md` D-0006); add them to
  `entities` in `.pii-scan.toml` to opt in.
- The pre-commit hook is hermetic: Presidio and the spaCy fr+en model wheels are
  pinned in `additional_dependencies`. CI gates PR-changed files (fast) and runs a
  weekly non-blocking full-repo audit.

## Model tagging

Rules and prompts that are model-specific are tagged with `@[MODEL_NAME]`.
Run the inventory tool to find them:
```bash
node .claude/hooks/model-debt-inventory.cjs --dir .
```

## Local LLM Stack Reference

This standard repository hosts ecosystem-wide guidelines and can reference the **Local LLM Stack for Software + Data Engineering** for projects requiring local LLM infrastructure.

📖 **Reference:** [Local LLM Stack (Notion)](https://www.notion.so/Local-LLM-Stack-for-Software-Data-Engineering-34459293e35e81c2b5b0f8283640b338)

**Purpose:** Central knowledge base for fully local, containerized LLM workflows (code generation, documentation, API connectors, ETL pipelines) to be adopted across the chrysa ecosystem.
