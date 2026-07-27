# Makefile Standard — chrysa

> **Scope.** Procedural detail for the Makefile contract summarised in the canonical
> `standards/STANDARDS.chrysa.md` (`## Makefile targets`). The canonical wins on any
> conflict; this file expands the *tier system*, the *base-makefile derivation*, and the
> supporting tooling. Enforced by `makefile-check` (chrysa/pre-commit-tools).

---

## Canonical scaffolding sources (mandatory)

Every **active** chrysa project derives its build tooling and frontend from canonical
generators in the `Forge-Stack-Workshop` org. Projects **extend** these sources — they
never fork them or hand-roll an equivalent.

| Concern | Canonical source | Applies to | Detail |
|---|---|---|---|
| Makefile contract | [`Forge-Stack-Workshop/base-makefile`](https://github.com/Forge-Stack-Workshop/base-makefile) | every repo (all tiers) | Derivation section below |
| React / Vite frontend | [`Forge-Stack-Workshop/react-app-generator`](https://github.com/Forge-Stack-Workshop/react-app-generator) | `fullstack` repos + standalone web apps | `copilot-instructions/react19.md` |
| FastAPI backend modules | [`Forge-Stack-Workshop/fastapi-app-generator`](https://github.com/Forge-Stack-Workshop/fastapi-app-generator) | FastAPI services | `copilot-instructions/fastapi.md` |

- **base-makefile** owns the Makefile contract; every repo's `Makefile` is generated
  from the matching tiered template.
- **react-app-generator** scaffolds every React 19 + Vite frontend with the
  non-negotiable baseline already wired (i18n FR+EN, dark mode, WCAG 2.1 AA). New
  frontends are produced by the generator, never copied from a sibling repo or
  bootstrapped with `create-react-app` / bare `vite`.
- **fastapi-app-generator** scaffolds FastAPI modules (router / schemas / models /
  service / dependencies + Alembic stub) from a YAML spec. New backend modules are
  generated from a spec, not hand-copied from a sibling service. (Sibling of the
  Django-side `chrysa/django-app-forge`.)

Conformance is checked by `makefile-check` for the Makefile contract; frontend origin is
asserted at scaffold time by `project-init`. Deviations from either source require a
documented ADR.

---

## Tier system

Target **names are invariant** (no `fmt`/`type-check`/`tests` variants — see naming policy).
The required set is **tiered by repo archetype**: a small core every repo has, plus additions
per tier.

### Tier declaration

Every Makefile **must** declare its tier on the first line as a marker comment, so
`makefile-check` knows which target set to require:

```makefile
# makefile-tier: lib        # one of: lib | python-app | fullstack | infra
```

### Core targets (all tiers)

| Target | Description |
|--------|-------------|
| `help` | Print all targets with descriptions (self-documenting) |
| `install` | Install all dev dependencies (venv, node_modules…) |
| `lint` | Run linter (ruff / eslint…) |
| `format` | Auto-format code (ruff format / prettier…) |
| `test` | Run unit tests |
| `build` | Build production artefact (Docker image / dist bundle) |
| `clean` | Remove generated artefacts and caches |
| `pre-commit` | Run pre-commit hooks on all files |

### Required targets by tier

These extend the core and must always be definable correctly without extra
infrastructure, so they are **mandatory** (`makefile-check` fails when one is missing).

| Target | `lib` | `python-app` | `fullstack` | `infra` | Description |
|--------|:---:|:---:|:---:|:---:|-------------|
| `dev` | ✅ | ✅ | ✅ | ✅ | Start dev server / watch mode (may be a no-op stub for libs) |
| `typecheck` | ✅ | ✅ | ✅ | — | Static type checker (mypy / tsc) — typed projects |
| `test-cov` | ✅ | ✅ | ✅ | — | Tests with coverage (writes `coverage.xml`); floor 80% |
| `docker-up` | — | ✅ | ✅ | — | Start docker compose services |
| `docker-down` | — | ✅ | ✅ | — | Stop docker compose services |
| `ci` | — | ✅ | ✅ | — | Aggregate gate: `lint typecheck test` |

### Recommended targets by tier

These depend on supporting infrastructure (a `Dockerfile.test`, `scripts/quality_gate.py`,
a wired frontend build). They are **recommended**: the hook emits a warning, not an error,
when absent — adopt each one as its infrastructure lands.

| Target | `lib` | `python-app` | `fullstack` | `infra` | Description |
|--------|:---:|:---:|:---:|:---:|-------------|
| `docker-test` | ✅ | ✅ | ✅ | — | Run the test suite in Docker (CI-compatible, host-isolated) |
| `quality-gate-baseline` | — | ✅ | ✅ | — | Capture quality baseline (`scripts/quality_gate.py baseline`) |
| `quality-gate-verify` | — | ✅ | ✅ | — | Verify against baseline (`scripts/quality_gate.py verify`) |
| `web-build` | — | — | ✅ | — | Build the frontend bundle |
| `web-lint` | — | — | ✅ | — | Lint the frontend |
| `web-typecheck` | — | — | ✅ | — | Type-check the frontend |
| `e2e` | — | — | ✅ | — | Run end-to-end tests (Playwright) |

**`e2e` — canonical form (local dev, opt-in).** Playwright runs inside the official docker
image (never on the host); the stack must be up first (`make docker-up`). It is **not** a CI
gate. Scaffold to copy: `shared-standards/templates/e2e/` (`playwright.config.ts` + auth-free
`smoke.spec.ts`; optional seeded-auth `fixtures.ts.example`). Reference implementation:
`chrysa/discordium`.

```makefile
e2e: ## Run Playwright E2E tests (stack must be up: make docker-up)
	docker run --rm --network host \
		-v $(PWD)/$(FRONTEND_DIR):/app -w /app \
		-e E2E_BASE_URL=http://localhost:$(E2E_PORT) \
		mcr.microsoft.com/playwright:v1.60.0-noble \
		sh -c "npm ci --silent && npx playwright test"

e2e-headed: ## Run Playwright with browser UI (debug)
	cd $(FRONTEND_DIR) && npx playwright test --headed
```

### Tier definitions

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

---

## Naming policy (invariant)

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

---

## Self-documenting `help` (standard)

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

---

## Derivation from `base-makefile`

Every Makefile **must derive from a `Forge-Stack-Workshop/base-makefile` template** —
never hand-rolled from scratch. The template carries the derivation markers the contract
expects: `.DEFAULT_GOAL := help`, the `$(MAKEFILE_LIST)`-driven self-documenting `help`
recipe, and `@`-prefixed recipe lines. Pick the template by archetype:

| Repo archetype                         | Tier         | base-makefile template       |
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
  or, for existing Makefiles, reports missing pieces without overwriting (`--write` drops a
  `Makefile.base-suggested` for manual merge). Dry-run by default.
- Enforcement stays `makefile-check` (chrysa/pre-commit-tools) — the tooling above audits
  and generates; it does not replace the gate.

> **Template baseline:** base-makefile release **`v0.1.0-29`** is the first where every
> template passes `makefile-check` (marker + tier targets). `sync-makefile.sh` pins
> `BASE_MAKEFILE_REF` to it; bump when a newer conformant release lands.
