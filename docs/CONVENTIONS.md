# Conventions chrysa — source de vérité unique

> Référencée depuis tous les templates. Les autres docs ne DUPLIQUENT pas ces règles,
> elles pointent vers celui-ci : "Conventions transverses → shared-standards/docs/CONVENTIONS.md".

---

## Git

- **Commits** : [Conventional Commits](https://www.conventionalcommits.org/) — `feat`, `fix`, `chore`, `docs`, `refactor`, `test`, `ci`, `perf`
- **Branches** : `feature/`, `fix/`, `chore/`, `hotfix/`, `release/`
- **Default branch** : `develop` (ou `main` pour repos simples sans flow)
- **Merge** : squash merge obligatoire
- **Push** : push force interdit
- **PR → Issue** : toute PR doit référencer une issue (`Closes #N` / `Fixes #N` / `Refs #N`) — exception `label: hotfix`
- **Scope** : 1 PR par issue, scopée au max
- **Auto-merge** : activé pour PRs Dependabot patch+minor avec tests verts

## Décisions (D-XXXX)

- Numérotation **locale à chaque repo** (pas globale)
- Fichier : `<repo>/DECISIONS.md`
- **Jamais supprimer** → marquer `SUPERSEDED par D-YYYY`
- Format : `## D-XXXX — Titre` + `**Date**` + `**État**` + `**Contexte**` + `**Décision**` + `**Conséquences**`
- Voir template : `shared-standards/templates/docs/DECISIONS.template.md`

## Standards code

| Critère | Python | TypeScript |
|---------|--------|------------|
| Max fonction | 40 lignes | 50 lignes |
| Max fichier | 300 lignes | 500 lignes |
| Max args | 5 | 4 |
| Complexité cyclomatique | 10 | 10 |
| Lint warnings | 0 (ruff) | 0 (eslint) |
| Type checker | mypy (0 erreur) | tsc (0 erreur) |
| Coverage | ≥ 85% | ≥ 85% |
| Docstring coverage | 80% | — |

## Qualité

- Pre-commit obligatoire : ruff/prettier + mypy/tsc + detect-secrets + gitleaks + commitlint
- CI bloquante sur `develop` et `main`/`master`
- SonarCloud : rating A, 0 hotspot
- Coverage report dans chaque PR

## Règles portefeuille

- **Règle 1+2** : max 1 Socle actif + 2 Actifs simultanés
- **Rôles** : Socle · Actif · Opportuniste · Gelé · Vision
- Nouveau projet → page Notion DB Projets + repo + ROADMAP + DECISIONS + PRD (si Actif)

## Hygiène workspace

- `.claude/settings.local.json` toujours gitignoré
- Pas de fichier session daté à la racine (`YYYY-MM-DD-*.md`) → `_session_archive/YYYY-MM-DD/`
- Pas de secret commité (detect-secrets + gitleaks actifs)

## Templates — référencer, pas copier

Les templates `README`, `CLAUDE`, `DECISIONS`, `ROADMAP`, `ARCHITECTURE`, `PRD`
N'AURONT PAS de duplication des règles ci-dessus. Ils disent simplement :

> Conventions transverses : voir `shared-standards/docs/CONVENTIONS.md`

Cela évite les dérives quand une règle évolue ici.

## Quand on ajoute une règle

1. Éditer ce fichier
2. Si ça touche le code → patcher les templates pre-commit / ci / makefile concernés
3. Si ça touche les PR → patcher `pr-template.md` et `enforce-issue-link.yml`
4. Notifier via commit message explicite : `chore: add convention XXX (#issue)`
