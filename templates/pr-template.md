<!--
⚠️ Règle chrysa : TOUTE PR en cours de traitement doit être liée à une issue.
   Pas d'issue = pas de PR (exception : hotfix urgent avec justification explicite).
   Lien via "Closes #N", "Fixes #N", "Refs #N" ou "Part of #N".
-->

## Summary
<!-- Briefly describe what this PR does -->

## Linked issue (OBLIGATOIRE)
<!-- Format : Closes #N · Fixes #N · Refs #N · Part of #N -->

Closes #

<!-- Si aucune issue n'existe, en créer une AVANT de continuer.
     Exception hotfix : ajouter label "hotfix" + justification ci-dessous -->

## Motivation
<!-- Why is this change needed? Quick context. -->

## Changes
<!-- List the changes made -->

## Dependencies
<!-- PRs this depends on (if any). Format: depends on chrysa/REPO#NUMBER -->

## Testing
<!-- How was this tested? -->

## Checklist

- [ ] Issue GitHub liée (Closes #N)
- [ ] Conventional commit messages (`feat:`, `fix:`, `chore:`, …)
- [ ] Pre-commit hooks pass locally (`make quality`)
- [ ] Tests écrits et passants (`make tests`)
- [ ] Coverage ≥ 85% sur le module modifié
- [ ] CI verte
- [ ] README / DECISIONS / ROADMAP mis à jour si applicable
- [ ] Pas de secret ou credential commité
