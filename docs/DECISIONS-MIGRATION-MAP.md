# DECISIONS — Migration map (2026-04-20)

> L'ancien système ADR (0001 → 0026) est démantelé.
> Chaque décision migre vers le fichier `DECISIONS.md` du repo concerné.
> Décisions transverses (stack, règles portfolio) **restent dans** `~/.claude/CLAUDE.md` — pas d'ADR.

---

## Règles de migration

1. Une décision impacte **un seul repo** → `<repo>/DECISIONS.md`
2. Une décision impacte **plusieurs repos** → le repo "pivot" (celui qui change le plus) + lien croisé dans les autres
3. Une décision = **convention universelle** (Python 3.14, i18n FR+EN, auth 4 modes, règle 1+2…) → reste dans `CLAUDE.md` global, pas de DECISIONS.md
4. Les numéros `D-XXXX` sont **locaux à chaque repo** (séquence indépendante)

---

## Tableau de migration

| Ancien ADR   | Titre                                                      | Destination                                                       | Nouveau #       |
| ------------ | ---------------------------------------------------------- | ----------------------------------------------------------------- | --------------- |
| ADR-0001     | Python 3.14 cible universelle                              | `CLAUDE.md` global (convention stack)                              | —               |
| ADR-0002     | chrysa-lib = prérequis absolu                              | `CLAUDE.md` global (règle portfolio)                               | —               |
| ADR-0003     | i18n FR+EN dès V1                                          | `CLAUDE.md` global (convention)                                    | —               |
| ADR-0004     | Auth 4 modes                                               | `chrysa-lib/DECISIONS.md` (scope auth du socle)                    | D-0001 local    |
| ADR-0005     | LifeOS = my-assistant (même repo)                          | `my-assistant/DECISIONS.md`                                        | D-0001 local    |
| ADR-0006     | DEV Nexus V1 inclut AI prioritization                      | `dev-nexus/DECISIONS.md`                                           | D-0001 local    |
| ADR-0007     | Discordium V3 : Godot retiré                               | `discordium/DECISIONS.md`                                          | D-0001 local    |
| ADR-0008     | Architecture Hybrid Notion + my-assistant                  | `my-assistant/DECISIONS.md`                                        | D-0002 local    |
| ADR-0009     | Fusion github-actions → shared-standards                    | `shared-standards/DECISIONS.md`                                    | D-0001 ✅        |
| ADR-0010     | Fusion pre-commit-hooks-changelog → pre-commit-tools       | `shared-standards/DECISIONS.md` (pivot) + `pre-commit-tools` link | D-0002 ✅        |
| ADR-0011     | Fusion linkedin-resume + my-resume → resume (frozen)       | `resume/DECISIONS.md`                                              | D-0001 local    |
| ADR-0012     | Fusion coaching-sport + coaching-guitare → coaching-tracker | `coaching-tracker/DECISIONS.md`                                    | D-0001 local    |
| ADR-0013     | project-init → shared-standards/packages/                  | `shared-standards/DECISIONS.md`                                    | D-0003 ✅        |
| ADR-0014 ❌  | Fusion windows-autonome + agent-config → chrysa-workstation | SUPERSEDED (voir ADR-0026 ci-dessous)                              | —               |
| ADR-0015 ❌  | CodeDoc AI absorbé dans doc-gen                            | SUPERSEDED (voir ADR-0024 ci-dessous)                              | —               |
| ADR-0016     | guideline-checker = package shared-standards               | `shared-standards/DECISIONS.md`                                    | D-0004 ✅        |
| ADR-0017     | SAT multi-jeu = Opportuniste                               | `satisfactory-assistant/DECISIONS.md`                              | D-0001 local    |
| ADR-0018     | prompt-optimizer = module ai-aggregator                    | `ai-aggregator/DECISIONS.md`                                       | D-0001 local    |
| ADR-0019     | Monitoring local-first (Prometheus+Grafana+Loki+Qdrant)    | `server/DECISIONS.md`                                              | D-0001 local    |
| ADR-0020     | auto-PR-handler workflow                                   | `shared-standards/DECISIONS.md` (pattern CI réutilisable)          | D-0005 à créer  |
| ADR-0021     | Adopt tommy-ca/notion-skills (selective)                   | `chrysa-workstation/DECISIONS.md` OR `shared-standards` skills/    | D-0001 local    |
| ADR-0022     | Unity Dev Toolkit DEFERRED                                 | `discordium/DECISIONS.md`                                          | D-0002 local    |
| ADR-0023     | (non attribué)                                             | —                                                                 | —               |
| ADR-0024     | doc-gen séparé de CodeDoc AI (révise ADR-0015)             | `doc-gen/DECISIONS.md`                                             | D-0001 local    |
| ADR-0025     | resume frozen (confirme ADR-0011)                          | `resume/DECISIONS.md`                                              | D-0002 local    |
| ADR-0026     | windows-autonome + agent-config séparés (révoque ADR-0014) | `windows-autonome/DECISIONS.md` + `agent-config/DECISIONS.md`      | D-0001 chacun   |

