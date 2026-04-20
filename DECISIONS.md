# DECISIONS.md — shared-standards

> Décisions **scopées à ce repo uniquement** (shared-standards).
> Pour les conventions transverses (Python 3.14, stack, règle 1+2…) → `~/.claude/CLAUDE.md`.
> Pour les décisions d'un autre repo → `<autre-repo>/DECISIONS.md`.
>
> Dernière maj : 2026-04-20

---

## Convention

- Fichier **local à chaque repo** — pas de DECISIONS.md global
- Numérotation : `D-XXXX` **locale au repo** (chaque repo a sa propre séquence)
- États : **ACTIF** · **SUPERSEDED par D-XXXX** · **RETIRED**
- Jamais supprimer, seulement marquer SUPERSEDED
- Décisions transverses (stack, règle 1+2) restent dans `CLAUDE.md` global (pas d'ADR)

---

## Décisions actives

| #      | Date       | Décision                                                                  | État  |
| ------ | ---------- | ------------------------------------------------------------------------- | ----- |
| D-0001 | 2026-04-01 | Fusion `github-actions` → `shared-standards` (un seul repo CI+conventions) | ACTIF |
| D-0002 | 2026-04-01 | Fusion `pre-commit-hooks-changelog` → `pre-commit-tools`                   | ACTIF |
| D-0003 | 2026-04-01 | `project-init` devient package `shared-standards/packages/project-init/`   | ACTIF |
| D-0004 | 2026-04-18 | `guideline-checker` devient package `shared-standards/packages/` (D-0003) | ACTIF |
| D-0005 | 2026-04-18 | auto-PR-handler workflow (GH Actions + Claude Code agent, labels `auto-handle`/`blocked-by`) | ACTIF |

---

## D-0005 — détail

**Contexte** : Automatiser la chaîne "issue ouverte → PR draft générée → review humaine → merge → déblocage des issues dépendantes".

**Décision** : pattern réutilisable hébergé dans `shared-standards` (ex-`chrysa/github-actions`, fusionné D-0001) :

1. Issue ouverte avec label `auto-handle`
2. Workflow trigger → Claude Code agent génère une PR draft sur le repo source
3. PR contient : analyse + implémentation + tests + docstring
4. User review → approve
5. Merge → webhook ferme issues dépendantes (link via GitHub Closes/Fixes)
6. Si l'issue était `blocked-by`, retire le blocage automatiquement

**Convention labels** : `auto-handle`, `blocked-by:<repo>#<issue>`, `blocks:<repo>#<issue>`.

**Pré-requis** :
- GitHub MCP UP (P0)
- prompt-optimizer livré (ai-aggregator/DECISIONS.md D-0001)
- Convention labels déployée sur tous repos chrysa

**Conséquences** :
- 🟢 Déblocage automatique des chaînes de dépendances
- 🟢 Réduction lag entre repos
- 🟡 Risque PR low-quality sans review systématique → review **obligatoire**
- 🟡 Coût tokens Claude élevé si non rate-limité → `prompt-optimizer` en amont

---

## Décisions superseded

Aucune pour l'instant dans ce repo.

---

## Template nouvelle décision

```markdown
## D-XXXX — Titre court

**Date** : YYYY-MM-DD
**État** : ACTIF

**Contexte** : 1-3 phrases.

**Décision** : verdict court.

**Justification** : bullets.

**Conséquences** :
- 🟢 …
- 🟡 …
```
