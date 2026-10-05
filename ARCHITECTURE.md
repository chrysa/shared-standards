# ARCHITECTURE — shared-standards

## Purpose

`shared-standards` est la **source canonique, tool-agnostic** des conventions de
l'écosystème chrysa : standards multi-langages, quality gates, contrats agentiques,
ADRs, templates et vues générées pour agents/IA. Le dépôt ne produit pas d'artefact
applicatif — c'est un **dépôt de documentation et de DevEx tooling** (voir les cibles
`make dev`/`test`/`build` qui répondent explicitement « no dev server / no tests /
no build artefact — shared-standards is a documentation repo »).

Il fournit à l'écosystème : les instructions GitHub Copilot partagées, des workflows CI
génériques (copy-to-use), des templates de dépôt, et l'outillage Claude Code
(hooks, scanners, générateurs). Les consommateurs **dépendent** de ce dépôt ; ils ne
recopient pas sa documentation canonique.

## Stack

- **Python** — outillage et console. Racine ciblée pour les scripts ; la console exige
  `requires-python >= 3.12` (`target-version = "py312"`, `line-length = 100`).
- **Ruff** (lint/format), **mypy** (typecheck), **pytest** + **pytest-cov** (tests) —
  déclarés dans `pyproject.toml` (racine et `console/pyproject.toml`).
- **FastAPI / uvicorn / pydantic v2 / httpx / ruamel.yaml / mcp** — dépendances de la
  console (`standards-console`), exposée en CLI via `standards-console = "standards_console.__main__:main"`.
- **Node/JS** — hooks Claude Code en `.cjs` sous `.claude/` (secret-scanner,
  verifiable-thresholds, memory-consolidation, model-debt-inventory).
- **pre-commit** (`.pre-commit-config.yaml`) comme gate de lint/hygiène.

## Layout

- **`standards/`** — le cœur canonique.
  - `STANDARDS.chrysa.md` (~128 Ko) : **la canon**, source de vérité tool-agnostic.
  - `CORE.chrysa.md` : slim always-on core, **généré** depuis la canon.
  - `annexes/` : annexes normatives par domaine (GOVERNANCE, SCM, ARCHITECTURE-DDD,
    API-CONTRACTS, DATA-MIGRATIONS, CI-CD, CONTAINERS-K3S, FRONTEND, TESTING,
    OBSERVABILITY-OPS, AI-ORCHESTRATION, STACK.chrysa, …). En cas de désaccord, la canon gagne.
  - `rules/` : 22 fichiers `<domain>.md` (governance, stack, scm, architecture, testing,
    frontend, api, security, code-quality, backend-python, containers, ci-cd, …) —
    texte complet pointé une-ligne depuis les vues générées.
  - `domains.yaml`, `rule-domains.yaml` : mapping domaines ↔ règles.
- **`docs/`** — documentation transverse et **`docs/adr/`** : série d'ADR
  (`0001-canonical-ci-and-hygiene-baseline` … `0006-decouple-skills-technical-persona`,
  puis taxonomie `D-0010`…`D-0013`). Aussi MAKEFILE-STANDARD, PYTHON-PACKAGING-STANDARD,
  QUALITY-GATES-SUMMARY.
- **`scripts/`** — générateurs et audits (voir Entrypoints).
- **`templates/`** — templates de dépôt : CODEOWNERS, pr-template.md, `vscode/` (tasks
  Python & fullstack), `e2e/` (scaffold Playwright).
- **`workflows/`** — templates CI **copy-to-use** (`ci-python.yml`, `ci-node.yml`,
  `notion-branch-sync.yml`, `context-pack-check.yml`, …) — **non** appelables via `uses:`.
- **`console/`** — `standards-console` : console FastAPI locale de pilotage de la flotte
  (avec `Dockerfile`, package `standards_console`, tests).
- **`copilot-instructions/`** — instructions GitHub Copilot partagées.
- **`makefiles/`** — fragments Makefile par profil (`base`, `django`, `fastapi`,
  `react19`, `python-library`, `monorepo`, `gas`) + `quality-gate.Makefile`.
- **`legal/`** — templates légaux (`cgu.md`, `mentions-legales.md`).
- **`.claude/`** — hooks Claude Code (`settings.json`, `HOOKS_README.md`, scanners `.cjs`).
- **`compliance/`** — rapports de conformité (ex. `makefile-conformance.json`).
- **`tests/`** — pytest (`tests/scripts`, `tests/pii`, …) couvrant les générateurs.

## Entrypoints

- `make gen-agent-views` → `scripts/gen_agent_views.py` : régénère les vues d'agents
  (CORE.chrysa.md slim, `standards/rules/<domain>.md`, AGENTS.md,
  `.github/copilot-instructions.md`) depuis la canon. Gate `agent-views-drift`.
- `make gen-context-files` → `scripts/gen_context_files.py` (ADR D-0012) : régénère les
  fichiers de contexte par dépôt. Gate `context-files-drift`.
- `scripts/gen_context_pack.py` : génération du context pack (voir `workflows/context-pack-check.yml`).
- `scripts/distribute-standards.sh` / `apply-repo-standard.sh` : distribution et
  application du baseline vers les dépôts consommateurs.
- `scripts/audit-*.sh` : audits de conformité (canonical, makefile, quality-gate, repo).
- ADR : `scripts/spec_plan_gate_report.py` et la commande `adr-new` (skill) pour créer un ADR.
- `standards-console` : CLI/serveur de la console de flotte (`python -m standards_console`).

## Data / deps

- **Entrées de génération** : `standards/STANDARDS.chrysa.md` (canon),
  `standards/domains.yaml`, `standards/rule-domains.yaml`, `.quality-gate.json`.
- **Fichiers de contexte générés** (ADR D-0012, marqués « GENERATED … do not edit ») :
  `handover.md`, `context-map.json`, `llms-full.txt`, `ai-instructions.md`.
  `context-map.json` déclare notamment `depends_on_shared_standards: true`, les ADR et
  les contrats (`contracts: ["standards"]`).
- **Consommation** : les dépôts tirent le standard via `distribute-standards.sh` /
  `apply-repo-standard.sh`, dépendent des contrats versionnés, et ne dupliquent pas la
  documentation canonique.

## Build & test

Commandes réelles (`Makefile`, `pyproject.toml`) :

```bash
make install      # installe les hooks pre-commit
make lint         # pre-commit run --all-files
make pre-commit   # idem, tous les gates
make format       # pre-commit (auto-fix best-effort)
make test-scripts # coverage pytest sur scripts/ (quality_gate, gen_agent_views, gen_context_files, pii, …)
make docker-test  # build console/Dockerfile (dev) + pytest --cov standards_console
make gen-agent-views      # régénère les vues d'agents depuis la canon
make gen-context-files    # régénère handover/context-map/llms/ai-instructions (ADR D-0012)
```

Lint/format = **Ruff**, types = **mypy**, tests = **pytest/pytest-cov**, le tout piloté
via **pre-commit**. Les gates de drift (`agent-views-drift`, `context-files-drift`)
vérifient que les fichiers générés sont à jour vis-à-vis de la canon.
