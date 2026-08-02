# shared-standards · spec v1 · 2026-05-04

> Source de vérité conventions · templates · workflows CI/CD pour tous les repos chrysa.
> Pattern : 0 dépendance amont · consommé par tous les autres repos chrysa.

## 1. Vue

`chrysa/shared-standards` est le repo central qui héberge les conventions partagées :
- Templates CI/CD (GitHub Actions workflows)
- Pre-commit hooks config
- Templates LICENSE / CODE_OF_CONDUCT / CONTRIBUTING / SECURITY / PUBLISH-CHECKLIST
- `project-init` CLI (bootstrap nouveau repo conforme)
- `chrysa-bootstrap-machine.sh` (orchestrateur 4 repos workstation · ADR-revert 2026-05-04)
- `guideline-checker` submodule (audit conformité repos existants)
- Conventional Commits config + commitlint
- Référence GitVersion config

Visibilité : 🌍 PUBLIC (Tier 1 · ADR repos private-by-default 2026-05-04).

## 2. Stack

- Bash + Python 3.14 (pour CLIs : project-init · chrysa-bootstrap-machine · guideline-checker)
- YAML (workflows GitHub Actions)
- Markdown (templates docs)
- TOML (pyproject configs templates)
- Pas de runtime serveur · pas de DB

## 3. Repo

`https://github.com/chrysa/shared-standards`
- Branche par défaut : `main`
- Squash merge · push force interdit · 1 PR par issue · ref `Closes/Fixes #N`
- Pre-commit obligatoire (sur lui-même)
- LICENSE : MIT
- CI : self-test (les templates générés passent les checks qu'ils définissent)

## 4. Données

Aucune persistance. Repo = artefacts statiques.

Conventions data partagées documentées :
- Naming DBs PostgreSQL (snake_case · pluriel)
- Naming Redis keys (`<service>:<entity>:<id>`)
- ULID > UUID v4 par défaut

## 5. Communication

- README.md complet à la racine
- `docs/` dossier hiérarchisé (templates · workflows · cli · conventions)
- Issues GitHub pour discussions
- Discussions GitHub pour propositions

## 6. Intégrations

Consommé par TOUS les repos chrysa via :
- Submodule `guideline-checker` (lint conformité)
- Workflows réutilisables (`uses: chrysa/shared-standards/.github/workflows/<name>@main`)
- `project-init` CLI installé via `pipx`/`uv` (bootstrap projet)

## 7. Infra

- Hosting : GitHub
- CI : GitHub Actions (sur `main` + PR)
- Releases : GitHub Releases (semver via GitVersion · auto-tagged)
- Docs : GitHub Pages OR Notion mirror

## 8. ADR (à créer dans repo `shared-standards/DECISIONS.md`)

D-0001 · Repo source vérité conventions chrysa
D-0002 · Workflows GitHub Actions réutilisables (vs templates copy-paste)
D-0003 · `project-init` CLI Python (vs Bash · vs Node)
D-0004 · Pre-commit obligatoire sur tous les repos consommateurs
D-0005 · LICENSE MIT par défaut Tier 1+2
D-0006 · GitVersion + Conventional Commits + commitlint
D-0007 · `chrysa-bootstrap-machine.sh` orchestrateur 4 repos workstation
D-0008 · `guideline-checker` submodule (audit conformité repos)

## 9. Hors-scope

- Pas de logique applicative
- Pas de templates frontend/backend complets (seulement skeletons via project-init)
- Pas de monitoring (Sentry/Uptime Kuma = ailleurs)
- Pas de gestion auth (chrysa-lib-py/ts gèrent ça)
- Pas de docs spécifiques projet (chaque repo a son propre README/CLAUDE.md)

---

## ✅ Décisions tranchées (DECISIONS.md à créer dans repo)

- LICENSE par défaut = MIT (sauf Tier 3 commercial · Tier 4 perso = pas de LICENSE)
- Pre-commit hooks obligatoires : detect-secrets · ruff · mypy · commitlint · markdownlint
- Conventional Commits strict (commitlint level error)
- Coverage minimum templates : ≥85% (jamais <80%)
- SonarCloud A obligatoire pour repos Tier 1+2

## 🟠 Décisions ouvertes / à trancher

- [ ] `project-init` CLI : utiliser `cookiecutter` ou écrire from scratch ?
- [ ] Migration `workstation-os` setup vers `chrysa-bootstrap-machine.sh` (script seulement OU + tests Pester)
- [ ] Versioning workflows GitHub Actions : tags semver vs branche `main` floating

## 📋 État des lieux

- Repo existe ? À vérifier sur GitHub `chrysa/shared-standards`
- Si oui : audit conformité actuelle vs spec v1
- Si non : bootstrap via `project-init` self-hosted (chicken-and-egg → première version manuelle)

## 🎫 Ticket #1 (à créer GitHub)

```
title: feat: bootstrap shared-standards v1 (templates + project-init CLI + chrysa-bootstrap-machine)
labels: feat · P0
description:
- [ ] Init repo si pas existant
- [ ] LICENSE MIT
- [ ] README.md complet
- [ ] Templates dans `templates/` : pre-commit-config.yaml · .gitignore.global · LICENSE-MIT.md · CONTRIBUTING.md · CODE_OF_CONDUCT.md · SECURITY.md · PUBLISH-CHECKLIST.md
- [ ] Workflows réutilisables `.github/workflows/`: ci-python-test.yml · ci-typescript-test.yml · sonar-scan.yml · release.yml
- [ ] CLI `project-init/` (Python · pipx-installable)
- [ ] Script `chrysa-bootstrap-machine.sh`
- [ ] DECISIONS.md avec D-0001 à D-0008
- [ ] guideline-checker en sous-module
```

## 🚀 Action items

- [ ] Bootstrap repo (manuel · ou via project-init quand dispo)
- [ ] Aligner CLAUDE.md projet (`shared-standards/CLAUDE.md`) avec cette spec
- [ ] Issue #1 créée → 1 PR par section template
- [ ] Tester le bootstrap sur un repo cobaye (chrysa-lib-py probable)
