---
fka_managed: true
source: notion
notion_id: 38d59293-e35e-81bc-a2c6-ce36b8da7e4f
notion_url: https://app.notion.com/p/Standard-Makefile-homog-n-is-r-f-rentiel-base-makefile-nommage-canonique-typecheck-38d59293e35e81bca2c6ce36b8da7e4f
notion_last_edited_time: 2026-07-06T16:46:00.000Z
---
# Standard Makefile homogénéisé — référentiel base-makefile + nommage canonique typecheck

## Contexte
Audit d'homogénéité Makefile sur **61 repos chrysa** vs le référentiel `Forge-Stack-Workshop/base-makefile`.
**Constat clé** : les noms de cibles sont déjà homogènes (56/61 utilisent `typecheck`, 0 utilisent `type-check`). La vraie dérive est : docs ↔ Makefile désynchronisés (`make type-check` documenté alors que la cible est `typecheck`), adoption inégale des cibles optionnelles (`format-check` 5/61, `quality-gate-verify` 21/61, `ci` 22/61), et référentiel lui-même incomplet entre ses 3 variantes.
## Décision figée
Nommage canonique = **suivre base-makefile** → `typecheck` (un mot, jamais `type-check`), `test-cov`, `format-check`, `quality-gate-verify`, `docker-test`, `ci`. Aliasing interdit. Socle de cibles obligatoire pour tout repo applicatif.
## PRs ouvertes (en review)
- **shared-standards #162** — section `## Makefile targets` ajoutée à la source des standards · Refs #165 · check `issue-link` ✅ → [https://github.com/chrysa/shared-standards/pull/162](https://github.com/chrysa/shared-standards/pull/162)
- **guideline-checker #181** — fix doc `make type-check` → `typecheck` · Refs #182 → [https://github.com/chrysa/guideline-checker/pull/181](https://github.com/chrysa/guideline-checker/pull/181)
- **linkendin-resume #243** — fix doc `make type-check` → `typecheck` (README) · Refs #244 → [https://github.com/chrysa/linkendin-resume/pull/243](https://github.com/chrysa/linkendin-resume/pull/243)
## Prochaines étapes
1. Merger #162, puis lancer `shared-standards/scripts/distribute-standards.sh` pour propager le standard aux 61 `.chrysa/STANDARDS.md`.
2. Compléter le référentiel `base-makefile` (porter `format-check` + `quality-gate-*` dans `Makefile.basic` et `Makefile.with-sub-folder`).
3. Propager le socle de cibles sur les repos applicatifs Python (hors exceptions infra/config/docs).
*Audit complet : **`chrysa/AUDIT-MAKEFILE-HOMOGENEITY-2026-06-28.md`*
