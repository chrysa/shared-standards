# Plan de restructuration Notion — chrysa

> État cible · à exécuter manuellement via UI Notion (API limitée pour création DB)
> Date : 2026-04-20

---

## 1 · Problèmes observés

- **26 ADRs dispersés** dans plusieurs pages + référencés dans CLAUDE.md global → migrés vers DECISIONS.md par repo (2026-04-20)
- **DB Projets** contient à la fois repos actifs, repos gelés, fusions avortées → rôle flou
- **Bugs + Dette technique** : pas de DB dédiée, les issues se perdent dans les Tasks
- **Aménagement Notion** (meta-work) mélangé avec les Projets
- **Travaux** (domaine Maison) pas clairement séparé des projets dev

## 2 · Architecture cible

```
chrysa workspace (Notion)
├── 🏠 Home — dashboard + liens rapides
├── 📚 Wiki Engineering
│   ├── Conventions transverses (Python 3.14, i18n FR+EN, auth 4 modes…)
│   ├── Git safety protocol
│   ├── Hooks locaux (validate-prompt, dev-run)
│   └── Migration ADRs → DECISIONS.md (lien vers shared-standards)
├── 📋 Databases
│   ├── DB Projets (déjà existante) — filtrée par scope :
│   │   ├── Vue "Portfolio dev" — projets dev uniquement
│   │   ├── Vue "Travaux maison" — domaine travaux
│   │   ├── Vue "Aménagement Notion" — meta-work organisation workspace
│   │   └── Vue "Gelés + Archive" — pour hygiène trimestrielle
│   ├── DB Tâches (déjà existante)
│   ├── 🆕 DB Bugs (à créer) — Nom · Projet (→DB Projets) · Severity (P0/P1/P2/P3) · Statut · Repro · Assigné
│   ├── 🆕 DB Dette technique (à créer) — Nom · Projet · Catégorie · Coût (XS/S/M/L/XL) · Impact · Statut
│   └── DB Scheduled tasks (déjà existante)
├── 🧭 Roadmaps (par domaine)
│   ├── Roadmap portefeuille (Now/Next/Later global)
│   ├── Roadmap projets informatique (existe déjà)
│   ├── Roadmap jeux (existe déjà)
│   ├── Roadmap travaux maison (à créer ou isoler)
│   └── Roadmap apprentissages perso
├── 📊 Reviews
│   ├── Sprint (clôtures sprint)
│   ├── Semaines (revue hebdo)
│   └── Mois (revue mensuelle)
├── 🤖 Agents & automations
│   ├── briefing-agent
│   ├── pr-review-agent
│   ├── sprint-agent
│   ├── health-agent
│   └── notion-sync-agent
└── 🗃️ Archive (pages migrées · avec préfixe [MIGRÉ YYYY-MM-DD])
    └── Anciennes ADRs (0016-0026 renommées)
```

## 3 · Actions concrètes (liste ordonnée)

### P1 (critique, session prochaine)

1. **Créer DB Bugs** (UI Notion)
   - Propriétés minimales : Nom (title), Projet (relation → DB Projets), Severity (select : P0/P1/P2/P3), Statut (select : Open/Investigating/Fixed/Won't fix), Repro (text), Assigné (person)
   - Vue par défaut : groupé par Projet, trié par Severity
2. **Créer DB Dette technique** (UI Notion)
   - Propriétés : Nom, Projet (relation), Catégorie (select : Refactor/Docs/Tests/Security/Perf), Coût (select : XS/S/M/L/XL), Impact (select : Low/Med/High), Statut (Open/Planned/In progress/Closed)
3. **Ajouter 4 vues à DB Projets** (filtres) :
   - Portfolio dev · Travaux maison · Aménagement · Gelés+Archive

### P2 (hygiène workspace)

4. **Rapatrier les ADRs migrés dans "🗃️ Archive"** (pages [MIGRÉ 2026-04-20])
5. **Créer page "Migration ADRs → DECISIONS.md"** dans Wiki Engineering
   - Contenu : lien vers `shared-standards/docs/DECISIONS-MIGRATION-MAP.md`
   - Table : ancien ADR → nouveau repo/numéro
6. **Créer page "Convention DECISIONS.md"** dans Wiki Engineering
   - Règle "par-repo · D-XXXX local · jamais supprimer"
7. **Créer page "LifeOS V2 — visu Notion"** (D-0003 lifeos)
   - Reprendre le contenu de `lifeos/DECISIONS.md` D-0003

### P3 (nettoyage)

8. **Auditer DB Projets** : classifier chaque entrée en Portfolio dev / Travaux / Aménagement / Gelé
9. **Remplacer les 26 pages ADRs individuelles** par 1 page d'index pointant vers les DECISIONS.md repos
10. **Créer page "Portfolio public"** dans Home, lien vers `portfolio-public.html` (hébergement à décider)

## 4 · Scripts/API possibles

Ce qui peut être automatisé via l'API Notion (une fois les DBs créées UI) :
- Peupler DB Bugs depuis les issues GitHub ouvertes (script Python via `requests`)
- Importer `shared-standards/docs/DECISIONS-MIGRATION-MAP.md` comme page Notion
- Synchroniser les 4 vues DB Projets (update_data_source + create_view)

Limitations :
- Création DB from scratch avec schéma complet : à faire **en UI** (API unreliable)
- Création relations (rel properties) : UI only
- Setup des vues filtrées : partiel via API, toujours mieux en UI

## 5 · Estimation temps

| Phase | Effort |
| ----- | ------ |
| P1 (3 DBs + 4 vues) | 45 min UI |
| P2 (5 pages) | 30 min |
| P3 (audit + nettoyage) | 1 h |
| **Total** | **~2h15** |

## 6 · Dépendances

Aucune externe. Uniquement accès Notion admin.

## 7 · Risques

- Création de DB avec propriétés mal typées → nécessite refactor ultérieur → prendre le temps sur P1
- Casser des automations existantes (MCP Notion MCP config) → faire un snapshot avant
