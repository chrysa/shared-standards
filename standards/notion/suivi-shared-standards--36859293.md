---
fka_managed: true
source: notion
notion_id: 36859293-e35e-8161-bb7f-efa2a590710a
notion_url: https://app.notion.com/p/Suivi-shared-standards-36859293e35e8161bb7fefa2a590710a
notion_last_edited_time: 2026-06-28T20:18:00.000Z
---
# 📈 Suivi — shared-standards

<table_of_contents/>
> **📈 Suivi · shared-standards** · cadence : mise à jour à chaque session significative
---
## 🎯 État actuel · 2026-05-22
- **Phase courante** : V1 déployé, pré-tag v1.0.0
- **Statut** : 🔴 Dev (proche Prod)
- **Maturité** : 4 — déployé sur 32 repos actifs
- **Bloquant principal** : aucun — reste tag v1.0.0 + yamllint
- **Prochaine action** : publier le tag v1.0.0 stable
---
## 🗺️ Milestones
- [x] **V0 — Conventions de base** — templates CI/CD, pre-commit, labels · fait
- [x] **V1 — Déploiement** — 32 repos actifs, ADR-0009 + ADR-0013 · fait
- [ ] **v1.0.0 — Tag stable** — yamllint aligné + tag publié · ETA: 2026-Q3
- [ ] **Propagation file-sync** — `repo-file-sync-action` comme mécanisme unique + `sync.yml` segmenté + générateur Notion→sync · ETA: 2026-Q3
- [ ] **V2 — Observability standard** — OpenTelemetry composite action, docs mkdocs · ETA: 2026-Q4
---
## 📊 Métriques
<table header-row="true">
<tr>
<td>Métrique</td>
<td>Cible</td>
<td>Actuel</td>
<td>Date mesure</td>
</tr>
<tr>
<td>Repos consommateurs</td>
<td>tous</td>
<td>32 repos actifs</td>
<td>2026-05-22</td>
</tr>
<tr>
<td>Tag stable</td>
<td>v1.0.0</td>
<td>pré-tag</td>
<td>2026-05-22</td>
</tr>
<tr>
<td>Régressions CI cascade</td>
<td>0</td>
<td>0</td>
<td>2026-05-22</td>
</tr>
</table>
---
## 📝 Journal de bord
> Plus récent en haut.
### 2026-06-28 — Salvage WIP container-runtime
- **Fait** : WIP stashé de `chore/container-runtime-policy` (branche 2 commits derrière main, 0 commit propre) trié vs `main` — le commit #161 « sync chrysa shared standards » l'avait **largement supplanté**. Branche `chore/container-runtime-salvage` (commit d4b2a24) ne garde que le réellement nouveau : **dependabot grouping**, intégration **graphify** (mcp + hook PreToolUse), hygiène `.gitignore`.
- **Jeté (supplanté par main)** : ajouts `STANDARDS.chrysa.md` (No hardcoded constants / Semantic URLs déjà sur main) + `EXECUTION_STANDARD.md` (main a beaucoup évolué — réintroduire = régression).
- **Suivant** : décider push/PR de la branche salvage ; supprimer `stash@{0}` + vieille branche après validation.
### 2026-06-28 — Détection PII / RGPD (Presidio)
- **Contexte** : ajout d'une détection de données personnelles (PII) via Microsoft **Presidio**, en pre-commit **et** en CI. Complète les hooks sécurité existants (gitleaks, detect-private-key) qui ne couvraient que les secrets, pas les PII.
- **Branche** : `feature/pii-presidio-detection` (depuis `main`). Spec + plan dans `docs/superpowers/{specs,plans}/2026-06-28-pii-presidio-detection*`.
- **Périmètre** : package `scripts/pii/` (recognizers FR_NIR avec validation clé + FR_CNI, config `.pii-scan.toml`, allowlist par empreinte sha256, moteur Presidio), CLI `scripts/pii_scan.py` (`--all`, `--report`, `--selftest`, `--print-fingerprint`), hook pre-commit `pii-scan` (bloquant, modèles spaCy fr+en épinglés en wheels → hermétique), workflow CI `workflows/pii-scan.yml`. Hors périmètre : Semgrep privacy rules + Fides (gouvernance) → follow-ups.
- **Avancement** : ✅ TERMINÉ — toutes les tasks (0→8) faites + revues ; revue finale whole-branch (opus) = **MERGE-READY**. 22 tests verts, Ruff/Mypy clean, hook vérifié en env isolé.
- **Décisions** : `PERSON` et `FR_CNI` exclus des entités par défaut (NER bruyant / pattern 12 chiffres imprécis → opt-in, DECISIONS D-0006) ; CI = gate sur fichiers modifiés des PR + audit `--all` hebdo non bloquant (le `--all` complet trop lent + flaggerait la PII pré-existante) ; `click` épinglé (typer-slim ne le tire plus).
- **PR** : [#164](https://github.com/chrysa/shared-standards/pull/164) ouverte → `main`, clôt l'issue #163.
- **Suivant** : merge après CI verte. Follow-ups Minor : normalisation chemins du fingerprint (fiabilité allowlist), scan multi-langue, exclure `.git` du `--all`.
### 2026-06-14 — Bascule propagation → file-sync
- **Décidé** : `repo-file-sync-action` devient LE mécanisme de propagation des standards (remplace les reusable workflows / référence centrale). Les fichiers standards sont **copiés** dans chaque repo via PR auto → cohérent avec la règle transversale « les configs k3s vivent DANS chaque projet » (plug'n'play) actée ce jour.
- **À faire** : (1) workflow `sync-standards.yml` + `sync.yml` dans shared-standards ; (2) segmentation par groupes (Socle/Actif/Opportuniste, déployé-k3s vs non, landing Pages = universelle) ; (3) script Notion→`sync.yml` générant les listes de repos depuis la DB canonique via propriétés projet ; (4) PAT `SYNC_PAT` en secret org.
- **Suivant** : implémenter le squelette + premier groupe pilote.
### 2026-06-10 — Passe Django / standards compliance
- **Fait** : `copilot-instructions/django.md` créé (PR #98) — il n'existait AUCUN standard Django écrit. `guideline-checker` détecteurs Django + `django.instructions.md` (PR #120, 327 tests verts). [CLAUDE.md](http://CLAUDE.md) remédiés sur 6 repos : django-autoload (#16, +Makefile), django-traceid (#21), fastapi-autoload/pytest/query-optimizer/traceid (#3 chacun). **8 PRs mergées.**
- **Corrigé (audit 2026-06-06)** : django-autoload n'est PAS « config-only EXEMPT » (vraie lib Django) ; `hatchling` autorisé pour les libs (pas une violation) ; plancher Python 3.12 sur lib = support multi-version intentionnel, pas du drift.
- **Décidé** : `lifeos` canonique → archiver `chrysa/my-assistant` (même projet, 2 repos) ; LICENSE → ajouter MIT fleet-wide (37 repos).
- **Suivant** : [CLAUDE.md](http://CLAUDE.md) restants (feedback-gateway, dotfiles, game-solver-platform, pre-commit-hooks-changelog) ; migrations layout flat→src (django-app-forge/pytest/traceid) ; exécuter décisions. Détails → section 6 de l'audit ci-dessous.
### 2026-05-22 — Fiche structurée
- **Fait** : fiche mise en conformité standard OSS (Features V1, Études faisabilité+technique Done, Suivi, Gate)
- **Décidé** : faisabilité + technique 🟢 Done (32 repos en prod prouvent la viabilité)
- **Suivant** : publier tag v1.0.0 stable
<page url="https://app.notion.com/p/37759293e35e817d99dbd03eb5030ccf">🔎 Standards Compliance Audit — 59 repos (2026-06-06)</page>
<page url="https://app.notion.com/p/3a859293e35e81449284c173edd458ab">🔎 Audit unifié profond — 70 dépôts (2026-07-24)</page>
