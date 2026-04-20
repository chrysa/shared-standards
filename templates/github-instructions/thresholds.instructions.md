---
applyTo: "**/*"
---

# Seuils numériques chrysa

<!-- @[claude-sonnet-4-6] -->

## Source de vérité

`.claude/config/hooks-config.json` → clé `thresholds`.
Ces valeurs sont synchronisées avec les règles ruff/eslint/pytest/vitest du projet.

## Règles de taille de code

### Python

| Règle | Seuil | Outil |
|---|---|---|
| Lignes par fonction/méthode | **40** | ruff PLR0915 + `wc -l` |
| Lignes par fichier | **300** | ruff E501 |
| Paramètres par fonction | **5** | ruff PLR0913 |
| Complexité cyclomatique | **10** | ruff C901 |
| Warnings lint | **0** | ruff check |
| Erreurs typage | **0** | mypy |

### TypeScript / React

| Règle | Seuil | Outil |
|---|---|---|
| Lignes par fonction/hook | **50** | ESLint + `wc -l` |
| Lignes par composant React | **150** | ESLint |
| Lignes par fichier .ts | **500** | ESLint |
| Paramètres par fonction | **4** | ESLint |
| Complexité cyclomatique | **10** | ESLint |
| Warnings lint | **0** | eslint --max-warnings=0 |
| Erreurs typage | **0** | tsc --noEmit |

## Couverture de tests

| Règle | Python | Node |
|---|---|---|
| Couverture min | **85%** | **80%** |
| Couverture par module modifié | **85%** | **80%** |
| Tests négatifs par API | **≥ 1** | **≥ 1** |
| Docstring coverage | **80%** (interrogate) | N/A |

## Dépendances et architecture

| Règle | Seuil |
|---|---|
| Niveaux d'import indirect | **max 3** (import-linter) |
| Une classe par fichier | **toujours** |
| Méthodes par classe | ≤ 10 publiques |

## Bundles / performance (frontend)

| Règle | Seuil |
|---|---|
| Bundle gzip | **< 500 KB** |
| Lighthouse accessibility | **≥ 90** |
| Lighthouse performance | **≥ 85** (desktop) |
| First Contentful Paint | **< 1.5s** |

## Vérification rapide

```bash
# Python
make ruff-check     # PLR0913, PLR0915, C901, E501
make tests          # pytest + coverage

# Node
make lint           # eslint --max-warnings=0
make type-check     # tsc --noEmit
make test-coverage  # vitest --coverage
```

## Coverage ratchet (automatique)

Si la coverage réelle dépasse le seuil de ≥ 2 points, le hook `coverage-ratchet-hook` (pre-commit-tools v0.2.0+) ouvre automatiquement une issue GitHub par package suggérant le bump.

Config override dans `pyproject.toml` / `package.json` :

```toml
[tool.coverage-ratchet]
margin = 2          # points min pour déclencher
dry-run = false     # true pour tester sans créer d'issue
```

## Édition de ce fichier

Toute modification requiert :

- PR review par owner @chrysa
- Justification dans le CHANGELOG
- Update de `.claude/config/hooks-config.json` (source de vérité)
