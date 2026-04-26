# shared-standards

Shared GitHub Copilot instructions, generic workflows, templates, and Claude Code DevEx tooling for the chrysa ecosystem.

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

workflows/
  ci-python.yml                 # Reusable CI workflow for Python projects
  ci-node.yml                   # Reusable CI workflow for Node/React projects
  sonar.yml                     # SonarQube analysis workflow
  release.yml                   # Semantic release workflow

templates/
  CLAUDE.md                     # Bootstrap CLAUDE.md template
  .gitignore.python             # Python .gitignore
  .gitignore.node               # Node .gitignore
  dependabot.yml                # Dependabot config template
  pr-template.md                # Pull request template
  vscode/
    tasks.python.json           # VS Code tasks template for Python projects
    tasks.fullstack.json        # VS Code tasks template for full-stack projects (Python + TS)
    README.md                   # Documentation and keyboard shortcuts
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

### Workflows

Reference the generic workflows from `.github/workflows/` in your repo CIs.

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

## Model tagging

Rules and prompts that are model-specific are tagged with `@[MODEL_NAME]`.
Run the inventory tool to find them:
```bash
node .claude/hooks/model-debt-inventory.cjs --dir .
```
