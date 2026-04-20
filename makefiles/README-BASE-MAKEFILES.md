# Base Makefiles · bibliothèque chrysa portfolio

**Source** · extraction des Makefiles génériques depuis `padam-av` (15/04/2026)
**Destination** · `shared-standards/makefiles/base/` (conforme ADR-0013)
**Usage** · réutilisables dans chrysa-lib · dev-nexus · doc-gen · FridgeAI · LifeOS · my-assistant · server · etc.

---

## Classification des 14 makefiles padam-av

| Makefile padam-av | Générique ? | Base chrysa ? | Justification |
|---|---|---|---|
| `functions.Makefile` | ✅ totalement | **OUI · CORE** | log-info · log-error · check-file-exists · helpers Docker généraux |
| `tools.Makefile` | ✅ totalement | **OUI · CORE** | clean · create-folders · opérations système basiques |
| `dependencies.Makefile` | ✅ majoritairement | **OUI** | check-dependencies · install-requirements (adaptable) |
| `docker.Makefile` | ✅ | **OUI** | docker-build · docker-up · docker-down · docker-logs |
| `docs.Makefile` | 🟡 Sphinx-specific | **OUI templatisé** | generate-docs générique, adaptateurs Sphinx OU MkDocs |
| `frontend.Makefile` | 🟡 padam-bus | **OUI simplifié** | run-front · stop-front · pour repos frontend séparés |
| `github.Makefile` | ✅ | **OUI** | pr-merge-conflicts · gh CLI wrappers |
| `quality.Makefile` | ✅ | **OUI** | ruff · mypy · actionlint · bandit · pip-audit |
| `tests.Makefile` | ✅ | **OUI** | pytest wrappers · tests · tests-debug · tests-failfast |
| `variables.Makefile` | 🟡 mix | **OUI partiel** | variables génériques (REQUIRED_SYSTEM_TOOLS) oui · padam-specific non |
| `workflows.Makefile` | ✅ | **OUI** | act install · workflows-lint · GitHub Actions local testing |
| `backoffice.Makefile` | ❌ padam-specific | NON | Wrapper `padam-av-backoffice` |
| `database.Makefile` | 🟡 Django-specific | NON (pattern à documenter) | graph_models · dbshell specific Django |
| `project.Makefile` | ❌ padam-specific | NON | collect-static · create-app Django commands |

**Verdict** · **11 makefiles** génériques à verser dans `shared-standards/makefiles/base/`. 3 laissés dans padam-av exclusivement.

---

## Structure cible `shared-standards/makefiles/base/`

```
shared-standards/makefiles/base/
├── README.md                     # ce fichier
├── functions.Makefile            # helpers + logs (PRÉREQUIS)
├── tools.Makefile                # clean + folders
├── dependencies.Makefile         # check-deps + install
├── variables.Makefile            # variables génériques (REQUIRED_SYSTEM_TOOLS)
├── docker.Makefile               # docker-build/up/down/logs/exec
├── quality.Makefile              # lint + type-check + security
├── tests.Makefile                # pytest wrappers
├── github.Makefile               # gh CLI wrappers
├── workflows.Makefile            # act + local workflow testing
├── docs.Makefile                 # generate-docs (pluggable Sphinx/MkDocs)
└── frontend.Makefile             # run/stop external frontend repo
```

---

## Usage dans un repo chrysa

### Option A · submodule git (recommandé)

```bash
# Dans un repo chrysa
git submodule add https://github.com/chrysa/shared-standards shared-standards
git commit -m "chore: add shared-standards submodule"

# Dans le Makefile racine du repo
include shared-standards/makefiles/base/functions.Makefile
include shared-standards/makefiles/base/tools.Makefile
include shared-standards/makefiles/base/dependencies.Makefile
include shared-standards/makefiles/base/docker.Makefile
include shared-standards/makefiles/base/quality.Makefile
include shared-standards/makefiles/base/tests.Makefile
# ... au besoin
```

### Option B · copie one-shot

Si tu veux éviter le submodule (plus simple mais drift probable) ·

```bash
cp -r shared-standards/makefiles/base/ mon-repo/makefiles/
cd mon-repo/makefiles
# éditer variables.Makefile pour personnaliser le nom projet
```

### Option C · include dynamique (comme padam-av)

```makefile
# Makefile racine
include $(shell find shared-standards/makefiles/base -type f -name "*.[Mm]akefile" -not -path "*/\.*" -exec echo " {}" \;)

# Puis les makefiles spécifiques au repo
include makefiles/backoffice.Makefile  # si applicable
include makefiles/project.Makefile     # si applicable
```

