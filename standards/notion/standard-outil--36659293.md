---
fka_managed: true
source: notion
notion_id: 36659293-e35e-8175-9932-f6d70cda6d68
notion_url: https://app.notion.com/p/Standard-Outil-36659293e35e81759932f6d70cda6d68
notion_last_edited_time: 2026-06-05T13:23:00.000Z
---
# 🛠️ Standard Outil

<table_of_contents/>
> **🛠️ Standard Outil** · script ou utilitaire technique éliminant une friction concrète dans le workflow.
## 🎯 Identité du type
Programme autonome (CLI, daemon, webhook, cron, script) qui élimine une friction concrète dans le workflow personnel ou professionnel. Petite taille (≤1000 LOC généralement). Pas d'UI complexe ni de BD propre. Différencié de l'OSS par l'absence d'intention de diffusion publique. Différencié du SaaS par l'absence de frontend ou de couche métier persistante.
## 📋 Synthèse du standard
<table header-row="true">
<tr>
<td>Aspect</td>
<td>Standard Outil</td>
</tr>
<tr>
<td>**Article (4 outils)**</td>
<td>Dépend de la friction résolue : 📎 Gouvernance · ⚒️ Build / Dev · 👁️ Observabilité · 📓 Connaissance (capture/sync) · 🔘 N/A si autonome</td>
</tr>
<tr>
<td>**Cycle de vie applicable**</td>
<td>Idée → Spec (Cadrage souvent skip) → Dev → Test → Prod → Maintenance → Sunset</td>
</tr>
<tr>
<td>**Étude marché**</td>
<td>🔘 N/A si perso/interne · sinon Draft</td>
</tr>
<tr>
<td>**Étude faisabilité**</td>
<td>Draft minimum (rapide)</td>
</tr>
<tr>
<td>**Étude technique**</td>
<td>**Obligatoire** — peut renvoyer à DB SYSTEM DESIGN si non triviale</td>
</tr>
<tr>
<td>**Pertinence marché**</td>
<td>🔘 N/A si perso</td>
</tr>
<tr>
<td>**Étude financière**</td>
<td>🔘 N/A si perso/interne · Draft si commercial</td>
</tr>
<tr>
<td>**Modèle de revenu**</td>
<td>Aucun (perso/interne) le plus souvent</td>
</tr>
<tr>
<td>**Versioning**</td>
<td>semver basique · Conventional Commits · README à jour</td>
</tr>
<tr>
<td>**Cadence de revue**</td>
<td>Sur signal · mensuelle si stuck</td>
</tr>
</table>
## ✅ Gates applicables
- **Gate Spec → Dev** : triggers définis (cron / event / manuel) · stack choisie · dépendances listées
- **Gate Dev → Test** : tests minimum présents (placeholders OK si XS) · logs structurés · erreurs gérées
- **Gate Test → Prod** : run manuel sans erreur · observabilité (stdout/fichier/syslog) vérifiée
- **Gate Prod → Maintenance** : 7 jours d'usage sans incident
## 📑 Contenu attendu
> Légende : `*` obligatoire · `+` recommandé · `📄` section inline (H2 dans la page) · `📁` sous-page dédiée · `📄/📁` au choix selon volume
- `*📄` **🎯 Problème résolu** — friction concrète éliminée (1-3 phrases)
- `*📄` **🚀 Quickstart** — bloc code minimal d'installation + run
- `*📄` **🛠️ Stack** — langage, dépendances principales, packaging
- `*📄` **🎙️ Triggers** — quand l'outil se déclenche (cron, event, manuel, webhook)
- `*📄` **🔍 Observabilité** — logs (stdout / fichier / syslog), métriques si pertinent, alertes si pertinent
- `*📄` **📜 État actuel** — statut (actif / développement / gelé), tests (présents / placeholders / absents)
- `*📄` **🔗 Dépendances** — repo GitHub, outils consommés, libs internes
- `*📁` **README** — quickstart utilisateur (sous-page)
- `*📁` **`DECISIONS.md`** — choix architecture (sous-page, même minimal)
- `*📁` **Études (technique principalement)** — via [template subpage Études v2](https://www.notion.so/36659293e35e81f69470ee692d4f843b)
- `*📁` **Suivi** — via [template subpage Suivi](https://www.notion.so/36359293e35e8106ace1e8691e082f66)
- `+📄/📁` **⚙️ Configuration env vars** — sous-page si très détaillée
- `+📁` **🚨 ADRs spécifiques** — sous-page si l'outil a des décisions structurelles propres
## 🚨 Critères Risk Window
- 🔴 **Critique** : outil critique pour un Actif et cassé · ou outil d'authentification/sécu défaillant
- 🟠 **At-risk** : dépendance dépréciée sans remplacement · packaging legacy (setup.cfg → pyproject.toml à migrer)
- 🟢 **Safe** : tourne sans incident · dépendances à jour
- ⚫ **Lost** : non utilisé \>90j · friction qu'il éliminait disparue → Sunset
## 🛑 Non-négociables
- **Packaging moderne** : pyproject.toml pour Python · package.json pour Node · go.mod pour Go
- **Conventional Commits** obligatoires
- **Triggers explicites** déclarés dans README
- **Observabilité minimum** : logs structurés vers stdout au minimum
- **Pas de cron-as-a-service externe** (pas de [cron-job.org](http://cron-job.org) · GitHub Actions cron OK)
- **GAFAM-indépendant** au niveau des dépendances tierces critiques
## 🔗 Template natif associé
Template Notion natif à créer dans DB Projets v2 (Vague B étape 2). Application automatique à la création d'une entrée `Type projet = 🛠️ Outil`.
