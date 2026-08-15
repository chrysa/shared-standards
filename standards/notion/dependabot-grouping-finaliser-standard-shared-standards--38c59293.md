---
fka_managed: true
source: notion
notion_id: 38c59293-e35e-8176-8548-e0ed31f8e344
notion_url: https://app.notion.com/p/Dependabot-grouping-finaliser-le-standard-shared-standards-38c59293e35e81768548e0ed31f8e344
notion_last_edited_time: 2026-07-06T16:46:00.000Z
---
# Dependabot grouping — finaliser le standard (shared-standards)

Suite de l'audit Dependabot grouping (2026-06-27) — cf. [ADR-CHRYSA-2026-18](https://app.notion.com/p/38c59293e35e8122bdbdd8c0f686e314).
**État** : 61/62 repos canoniques conforment au grouping ; `pre-commit-hooks-changelog` corrigé. 3 restes, tous dans `shared-standards` :
- [x] Aligner la `.github/dependabot.yml` *propre* de shared-standards sur son template groupé (github-actions groupé + pre-commit). Bloqué en session par le guard bgIsolation → à faire en worktree/local.
- [x] Documenter le grouping comme exigence explicite dans `EXECUTION_STANDARD.md` (« groups: bundle related updates »).
- [x] Ajouter un check `dependabot-grouping` à `audit-standards.sh` (ne vérifie pas dependabot aujourd'hui).
---
**MAJ 2026-06-27** : les 3 correctifs sont appliqués dans le working tree, **non commités/poussés** (shared-standards sur branche `chore/container-runtime-policy`). Audit `audit-standards.sh` (nouvelle colonne `dependabot_grp`) : **0 violation** — 61 repos groupés + 4 repos config sans dependabot. Reste à commiter/pousser shared-standards + propager le template si besoin.
