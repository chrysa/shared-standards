# `.github/instructions/*.instructions.md` — template chrysa

> Dérivé de padam-av (18 fichiers) et padam-av-backoffice (3 fichiers). À copier dans `<repo>/.github/instructions/` et adapter.

## Principe

Chaque fichier `*.instructions.md` décrit **un domaine technique précis** du repo. Copilot et Claude Code lisent tous ces fichiers au démarrage d'une tâche pour appliquer les patterns corrects.

## Fichiers fournis en template

| Fichier | Portée | Obligatoire pour |
|---|---|---|
| `python_guidelines.instructions.md` | Patterns Python généraux | Tout repo Python |
| `typing.instructions.md` | Type hints, generics, protocols | Tout repo Python |
| `tests.instructions.md` | Pytest, factories, mocking | Tout repo Python |
| `test_performance.instructions.md` | xdist, pytest-benchmark | Tout repo Python |
| `django_models.instructions.md` | Models, managers, migrations | Django repo |
| `django_migrations_review.instructions.md` | Review des migrations | Django repo |
| `drf_performance.instructions.md` | DRF serializers + N+1 | Django+DRF repo |
| `python_django_performance.instructions.md` | Query optim, caching | Django repo |
| `ruff_compliance.instructions.md` | Règles ruff custom | Tout repo Python |
| `makefiles.instructions.md` | Structure Makefile modulaire | Tout repo |
| `secrets_config.instructions.md` | Gestion secrets (sealed, env) | Tout repo |
| `documentation.instructions.md` | Docstrings, README | Tout repo |
| `decorator_optimization.instructions.md` | Decorators perf Python | Tout repo Python |
| `backoffice_context.instructions.md` | Auth, routing, patterns React | Repo frontend React |
| `backoffice_frontend_guidelines.instructions.md` | Components, hooks, testing | Repo frontend React |
| `guidelines_checklist.instructions.md` | Code review checklist | Tout repo |
| `instructions_generation.instructions.md` | Meta : comment écrire une instruction | Tout repo |
| `thresholds.instructions.md` | Seuils numériques (40/300/5/10) | Tout repo |
| `model-tagged.instructions.md` | Règles taggées `@[MODEL_NAME]` | Tout repo |

## Format d'un fichier d'instruction

```markdown
---
applyTo: "**/*.py"    # glob pattern — à quels fichiers cette instruction s'applique
---

# <Titre du domaine>

<!-- @[claude-sonnet-4-6] -->

## Contexte

Bref paragraphe sur le domaine couvert.

## Règles

### Règle 1 : <titre court>

**Obligation / Interdiction**.

Exemple bon :
```python
# ...
```

Exemple mauvais :
```python
# ...
```

## Édition

Modifier ce fichier requiert :
- PR review obligatoire
- Mention dans le CHANGELOG
- Mise à jour de `.github/instructions/README.md` si impact transverse
```

## Convention model-tagging

Certaines règles sont optimisées pour un modèle Claude spécifique. Tag HTML :

```markdown
<!-- @[claude-sonnet-4-6] Règle calibrée pour ce modèle -->
```

Inventaire via `.claude/hooks/model-debt-inventory.cjs`. Quand on change de modèle → réviser les règles taggées.

## Adoption audit

Le scheduled-task `monday-audit-combo` (lundi 09h30) vérifie :

1. `.github/instructions/` existe dans le repo
2. Chaque fichier `.instructions.md` a un frontmatter `applyTo:` valide
3. Les règles taggées `@[MODEL_NAME]` sont à jour vis-à-vis du modèle courant

Si un repo manque les instructions obligatoires → issue `standards-drift` créée.

## Quickstart

Depuis la racine d'un repo chrysa :

```bash
cp -r ~/chrysa/shared-standards/templates/github-instructions/*.instructions.md \
    ./.github/instructions/
cd .github/instructions/
# Adapter chaque fichier au contexte du repo
```

Les fichiers sont des squelettes. L'usage réel copie ceux de padam-av (les plus matures) — voir procedure dans `shared-standards/docs/INSTRUCTIONS-ADOPTION.md`.
