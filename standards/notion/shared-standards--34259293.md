---
fka_managed: true
source: notion
notion_id: 34259293-e35e-81e8-bc7f-f2b43e4039fe
notion_url: https://app.notion.com/p/shared-standards-34259293e35e81e8bc7ff2b43e4039fe
notion_last_edited_time: 2026-06-27T16:20:00.000Z
---
# shared-standards

<table_of_contents/>
## But du projet
Référentiel centralisé de conventions, templates CI/CD, workflows GitHub Actions, et outils de standardisation. Source unique de vérité pour tous les repos chrysa.
## Périmètre V1
- Templates CI/CD réutilisables (lint, test, build, deploy)
- Conventions de nommage, structure de repos
- project-init CLI : bootstrapper un nouveau repo avec la config standard (ADR-0013)
- guideline-checker : submodule qui valide la conformité d'un repo
- Labels GitHub standardisés (18 labels)
- Pre-commit config template
## Stack
- Python 3.14 (CLI + scripts)
- GitHub Actions (reusable workflows)
- Shell scripts ([setup-repo.sh](http://setup-repo.sh))
## Architecture
```javascript
shared-standards/
  packages/project-init/     # CLI bootstrapper (ADR-0013)
  templates/                 # CI/CD, pre-commit, .editorconfig
  workflows/                 # Reusable GitHub Actions
  guidelines/                # Conventions écrites
  scripts/                   # guideline-checker
```
## Dépendances
- Amont : aucune
- Aval : tous les repos chrysa utilisent ces standards
## ADRs liés
- ADR-0009 : Fusion github-actions → shared-standards
- ADR-0013 : Fusion project-init → shared-standards/packages/
## Risques
- Trop de standardisation tue l'agilité — garder les templates flexibles
- Maintenance : chaque mise à jour impacte potentiellement 23+ repos
---
## 🎯 Problème · But
Chaque projet chrysa réinventait ses conventions CI/CD, ses linters, ses Makefiles — divergence coûteuse à mesure que l'écosystème grandit.
shared-standards = source de vérité unique pour toutes les conventions chrysa. Tout nouveau repo se bootstrap dessus. Les updates se propagent via reusable workflows.
## 🏗️ Stack
- Python 3.14 — CLI project-init + scripts
- GitHub Actions reusable workflows — lint / test / build / release / docker push
- Shell scripts — setup-repo.sh, labels config
- pre-commit framework — .pre-commit-config.yaml template
- SemVer auto : GitVersion · changelog : git-cliff
## 🗺️ Roadmap
### Now
- [ ] v1.1 — Semantic layer : `guidelines/semantic-code.md` (PR 1, impact max)
- [ ] AI contract : `.ai/coding-rules.md` (PR 2)
- [ ] guideline-checker — règles `semantic/` + `ai-readiness/` (PR 3)
- [ ] yamllint configs à aligner (résidus détectés audit 2026-05-11)
### Next
- [ ] Template `docs/domain-glossary.md` obligatoire (PR 4)
- [ ] Couche `quality/` (pre-commit + CI semantic-quality) avec mode migration report → warn → strict
- [ ] Composite action SonarCloud v2 (rewrite)
- [ ] project-init CLI : finaliser fusion depuis packages/ (ADR-0013)
- [ ] Refonte README/Notion « engineering operating system » (PR 5)
### Later
- [ ] Observability standard : OpenTelemetry composite action
- [ ] Docs mkdocs publiées sur gh-pages
- [ ] Badge `🧠 Semantic Health` par repo
## ✅ Milestones
- Workflows déployés sur 32 repos actifs — 2026-04-30 ✅
- ADR-0009 : fusion github-actions → shared-standards ✅
- ADR-0013 : fusion project-init → shared-standards/packages/ ✅
- v1.0.0 tag stable : prévu prochain sprint
## ⚠️ Risks
<callout icon="⚠️">
	Trop de standardisation tue l'agilité — garder les templates opt-in et flexibles.
</callout>
<callout icon="🔥">
	Toute mise à jour de workflow impacte potentiellement 32+ repos simultanément — casser un workflow = cascade d'échecs CI.
</callout>
## 📘 Décisions
- ADR-0009 : fusion github-actions → shared-standards (convention unique, un seul repo)
- ADR-0013 : fusion project-init → shared-standards/packages/project-init/
- Modèle : reusable workflows GitHub Actions — pas de SDK/lib Python tiers
- **Constantes en YAML externe (2026-06-25)** : aucune constante hard-codée dans le code, ni backend (Python) ni frontend (TS). Seuils, règles métier, labels, URLs et magic numbers vivent dans des YAML externes (`config/`) chargés au runtime via un loader typé (Pydantic Settings côté backend · module `constants.ts` généré côté frontend). Seuls les enums langage (`status.HTTP_*`) sont exemptés. Mergé via PR #151 → release `v1.1.0-129`, propagé à tous les repos `status:dev` (61 PRs de sync). Source de vérité : `standards/STANDARDS.chrysa.md`.
- **Dependabot grouping (2026-06-27)** : tout `.github/dependabot.yml` chrysa DOIT grouper les updates (`groups:` par écosystème) pour réduire le volume de PR — standard = `templates/dependabot.yml` (+ `templates/github-config/dependabot.yml.tpl`). Audit cross-repo : **61/62 repos canoniques conformes** (gap `pre-commit-hooks-changelog` corrigé). Restes : aligner la `.github/dependabot.yml` propre de shared-standards + documenter le grouping dans `EXECUTION_STANDARD.md` + ajouter un check à `audit-standards.sh`. Réf. [ADR-CHRYSA-2026-18](https://app.notion.com/p/38c59293e35e8122bdbdd8c0f686e314).
## 📚 Bibliographie
- GitHub Reusable Workflows : https://docs.github.com/en/actions/sharing-automations/reusing-workflows
- GitVersion : https://gitversion.net
- git-cliff : https://git-cliff.org
## 🖼️ Mockups & Références visuelles
<span color="gray">Outil sans UI graphique — schémas d'architecture si nécessaire.</span>
- Diagramme dépendances : shared-standards → 32 repos (à ajouter Excalidraw)
- Screenshot CI pipeline standard : (à ajouter)
<page url="https://app.notion.com/p/37759293e35e81048e58c0e377f24a1e">Intégration awattar — Slash commands & subagents Claude Code</page>
---
## 🐙 GitHub Overview (clone local · 2026-06-25) — ⚠️ PÉRIMÉ (voir « État repo 2026-06-27 » en bas)
> Lecture git locale, pas de PAT.
- Repo `github.com/chrysa/shared-standards` (SSH) · branche active `chore/container-runtime-policy` (main = 133 commits)
- Dernier commit `42f8faa` 2026-06-22 (« docs skill D-0004 #142 ») · GitVersion `v1.1.0-98`
- `repos.yml` = **65 repos** pilotés (dev/non-dev/archived + runtime policy container/exempt/pending)
- 20 workflows dont `distribute-standards.yml` · `compliance/*.json` (docker/makefile/gitversion/cliff)
- 69 branches · tree sale (`.claude/hookify.*.local.md` + `.vscode/`)
## ⚠️ Écarts Notion ↔ repo (2026-06-25)
- ⚠️ La fiche dit « 32 repos » → `repos.yml` en compte désormais **65** → actualiser
- ℹ️ « guideline-checker (submodule) » = **complément logiciel, jamais un submodule git** → corriger le wording
- ⚠️ Tag **v1.0.0 toujours pas posé** alors que Maturité 4 affichée → poser le tag stable
- ⚠️ 69 branches + travail hors `main` → ménage (`cleanup-local.sh`)
---
## 🧠 Évolution v1.1 — Kernel sémantique (revue 2026-06-26)
> Issu d'une revue de conception (objectif : **code sémantique**). Diagnostic : shared-standards est déjà un *kernel DevOps* (source de vérité multi-repo, propagation, bootstrap, conformité, CI/CD). La prochaine étape n'est pas plus de templates mais une **couche de langage et d'intention** — empêcher 32+ repos de diverger non seulement techniquement mais aussi dans leur vocabulaire et leur modèle métier.
### Principe directeur
Toute règle importante doit exister sous **3 formes** : 📘 Documentation (l'humain comprend) · 🤖 Instruction IA (`.ai/`) · ⚙️ Validation automatique (pre-commit + CI). Une règle qui n'est pas automatisée n'est qu'un vœu.
### Engineering Principles (`guidelines/engineering-principles.md`)
- **Semantic first** — le code exprime l'intention métier.
- **Explicit over implicit** — concepts visibles plutôt que magie cachée (no boolean blindness, objets métier \> primitives).
- **Domain over technology** — la structure des repos suit les concepts métier, pas les couches techniques (`domain/`, `application/`, `infrastructure/`, `interfaces/` plutôt que `services/` fourre-tout).
- **Automation over convention** — si une règle compte, elle est enforced.
### Semantic Code Standard (`guidelines/semantic-code.md`, priorité P0)
Termes génériques interdits sauf justification : `data`, `result`, `item`, `tmp`, `manager`, `processor`, `handler`, `helper`, `utils`, `common`, `misc`.
- **Variables** : nom = rôle métier, pas le type/mécanisme (`activeCustomer`, `invoiceTotal`, `unpaidOrders`).
- **Fonctions** = verbes métier (`registerCustomer`, `approveInvoice`, `cancelSubscription`) plutôt que `save`/`process`/`handle`.
- **Classes** = responsabilité métier (`CustomerRegistration`, `OrderFulfillment`, `PaymentAuthorization`) plutôt que `UserService`/`OrderManager`.
- **No boolean blindness** : args nommés plutôt que `createUser(true, false, true)`.
- **Tests = doc métier** : `describe("when a customer has unpaid invoices")` plutôt que `describe("InvoiceService")`.
- **Fichiers** : pas de `utils.ts`/`helpers.ts` fourre-tout — un dossier exprime un domaine.
### Domain Glossary (`templates/domain-glossary.md`, obligatoire par repo)
Glossaire du vocabulaire métier (ex. Customer ≠ User ≠ Account). Plus gros levier d'alignement humain ↔ IA.
### Contrat AI (`.ai/`)
`context.md` · `coding-rules.md` · `architecture.md`. Règles génération : utiliser le vocabulaire métier, éviter les abstractions génériques, préserver les frontières d'architecture, expliquer les tradeoffs, préférer les workflows explicites.
### Couche `quality/` — gardes-fous automatisés
```javascript
quality/
├── pre-commit/   # semantic-check, yaml-check, markdown-check
├── ci/           # semantic-quality.yml, standards.yml
├── rules/        # semantic.yml, architecture.yml
└── checker/      # semantic-engine
```
- **pre-commit local** : détecter avant le push (hooks `semantic-check`, `standards-check`).
- **CI obligatoire** : workflow `semantic-quality.yml` sur `pull_request` (`make semantic-check`).
- **guideline-checker étendu** — dimensions activables : `repository` · `ci` · `security` · `semantic` · `ai-readiness`. Rôle qui passe de « le repo respecte la structure » à « le repo respecte l'intention chrysa ».
- **Sévérité par règle** (`error`/`warning`/`info`) pour ne pas casser 32 repos : ex. `security.secret_detected: error`, `semantic.generic_class_name: warning`, `semantic.missing_domain_glossary: info`.
- **Mode migration en 3 phases** : `--report` (inventaire des violations) → `--warn` → `--strict`.
- **Config centrale ****`standards.yml`** overridable par repo (`extends: chrysa/default` + `exceptions:`).
### Versioning des standards (`guidelines/versioning.md`)
Politique SemVer explicite : **patch** = correction non disruptive · **minor** = nouvelle règle optionnelle (ex. ajouter un lint) · **major** = breaking change (ex. interdire un pattern existant).
### Propriété « Standard maturity » (par règle)
🟢 Foundation · 🔵 Adopted · 🟣 Enforced · 🟡 Automated. Ex. CI/CD 🟣 Enforced · Semantic naming 🟢 Foundation · Domain glossary cible 🟡 Automated.
### Ordre de PR recommandé
1. `guidelines/semantic-code.md` (impact max) · 2. `.ai/coding-rules.md` · 3. `guideline-checker/rules/semantic/` · 4. `docs/domain-glossary.md` (template) · 5. refonte README/Notion.
*MAJ 2026-06-26 — intégration revue « standards de dev » : couche sémantique + quality-gates, correction roadmap (v1.0.0 déjà taggé, v1.1.x en cours), nouvelle description.*
---
## 🐙 État repo 2026-06-27
> Re-scan git local. `main` inchangé depuis le 22/06 ; gros ménage de branches.
- **Branche active** : `chore/container-runtime-policy` · `main` = **133 commits** · dernier `42f8faa` 2026-06-22 · GitVersion **`v1.1.0-131`** (vs `-98` le 25/06)
- **Hygiène** : **25 branches** (vs **69** → ménage ✅) · 4 fichiers dirty
### Écarts restants
- ⚠️ **Tag stable ****`v1.0.0`**** toujours pas posé** alors que Maturité 4 affichée → à poser.
- ⚠️ Feature branch `chore/container-runtime-policy` non mergée.
- ✅ `.env` couvert par `.gitignore`.
<page url="https://app.notion.com/p/38c59293e35e8144aa05ddb666ce9bb2">Vérif distribution + deep-gaps + graphify rollout + sync — session 2026-06-27</page>
