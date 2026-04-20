# Hooks locaux chrysa

Deux hooks pour usage local et/ou intégration pre-commit / CI.

---

## 1 · `validate-prompt.py` — validation de prompts Claude

Critères dérivés de [plume-ecriture.fr/…/prompt-engineering-claude-debutants-tpe-pme](https://plume-ecriture.fr/langue-francaise-et-orthographe/prompt-engineering-claude-debutants-tpe-pme/) + conventions chrysa (FR+EN, roles).

### Checks effectués (10 au total)

| Check          | Poids | Critère                                                               |
| -------------- | ----- | --------------------------------------------------------------------- |
| longueur       | 2     | 10 ≤ mots ≤ 2000                                                      |
| rôle           | 2     | "Tu es" / "Vous êtes" / "You are" / "Act as"                          |
| contexte       | 2     | "Je suis/dirige/…" / "My goal/context"                                |
| objectif       | 1     | "Objectif:" / "Je veux" / "I want"                                    |
| structure      | 1     | bullets/numérotation/headers markdown/tags XML                        |
| ton/style      | 1     | "Ton:" / "Style:" / mots-clés registre (chaleureux/professionnel/…)   |
| exemples       | 1     | "Exemples:" / "Voici un exemple" / code fences                        |
| contraintes    | 1     | "max/min N mots" / "Évite/N'utilise pas" / interdictions              |
| format         | 1     | "Format:" / mention explicite (json/yaml/md/…)                        |
| anti-patterns  | 2     | mono-ligne générique · décharge de responsabilité · demande à deviner |

**Score** : 0-10 pondéré · verdict EXCELLENT (≥8) · ACCEPTABLE (≥6) · INSUFFISANT (≥4) · MAUVAIS

### Usage

```bash
# Fichier
validate-prompt.py path/to/prompt.md

# Stdin
cat prompt.txt | validate-prompt.py -

# Seuil strict (exit 1 si < 8)
validate-prompt.py --min-score 8 prompt.md

# JSON pour CI
validate-prompt.py --format=json prompt.md

# Mode pre-commit (valide tous les .prompt.md stagés)
validate-prompt.py --pre-commit
```

### Intégration pre-commit (`.pre-commit-config.yaml`)

```yaml
repos:
  - repo: local
    hooks:
      - id: validate-prompt
        name: Validate Claude prompts (plume-ecriture criteria)
        entry: python3 shared-standards/scripts/validate-prompt.py --pre-commit --min-score 6
        language: system
        pass_filenames: false
        files: '(^|/)(prompts?/.*\.md$|.*\.prompt\.md$)'
        stages: [pre-commit]
```

---

## 2 · `dev-run.sh` — runner unifié app/test/lint/quality

Détecte automatiquement le stack (Python / Node / Go / Rust / Django / Docker / Makefile) et lance la commande appropriée.

### Ordre de priorité

1. **Makefile** — si cible existe (`make tests`, `make lint`, `make quality`, `make dev`, `make run`, `make ci`)
2. **Stack natif** — fallback `ruff` + `mypy` + `pytest` (Python) / `npm run lint` + `tsc` + `npm test` (Node) / `cargo clippy` + `cargo test` (Rust) / `go vet` + `go test` (Go)
3. **Docker** — si `--docker` forcé ou si seul Dockerfile présent

### Actions

| Action      | Description                                     |
| ----------- | ----------------------------------------------- |
| `app`       | dev server / run                                |
| `test`      | lance les tests                                 |
| `lint`      | lint                                            |
| `format`    | auto-format (use `--fix` pour auto-correction)  |
| `typecheck` | vérification types (mypy/tsc/cargo check/…)     |
| `quality`   | lint + typecheck (composite)                    |
| `all`       | quality + test (composite, pas app)             |
| `ci`        | si Makefile a cible `ci`                        |

### Usage

```bash
cd my-repo

# Menu interactif (si TTY)
dev-run.sh

# Liste les commandes détectées sans rien lancer
dev-run.sh --list

# Action directe
dev-run.sh test
dev-run.sh lint --fix
dev-run.sh quality
dev-run.sh all

# Force l'exécution via docker compose
dev-run.sh test --docker

# Mode verbose (affiche les commandes)
dev-run.sh all --verbose
```

### Intégration pre-commit (`.pre-commit-config.yaml`)

```yaml
repos:
  - repo: local
    hooks:
      - id: dev-run-quality
        name: Quality check (lint + typecheck)
        entry: bash shared-standards/scripts/dev-run.sh quality
        language: system
        pass_filenames: false
        stages: [pre-commit]
        always_run: true

      - id: dev-run-test
        name: Tests
        entry: bash shared-standards/scripts/dev-run.sh test
        language: system
        pass_filenames: false
        stages: [pre-push]
        always_run: true
```

### Alias shell recommandés

Dans `~/.zshrc` ou `~/.bashrc` :

```bash
alias r="bash $CHRYSA_ROOT/shared-standards/scripts/dev-run.sh"
alias rq="r quality"
alias rt="r test"
alias ra="r all"
```

---

## 3 · Bonus : gitignore global chrysa

Fichier pollueur constaté (Cowork runtime) à gitignorer dans tous les repos :

```gitignore
# Cowork runtime state
.claude/settings.local.json

# pytest cache, ruff cache, venv
.pytest_cache/
.ruff_cache/
.mypy_cache/
.venv/
venv/

# macOS / editor
.DS_Store
*.swp
.idea/
.vscode/settings.json
```

À ajouter soit :
- par repo (dans `.gitignore`)
- globalement : `git config --global core.excludesfile ~/.gitignore_global`
