---
fka_managed: true
source: notion
notion_id: 36759293-e35e-8158-ac04-dae725f2fb58
notion_url: https://app.notion.com/p/shared-standards-36759293e35e8158ac04dae725f2fb58
notion_last_edited_time: 2026-08-03T21:10:00.000Z
---
# shared-standards

<table_of_contents/>
> 📏 **shared-standards** · Source de vérité des conventions, profils, templates CI/CD et contrôles partagés Chrysa. Les projets consommateurs, dont `project-init` et `guideline-checker`, restent autonomes et utilisent des artefacts versionnés. Licence MIT.
## 🎯 Problème résolu
Chaque projet chrysa réinventait ses conventions CI/CD, ses linters, ses Makefiles — divergence coûteuse à mesure que l'écosystème grandit. shared-standards = source de vérité unique pour toutes les conventions chrysa. Tout nouveau repo se bootstrap dessus. Les updates se propagent par **file-sync (copie)** : `repo-file-sync-action` pousse les fichiers standards dans chaque repo via PR auto — cohérent avec la règle « les configs vivent DANS chaque projet » (plug'n'play). Remplace le modèle reusable-workflows (référence centrale) acté 2026-06-14.
## ✨ Features V1
- [x] Templates standards (lint / test / build / release / docker push / k3s)
- [x] Propagation par file-sync (copie) — `repo-file-sync-action`, PR auto par repo
- [x] Templates CI/CD + pre-commit + .editorconfig
- [x] 18 labels GitHub standardisés
- [x] guideline-checker (validation conformité repo)
- [x] Déploiement sur 32 repos actifs
- [x] Tag v1.0.0 stable
- [ ] yamllint configs alignées
## 📦 Périmètre
- Templates CI/CD réutilisables (lint, test, build, deploy)
- Conventions de nommage, structure de repos
- project-init CLI : bootstrapper un nouveau repo avec la config standard (ADR-0013)
- guideline-checker : submodule qui valide la conformité d'un repo
- Labels GitHub standardisés (18 labels)
- Pre-commit config template
## 🧱 Stack
- Python 3.14 — CLI project-init + scripts
- GitHub Actions reusable workflows — lint / test / build / release / docker push
- Shell scripts — [setup-repo.sh](http://setup-repo.sh), labels config
- pre-commit framework — .pre-commit-config.yaml template
- SemVer auto : GitVersion · changelog : git-cliff
## 🏗️ Architecture
```javascript
shared-standards/
  packages/project-init/     # CLI bootstrapper (ADR-0013)
  templates/                 # CI/CD, pre-commit, .editorconfig
  workflows/                 # Reusable GitHub Actions
  guidelines/                # Conventions écrites
  scripts/                   # guideline-checker
```
## 🔗 Dépendances
- **Amont** : aucune
- **Aval** : tous les repos chrysa utilisent ces standards (32 repos actifs)
## 🗺️ Roadmap
### Now
- [ ] **Bascule propagation → file-sync (****`repo-file-sync-action`****)** : mécanisme unique de diffusion des standards (remplace reusable workflows) — acté 2026-06-14
- [ ] `sync.yml` segmenté par groupes (Socle / Actif / Opportuniste, déployé-k3s vs non, landing Pages universelle)
- [ ] Script Notion→`sync.yml` : génère les listes de repos depuis la DB canonique (`4aa91584-...`) via les propriétés projet
- [x] Tag v1.0.0 stable — déployé sur 32 repos ✅
- [ ] yamllint configs à aligner (résidus détectés)
### Next
- [ ] PAT `SYNC_PAT` + secret org pour le push cross-repo
- [ ] Publier un profil de standards versionné consommable par `project-init` et les générateurs autonomes, avec compatibilité, fraîcheur et tests de contrat visibles.
### Later
- [ ] Observability standard : OpenTelemetry composite action
- [ ] Docs mkdocs publiées sur gh-pages
## ✅ Milestones atteints
- Workflows déployés sur 32 repos actifs — 2026-04-30 ✅
- ADR-0009 : fusion github-actions → shared-standards ✅
- ADR-0013 : ancienne option de fusion de `project-init` — **supersédée le 29 juillet 2026** par la décision d’autonomie définitive ; historique conservé.
- v1.0.0 tag stable : publié ✅ (+ série v1.1.0-NNN)
- **Sonar fleet fix — 2026-06-22** : [PR #137](https://github.com/chrysa/shared-standards/pull/137) (sources fix) + [PR #138](https://github.com/chrysa/shared-standards/pull/138) (REPO_NAME substitution) merged. **36/36 dev repos correct project-key on ****`main`**. Durably fixes the unsubstituted `chrysa_target` / `sources: .` Sonar template defaults that were generating false reds fleet-wide. \~31 regressing "sync chrysa shared standards" PRs closed (re-introduced the stale template; main already correct + newer).
## ⚠️ Risques
<callout icon="⚠️">
	Trop de standardisation tue l'agilité — garder les templates opt-in et flexibles.
</callout>
<callout icon="🔥">
	Toute mise à jour de workflow impacte potentiellement 32+ repos simultanément — casser un workflow = cascade d'échecs CI.
</callout>
## 📘 Décisions
- ADR-0009 : fusion github-actions → shared-standards (convention unique, un seul repo)
- Décision du 29 juillet 2026 : `project-init` reste un projet autonome et implémente les standards publiés par `shared-standards` via un contrat versionné.
- Modèle : reusable workflows GitHub Actions — pas de SDK/lib Python tiers
## 📚 Références
- GitHub Reusable Workflows : [https://docs.github.com/en/actions/sharing-automations/reusing-workflows](https://docs.github.com/en/actions/sharing-automations/reusing-workflows)
- GitVersion : [https://gitversion.net](https://gitversion.net)
- git-cliff : [https://git-cliff.org](https://git-cliff.org)
<page url="https://app.notion.com/p/36859293e35e81feb63ff4a487a28ed3">Études — shared-standards</page>
<page url="https://app.notion.com/p/36859293e35e8161bb7fefa2a590710a">📈 Suivi — shared-standards</page>
<page url="https://app.notion.com/p/33a59293e35e8196bb37e8f5dd4050d6">📐 shared-standards — Standards & Guidelines écosystème chrysa</page>
<page url="https://app.notion.com/p/36f59293e35e8168a5b1ed0d716a6c30">📐 guideline-checker — Référentiel de règles multi-dimensions (models / languages)</page>
## 🐙 GitHub Overview (clone local · 2026-06-25)
> Source : clone local `shared-standards` (lecture git, pas de PAT).
- **Repo** : [github.com/chrysa/shared-standards](http://github.com/chrysa/shared-standards) · branche `chore/container-runtime-policy` (⚠️ pas `main`)
- **Activité** : 133 commits · dernier `42f8faa` 2026-06-22 (« docs(skill): document D-0004 private-distribution fetch (BuildKit secret) #142 ») · tags **v1.0.0** + série **v1.1.0-NNN** (jusqu'à -128)
- **Tests** : 1 fichier · [DECISIONS.md](http://DECISIONS.md) = 4 entrées · 24 branches locales · 1 dirty
## ⚠️ Écarts Notion ↔ repo (2026-06-25)
- 🔴 **Roadmap périmée** : la fiche coche « Tag v1.0.0 stable \[ \] » (non fait), or le repo **porte déjà le tag ****`v1.0.0`** + toute une série `v1.1.0-NNN`. → v1.0.0 est livré, cocher et avancer le jalon (on est déjà en cycle 1.1.0).
- 🟠 **Fraîcheur** : propriété « Dernier commit 2026-06-12 », repo à **2026-06-22** (la Note cite déjà PR #137/#138 du 22/06 → la propriété date est en retard sur la Note). Aligner.
- ⚠️ Travail sur `chore/container-runtime-policy` (pas `main`) + 24 branches locales → merger/prune.
- ℹ️ Tension de modèle à trancher : Roadmap « bascule vers file-sync (`repo-file-sync-action`) » vs ex-ADR-0009 « fusion github-actions → shared-standards (reusable workflows) ». Les deux mécanismes coexistent encore (Description mentionne les deux) → clarifier lequel fait foi pour la propagation.
## 🧠 Couche sémantique — v1.1 (proposition, session 2026-06-26)
Objectif : faire évoluer `shared-standards` d'un **Dev Platform Layer** (qui standardise *comment travailler*) vers un **Engineering Operating System** qui standardise aussi *comment le code exprime le domaine* — du **code sémantique**. Aujourd'hui les couches exécution (CI/CD, repo, runtime, IA, enforcement) sont solides ; il manque la couche **Foundation / langage de conception**.
### Réorganisation cible des standards
```javascript
shared-standards/
  01-foundation/   engineering-principles.md · semantic-code.md · naming.md
  02-repository/   structure.md · git.md · ci-cd.md
  03-runtime/      docker.md · k8s.md · observability.md
  04-ai/           copilot.md · claude.md · agent-contract.md
  05-enforcement/  guideline-checker/ · linters/ · hooks/
```
Déjà couvert : 02 / 03 / 05. À renforcer : **01** et **04**.
### Nouveaux artefacts à ajouter
- `guidelines/semantic-code.md` — règles : intent over implementation, vocabulaire métier d'abord, pas de règles métier cachées (`if(status===3 && flag)` → `if(customer.canAccessPremiumFeatures())`), pas de primitive obsession, pas d'abstraction générique sans justification.
- `guidelines/engineering-principles.md` — Semantic first · Explicit over implicit · Domain over technology · Automation over convention.
- `.ai/coding-contract.md` — contrat IA : interdire `Manager/Helper/Utils/Processor/Handler/Data/Object` sauf justification, respecter les boundaries, préférer `customer.activateSubscription()` à `subscriptionService.updateStatus(id, "active")`.
- `templates/domain-glossary.md` — glossaire métier par repo (alignement produit / dev / archi / IA). Table « traductions interdites » : User→Customer, Record→Entity, Data→concept métier, Status flag→State.
### Liste de termes génériques à bannir (sauf justification)
`Manager · Handler · Processor · Helper · Utils · Service · Data · Object · Thing · Common · Generic · Base · Factory · Provider`
→ préférer des responsabilités explicites : `PaymentAuthorization`, `PaymentCapture`, `OrderFulfillment`, `CustomerRegistration`.
### Évolution `guideline-checker` (dimensions)
```yaml
dimensions:
  repository:   {enabled: true}
  ci:           {enabled: true}
  security:     {enabled: true}
  semantic:     {enabled: true}
  ai-readiness: {enabled: true}
semantic:
  forbidden_names: [Manager, Helper, Utils, Processor, Handler]
  warnings: [data, result, item]
  required_files: [domain-glossary.md]
```
### Couche CI / pre-commit (enforcement sémantique)
Principe : **une règle importante = 3 formes** → 📘 doc · 🤖 instruction IA · ⚙️ validation automatique.
- `quality/pre-commit/semantic-check` + `quality/ci/semantic-quality.yml` (job sur PR).
- `scripts/semantic-check.py` : détecte noms génériques, variables faibles (`data = get_customer()`), boolean blindness (`create_user(True, False)`).
- **Sévérité** par règle (`error` / `warning` / `info`) pour ne pas casser 32 repos.
- **Mode migration progressif** : `--report` → `--warn` → `--strict`.
- Config centrale `standards.yml` surchargeable par repo (`extends: chrysa/default` + `exceptions`).
- Badge `🧠 Semantic Health: 🟢` dans les README (calqué sur Config health).
### ADR / versioning à formaliser
- Format ADR enrichi : **Context · Concept · Decision · Rejected · Invariant** (le mot-clé durable = *Invariant*).
- `guidelines/versioning.md` : ajouter un lint = **minor** ; interdire un pattern existant = **major** ; cycle de vie `draft → experimental → stable → deprecated → removed`.
- Propriété de maturité par standard : 🟢 Foundation · 🔵 Adopted · 🟣 Enforced · 🟡 Automated.
### Ordre de PR recommandé
1. `feat(guidelines): add semantic code standard`
2. `feat(ai): add coding contract`
3. `feat(template): add domain glossary`
4. `feat(checker): add semantic rules`
5. `feat(quality): semantic pre-commit + CI gate`
6. refonte README/Notion (« Engineering operating system » plutôt que « templates CI/CD »)
> Diagnostic : `shared-standards` est déjà un kernel DevOps. La différenciation suivante = un **kernel sémantique** empêchant les 32 repos de diverger non seulement techniquement mais aussi dans leur vocabulaire et leur modèle métier.
*Source : session de revue ChatGPT 2026-06-26 (objectif « code sémantique »). À arbitrer / trier avant intégration au repo.*
## 🐙 État repo 2026-07-04 (reconciliation code↔Notion)
> Reconciliation automatique code réel ↔ fiche (append daté, ne remplace rien ci-dessus). Sur les points ci-dessous, le **code fait foi**.
- **stack** — Notion : Python 3.14 + CLI project-init + scripts, GitVersion, git-cliff → **Code : GitHub Actions (YAML) + Markdown + pre-commit; aucun Python**. Aucun pyproject.toml/.py, pas de project-init, pas de packages/. lint.yml épingle python-3.12 pour l'env pre-commit uniquement, pas 3.14.
- **maturité/déploiement** — Notion : V1 done, déployé sur 32 repos actifs → **Code : scaffold : sync.yml liste des repos placeholder (REPO-A/B/C), README = checklist de setup**. README dit 'Create this repo as chrysa/standards' + 'Fill the real repo names'. Aucune diffusion réelle observable.
- **tag/version** — Notion : v1.0.0 stable + série v1.1.0-NNN publiés → **Code : aucun tag git**. git tag vide. README étape 4 = 'Tag a release v1' (à faire).
- **README** — Notion : README complet = YES → **Code : README = checklist d'installation/scaffold, pas doc d'un système déployé**. Structuré et lisible mais décrit l'intention de distribution, pas un état livré.
- **working tree / branche** — Notion : GitHub Overview: branche chore/container-runtime-policy, 24 branches, 1 dirty → **Code : propre, branche chore/conformity-standards (2 branches: main + chore)**. Working tree clean. Snapshot Notion (2026-06-25) obsolète : repo apparemment ré-initialisé depuis.
- **dernier commit (fraîcheur)** — Notion : Dernier commit 2026-06-22 → **Code : 2026-07-03 (caf0129)**. Propriété date Notion en retard d'environ 11 jours.
*Cycle réel estimé : Build / bootstrap — scaffold non déployé (placeholders, aucun tag) · complétion \~35%. Section générée par reconciliation multi-agents ; corrections marquées « code fait foi » (haute/moy. confiance).*
## 🤖 Enrichissement auto — 2026-07-10
### 🧭 Améliorations de contenu
- L'hypothèse de mort est coupée ('divergence ') : finir — si les PR auto sont fermées sans merge, la source de vérité devient fiction et la divergence reprend.
- Le DoD s'arrête à 'MIT, d' : finir 'MIT, doc de propagation' et ajouter un critère de taux de merge minimal (ex. ≥90% des PR mergées).
- Ajouter une section 'Gouvernance' : qui merge les PR file-sync, sous quel délai, comment gérer les conflits par repo.
### 📄 Spec
- Problème : Les conventions chrysa (CI/CD, k3s, project-init, guideline-checker) divergent entre 32 repos faute de source de vérité propagée et effectivement adoptée.
- Hypothèse : Un repo source unique propagé par file-sync (PR auto) maintient l'alignement SI les PR sont réellement mergées et les configs yamllint-clean.
- Approche : Stabiliser + tagger v1.0.0, garantir 0 régression CI, puis suivre le taux de merge comme métrique de succès (la source de vérité vit par l'adoption).
- Design : Repo source (templates CI/CD, configs k3s, project-init, guideline-checker) + repo-file-sync-action générant une PR par repo, tags SemVer, yamllint, mécanisme .syncignore par repo. Licence MIT.
- DoD : Repo source unique propagé par file-sync sur 32 repos via PR auto, ≥1 cycle propagé et mergé, tag v1.0.0, yamllint aligné, 0 régression CI, MIT, doc de propagation.
### 💡 Suggestions
- Le risque de mort est social, pas technique : instrumenter le taux de merge des PR auto de file-sync par repo — si les repos écrasent/ferment sans merge, la source de vérité devient fiction.
- Publier un tag v1.0.0 stable + aligner yamllint avant de propager largement, pour ne pas casser la CI des 32 repos consommateurs.
- Prévoir un mécanisme de dérogation explicite (fichier .syncignore par repo) pour éviter que les repos ferment les PR en bloc quand un fichier ne les concerne pas.
### 🗺️ Plan
1. Stabiliser la source (templates CI/CD, k3s, project-init, guideline-checker) + tag v1.0.0.
2. Aligner yamllint et vérifier 0 régression CI sur les 32 repos.
3. Propager par file-sync (PR auto) et suivre le taux de merge.
4. Traiter les dérogations (syncignore) pour les fichiers non pertinents par repo.
## Standard transverse — observabilité vendor-neutral · décision Datadog 2026-07-25
Référence : <mention-page url="https://app.notion.com/p/3a859293e35e8128ac1ec0669798fbf3"/>
### Principe
Tout projet chrysa émet sa télémétrie avec **OpenTelemetry** et reste indépendant du backend d’observabilité. Prometheus, Grafana, Loki et Tempo constituent la destination principale. Datadog, Sentry ou tout autre SaaS ne sont que des exporteurs facultatifs configurés par la plateforme.
### Exigences obligatoires
- OpenTelemetry SDK ou instrumentation compatible ; aucun appel Datadog dans le domaine métier.
- Propagation W3C Trace Context entre services, workers, agents et workflows.
- Logs structurés JSON avec `trace_id`, `span_id`, `correlation.id`, `service.name` et environnement.
- Corrélation logs, métriques et traces.
- Exporteurs activables sans modification du code applicatif.
- Démarrage et fonctionnement nominal possibles sans backend SaaS.
- Sampling, rétention et indexation configurables par environnement.
- Redaction locale et allowlist avant tout export hors du cluster.
- Interdiction des secrets, contenus personnels, prompts complets et payloads métier sensibles dans la télémétrie par défaut.
- Cardinalité des attributs bornée et contrôlée.
- Mesure de la surcharge et du coût de télémétrie.
### Attributs communs minimums
```yaml
service.name: required
service.namespace: required
service.version: required
deployment.environment: required
deployment.cluster: optional
chrysa.project: required
chrysa.component: required
chrysa.owner: required
correlation.id: required
workflow.id: optional
workflow.run_id: optional
agent.id: optional
agent.role: optional
task.id: optional
```
### Politique Datadog
- statut : **intégration optionnelle / POC** ;
- activation : uniquement au niveau OpenTelemetry Collector ;
- site cible : région européenne lorsque l’usage est validé ;
- export : métriques sélectionnées, traces échantillonnées et logs filtrés ;
- absence de dépendance directe dans Python, TypeScript, React, C# ou Docker ;
- kill-test : retrait de Datadog sans réinstrumenter ni casser un service.
### Livrables à ajouter au repo
- `standards/OBSERVABILITY_STANDARD.md` ;
- profils OpenTelemetry Python, TypeScript et C# ;
- configuration Collector gateway de référence ;
- processors de redaction et allowlist ;
- exemple de propagation des traces dans les workers et événements ;
- règles exécutables dans `guideline-checker` ;
- test CI vérifiant l’absence de dépendance Datadog non autorisée ;
- dashboard Grafana de référence et exporteur Datadog désactivé par défaut.
## 🔎 Re-audit fonctionnel + centralisation — 2026-07-25
Passe multi-agents des **81 repos** (`origin/main`, 4 axes : fonctionnel · standards · demandes · cleanup). Rapport détaillé = §10 de [🔎 Standards Compliance Audit](https://app.notion.com/p/37759293e35e817d99dbd03eb5030ccf). Artifact décisionnel : [claude.ai/code/artifact/28c9f756](https://claude.ai/code/artifact/28c9f756-4c82-4dce-94f8-54c72a259dc2).
- **Santé** : 29 healthy · 31 minor · 12 stub · 1 major · 1 broken · 7 dead.
- **Thèse** : \~600 findings = **10 leviers systémiques** à foyer canonique (dont `shared-standards`), pas 81 correctifs. Nouveau **levier #10 — dédup de code → ****`chrysa-lib`** (31 repos).
- **Note** : le subagent auditant `shared-standards` a été flaggé sécurité (`rm -rf tasks/*` sur scratch partagé) → son verdict a été écarté ; à re-auditer proprement.
---
## 🔗 Cohérence inter-fiches — réouverture project-init (2026-07-29)
<callout icon="✅" color="green_bg">
	**Décision consolidée — 29 juillet 2026.** `project-init` est un projet autonome définitif. L’ancienne trajectoire de fusion dans `shared-standards/packages/project-init` est supersédée.
</callout>
- `shared-standards` possède les conventions, profils, templates et contrôles publiés.
- `project-init` est un orchestrateur léger autonome : il sélectionne les générateurs, génère la configuration et vérifie la conformité.
- La relation canonique est `project-init → shared-standards` de type `📐 Implémente un standard`, P1, par contrat versionné.
- Aucun import par chemin local, package interne, sous-module runtime ou copie concurrente des règles n’est autorisé.
- L’ancienne tâche de fusion est archivée ; les mentions historiques sont conservées comme décision supersédée.
## Navigation canonique et illustrations — 31 juillet 2026
<callout icon="📐" color="green_bg">
	**Rôle canonique :** shared-standards est un dépôt autonome de gouvernance technique. Il publie des standards, templates, contrôles et artefacts versionnés ; il n’est ni un hub, ni le parent produit des dépôts consommateurs.
</callout>
### Frontières et relations
- **Consommateurs :** les projets réutilisent les standards par packages versionnés ou synchronisation contrôlée, jamais par dépendances internes non documentées.
- **Propagation :** changement → tests canary → version → PR automatiques → CI → merge → mesure de dérive.
- **Forge-Stack :** l’organisation GitHub reste un hub séparé ; l’appartenance à une organisation ne modifie pas l’autorité de ce dépôt.
- **Séparation des responsabilités :** les configurations d’agents, les secrets et les paramètres de postes conservent leurs propriétaires ; shared-standards ne doit pas devenir un dépôt fourre-tout.
### Liens opérationnels
- [Dépôt GitHub](https://github.com/chrysa/shared-standards)
- [Dossier Drive — shared-standards](https://drive.google.com/drive/folders/1Z4y5y0sJa8zEp2RvhH-NLFKrIUILCTuw)
- Schémas planifiés : <mention-page url="https://app.notion.com/p/3ae59293e35e81749173ea49ca4e2694"/> · <mention-page url="https://app.notion.com/p/3ae59293e35e812cb3a0cfe0ea6f3da4"/>.
- Registre transverse : <mention-page url="https://app.notion.com/p/68354831ebbc45aaa6412d5c0a9c628a"/>.
<page url="https://app.notion.com/p/3ae59293e35e81fca372e84631c7c2b3">📚 Standards transverses prioritaires — gouvernance, données et exploitation</page>
---n\<empty-block/\>n## 🛰️ Veille Août 2026 — standards d'interopérabilité IAn\<empty-block/\>nSource : Veille — Protocoles agents & assistants local-first — Août 2026 · ADR : ADR-LOGOS-013, ADR-LOGOS-014.n\<empty-block/\>nNouveaux standards transverses à intégrer (section **Interopérabilité IA**) :n\<empty-block/\>n- **Séparation protocole / métier** : un protocole d'accès (MCP, A2A) n'est jamais le contrat métier ; les invariants restent dans les services propriétaires.n- **Capability Manifest** (inspiré OASF) : id, version, owner, protocoles, identité workload SPIFFE, statut de scan de sécurité, schemas in/out, niveau de risque, observabilité.n- **AgentRuntimeSpec** : spécification versionnée, reproductible, comparable, rollbackable.n- **Tests contractuels multi-version** (chantier *Protocol Compatibility* rattaché à shared-standards, **pas** un projet top-level) : conformité MCP par version, conformité A2A, tests de contrat, performance, sécurité.n- **Versionning & compatibilité ascendante** des capacités ; **scan de sécurité obligatoire** stocké comme artefact immutable ; **identité de workload** ; **traces** normalisées.