---

## Adaptations requises lors de l'extraction depuis padam-av

Quand tu copies un makefile padam-av vers `shared-standards/makefiles/base/`, purifier ·

### variables.Makefile · ne garder que le générique

À **garder** ·
```makefile
REQUIRED_SYSTEM_TOOLS := git docker pip pre-commit gh
REQUIRED_SYSTEM_TOOLS_APT_PACKAGES := git=git docker=docker.io pip=python3-pip pre-commit=pre-commit gh=gh
BOOTSTRAP_FOLDER ?= /entrypoints/bootstraped
```

À **retirer** (padam-specific) ·
```makefile
BACKOFFICE_BASE_URL ?= http://0.0.0.0:3002
BACKOFFICE_FOLDER ?= ../padam-av-backoffice
```

Remplacer `PADAM_AV_APP_VERSION` par `${PROJECT_NAME}_APP_VERSION` (nom dynamique).

### docs.Makefile · rendre pluggable

Actuellement Sphinx hardcodé. Ajouter condition ·

```makefile
docs: ## Generate documentation
ifeq ($(DOCS_ENGINE),sphinx)
	$(call log-info,generating Sphinx docs)
	# ... (code Sphinx existant)
else ifeq ($(DOCS_ENGINE),mkdocs)
	$(call log-info,generating MkDocs)
	mkdocs build
else
	$(call log-error,DOCS_ENGINE not set - use sphinx or mkdocs)
	exit 1
endif
```

### frontend.Makefile · simplifier

Retirer références spécifiques `FRONT_FOLDER` padam et remplacer par variable configurable ·

```makefile
FRONTEND_REPO_PATH ?= ../$(notdir $(CURDIR))-frontend

run-frontend: ## Start frontend repo
	$(call run_external_repo,Frontend,${FRONTEND_REPO_PATH},${branch_name},up)
```

---

## Repos chrysa cibles (ordre de rollout recommandé)

### Rollout batch 1 · repos qui ont déjà un `makefiles/` directory
- chrysa-lib (déjà 5 makefiles, compléter par les 6 manquants)
- dev-nexus (déjà 5 makefiles, compléter)
- my-fridge → sera FridgeAI
- container-webview
- server
- usefull-containers
- linkendin-resume

### Rollout batch 2 · repos sans makefiles/
- doc-gen
- my-assistant (→ LifeOS)
- ai-aggregator
- D-D
- coach (→ coaching-tracker)
- chrysa-lib

### Rollout batch 3 · optionnels (Opportunistes)
- epub-sorter
- notion-automation
- genealogy-validator
- discord-bot-back
- diy-stream-deck

---

## Décision · repo dédié `base-makefile` vs `shared-standards/makefiles/base/` ?

**Deux options considérées** ·

**A · Repo dédié `chrysa/base-makefile`**
- ✅ Simple à référencer (`git submodule add https://github.com/chrysa/base-makefile`)
- ✅ Scope clair, versioning indépendant
- ❌ Nouveau repo à maintenir, cohérence avec shared-standards à gérer

**B · Sous-dossier `shared-standards/makefiles/base/` (recommandé)**
- ✅ Source de vérité unique (ADR-0013)
- ✅ Versioning cohérent avec CI templates, project-init, guideline-checker
- ✅ Pas de nouveau repo à créer
- ❌ Submodule `shared-standards` plus large qu'un simple base-makefile

**Recommandation · Option B** pour cohérence avec l'architecture chrysa existante.

Si tu préfères un repo dédié (Option A), la décision doit être documentée en ADR (ADR-0036 par exemple).

---

## Status actuel

- ✅ Structure `shared-standards/makefiles/base/` créée (dossier vide, à peupler)
- ✅ README-BASE-MAKEFILES.md (ce fichier) rédigé
- 🟡 Les 11 makefiles à copier depuis padam-av et nettoyer (sous-tâche)
- 🟡 Rollout sur chrysa-lib et dev-nexus (tests de non-régression requis)

## Prochaines étapes recommandées

1. Copier les 11 makefiles depuis `padam-av/makefiles/` vers `shared-standards/makefiles/base/`
2. Nettoyer padam-specific references (variables, paths)
3. Tester l'include dans chrysa-lib (1 repo test)
4. Documenter dans shared-standards/CLAUDE.md les règles d'include
5. Rollout batch 1 (7 repos)
6. Rollout batch 2 (6 repos)
7. Écrire ADR-0036 si repo dédié retenu au lieu du sous-dossier
