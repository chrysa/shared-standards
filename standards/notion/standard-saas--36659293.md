---
fka_managed: true
source: notion
notion_id: 36659293-e35e-8124-8b6c-e741fd84d9c9
notion_url: https://app.notion.com/p/Standard-SaaS-36659293e35e81248b6ce741fd84d9c9
notion_last_edited_time: 2026-06-05T13:22:00.000Z
---
# 🚀 Standard SaaS

<table_of_contents/>
> **🚀 Standard SaaS** · application web full-stack déployée en continu, périmètre fonctionnel défini, V1/V2/V3 incrémental.
## 🎯 Identité du type
Application avec backend serveur (API + BD propre) et frontend, déployable en autonomie sur infrastructure auto-hébergée. Architecture multi-tenant possible ou mono-utilisateur. Cycle de produit incrémental versionné. Différencié de l'Outil par la présence d'un frontend et d'une BD persistante propre.
## 📋 Synthèse du standard
<table header-row="true">
<tr>
<td>Aspect</td>
<td>Standard SaaS</td>
</tr>
<tr>
<td>**Article (4 outils)**</td>
<td>⚒️ DEV Nexus (par défaut) ou 👁️ Mirador (si LLM-heavy) — jamais 🔘 N/A</td>
</tr>
<tr>
<td>**Cycle de vie applicable**</td>
<td>Tout l'enum (Idée → Sunset). Cadrage obligatoire.</td>
</tr>
<tr>
<td>**Étude marché**</td>
<td>**Obligatoire** (sauf usage strictement interne)</td>
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
<td>**Obligatoire** avant passage en Dev</td>
</tr>
<tr>
<td>**Étude financière**</td>
<td>**Obligatoire** — coûts initiaux, coûts récurrents, break-even, ROI estimé</td>
</tr>
<tr>
<td>**Modèle de revenu**</td>
<td>Commercial / OSS+commercial / Aucun (perso)</td>
</tr>
<tr>
<td>**Versioning**</td>
<td>semver strict · Conventional Commits · openapi.json committé · [CHANGELOG.md](http://CHANGELOG.md)</td>
</tr>
<tr>
<td>**Cadence de revue**</td>
<td>Hebdo si Actif · mensuelle si Maintenance</td>
</tr>
</table>
## ✅ Gates applicables
- **Gate Cadrage → Spec** : Article set (domaine fonctionnel) · étude marché Draft minimum
- **Gate Spec → Dev** : ADRs ouverts · ISA done-criteria écrits · openapi.json committé · Pertinence marché Draft minimum
- **Gate Dev → Review** : Gate UI (Playwright) verte · Gate API (Schemathesis + oasdiff) verte · aucun TODO dans lignes modifiées
- **Gate Review → Test** : revue humaine · [CLAUDE.md](http://CLAUDE.md) à jour · traces Mirador sans régression coût/latence
- **Gate Test → Pilote** : un run complet conditions réelles · plan rollback documenté
- **Gate Pilote → Prod** : 7 jours sans incident P1 · runbook dans Wiki
## 📑 Contenu attendu
> Légende : `*` obligatoire · `+` recommandé · `📄` section inline (H2 dans la page) · `📁` sous-page dédiée · `📄/📁` au choix selon volume
- `*📄` **🎯 Vision** — 1-2 phrases : qu'est-ce que c'est, pour qui, pourquoi
- `*📄` **🏛️ Problème résolu** — pain point concret pour la cible
- `*📄` **💰 Modèle économique** — pricing, cible segment, gate de validation usage
- `*📄/📁` **🛠️ Stack technique** — backend, frontend, BD, déploiement, tests (sous-page si stack non-standard ou très détaillée)
- `*📄` **🔗 Liens** — repo GitHub, dépendances libs internes, ce que ce projet bloque
- `*📄` **⚠️ Hors scope V1** — ce qui n'est explicitement PAS dans la première version
- `*📁` **`CLAUDE.md`** — quickstart IA (sous-page)
- `*📁` **Études (marché / faisabilité / technique / pertinence / financière)** — via [template subpage Études v2](https://www.notion.so/36659293e35e81f69470ee692d4f843b)
- `*📁` **Suivi** — journal + état + métriques · via [template subpage Suivi](https://www.notion.so/36359293e35e8106ace1e8691e082f66)
- `+📄/📁` **📍 Sous-produits standalone éventuels** — sous-page si plusieurs
- `+📁` **🗺️ Roadmap V1/V2/V3** — sous-page (souvent volumineuse)
- `+📁` **🚨 ADRs spécifiques** — sous-page liée à DB Reference (filtrée projet)
## 🚨 Critères Risk Window
- 🔴 **Critique** : données client/revenue en prod + incident P0 actif · ou faille sécu non patchée
- 🟠 **At-risk** : bug bloquant \>7j sans fix · PR ouverte \>30j · dépendance OSS abandonnée
- 🟢 **Safe** : prod stable · incidents \<P2 uniquement
- ⚫ **Lost** : non touché \>90j ET cycle de vie Maintenance → candidat Sunset
## 🛑 Non-négociables
- RGPD-compliant si données personnelles
- GAFAM-indépendant (pas de Firebase, pas de Vercel managed, pas d'Auth0)
- AI-agnostic au niveau adaptateurs (Claude/GPT/Gemini/Mistral interchangeables)
- Stack standard : FastAPI + Python 3.14 + Pydantic v2 + SQLAlchemy 2.0 async · React 19 + TypeScript + Vite 6 + Tailwind + shadcn/ui · PostgreSQL 16 + Redis 7 · Docker Compose sur Kimsufi + Tailscale
## 🔗 Template natif associé
Template Notion natif à créer dans DB Projets v2 (Vague B étape 2). Application automatique à la création d'une entrée `Type projet = 🚀 SaaS`.
