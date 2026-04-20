# CLAUDE.md — {{REPO_NAME}}

> @[claude-sonnet-4-6]

## Project

**Name** : {{REPO_NAME}}
**Stack** : {{STACK}}
**Purpose** : {{ONE_LINE_PURPOSE}}
**Rôle** : {{Socle | Actif | Opportuniste | Gelé}}

## Conventions + Standards

Conventions transverses (git, décisions, code style, coverage, portefeuille…) :
→ **`shared-standards/docs/CONVENTIONS.md`** (source de vérité unique)

Ce repo applique toutes ces règles par défaut. Déviations locales documentées
dans `DECISIONS.md` (format D-XXXX).

## Setup

```bash
make install
make dev
make tests
make quality
```

## CI

GitHub Actions `.github/workflows/ci.yml` · SonarCloud · GitVersion (tag `prd-*`)
Pre-commit 5+ hooks minimum (voir `.pre-commit-config.yaml`)

## Structure

```
{{ARBORESCENCE_HAUT_NIVEAU}}
```

## Repository-specific rules

- {{RÈGLE_SPÉCIFIQUE_1}}
- {{RÈGLE_SPÉCIFIQUE_2}}

## Compact instructions

When compacting, always preserve :
1. List of all files modified this session
2. Current task description and next steps
3. Any uncommitted / unpushed changes
4. Open blockers and errors not yet resolved

## Liens

- Décisions locales : `DECISIONS.md`
- Roadmap : `ROADMAP.md`
- Conventions globales : `~/.claude/CLAUDE.md`
