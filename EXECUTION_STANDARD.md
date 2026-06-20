# Chrysa — Execution Standard

**Version 1.7 — 2026-06-14**

This document defines the **mandatory execution conventions** for every chrysa project.
All repos scaffolded with `project-init` must comply. Deviations require a documented ADR.

---

## 0. Canonical Scaffolding Sources (Mandatory)

Every **active** chrysa project derives its build tooling and frontend from two
canonical generators in the `Forge-Stack-Workshop` org. Projects **extend** these
sources — they never fork them or hand-roll an equivalent.

| Concern | Canonical source | Applies to | Detail |
|---|---|---|---|
| Makefile contract | [`Forge-Stack-Workshop/base-makefile`](https://github.com/Forge-Stack-Workshop/base-makefile) | every repo (all tiers) | §1.6 |
| React / Vite frontend | [`Forge-Stack-Workshop/react-app-generator`](https://github.com/Forge-Stack-Workshop/react-app-generator) | `fullstack` repos + standalone web apps | `copilot-instructions/react19.md` |
| FastAPI backend modules | [`Forge-Stack-Workshop/fastapi-app-generator`](https://github.com/Forge-Stack-Workshop/fastapi-app-generator) | FastAPI services | `copilot-instructions/fastapi.md` |

- **base-makefile** owns the §1 Makefile contract; every repo's `Makefile` is generated
  from the matching tiered template — see §1.6 for template selection, tooling, and the
  pinned baseline release.
- **react-app-generator** scaffolds every React 19 + Vite frontend with the
  non-negotiable baseline already wired (i18n FR+EN, dark mode, WCAG 2.1 AA). New
  frontends are produced by the generator, never copied from a sibling repo or
  bootstrapped with `create-react-app` / bare `vite`.
- **fastapi-app-generator** scaffolds FastAPI modules (router / schemas / models /
  service / dependencies + Alembic stub) from a YAML spec via its `fastapi-app-generator`
  CLI. New backend modules are generated from a spec, not hand-copied from a sibling
  service. (Sibling of the Django-side `chrysa/django-app-forge`.)

Conformance is checked by `makefile-check` (chrysa/pre-commit-tools) for the Makefile
contract; frontend origin is asserted at scaffold time by `project-init`. Deviations from
either source require a documented ADR.

---

## 1. Makefile Required Targets

Every chrysa project **must** expose a uniform Makefile contract, generated from the
canonical `Forge-Stack-Workshop/base-makefile` templates (see §0). Target **names are
invariant** (no `fmt`/`type-check`/`tests` variants — see §1.4). The required set is
**tiered by repo archetype**: a small core that every repo has, plus additions per tier.

### 1.1 Tier declaration

Every Makefile **must** declare its tier on the first line as a marker comment, so the
conformance checker (chrysa/pre-commit-tools `makefile-check`) knows which target set to
require:

```makefile
# makefile-tier: lib        # one of: lib | python-app | fullstack | infra
```

### 1.2 Core targets (all tiers)

| Target | Description |
|--------|-------------|
| `help` | Print all targets with descriptions (self-documenting, see §1.5) |
| `install` | Install all dev dependencies (venv, node_modules…) |
| `lint` | Run linter (ruff / eslint…) |
| `format` | Auto-format code (ruff format / prettier…) |
| `test` | Run unit tests |
| `build` | Build production artefact (Docker image / dist bundle) |
| `clean` | Remove generated artefacts and caches |
| `pre-commit` | Run pre-commit hooks on all files |

### 1.3 Required targets by tier

These extend §1.2 and must always be definable correctly without extra
infrastructure, so they are **mandatory** (the `makefile-check` hook fails when
one is missing).

| Target | `lib` | `python-app` | `fullstack` | `infra` | Description |
|--------|:---:|:---:|:---:|:---:|-------------|
| `dev` | ✅ | ✅ | ✅ | ✅ | Start dev server / watch mode (may be a no-op stub for libs) |
| `typecheck` | ✅ | ✅ | ✅ | — | Static type checker (mypy / tsc) — typed projects |
| `test-cov` | ✅ | ✅ | ✅ | — | Tests with coverage (writes `coverage.xml`); floor 80% |
| `docker-up` | — | ✅ | ✅ | — | Start docker compose services |
| `docker-down` | — | ✅ | ✅ | — | Stop docker compose services |
| `ci` | — | ✅ | ✅ | — | Aggregate gate: `lint typecheck test` |

### 1.3b Recommended targets by tier

These depend on supporting infrastructure (a `Dockerfile.test`,
`scripts/quality_gate.py`, a wired frontend build). They are **recommended**:
the hook emits a warning, not an error, when absent — adopt each one as its
infrastructure lands.

| Target | `lib` | `python-app` | `fullstack` | `infra` | Description |
|--------|:---:|:---:|:---:|:---:|-------------|
| `docker-test` | ✅ | ✅ | ✅ | — | Run the test suite in Docker (CI-compatible, host-isolated) |
| `quality-gate-baseline` | — | ✅ | ✅ | — | Capture quality baseline (`scripts/quality_gate.py baseline`) |
| `quality-gate-verify` | — | ✅ | ✅ | — | Verify against baseline (`scripts/quality_gate.py verify`) |
| `web-build` | — | — | ✅ | — | Build the frontend bundle |
| `web-lint` | — | — | ✅ | — | Lint the frontend |
| `web-typecheck` | — | — | ✅ | — | Type-check the frontend |
| `e2e` | — | — | ✅ | — | Run end-to-end tests (Playwright) |

**Tier definitions:**
- **`lib`** — pure package, no `docker-compose.yml`. `lint/format/typecheck/test/test-cov`
  run the tool directly via the venv created by `make install`; the recommended
  `docker-test` builds `Dockerfile.test`. Reference: `chrysa/django-pytest`.
- **`python-app`** — backend service with `docker-compose.yml`. Tests/lint run via
  compose; `ci` chains `lint typecheck test`. The recommended `docker-test` and
  `quality-gate-*` targets activate once `Dockerfile.test` / `scripts/quality_gate.py` exist.
- **`fullstack`** — backend + frontend. Uses `COMPOSE`/`COMPOSE_TEST` + `BACKEND_DIR`/
  `FRONTEND_DIR` vars and `web-*`/`e2e`. Reference: `chrysa/discordium`, `chrysa/sport-intelligence-hub`.
- **`infra`** — helm / k8s / vscode-ext / GAS / compose-only. Core targets plus domain
  targets (`deploy`, `render`, `package`…). No forced Python targets where they make no sense.

### 1.4 Naming policy (invariant)

Canonical names only. Forbidden variants and their replacements:

| Forbidden | Canonical |
|---|---|
| `fmt` | `format` |
| `type-check`, `typecheck-frontend` (alone) | `typecheck` |
| `tests` | `test` |
| `docker-compose …` (legacy v1 CLI) | `docker compose …` |

Optional extras (allowed, not required): `format-check`, `test-fast`, `test-local`,
`logs`, `ps`, `shell`, `seed`, migration targets (`alembic-*`, `db-*`), `docs-*`.
Redundant aliases (e.g. `type-check` kept *alongside* `typecheck`) must be removed.

`.PHONY` must list **every** non-file target.

### 1.5 Self-documenting `help` (standard)

`help` is the default goal and is generated from `## ` comments — no hand-maintained echo
list:

```makefile
.DEFAULT_GOAL := help
help: ## Show available targets
	@grep -E '^[a-zA-Z_-]+:.*##' $(MAKEFILE_LIST) | \
		awk 'BEGIN{FS=":.*##"}{ printf "  %-20s %s\n", $$1, $$2 }'
```

> **Convention**: `make dev` must be idempotent and exit cleanly with Ctrl+C.
> Enforcement: `makefile-check` (chrysa/pre-commit-tools) fails CI if the tier's required
> targets are missing, a forbidden name is used, `help` is non-conforming, or a rule
> references a directory/service/script that does not exist.

### 1.6 Derivation from `base-makefile`

Every Makefile **must derive from a `Forge-Stack-Workshop/base-makefile` template** —
never hand-rolled from scratch. The template carries the derivation markers the contract
expects: `.DEFAULT_GOAL := help`, the `$(MAKEFILE_LIST)`-driven self-documenting `help`
recipe (§1.5), and `@`-prefixed recipe lines. Pick the template by archetype:

| Repo archetype                         | §1 tier      | base-makefile template       |
|----------------------------------------|--------------|------------------------------|
| py / django **library**                | `lib`        | `Makefile.python`            |
| node **library**                       | `lib`        | `Makefile.basic`             |
| backend service (compose, no frontend) | `python-app` | `Makefile.python`            |
| backend + frontend monorepo            | `fullstack`  | `Makefile.with-sub-folder`   |
| infra / helm / GAS / vscode-ext / config | `infra`    | `Makefile.basic`             |

**Tooling** (in `shared-standards/scripts/`):

- `audit-makefile-conformance.sh` — read-only fleet audit (classifies each repo, runs
  `makefile-check`, reports hook wiring + CI coverage). Persists a ledger at
  `compliance/makefile-conformance.json`.
- `sync-makefile.sh` — scaffolds a per-tier Makefile from base-makefile (repos with none)
  or, for existing Makefiles, reports missing §1 pieces without overwriting (`--write`
  drops a `Makefile.base-suggested` for manual merge). Dry-run by default.
- Enforcement stays `makefile-check` (chrysa/pre-commit-tools) — the tooling above audits
  and generates; it does not replace the gate.

> **Template baseline:** base-makefile release **`v0.1.0-29`** is the first where every
> template passes `makefile-check` (marker + tier targets). `sync-makefile.sh` pins
> `BASE_MAKEFILE_REF` to it; bump when a newer conformant release lands.

---

## 2. Directory Structure (Standard Layout)

```
{repo}/
├── .github/
│   ├── workflows/          # CI workflows (from shared-standards)
│   │   ├── ci-*.yml        # Language-specific CI
│   │   ├── pages.yml       # GitHub Pages / MkDocs
│   │   └── release.yml     # Semantic release
│   ├── PULL_REQUEST_TEMPLATE.md
│   └── labeler.yml         # PR size + content labeler
├── docs/                   # MkDocs source
│   └── index.md
├── {src_dir}/              # Main source code
├── tests/                  # All tests; mirrors src structure
├── CLAUDE.md               # Repo-specific agent config
├── CHANGELOG.md            # Generated by cliff
├── cliff.toml              # Git-cliff changelog config
├── GitVersion.yml          # Semantic versioning config
├── Makefile                # Required targets (see §1)
├── opencode.json           # Opencode agent config (propagated from agent-config)
├── pyproject.toml / package.json
└── README.md               # Reflects actual state; updated on each release
```

---

## 3. Branching & Commit Rules

### Branch naming
```
feat/<issue-id>-short-desc     # new feature
fix/<issue-id>-short-desc      # bug fix
chore/<desc>                   # maintenance, deps, refactor
docs/<desc>                    # documentation only
ci/<desc>                      # CI/CD changes
hotfix/<desc>                  # urgent prod fix
```

### Commit format (Conventional Commits)
```
<type>(<scope>): <description>

type: feat | fix | chore | docs | ci | refactor | test | perf
scope: optional, lowercase, matches affected module
description: imperative, lowercase, no period
```

### Merge rules
- All PRs require at least 1 approval
- CI must pass (lint + test + typecheck)
- Branch must be up to date with `main`
- Squash merge for feature branches; merge commit for releases

---

## 4. Testing Standards

- Minimum **85% line coverage** on all new code (per-project override allowed, never below 80%)
- Tests are **deterministic**: no network, no real filesystem without mocking
- Test names: `test_<unit>_when_<condition>_should_<expected>`
- Coverage artifact: `coverage.xml` generated on every CI run
- Python: `pytest` · JS/TS: `vitest` or `jest` · Go: `go test`
- Flaky tests: mark with `@pytest.mark.flaky` and open a GitHub issue

---

## 5. CI/CD Lifecycle

```
push (any branch)
  ↓
ci.yml (thin caller → chrysa/github-actions ci-python.yml@main):
  lint (pre-commit GATE: ruff + format + mypy + gitleaks + actionlint + pre-commit-tools)
    ↓ reports (ruff.json + mypy.txt for Sonar) ↓ test-cov (matrix) ↓ sonar
  ↓
PR review: 1 approval required
  ↓
Merge to main
  ↓
release.yml (main push): GitVersion auto-version + cliff CHANGELOG + GitHub Release
  ↓
pages.yml (main push): MkDocs deploy to GitHub Pages
```

**Weekly (cron):**
```
mutation-testing.yml: mutmut mutation score — minimum 70% threshold
```

### Canonical CI (mandatory, Python repos)

Every Python repo's `.github/workflows/ci.yml` is a **thin caller** of the reusable
lean pipeline — it does **not** inline jobs:

```yaml
jobs:
  ci:
    uses: chrysa/github-actions/.github/workflows/ci-python.yml@main
    with:
      package: my_pkg                 # import / coverage module
      sources: "src/my_pkg tests"     # ruff sources
      project-key: chrysa_my-repo
      project-name: my-repo
      # src layout : sonar-sources: src · typecheck-paths: src/my_pkg
      # flat layout: sonar-sources: "." · typecheck-paths: my_pkg
    secrets: inherit
```

The reusable workflow runs four jobs: **lint** (pre-commit replay — the single quality
GATE: ruff, format, mypy, gitleaks, actionlint, `chrysa/pre-commit-tools`), **reports**
(ruff.json + mypy.txt artifacts for Sonar), **test** (coverage matrix), **sonar**.
Everything that can be a pre-commit hook *is* one — there is **no** standalone
`secret-scan.yml` / `lint` / `action-check` workflow (gitleaks + actionlint run in
pre-commit). Node repos use `ci-node`; infra/GAS use domain-appropriate checks.

### Required workflows (every repo)

| Workflow | File | Source | Trigger |
|---|---|---|---|
| CI | `ci.yml` (thin caller) | `chrysa/github-actions/.github/workflows/ci-python.yml@main` | push + PR |
| Release (auto-version) | `release.yml` | GitVersion + git-cliff | push to main |

`dependabot.yml` + `auto-update-pre-commit.yml` keep deps and hooks current. The
**auto-version calculation (GitVersion) is preserved in every repo's `release.yml`** and
is never folded into CI. PR-cosmetic automations (labeler, size, auto-assign…) are
optional, not required.

### Conditional workflows

| Workflow | Condition |
|---|---|
| `pages.yml` | Projects with MkDocs docs |
| `mutation-testing.yml` | Opt-in (weekly cron) |
| `regression-gate` (pre-commit, pre-push stage) | Projects with `make test` |

Reusable `workflow_call` workflows live in **`chrysa/github-actions/.github/workflows/`**
(callable via `uses:`). Copy-to-use templates live in `chrysa/shared-standards/workflows/`.

---

## 6. Docker Standards

- Dockerfile: **4-stage** build (deps → build → test → runtime)
- Base image: `python:3.14-slim` / `node:22-alpine`
- Image tag: `{repo}:{version}` and `{repo}:latest`
- Health check: every container must define `HEALTHCHECK`
- No secrets in image layers
- `docker-compose.yml` must define `healthcheck` + `restart: unless-stopped`

### Registry (mandatory)

- Docker images are pushed to a **private registry** — **GHCR** under the chrysa org:
  `ghcr.io/chrysa/{repo}`, package visibility **private** (never public).
- Published tags mirror the git tag: `ghcr.io/chrysa/{repo}:{version}` (semver) **and** `:latest`.
- CI authenticates to `ghcr.io` via `docker/login-action` using the workflow `GITHUB_TOKEN`
  (or a least-privilege `packages:write` token) — **no PAT in plaintext**, no long-lived secret in image layers.
- The build + scan + push is carried by the reusable `build-image.yml` workflow (see `chrysa/github-actions`).

### 6.1 Container-runtime policy & nature exemptions

**Rule: a project runs ONLY in a container — unless its nature forbids it.** No project's runtime
may depend on host-installed interpreters or tooling; if it executes as a service, it executes in a
container. Tests, lint, and type-checks always go through `make` Docker targets, never the host
(§12).

Every repo is classified by a `runtime:` field in [`repos.yml`](repos.yml). The "nature forbids"
exemptions are explicit and finite:

| `runtime` | What it means | Must provide |
|---|---|---|
| `container` | Runs as a service. | Dockerfile(s) + `docker-compose*` + `HEALTHCHECK` + `docker-up`/`docker-down`/`docker-test` targets. |
| `exempt:lib` | Distributed/imported — library, plugin, pre-commit hook, GitHub Action, CLI tool. Runs inside the **consumer's** environment, not as our service. | `docker-test` target (CI runs the suite in a container). |
| `exempt:config` | No executable runtime — config, knowledge base (Obsidian), deployment manifests, reusable container-definition collections. | Nothing (nothing to run). |
| `exempt:native` | Bound to a host OS, physical device, cloud platform, or editor — Windows desktop integration, webcam/gesture control, hardware controllers, Google Apps Script, VS Code extensions, infra/Helm/GitOps. A container cannot provide the required host access. | Optional `Dockerfile.test` for CI; runtime stays native by necessity. |
| `pending` | Pre-code scaffold (no app code yet). | Flips to `container` at first code — `project-init`/`chrysa-init` scaffold the container so new repos start compliant. |

A repo is exempt **only** when its nature genuinely forbids containerized execution. Convenience,
"it's easier on the host", or "it's just a script" are **not** exemptions. When in doubt, classify
`container`.

Conformance is machine-checked by [`audit-docker-compliance.sh`](audit-docker-compliance.sh), which
reads `repos.yml` and verifies each repo provides what its class requires (output:
`compliance/docker-conformance.json`).

---

## 7. Documentation

- `README.md` reflects actual current state; updated on each release
- `docs/` contains MkDocs source; deployed via `pages.yml`
- Architecture decisions → `docs/adr/ADR-XXX-title.md`
- No executable code in Notion; no production secrets anywhere in docs

---

## 8. Security

- OWASP Top 10 check on every PR via PR Review Skill
- No hardcoded secrets — use env vars + `.env.example`
- **Secret scanning (mandatory):** `gitleaks` pre-commit hook + `secret-scan.yml` CI workflow on every repo
- Dependabot enabled for all repos (`.github/dependabot.yml`)
- SonarQube scan for Python and JS/TS projects (via `sonar.yml`)
- `pre-commit run --all-files` before pushing (enforced via `pre-commit.yml` CI on every PR)

### Pre-commit hooks (mandatory baseline)

Every repo **must** include these hooks in `.pre-commit-config.yaml`:

| Hook | Repo | Purpose |
|---|---|---|
| `no-commit-to-branch` | `pre-commit-hooks` | Prevent direct push to main/develop |
| `trailing-whitespace`, `end-of-file-fixer` | `pre-commit-hooks` | File hygiene |
| `gitleaks` | `gitleaks/gitleaks` | Secret detection |
| `conventional-pre-commit` | `compilerla/conventional-pre-commit` | Commit message lint |

Additional hooks by stack:

| Hook | Stack | Purpose |
|---|---|---|
| `ruff` + `ruff-format` | Python | Lint + format |
| `mypy` | Python (typed) | Static type checking |
| `hadolint` | Any with Dockerfile | Dockerfile lint |
| `debugger-detection`, `python-print-detection` | Python | Code quality |

Reference config: `chrysa/shared-standards/.pre-commit-config.yaml`

---

## 9. Environment Variables

Standard `.env.example` naming:
```sh
# Required
DATABASE_URL=postgresql://user:pass@localhost:5432/db
SECRET_KEY=change-me

# Optional
LOG_LEVEL=INFO
DEBUG=false
```

Never commit `.env`. Always commit `.env.example` with placeholder values.

---

## 10. Agent & AI Tooling

- Every repo contains `opencode.json` (propagated from `agent-config/base/`)
- Agents read `CLAUDE.md` (global base + repo-specific) before acting
- MCP integrations: GitHub (all repos) + Notion (projects with Notion content)
- Unattended agent mode: no code changes outside open PRs

---

## 11. Python Packaging & Tooling Standard

**`pyproject.toml` is the single source of truth** for all Python projects.
`setup.cfg` and `setup.py` are **forbidden** — do not create or commit them.

### Build backend

| Project type | Backend | `requires` |
|---|---|---|
| Library / package | `setuptools` | `["setuptools>=70", "wheel"]` |
| Application (no distribution) | `setuptools` | `["setuptools>=72", "wheel"]` |

> Backend rationale (2026-06-10): the portfolio standardised on
> `setuptools` (7/8 libs already use it). `hatchling` is **not** used;
> migrate any stray `hatchling` lib (e.g. `django-autoload`) to setuptools.

### Mandatory sections

```toml
[build-system]
requires = ["setuptools>=70", "wheel"]
build-backend = "setuptools.build_meta"

[project]
name = "..."
version = "..."
requires-python = ">=3.14"        # minimum 3.12 for legacy packages
dependencies = [...]

[project.optional-dependencies]
dev = ["pytest>=8.3", "pytest-cov>=6", "ruff>=0.11", "mypy>=1.15"]

[tool.pytest.ini_options]
testpaths = ["tests"]
addopts = "-v --tb=short --cov=src --cov-report=xml --cov-report=term-missing"

[tool.ruff]
line-length = 120
target-version = "py314"          # match requires-python

[tool.ruff.lint]
select = ["E", "F", "W", "I", "B", "UP", "N", "S", "RUF"]
ignore = ["S101"]                  # assert OK in tests

[tool.mypy]
python_version = "3.14"
strict = true
ignore_missing_imports = true
```

### Rules

- All tool config (`ruff`, `mypy`, `pytest`, `coverage`) lives in `[tool.*]` sections of `pyproject.toml`.
- External config files (`ruff.toml`, `mypy.ini`, `pytest.ini`, `.mypy.ini`) are **forbidden**.
- `setup.cfg` is permitted only for non-Python tooling (e.g. uwsgi); never for Python packaging.
- Library packages use `src/` layout with `[tool.setuptools.packages.find] where = ["src"]`.
- Library packages follow the **Public API Contract** (`docs/PUBLIC-API-CONTRACT.md`): sorted `__all__`, relative imports in `__init__`, `__version__` via `importlib.metadata`, uniform `install()` entrypoint, shared types in `chrysa-lib`.
- Applications without distribution do not need `[build-system]`; only `[tool.*]` sections are required.

### Distribution

Distribution is driven by the project type declared in the **Build backend** table above:

- **Library / package (distributable)** → published to **public PyPI**, triggered by CI on a git tag
  matching `v*.*.*`. Build with `setuptools`, upload via Trusted Publishing (PyPI OIDC) — **no PyPI API
  token in plaintext**. Include `CHANGELOG.md`, `LICENSE`, and `README.md` in the sdist.
- **Application (no distribution)** → **not** published to PyPI; shipped as a **private GHCR image** (see §6).
- Publication is carried by the reusable `release.yml` workflow (tag → publish; see `chrysa/github-actions`).

---

## 12. Local Test Procedure (all projects)

**NON-NEGOTIABLE**: never invoke `ruff`, `pytest`, `mypy`, `tsc`, `eslint`, `vitest` or `npm test` directly
on the host. Always delegate to `make` targets which handle the correct environment (Docker or venv).

### Universal sequence (every project, every stack)

```bash
# 1. Install dependencies
make install            # or: make install-dev for dev extras

# 2. Lint (zero warnings required)
make lint

# 3. Tests
make test               # unit tests, fast feedback loop
make test-cov           # with coverage — must stay >= 85%

# 4. Type check (typed projects only)
make typecheck

# 5. Pre-commit hooks on all files
make pre-commit

# 6. Validate GitHub Actions workflows (no host actionlint required)
docker run --rm -v "$PWD:/repo" -w /repo rhysd/actionlint:latest

# 7. Quality gate
make quality-gate-verify
```

### Regression gate (automated — pre-push + CI)

The regression gate runs automatically at two points:

**1. Pre-push (local, blocking)**

The `regression-gate` pre-commit hook fires on `git push` and compares the
reports generated by `make test` against the stored baseline:

```bash
# One-time setup: capture baseline after a clean test run
make baseline           # writes .quality-baseline.json

# Thereafter: push is automatically blocked if metrics regress
git push                # regression-gate hook runs here
```

If a regression is detected, the push is blocked with a diff report.
Update the baseline intentionally after a deliberate reduction:

```bash
make baseline           # only after confirming the change is acceptable
```

**2. CI (pull_request, blocking)**

The reusable workflow `regression-gate.yml` from `chrysa/shared-standards`:
- Downloads the `quality-baseline` artifact stored from the last `main` push.
- Compares coverage and test count; fails the job on any regression.
- Posts a coverage-delta comment on the PR.
- Uploads a new baseline artifact on merge to `main`/`develop`.

Add it to a project CI:

```yaml
jobs:
  regression-gate:
    uses: chrysa/shared-standards/.github/workflows/regression-gate.yml@main
```

**Thresholds enforced by the gate**

| Metric | Rule |
|---|---|
| Tests passing | ≥ baseline count (never decrease) |
| Line coverage | ≥ baseline %; hard floor 80% (pyproject `--cov-fail-under`) |
| Lint warnings | exactly 0 (enforced by `make lint` step in CI) |
| Type errors | 0 new errors vs baseline (enforced by `make typecheck`) |
| Build | exit 0 (`make build`) |

Do **not** open a PR if any gate is red. Fix first, then re-run.

### Docker-backed projects (FastAPI, Node services)

```bash
make docker-up          # start DB + services
make docker-test        # pytest / vitest inside Docker (isolated from host)
make docker-down        # tear down
```

Unit-only fallback (no DB):
```bash
# Python FastAPI example
DATABASE_URL="" make test
```

### Infrastructure projects (Helm / k8s / Terraform)

```bash
# Helm chart lint + dry-run render
helm lint apps/<namespace>/<service>/
helm template <name> apps/<namespace>/<service>/ \
  -f apps/<namespace>/<service>/values/kimsufi.yaml \
  | kubectl apply --dry-run=client -f -

# Terraform
cd terraform/ && terraform fmt -check && terraform validate

# YAML lint
yamllint -d relaxed apps/ k8s/ secrets/
```

### n8n workflow projects (Node / automations)

```bash
make lint && make pre-commit

# Import test — requires running n8n:
#   Option A: kubectl port-forward svc/n8n 5678:5678 -n automation
#   Option B: docker run -it --rm -p 5678:5678 n8nio/n8n
# Then: n8n UI → Settings → Import workflow → select JSON
```

### Reporting format (after every task)

```
Tests   : <N> passed (baseline <N>) ✓/✗
Coverage: <X>% (baseline <X>%) ✓/✗
Lint    : 0 warnings ✓/✗
Types   : 0 errors ✓/✗
Build   : ok ✓/✗
```

---

## 13. Session Workflow (primer + memory + hindsight)

Every chrysa repo ships with a **session lifecycle** to maintain AI agent context across sessions.

### Files

| File | Role | Committed |
|------|------|-----------|
| `primer.md` | Current state — what to do NOW (read before CLAUDE.md) | ✅ yes |
| `.claude/memory/session.md` | Volatile session notes (reset each session) | ❌ no |
| `.claude/memory/decisions.md` | Pending decisions not yet in DECISIONS.md | ✅ yes |
| `.claude/memory/known-issues.md` | Persistent quirks and gotchas | ✅ yes |
| `.claude/memory/progress.md` | Append-only session history | ✅ yes |

### Session protocol

```
┌─ SESSION START ─────────────────────────────────────────────┐
│  make prepare          (or: /prepare in Claude Code)         │
│  → displays primer.md + git context + open PRs              │
└─────────────────────────────────────────────────────────────┘
              ↓ (work happens)
┌─ SESSION END ───────────────────────────────────────────────┐
│  make hindsight        (or: /hindsight in Claude Code)       │
│  → updates primer.md + progress.md + clears session.md      │
│  → optionally exports to Obsidian vault                      │
└─────────────────────────────────────────────────────────────┘
```

### Makefile targets (add to every project Makefile)

```makefile
SCRIPTS_DIR ?= $(shell \
  find $(CURDIR)/.. -maxdepth 4 -path "*/shared-standards/scripts" 2>/dev/null | head -1)

memory-init:  ## Initialize primer.md and .claude/memory/
	@bash $(SCRIPTS_DIR)/memory.sh init

prepare:  ## Pre-session context loader (reads primer + git + PRs)
	@bash $(SCRIPTS_DIR)/prepare.sh

hindsight:  ## Post-session retrospective (updates primer + memory)
	@bash $(SCRIPTS_DIR)/hindsight.sh $(if $(OBSIDIAN),--obsidian $(OBSIDIAN),)

memory-status:  ## Show current memory state
	@bash $(SCRIPTS_DIR)/memory.sh status

memory-obsidian:  ## Export memory to Obsidian vault (OBSIDIAN=<path> required)
	@bash $(SCRIPTS_DIR)/memory.sh obsidian $(OBSIDIAN)
```

### Initial setup for a repo

```bash
make memory-init        # creates primer.md + .claude/memory/
# Fill in primer.md with initial state
git add primer.md .claude/memory/decisions.md .claude/memory/known-issues.md \
        .claude/memory/progress.md
git commit -m "chore: initialize session memory and primer"
```

### Obsidian export

```bash
# Export to an Obsidian vault
make hindsight OBSIDIAN=~/Documents/obsidian/chrysa
# or directly:
./scripts/memory.sh obsidian ~/Documents/obsidian/chrysa
```

Vault structure documented in `shared-standards/templates/obsidian/vault-structure.md`.

### Claude Code slash commands

| Command | Purpose |
|---------|---------|
| `/prepare` | Load primer + git context at session start |
| `/hindsight` | Update primer + memory at session end |

Both are defined in `claude-config/claude/commands/`.

---

## 14. Repository Hygiene Files (Mandatory Baseline)

Every chrysa repo **must** carry these files. They are deployed/normalized by
`shared-standards/scripts/apply-repo-standard.sh` from `templates/`.

| File | Source template | Required | Notes |
|---|---|---|---|
| `.gitignore` | `templates/.gitignore.{python,node}` | ✅ | by stack |
| `.gitattributes` | `templates/.gitattributes` | ✅ | LF normalization + lockfile/binary markers |
| `.editorconfig` | `templates/.editorconfig` | ✅ | |
| `.pre-commit-config.yaml` | `.pre-commit-config.yaml` (Full §8 baseline) | ✅ | trim stack-conditional blocks if N/A |
| `.github/dependabot.yml` | `templates/github-config/dependabot.yml.tpl` | ✅ | by detected ecosystem |
| `.github/CODEOWNERS` | `templates/CODEOWNERS` | ✅ | |
| `CONTRIBUTING.md` | `templates/CONTRIBUTING.md` | ✅ | |
| `CHANGELOG.md` | generated by `cliff` | ✅ | |
| `LICENSE` | `templates/LICENSE.mit` | public repos only | private repos skip; classified in `repos.yml` |
| `README.md` | — | ✅ | reflects actual state (§7) |

### Canonical CI templates

`workflows/ci-python.yml` and `workflows/ci-node.yml` are the canonical stack-CI
templates (copy-to-use, NOT reusable `uses:` workflows). Job names
`pre-commit` / `lint` / `test` / `sonar` are **invariant** — they are the
branch-protection required status checks (see OPS-188). Python CI runs on
Python 3.14 via `chrysa/github-actions/*@v1.0.12` reusable actions with
Docker-based tests (`make docker-test`).
