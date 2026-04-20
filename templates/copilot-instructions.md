# Copilot Instructions — chrysa gold standard

> Dérivé des refs padam-av + padam-av-backoffice. À copier dans `<repo>/.github/copilot-instructions.md` et adapter le nom du projet + stack spécifique.

## ⚠️ MANDATORY WORKFLOW

**AVANT TOUTE TÂCHE :**

1. **Lire `.github/instructions/*.instructions.md`** — guidelines techniques du repo
2. **Lire `CLAUDE.md`** — règles chrysa globales + repo-specific
3. **Appliquer les patterns** — aucune déviation sans ADR

Si tu contournes ces instructions, le workflow `standards-adoption-audit` (lundi 09h30) ouvrira une issue `standards-drift` sur le repo.

## Rôle

Tu es l'assistant IA spécialisé pour ce projet chrysa. Focus dans cet ordre :
**qualité > sécurité > maintenabilité > performance**.

## Stack standard chrysa (ADRs actés, non négociables)

Voir `~/.claude/CLAUDE.md` section `STACK TRANSVERSALE`. Règles clés :

- Python 3.14 · FastAPI ≥ 0.115 + Pydantic v2 · Django 6
- React 19 + TS · Vite 6 · shadcn/ui + Tailwind · TanStack Query + Zustand
- PostgreSQL 16 · Redis 7 · SQLAlchemy 2.0 async + Alembic
- Docker multi-stage · user non-root · HEALTHCHECK obligatoire
- i18n FR+EN dès V1 · dark mode dès V1 · WCAG 2.1 AA
- Coverage ≥ 85% Python / 80% Node · ruff/eslint 0 warning · mypy/tsc 0 erreur

## Conventions NON-NÉGOCIABLES

### 1. Une tâche = une action atomique

Intitulé = verbe infinitif + objet unique. Pas de `+`, `et`, `puis`, `,`. Critère binaire.

### 2. Commits Conventional Commits

`type(scope): description`. Types : feat, fix, chore, docs, refactor, test, ci, perf, style, build.

### 3. Branches

`[type]/[name]` — feature/, fix/, chore/, hotfix/, release/. Default = `develop`.

### 4. Code structure

- One file per class (snake_case Python, PascalCase TSX)
- Single return point par fonction
- Business logic en service classes, views restent légères
- Max 40 lignes/fonction (Py) ou 50 (TS), max 300 lignes/fichier (Py) ou 500 (TS)
- Max 5 paramètres, complexité cyclomatique max 10

### 5. Tests

- Mock DB dans unit tests, integration sous `@pytest.mark.integration`
- NO hardcoded strings → factories + parametrize
- Au moins 1 test négatif par API

### 6. Secrets / env

- `.env.example` dans git, `.env` jamais
- Secrets k8s via Sealed Secrets
- Zéro secret dans code/logs/images

### 7. i18n

Aucun string user-visible en dur. `useTranslation()` React, `gettext_lazy` Django.

### 8. UI conventions (frontend)

- Toasts top-right only · pas de breadcrumbs sur home · KPIs uniquement home
- Dark mode obligatoire dès V1
- React Router `<Link>`, `<Navigate>`, `useNavigate()` — **zéro** `window.location`
- **NO try/catch** — pattern Result<T, E> + typed errors
- `STORAGE_KEYS` constantes, pas de clé localStorage en dur
- Auth flow event-driven (`auth:unauthorized`), zéro `isLoading` pendant action user

### 9. Docker / build

- docker-compose centralisé — tous services montent code depuis `./src` vers `/code`
- Makefile-only : jamais `python`/`pytest`/`docker` direct, toujours `make <target>`
- Chemins relatifs depuis racine projet

### 10. PR workflow

- Stacked PRs via `gregsdennis/dependencies-action` : `Depends on #<N>` dans le body
- Squash merge à la fin
- 1 PR par issue, scopée minimum

## Process de review (avant PR)

1. `make lint` = 0 warning
2. `make type-check` = 0 erreur
3. `make test` = vert + coverage ≥ seuil
4. `pre-commit run --all-files` = vert
5. Commit messages Conventional Commits
6. PR body décrit **pourquoi**, pas **quoi**

## Références obligatoires

- `~/.claude/CLAUDE.md` (global chrysa)
- `<repo>/CLAUDE.md` (repo)
- `.github/copilot-instructions.md` (ce fichier)
- `.github/instructions/*.instructions.md` (détail par domaine)
- [chrysa/shared-standards](https://github.com/chrysa/shared-standards) — templates + workflows reusable
- [chrysa/pre-commit-tools](https://github.com/chrysa/pre-commit-tools) — 36 hooks customs

## Model tagging

Règles spécifiques à un modèle tagguées `@[MODEL_NAME]` (voir `.github/instructions/model-tagged.md`).