✅ = déjà migré dans `shared-standards/DECISIONS.md`
❌ = SUPERSEDED (pas de migration, conservé pour historique uniquement)

---

## Actions concrètes restantes (par priorité)

### P1 — repos actifs qui ont des décisions propres
- [ ] `chrysa-lib/DECISIONS.md` — ADR-0004 (auth 4 modes, scope socle)
- [ ] `dev-nexus/DECISIONS.md` — ADR-0006 (AI prioritization V1)
- [ ] `doc-gen/DECISIONS.md` — ADR-0024 (séparation CodeDoc AI)
- [ ] `my-assistant/DECISIONS.md` — ADR-0005 + ADR-0008 (LifeOS + Hybrid)
- [ ] `my-fridge/DECISIONS.md` — si décisions scope FridgeAI

### P2 — repos opportunistes
- [ ] `discordium/DECISIONS.md` — ADR-0007 (Godot retiré) + ADR-0022 (Unity deferred)
- [ ] `ai-aggregator/DECISIONS.md` — ADR-0018 (prompt-optimizer)
- [ ] `server/DECISIONS.md` — ADR-0019 (monitoring stack)
- [ ] `satisfactory-assistant/DECISIONS.md` — ADR-0017 (multi-jeu scope)

### P3 — repos Socle (workstation)
- [ ] `windows-autonome/DECISIONS.md` — ADR-0026 (séparation actée)
- [ ] `agent-config/DECISIONS.md` — ADR-0026 (séparation actée) + ADR-0021 (notion-skills)

### P4 — repos frozen / historique uniquement
- [ ] `resume/DECISIONS.md` — ADR-0011 + ADR-0025 (frozen confirmé)
- [ ] `coaching-tracker/DECISIONS.md` — ADR-0012 (fusion sport+guitare)

---

## Notion — ménage après migration

Les pages Notion suivantes existent et **peuvent être archivées** (plus source vérité) :

| Page Notion                                                       | ID                                    | Action                           |
| ----------------------------------------------------------------- | ------------------------------------- | -------------------------------- |
| 📝 ADRs 0016 → 0020                                              | 34659293-e35e-8151-95e0-dc1c1acdb7d1 | Archive + note "migré DECISIONS" |
| ADR-0021 — tommy-ca/notion-skills                                | 34659293-e35e-811a-bc82-f823a837b995 | Archive + note                    |
| ADR-0022 — Unity Dev Toolkit DEFERRED                            | 34659293-e35e-81a0-b8cd-d2d280d8794e | Archive + note                    |
| ADR-0024 — doc-gen séparé de CodeDoc AI                          | 34759293-e35e-8189-ab01-f1945f8181ec | Archive + note                    |
| ADR-0025 — resume frozen                                          | 34759293-e35e-8181-a2ed-dc00cc67cdd7 | Archive + note                    |
| ADR-0026 — windows-autonome/agent-config séparés                 | 34859293-e35e-814e-9ce5-c78f3b9e244c | Archive + note                    |

**Ne pas supprimer** — archiver avec mention "Source vérité migrée vers `<repo>/DECISIONS.md` le 2026-04-20".

---

## Patch CLAUDE.md global

Déjà fait : la section `## ◈ ADRs ACTÉS` a été remplacée par `## ◈ DÉCISIONS` pointant vers `shared-standards/DECISIONS.md`.

⚠️ **À corriger** : CLAUDE.md global pointe actuellement vers `shared-standards/DECISIONS.md` comme source vérité unique — ce n'est plus exact. Il faut :
- Soit conserver un mini-index dans CLAUDE.md (D-0001 → D-0026 avec le repo destinataire)
- Soit pointer vers ce fichier de migration pour la traçabilité
