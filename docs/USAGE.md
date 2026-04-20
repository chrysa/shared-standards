# Comment appeler les standards chrysa depuis un autre projet

Référentiel pour tout repo chrysa qui veut consommer `shared-standards` sans
copier-coller. Deux modes : **bootstrap one-shot** pour un nouveau repo,
**intégration continue** pour un repo existant.

---

## Mode 1 — Bootstrap d'un nouveau repo (one-shot)

```bash
# Depuis un repo vide / fraîchement cloné
curl -sSL https://raw.githubusercontent.com/chrysa/shared-standards/main/scripts/bootstrap-new-repo.sh \
  | bash -s -- --type python --name dev-nexus --apply
```

Options :

- `--type python|node|mixed` (obligatoire)
- `--name <slug>` (obligatoire — utilisé dans Dockerfile labels, compose, etc.)
- `--apply` pour modifier les fichiers (sinon dry-run)
- `--standards <path>` pour pointer sur un checkout local au lieu de GitHub

Le script dépose :

- `Dockerfile` (Python ou Node selon `--type`)
- `docker-compose.yml` + `.env.example`
- `Makefile` + `makefiles/{install,quality,docker}.makefile`
- `.gitignore` adapté au type
- `.pre-commit-config.yaml` callant `chrysa/pre-commit-tools`
- `.github/workflows/ci.yml` callant les workflows `workflow_call` de `shared-standards`
- `.github/copilot-instructions.md`, `.github/pull_request_template.md`, `CODEOWNERS`

---

## Mode 2 — Intégration dans un repo existant

### 2.1 — Appeler le CI reusable (Python)

Crée `.github/workflows/ci.yml` dans ton repo :

```yaml
name: CI
on:
  pull_request:
  push:
    branches: [main, develop]

jobs:
  ci:
    uses: chrysa/shared-standards/.github/workflows/ci-python.yml@main
    with:
      python-version: "3.14"
      paths: "src/ tests/"
      coverage-threshold: 85
    secrets:
      SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
```

### 2.2 — Appeler le CI reusable (Node)

```yaml
name: CI
on:
  pull_request:
  push:
    branches: [main, develop]

jobs:
  ci:
    uses: chrysa/shared-standards/.github/workflows/ci-node.yml@main
    with:
      node-version: "25"
      package-manager: pnpm
      build-command: "pnpm build"
      coverage-threshold: 80
    secrets:
      SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
```

### 2.3 — Appeler les composite actions individuellement

Une fois ADR-0009 exécutée, les actions vivent sous `chrysa/shared-standards/.github/actions/`:

```yaml
- uses: chrysa/shared-standards/.github/actions/ruff-check@main
- uses: chrysa/shared-standards/.github/actions/mypy-check@main
- uses: chrysa/shared-standards/.github/actions/sonar-scan-python@main
```

### 2.4 — Ajouter les pre-commit hooks chrysa

Dans ton `.pre-commit-config.yaml`, ajoute :

```yaml
repos:
  - repo: https://github.com/chrysa/pre-commit-tools
    rev: v1.0.0
    hooks:
      - id: secret-scanner-enhanced
      - id: dockerfile-security-baseline
      - id: makefile-target-validator
      - id: sonar-project-detector
      - id: python-version-pin-checker
```

### 2.5 — Appliquer les templates isolément

Sans tout le bootstrap — exemple : juste récupérer le Dockerfile Python :

```bash
curl -sSL -o Dockerfile \
  https://raw.githubusercontent.com/chrysa/shared-standards/main/templates/dockerfile/Dockerfile.python
```

Ou tout `templates/` en mode browse :

```bash
git clone --depth 1 https://github.com/chrysa/shared-standards /tmp/std
cp /tmp/std/templates/compose/docker-compose.yml .
```

---

## Pinning — ne pas utiliser `@main` en prod

`@main` est pratique en dev. En prod, pinner par **tag semver** ou **SHA** :

```yaml
uses: chrysa/shared-standards/.github/workflows/ci-python.yml@v1.2.0
# ou
uses: chrysa/shared-standards/.github/workflows/ci-python.yml@a1b2c3d
```

Dependabot peut bump ça automatiquement. Extrait de `dependabot.yml` pour ton repo :

```yaml
version: 2
updates:
  - package-ecosystem: github-actions
    directory: /
    schedule:
      interval: weekly
```

---

## Overrides locaux

Tu peux override les valeurs par défaut du CI reusable en passant des inputs.
Exemple : augmenter le seuil de coverage sur ton repo critique :

```yaml
jobs:
  ci:
    uses: chrysa/shared-standards/.github/workflows/ci-python.yml@v1
    with:
      coverage-threshold: 95   # > seuil par défaut 85
```

Si tu as besoin d'une étape absente du workflow reusable : ajoute un
**second job** dans ton ci.yml qui s'enchaîne après.

---

## Incident : un standard te bloque

Si un standard chrysa fait capoter ton build sans que ton code soit en cause :

1. Ouvre une issue sur `chrysa/shared-standards` avec label `incident-standard`
2. En attendant le fix, pinne sur une version précédente (`@v1.1.0`) dans ton repo
3. Documente le workaround dans ton CHANGELOG.md

Ne jamais copier-paster le workflow dans ton repo pour le "fixer" — ça casse
la standardisation.

---

## Contrats de version

- `v1.*` → workflows reusable Python + Node, templates Dockerfile multi-stage, composite actions héritées de chrysa/github-actions
- `v2.*` (planifié) → project-init en packages/ (ADR-0013) + template mixed Python+Node
- `v3.*` (évaluer après adoption) → support Rust et Go

Le CHANGELOG de shared-standards liste les breaking changes.
