# VS Code Tasks Templates

Standard `.vscode/tasks.json` templates for chrysa projects.
These complement the `.devcontainer/devcontainer.json` and expose common `make` targets as runnable VS Code tasks.

## Templates

| File | Stack | Target projects |
|------|-------|-----------------|
| `tasks.python.json` | Python (uv + ruff + mypy) | ai-aggregator, lifeos, doc-gen, etc. |
| `tasks.fullstack.json` | Python backend + TypeScript frontend | dev-nexus, chrysa-lib |

## Available task groups

### Python projects

| Task label | Command | Group |
|------------|---------|-------|
| `lint` | `make lint` | test |
| `format` | `make format` | — |
| `typecheck` | `make typecheck` | test |
| `pre-commit` | `make pre-commit` | — |
| `test` | `make test` | **test (default)** |
| `test-cov` | `make test-cov` | test |
| `dev` | `make dev` | **build (default)** |
| `docker-up` | `make docker-up` | build |
| `docker-down` | `make docker-down` | — |
| `quality-check` | lint → typecheck → test | test |

### Full-stack projects

All Python tasks above, plus:

| Task label | Command | Group |
|------------|---------|-------|
| `lint-backend` | `make lint-backend` | test |
| `lint-frontend` | `make lint-frontend` | test |
| `typecheck-backend` | `make typecheck-backend` | test |
| `typecheck-frontend` | `make typecheck-frontend` | test |
| `test-backend` | `make test-backend` | test |
| `test-frontend` | `make test-frontend` | test |
| `backend` | `make backend` | build |
| `frontend` | `make frontend` | build |

## Usage

Copy the appropriate template to `.vscode/tasks.json` in your project, then add project-specific tasks (e.g. `db-migrate`, `run-headless`).

```bash
cp path/to/shared-standards/templates/vscode/tasks.python.json .vscode/tasks.json
```

Then remove tasks that do not have a corresponding `make` target in the project.

## Keyboard shortcuts

Default VS Code shortcuts:
- `Ctrl+Shift+B` → runs the **build** default task (`dev`)
- `Ctrl+Shift+T` → _(no default)_ — open Command Palette and search _"Run Test Task"_ to run `test`

Custom shortcuts can be added to `keybindings.json`:
```json
{ "key": "ctrl+shift+alt+t", "command": "workbench.action.tasks.test" }
{ "key": "ctrl+shift+alt+l", "command": "workbench.action.tasks.runTask", "args": "quality-check" }
```
