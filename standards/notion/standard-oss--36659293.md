---
fka_managed: true
source: notion
notion_id: 36659293-e35e-813f-b40c-c54a82a49b63
notion_url: https://app.notion.com/p/Standard-OSS-36659293e35e813fb40cc54a82a49b63
notion_last_edited_time: 2026-06-05T13:23:00.000Z
---
# 🌱 Standard OSS

<table_of_contents/>
> **🌱 Standard OSS** · lib ou outil diffusé publiquement sous licence ouverte, conçu pour être consommé par d'autres projets.
## 🎯 Identité du type
Composant logiciel destiné à être réutilisé : lib, package, framework léger, MCP server, etc. Cycle de vie conditionné par les consumers (autres projets qui l'utilisent). Différencié de l'Outil par l'intention de diffusion publique sous licence ouverte. Différencié du SaaS par l'absence de frontend et de BD propre.
## 📋 Synthèse du standard
<table header-row="true">
<tr>
<td>Aspect</td>
<td>Standard OSS</td>
</tr>
<tr>
<td>**Article (4 outils)**</td>
<td>Dépend du consumer principal : 📓 Connaissance / 📎 Gouvernance / ⚒️ Build / Dev / 👁️ Observabilité / 🔘 N/A si lib autonome</td>
</tr>
<tr>
<td>**Cycle de vie applicable**</td>
<td>Tout l'enum + **contrainte** : passage Spec → Dev exige ≥2 consumers en 🟠 Spec minimum (règle lib-avant-consumer)</td>
</tr>
<tr>
<td>**Étude marché**</td>
<td>Optionnel — analyse écosystème concurrent OSS</td>
</tr>
<tr>
<td>**Étude faisabilité**</td>
<td>**Obligatoire**</td>
</tr>
<tr>
<td>**Étude technique**</td>
<td>**Obligatoire**</td>
</tr>
<tr>
<td>**Pertinence marché**</td>
<td>Obligatoire si OSS+commercial · N/A si OSS pur perso</td>
</tr>
<tr>
<td>**Étude financière**</td>
<td>**Obligatoire si OSS+commercial** (modèle revenu addons) · N/A si OSS pur perso</td>
</tr>
<tr>
<td>**Modèle de revenu**</td>
<td>OSS pur (MIT/Apache 2.0) / OSS+commercial / Aucun (interne)</td>
</tr>
<tr>
<td>**Versioning**</td>
<td>semver strict · Conventional Commits · [CHANGELOG.md](http://CHANGELOG.md) · tags Git par release</td>
</tr>
<tr>
<td>**Cadence de revue**</td>
<td>Sur signal (PR consumer) · mensuelle minimum</td>
</tr>
</table>
## ✅ Gates applicables
- **Gate Cadrage → Spec** : Article set ou justification N/A · 1 consumer identifié en 🟡 Idée minimum
- **Gate Spec → Dev** : **≥2 consumers en 🟠 Spec minimum** (règle lib-avant-consumer) · ADRs ouverts · ISA done-criteria écrits
- **Gate Dev → Review** : Gate API verte (Schemathesis si HTTP) · CI tests verts · coverage ≥50%
- **Gate Review → Test** : revue humaine · [README.md](http://README.md) à jour · [CHANGELOG.md](http://CHANGELOG.md) à jour · [CONTRIBUTING.md](http://CONTRIBUTING.md) présent
- **Gate Test → Pilote** : un consumer en prod consomme la lib avec succès
- **Gate Pilote → Prod** : 7 jours sans bug bloquant remonté · release v1.0 taguée
## 📑 Contenu attendu
> Légende : `*` obligatoire · `+` recommandé · `📄` section inline (H2 dans la page) · `📁` sous-page dédiée · `📄/📁` au choix selon volume
- `*📄` **🎯 Mission** — en 1 phrase, quel problème ce composant résout
- `*📄` **🚀 Quickstart** — bloc code minimal d'installation + utilisation
- `*📄/📁` **✨ Features V1** — liste cochable (sous-page si nombreuses ou très détaillées)
- `*📄` **🛠️ Stack technique** — langage, dépendances principales, packaging
- `*📄` **🎁 Modèle de diffusion** — licence (MIT/Apache 2.0 par défaut), channel de distribution
- `*📄` **🔗 Consumers identifiés** — projets qui consommeront cette lib avec leur cycle de vie (vérif lib-avant-consumer)
- `*📁` **`README.md`** — quickstart utilisateur (sous-page)
- `*📁` **`DECISIONS.md`** — ADRs séquentiels du projet (sous-page, cf. ADR-CHRYSA-2026-12)
- `*📁` **`CLAUDE.md`** — quickstart IA (sous-page)
- `*📁` **`CONTRIBUTING.md`** — guide contributeurs (sous-page)
- `*📁` **Études (faisabilité / technique principalement · financière si OSS+commercial)** — via [template subpage Études v2](https://www.notion.so/36659293e35e81f69470ee692d4f843b)
- `*📁` **Suivi** — via [template subpage Suivi](https://www.notion.so/36359293e35e8106ace1e8691e082f66)
- `+📁` **🗺️ Roadmap** — V0.1 MVP, V0.2 coverage, V1.0 stable (sous-page)
- `+📁` **📜 API publique** — interface, signatures, contrat de stabilité (sous-page si non triviale)
## 🚨 Critères Risk Window
- 🔴 **Critique** : lib bloque ≥2 consumers en Spec+ · dépendance OSS du Socle abandonnée · faille sécu non patchée
- 🟠 **At-risk** : lib en Spec/Dev sans consumer actif depuis \>60j (viole lib-avant-consumer)
- 🟢 **Safe** : consumers actifs, releases régulières
- ⚫ **Lost** : abandonné par tous les consumers → candidat Sunset
## 🛑 Non-négociables
- **Règle lib-avant-consumer** : ≥2 consumers en 🟠 Spec minimum avant Sprint 1 (exception possible pour le Socle, à acter par ADR au cas par cas)
- Licence déclarée dès Cadrage (MIT/Apache 2.0 par défaut)
- Tests minimum coverage 50% avant Pilote
- Pas de breaking change sans bump major + ADR
- API publique stable documentée dès Test
## 🔗 Template natif associé
Template Notion natif à créer dans DB Projets v2 (Vague B étape 2). Application automatique à la création d'une entrée `Type projet = 🌱 OSS`.
