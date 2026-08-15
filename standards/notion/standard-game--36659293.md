---
fka_managed: true
source: notion
notion_id: 36659293-e35e-81fb-90ad-e145e7c5ee7e
notion_url: https://app.notion.com/p/Standard-Game-36659293e35e81fb90ade145e7c5ee7e
notion_last_edited_time: 2026-07-30T19:37:00.000Z
---
# 🎮 Standard Game

<table_of_contents/>
> **🎮 Standard Game** · jeu vidéo solo-dev · 3 critères non-négociables · cycles de production longs.
## 🎯 Identité du type
Projet ludique avec gameplay, identité forte, système d'achievements. Réalisé en solo dev (parfois avec assistance IA). Cycles de production longs (12-24 mois minimum pour V1 jouable). Versionnement narratif (Prototype → Vertical Slice → V1 → V2 → V3) plutôt que semver classique. Frontière physique : maximum 3 projets de type Game en cycle de vie actif simultanément.
## 📋 Synthèse du standard
<table header-row="true">
<tr>
<td>Aspect</td>
<td>Standard Game</td>
</tr>
<tr>
<td>**Article (4 outils)**</td>
<td>🔘 N/A le plus souvent — les jeux sont autonomes des 4 outils canoniques</td>
</tr>
<tr>
<td>**Cycle de vie applicable**</td>
<td>Mapping spécifique : Idée → Cadrage → Spec (GDD) → Dev (Prototype) → Review (Vertical Slice) → Test (V1 jouable) → Pilote (V1 release) → Prod (V2+) → Maintenance → Sunset</td>
</tr>
<tr>
<td>**Étude marché**</td>
<td>**Obligatoire** — concurrence + segment joueurs</td>
</tr>
<tr>
<td>**Étude faisabilité**</td>
<td>**Obligatoire et BLOQUANTE** (critère solo-dev sur 12-24 mois)</td>
</tr>
<tr>
<td>**Étude technique**</td>
<td>**Obligatoire et BLOQUANTE** — moteur, stack et architecture multi/solo évalués avec la <mention-page url="https://app.notion.com/p/3ad59293e35e8134bbf0c0935111522e">Matrice de décision — Moteurs de jeu</mention-page>, puis validés par un spike comparatif et un ADR</td>
</tr>
<tr>
<td>**Pertinence marché**</td>
<td>**Obligatoire** — vérifie les 3 critères chrysa avant Sprint 1</td>
</tr>
<tr>
<td>**Étude financière**</td>
<td>**Obligatoire** — coûts production solo-dev sur 12-24 mois, point d'équilibre joueurs/CA, modèle économique chiffré</td>
</tr>
<tr>
<td>**Modèle de revenu**</td>
<td>Commercial (B2P/F2P/Premium) ou Aucun (perso/portfolio)</td>
</tr>
<tr>
<td>**Versioning**</td>
<td>Versions narratives : Prototype → Vertical Slice → V1 → V2 → V3 · outils internes en semver</td>
</tr>
<tr>
<td>**Cadence de revue**</td>
<td>Trimestrielle (sauf Actif)</td>
</tr>
</table>
## ✅ Gates applicables
- **Gate Cadrage → Spec** : 3 critères chrysa pré-validés · étude faisabilité solo-dev Draft
- **Gate Spec → Dev (Prototype)** : GDD rédigé · mécanique clé décrite · 3 critères chrysa Done · Pertinence marché Done · contraintes moteur renseignées · shortlist issue de la matrice · spike comparatif planifié ou réalisé · ADR moteur au minimum Draft
- **Gate Dev → Review (Vertical Slice)** : prototype jouable · 1 boucle de gameplay complète · squelette achievements (3-5 démontrés)
- **Gate Review → Test (V1)** : VS testé par ≥2 personnes extérieures · retours intégrés ou justifiés
- **Gate Test → Pilote (release)** : V1 jouable bout-en-bout · système d'achievements complet · build distribuable
- **Gate Pilote → Prod** : 30 jours sans bug bloquant · minimum 10 joueurs externes
## 📑 Contenu attendu
> Légende : `*` obligatoire · `+` recommandé · `📄` section inline (H2 dans la page) · `📁` sous-page dédiée · `📄/📁` au choix selon volume
- `*📄` **🎯 Pitch (1 phrase)** — tagline du jeu, comme un éditeur pourrait le dire
- `*📄` **📖 Genre + Plateformes** — genre, plateformes V1 (PC/mobile/web)
- `*📄` **🎨 Identité forte (NON NÉGOCIABLE)** — proposition unique reconnaissable, tone/univers en 3 mots
- `*📄` **💡 Innovation (NON NÉGOCIABLE)** — au moins 1 dimension originale (mécanique, narratif, technique)
- `*📄/📁` **🏆 Système de succès / achievements (NON NÉGOCIABLE)** — squelette 3-5 succès · sous-page si plus de 5
- `*📄` **🛠️ Stack technique** — moteur choisi via la <mention-page url="https://app.notion.com/p/3ad59293e35e8134bbf0c0935111522e">Matrice de décision — Moteurs de jeu</mention-page>, résultats du spike, ADR associé, backend si multi et cible mobile si prévue
- `*📄` **💰 Modèle économique** — si commercial : F2P+microtransactions / B2P / premium / freemium
- `*📁` **One Page Projet Jeu** — pitch résumé en sous-page (utile pour partage externe)
- `*📁` **Game Design Document (GDD)** — sous-page complète
- `*📁` **Mécanique clé + Innovation (détail)** — sous-page
- `*📁` **Études (marché / faisabilité / technique / pertinence / financière)** — via [template subpage Études v2](https://www.notion.so/36659293e35e81f69470ee692d4f843b)
- `*📁` **Suivi** — via [template subpage Suivi](https://www.notion.so/36359293e35e8106ace1e8691e082f66)
- `+📁` **🌍 Lore + Univers** — sous-page (souvent volumineux)
- `+📁` **Pages dédiées Game Design Patterns / Level Design / Direction Artistique** — sous-pages
- `+📁` **🗺️ Roadmap** — Prototype → Vertical Slice → V1 → V2 → V3 (sous-page)
- `+📁` **🚨 ADRs spécifiques** — sous-page liée à DB Reference
## 🚨 Critères Risk Window
- 🔴 **Critique** : non-respect d'un des 3 critères chrysa identifié après Spec · choix moteur sans matrice, sans spike ou sans ADR · violation d’une contrainte portfolio active, dont l’ADR-0007
- 🟠 **At-risk** : solo-dev infaisable révélé par étude faisabilité · cycle de production estimé \>24 mois · plus de 3 jeux en Actif simultané
- 🟢 **Safe** : Vertical Slice validé · 3 critères respectés · rythme tenu
- ⚫ **Lost** : abandonné ou prototypé sans suite \>12 mois → candidat Sunset (libération)
## 🛑 Non-négociables (3 critères chrysa)
1. **🎨 Identité forte** : proposition unique reconnaissable (tone, univers, mécanique signature)
2. **💡 Innovation** : au moins 1 dimension originale (mécanique, narratif, technique)
3. **🏆 Système de succès / achievements** : 3-5 succès représentatifs court/moyen/long terme, diversité, pas du remplissage
Autres non-négociables :
- **PAS DE GODOT** (ADR-0007) — sortie de l'enum tech
- **Maximum 3 jeux en Actif simultané** (Rule 1+3 étendue au cluster Game)
- Candidats encadrés par la matrice : Unity, Unreal Engine, Phaser, PixiJS, Three.js / Web custom, Defold et Stride · O3DE en expérimentation · Godot benchmarké mais non admissible tant que l’ADR-0007 reste actif · backend Python/Node si multi · Flutter uniquement pour un client compagnon ou une interface mobile séparée
## 🔗 Template natif associé
Template Notion natif à créer dans DB Projets v2 (Vague B étape 2). Application automatique à la création d'une entrée `Type projet = 🎮 Game`.
<page url="https://app.notion.com/p/3ad59293e35e8134bbf0c0935111522e">Matrice de décision — Moteurs de jeu</page>
