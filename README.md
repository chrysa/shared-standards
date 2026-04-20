# shared-standards

**Source de vérité** de la standardisation chrysa : Copilot instructions partagées, workflows GitHub Actions reusable, templates (Docker, compose, Makefile, gitignore, pre-commit), scripts de bootstrap, et tooling DevEx Claude Code.

**Objectifs** :

1. Reconfigurer un nouvel environnement chrysa en **une commande**
2. Être **appelable par tous les projets** (workflows via `workflow_call`, templates via `curl`, hooks via `pre-commit repos`)
3. Un seul changement de standard → propagé via Dependabot à tout l'écosystème

## Démarrage rapide

### Nouveau repo — bootstrap one-command

```bash
curl -sSL https://raw.githubusercontent.com/chrysa/shared-standards/main/scripts/bootstrap-new-repo.sh \
  | bash -s -- --type python --name my-new-project --apply
```

Types supportés : `python`, `node`, `mixed`. Dry-run par défaut (sans `--apply`).

### Repo existant — intégration

```yaml
# .github/workflows/ci.yml
name: CI
on: { pull_request: {}, push: { branches: [main, develop] } }
jobs:
  ci:
    uses: chrysa/shared-standards/.github/workflows/ci-python.yml@v1
    with:
      python-version: "3.14"
      coverage-threshold: 85
    secrets:
      SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
```

Guide complet : [docs/USAGE.md](docs/USAGE.md).

## Structure

```
shared-standards/
├── .claude/
│   ├── hooks/                      # 5 hooks Claude Code (circuit-breaker, secret-scanner, frustration, thresholds, memory)
│   ├── skills/                     # Skills vendorisables
│   ├── settings.json               # Config hooks
│   ├── thresholds.json
│   ├── secret-scanner-allowlist.json
│   └── HOOKS_README.md
│
├── .github/
│   ├── workflows/                  # Callables depuis autres repos (workflow_call)
│   │   ├── ci-python.yml           # ← reusable · inputs python-version, paths, coverage-threshold
│   │   ├── ci-node.yml             # ← reusable · inputs node-version, package-manager, build-command
│   │   ├── ci.yml                  # CI interne du repo shared-standards lui-même
│   │   ├── dependencies.yml
│   │   └── labeler.yml
│   ├── actions/                    # (post ADR-0009) composite actions héritées de chrysa/github-actions
│   ├── ISSUE_TEMPLATE/
│   ├── instructions/
│   ├── copilot-instructions.md
│   ├── dependabot.yml
│   ├── labeler.yml
│   └── pull_request_template.md
│
├── copilot-instructions/
│   └── base.md                     # Base GitHub Copilot instructions
│
├── templates/
│   ├── CLAUDE.md                   # Bootstrap CLAUDE.md
│   ├── CODEOWNERS
│   ├── copilot-instructions.md
│   ├── dependabot.yml
│   ├── dependabot.unified.yml
│   ├── labeler.yml
│   ├── pr-template.md
│   ├── opencode.json
│   ├── settings.json
│   ├── issue-templates/            # bug.md · feature.md · chore.md
│   ├── dockerfile/
│   │   ├── Dockerfile.python       # Python 3.14 multi-stage, non-root, HEALTHCHECK
│   │   └── Dockerfile.node         # Node 25 + nginx runtime, SPA fallback
│   ├── compose/
│   │   ├── docker-compose.yml      # compose v2 + postgres + redis + healthchecks
│   │   └── .env.example
│   ├── makefile/
│   │   ├── Makefile                # Entry point
│   │   └── makefiles/              # Modulaires : install, quality, docker
│   ├── gitignore/
│   │   ├── .gitignore.python       # Python + Poetry + uv + Django + IDE
│   │   └── .gitignore.node         # Node + Vite + pnpm + playwright
│   └── pre-commit/
│       └── .pre-commit-config.yaml # Callant chrysa/pre-commit-tools
│
├── workflows/                      # ⚠️ Duplicatas documentaires — pour usage reusable, voir .github/workflows/
│   ├── sonar.yml
│   ├── release.yml
│   ├── pr-size.yml
│   ├── pages.yml
│   ├── labeler.yml
│   └── notion-roadmap-sync.yml
│
├── scripts/
│   └── bootstrap-new-repo.sh       # ← appelé par curl … | bash pour nouveau repo
│
├── docs/
│   ├── USAGE.md                    # Guide complet pour projets tiers
│   └── MIGRATION-ADR-0009-0010-0013.md   # Plan d'exécution des 3 ADRs pending
│
└── notion-assets/                  # SVGs et docs Notion
```

## Workflows callables

Tous les workflows sous `.github/workflows/ci-*.yml` sont en `on: workflow_call`. Les inputs, secrets et valeurs par défaut sont documentés dans leur en-tête.

| Workflow | Inputs clés | Secrets optionnels |
|---|---|---|
| `ci-python.yml` | python-version, paths, coverage-threshold, poetry-version, run-sonar | SONAR_TOKEN |
| `ci-node.yml` | node-version, package-manager, build-command, coverage-threshold, run-sonar | SONAR_TOKEN |

Pinning en production : **par SHA ou tag semver**, jamais `@main`.

## Templates

Chaque template est conçu pour être copié via `curl` ou via le script `bootstrap-new-repo.sh`. Ils encodent les décisions actées du portfolio chrysa :

- Python 3.14 · FastAPI + Pydantic v2 · Poetry
- Node 25 · React 19 · TypeScript · Vite · pnpm
- Docker multi-stage · user non-root · HEALTHCHECK obligatoire
- PostgreSQL 16 · Redis 7
- Coverage cibles : Python 85%, Node 80%
- Conventional Commits + pre-commit hooks SHA-pinned

Voir [docs/USAGE.md](docs/USAGE.md) pour les exemples complets.

## ADRs en cours d'exécution

Trois ADRs actées attendent leur exécution pour finir la consolidation :

- **ADR-0009** — fusion `chrysa/github-actions` → `shared-standards/.github/actions/`
- **ADR-0010** — consolidation `chrysa/pre-commit-hooks-changelog` → `chrysa/pre-commit-tools`
- **ADR-0013** — fusion `chrysa/project-init` → `shared-standards/packages/project-init/`

Plan d'exécution atomique : [docs/MIGRATION-ADR-0009-0010-0013.md](docs/MIGRATION-ADR-0009-0010-0013.md).

## Claude Code hooks

Voir [.claude/HOOKS_README.md](.claude/HOOKS_README.md). Installation rapide dans un repo :

```bash
cp -r path/to/shared-standards/.claude/hooks/ .claude/hooks/
# Merger .claude/settings.json manuellement
```

## Model tagging

Règles et prompts spécifiques à un modèle taggés `@[MODEL_NAME]`. Inventaire :

```bash
node .claude/hooks/model-debt-inventory.cjs --dir .
```

## Local LLM Stack Reference

Ce repo héberge les guidelines de l'écosystème et peut référencer le **Local LLM Stack for Software + Data Engineering** pour les projets qui demandent une infra LLM locale.

📖 [Local LLM Stack (Notion)](https://www.notion.so/Local-LLM-Stack-for-Software-Data-Engineering-34459293e35e81c2b5b0f8283640b338)
