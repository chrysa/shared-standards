---
fka_managed: true
source: notion
notion_id: 36659293-e35e-8158-94d9-f3e10b2b63a8
notion_url: https://app.notion.com/p/Standard-Travaux-36659293e35e815894d9f3e10b2b63a8
notion_last_edited_time: 2026-06-05T13:23:00.000Z
---
# 🔨 Standard Travaux

<table_of_contents/>
> **🔨 Standard Travaux** · chantier physique sur la propriété · irréversibilité physique souvent élevée.
## 🎯 Identité du type
Intervention matérielle sur le site : installation, réparation, amélioration. Différencié des autres types par le caractère **physique et souvent irréversible** des actions (béton coulé, câblage encastré, modification structurelle). Dépendance possible aux fenêtres météo ou saison. Cycle de vie marqué par phases concrètes (préparation, installation, tests, finitions).
## 📋 Synthèse du standard
<table header-row="true">
<tr>
<td>Aspect</td>
<td>Standard Travaux</td>
</tr>
<tr>
<td>**Article (4 outils)**</td>
<td>🔘 N/A le plus souvent — sauf intégration domotique (⚒️ Build / Dev si tracking) ou suivi en page Notion (📓 Connaissance)</td>
</tr>
<tr>
<td>**Cycle de vie applicable**</td>
<td>Idée → Cadrage → Spec (devis/achats) → Dev (préparation) → Review (installation) → Test (tests fonctionnels) → Pilote (finitions) → Prod (opérationnel) → Maintenance → Sunset (démantèlement)</td>
</tr>
<tr>
<td>**Étude marché**</td>
<td>🔘 N/A (perso/maison)</td>
</tr>
<tr>
<td>**Étude faisabilité**</td>
<td>**Obligatoire** — budget + compétences + délais + dépendance météo/saison</td>
</tr>
<tr>
<td>**Étude technique**</td>
<td>**Obligatoire** — matériel + intégration domotique si pertinent + sécurité</td>
</tr>
<tr>
<td>**Pertinence marché**</td>
<td>🔘 N/A</td>
</tr>
<tr>
<td>**Étude financière**</td>
<td>🔘 N/A (perso/maison) — budget couvert par la table "Synthèse" et la sous-page Devis & achats</td>
</tr>
<tr>
<td>**Modèle de revenu**</td>
<td>Aucun (perso/interne)</td>
</tr>
<tr>
<td>**Versioning**</td>
<td>Journal de bord + photos avant/après · pas de semver</td>
</tr>
<tr>
<td>**Cadence de revue**</td>
<td>Sur signal (phase achevée) · mensuelle si bloqué</td>
</tr>
</table>
## ✅ Gates applicables
- **Gate Cadrage → Spec** : budget estimé · fenêtre météo/saison identifiée · risque d'irréversibilité évalué
- **Gate Spec → Dev** : devis validés · matériel commandé · plan d'installation documenté · conformité légale vérifiée
- **Gate Dev → Review** : préparation terminée · outils sur site · créneau bloqué
- **Gate Review → Test** : installation terminée · photos avant/après prises · conformité vérifiée
- **Gate Test → Pilote** : tests fonctionnels OK (électricité = norme, mécanique = essais, domotique = intégration validée)
- **Gate Pilote → Prod** : 30 jours sans défaillance · runbook maintenance rédigé
## 📑 Contenu attendu
> Légende : `*` obligatoire · `+` recommandé · `📄` section inline (H2 dans la page) · `📁` sous-page dédiée · `📄/📁` au choix selon volume
- `*📄` **🎯 Objectif** — ce qui doit être installé / réparé / amélioré
- `*📄` **📍 Localisation** — pièce(s) concernée(s), zone du terrain
- `*📄/📁` **🛠️ Stack / Matériel** — matériel principal, outils, durée par phase (sous-page si liste longue)
- `*📄` **💰 Budget** — total estimé en euros, décomposition par poste
- `*📄` **🔗 Dépendances** — chantiers liés, compétences requises, fenêtre météo/saison
- `*📄/📁` **📜 Phases** — Préparation → Installation → Tests → Finitions (sous-page si plan d'installation détaillé)
- `*📄` **⚠️ Risques physiques / irréversibilité** — points où une erreur coûte cher à corriger
- `*📁` **Devis & achats** — sous-page (justificatifs)
- `*📁` **Photos avant/après** — sous-page (album)
- `*📁` **Études (faisabilité + technique principalement)** — via [template subpage Études v2](https://www.notion.so/36659293e35e81f69470ee692d4f843b)
- `*📁` **Suivi** — journal + budget + % phases · via [template subpage Suivi](https://www.notion.so/36359293e35e8106ace1e8691e082f66)
- `+📁` **Plan d'installation détaillé** — schémas, diagrammes (sous-page)
- `+📁` **🔌 Intégration domotique** — si applicable, schéma d'intégration HA / Victron / autre (sous-page)
- `+📁` **Runbook maintenance** — créée à Prod → Maintenance (sous-page)
- `+📄` **🚨 Conformité légale** — déclarations préalables, NF C 15-100 si applicable
## 🚨 Critères Risk Window
- 🔴 **Critique** : irréversibilité physique élevée dans une fenêtre temporelle courte (béton coulé, modification structurelle) · ou sécurité électrique/structure en cause
- 🟠 **At-risk** : dépendance météo/saison non respectée · matériel manquant · retard \>30j
- 🟢 **Safe** : phases réversibles ou non urgentes
- ⚫ **Lost** : abandonné, matériel acheté non utilisé → déclarer Sunset franchement
## 🛑 Non-négociables
- **Sécurité électrique** : conformité NF C 15-100 obligatoire pour toute intervention réseau 230V
- **Conformité légale** : déclarations préalables si modification structurelle
- **Irréversibilité physique = Risk Window 🔴 obligatoire** dès Spec validation
- Photos avant/après systématiques pour Maintenance future
- Compatibilité installation existante (off-grid, domotique, etc.) à vérifier pour toute consommation électrique nouvelle
## 🔗 Template natif associé
Template Notion natif à créer dans DB Projets v2 (Vague B étape 2). Application automatique à la création d'une entrée `Type projet = 🔨 Travaux`.
