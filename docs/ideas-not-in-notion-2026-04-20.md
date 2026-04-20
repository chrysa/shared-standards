# Idées session 2026-04-20 non présentes dans Notion

> Revue de conversation session 2026-04-20.
> Sont listées ici les décisions, patterns, idées produites durant la session qui **n'ont pas encore de page Notion dédiée**.
> À reporter manuellement ou via batch Notion quand pertinent.

---

## 1 · Abandon du système ADR → DECISIONS.md par repo

**Contexte** : les 26 ADRs étaient dispersés (fichiers disque + pages Notion + refs CLAUDE.md). Conflits latents (ADR-0014 vs 0026, 0015 vs 0024).

**Décision** : remplacé par `DECISIONS.md` **local à chaque repo**, numérotation D-XXXX indépendante. Conventions transverses restent dans `CLAUDE.md` global.

**À reporter Notion** : créer une page "Convention Décisions — D-XXXX par repo" dans Wiki Engineering chrysa, avec lien vers `shared-standards/docs/DECISIONS-MIGRATION-MAP.md`.

---

## 2 · Hook local `validate-prompt.py`

**Contexte** : article plume-ecriture.fr analysé → 10 critères pondérés pour valider un prompt Claude (rôle, contexte, objectif, structure, ton, exemples, contraintes, format, longueur, anti-patterns).

**Livrable** : `shared-standards/scripts/validate-prompt.py` + `README-hooks.md`.

**À reporter Notion** : section "Hooks locaux" dans Wiki Engineering ou Skills, référence `validate-prompt.py`.

---

## 3 · Hook local `dev-run.sh` (runner unifié)

**Contexte** : un seul binaire pour lint/test/format/quality/app sur n'importe quel repo. Détection auto stack (Python/Node/Go/Rust/Django/Docker/Makefile), priorité Makefile > stack natif > Docker.

**Livrable** : `shared-standards/scripts/dev-run.sh`.

**À reporter Notion** : idem (section Hooks locaux).

---

## 4 · Convention auto-rollback vs auto-commit+push

**Contexte** : différenciation claire dans la pipeline d'uniformisation :
- Repos destinés à l'archivage → **rollback automatique** (`git checkout -- . && git clean -fd`) avant mv local vers `_archived/`
- Repos actifs dirty → **auto-commit + push** (message `chore: auto-commit via fix-all YYYY-MM-DD`), skip branches default `main`/`master`/`develop` sauf `--include-default`

**Livrable** : patches dans `archive-obsolete-repos.sh`, `archive-merged-repos.sh`, réécriture de `repos-push-pending.sh`.

**À reporter Notion** : pattern "Git safety protocol — pipeline uniformisation" dans Wiki Engineering.

---

## 5 · Portfolio interne vs externe (filtrage `--external`)

**Contexte** : scope clarifié durant la session :
- **Interne** : tout le portefeuille chrysa (hors padam), **incluant travaux + aménagement Notion**
- **Externe** : version à transmettre aux externes → **exclut travaux + aménagement + outillage interne**

**Livrable** : `generate-portfolio-html.sh --external` avec liste `EXCLUDE_EXTERNAL`.

**À reporter Notion** : scope des deux vues dans page "Portfolio public chrysa".

---

## 6 · Idée lifeos — visualisation Notion ergonomique (D-0003)

**Contexte** : ajoutée cette session dans `lifeos/DECISIONS.md`. Couche de visu au-dessus de Notion + option de découplage V2 vers PostgreSQL local.

**À reporter Notion** : créer une page "LifeOS — visu Notion + découplage V2" dans la DB Projets (rôle Actif ou Opportuniste selon priorité).

---

## 7 · D-0026 · ADR-0014 révoqué (pas de chrysa-workstation)

**Contexte** : fusion `windows-autonome` + `agent-config` → `chrysa-workstation` annulée. Les 2 repos restent Socle.

**Statut Notion** : ✅ déjà présent (page ADR-0026 créée, ligne DB Projets `chrysa-workstation` marquée [ANNULÉ ADR-0026]).

---

## 8 · Idées / inflexions détectées mais **non actées**

Listées ici pour décision ultérieure. À trancher + créer ADR local ou déplacer ici vers "actées" :

- **Option découplage Notion → PostgreSQL local** (V2 lifeos) — pas de date cible, pas de budget estimé
- **`prompt-optimizer` comme module ai-aggregator** (D-0001 ai-aggregator) — pas encore commencé, position d'attente
- **`auto-PR-handler` workflow** (D-0005 shared-standards) — pré-requis GitHub MCP non configuré
- **Monitoring stack Prometheus+Grafana+Loki+Qdrant** (D-0001 server) — ~4 Go RAM à budgéter, pas de date
- **Fusions non-exécutées** : `linkendin-resume`+`my-resume`→`resume`, `coaching-sport`+`coaching-guitare`→`coaching-tracker`, `guideline-checker`→package shared-standards — sont listées comme décidées mais pas faites

---

## 9 · Patterns techniques nouveaux documentés (hors Notion)

- **Git safety protocol pipeline** — différenciation archive-targets vs active
- **Portfolio dual-mode** — `--external` avec filtre EXCLUDE
- **Validateur prompt** — 10 checks pondérés FR+EN avec anti-patterns
- **Runner unifié** — priorité Makefile > natif > Docker
- **Auto-commit safe** — skip branches défaut sauf opt-in

---

## Décision à prendre

Pour chacun des 9 points ci-dessus, 3 options :
1. Créer une page Notion dédiée (Wiki Engineering ou DB appropriée)
2. Intégrer dans une page existante
3. Ignorer (info mineure, reste sur disque suffit)

Recommandation : **1-2 pages Notion maximum** — ne pas répliquer tout sur Notion au risque de recréer la dispersion qu'on vient de simplifier. Candidats prioritaires : points 1 (convention DECISIONS.md) et 6 (idée lifeos visu Notion).
