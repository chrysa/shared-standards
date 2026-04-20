# PRD — {{NOM_PROJET}} (version {{V1}})

> Product Requirements Document · cadrage avant démarrage sprint 1
> Auteur : chrysa · Date : YYYY-MM-DD · Statut : Draft / Review / Approved

---

## 1 · Problème

{{Quel problème on résout. 3 phrases max. Qui souffre aujourd'hui ? Comment ils compensent ?}}

## 2 · Utilisateur cible

- Primaire : {{profil + volume estimé}}
- Secondaire : {{si applicable}}

## 3 · Value proposition (1 phrase)

> {{NOM_PROJET}} permet à {{utilisateur}} de {{bénéfice principal}} sans {{effort/friction évitée}}.

## 4 · Scope V1 (IN)

- [ ] {{feature}}
- [ ] {{feature}}

## 5 · Scope V1 (OUT) — à ne PAS faire

- {{feature}} — raison : {{…}}
- {{feature}} — raison : {{…}}

## 6 · Success metrics (V1)

| Métrique | Cible V1 | Cible V2 | Outil |
| -------- | -------- | -------- | ----- |
| | | | |

## 7 · Stack cible (adhérence CLAUDE.md global)

- Backend : {{Python 3.14 / FastAPI ≥0.115 / …}}
- Frontend : {{React 19 + TS + Vite 6 + shadcn/ui + Tailwind}}
- DB : {{PostgreSQL 16 + Redis 7}}
- Auth : {{4 modes chrysa-lib}}
- i18n : FR + EN
- Dark mode : obligatoire

## 8 · Dépendances amont

- chrysa-lib/auth : {{requis | pas requis}}
- Autres repos chrysa : {{…}}
- Services externes : {{…}}

## 9 · Bloqueurs techniques identifiés

| Bloqueur | Probabilité | Impact | Mitigation |
| -------- | ----------- | ------ | ---------- |
| | | | |

## 10 · Budget estimé

| Phase | Effort (h solo dev) | Coût infra annuel | Coût SaaS annuel |
| ----- | ------------------- | ----------------- | ---------------- |
| V0 prototype | | | |
| V1 MVP | | | |
| V1.x stabilisation | | | |

## 11 · Risques + plan B

- {{risque}} → {{plan B}}

## 12 · Plan de livraison (phases)

- Phase 1 ({{durée}}) : {{livrable 1}}
- Phase 2 ({{durée}}) : {{livrable 2}}
- Phase 3 ({{durée}}) : {{livrable 3}}

## 13 · Décisions clés (référence DECISIONS.md du repo)

- D-XXXX : {{décision}}

---

## Approbation

- [ ] Problème validé
- [ ] Scope V1 tranché (IN + OUT)
- [ ] Métriques définies
- [ ] Budget accepté
- [ ] Bloqueurs identifiés + mitigations
- [ ] Prêt à démarrer Sprint 1
