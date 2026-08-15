---
fka_managed: true
source: notion
notion_id: 37c59293-e35e-8153-8d2d-cca0d5c791e4
notion_url: https://app.notion.com/p/shared-standards-Observability-standard-OpenTelemetry-vendor-neutral-Datadog-POC-37c59293e35e81538d2dcca0d5c791e4
notion_last_edited_time: 2026-07-25T10:44:00.000Z
---
# [shared-standards] Observability standard — OpenTelemetry vendor-neutral + Datadog POC

## Objectif
Créer le standard d’observabilité transverse et exécutable de l’écosystème chrysa. Les projets doivent produire une télémétrie OpenTelemetry portable vers Prometheus, Grafana, Loki, Tempo, Mirador et, facultativement, Datadog.
Référence : <mention-page url="https://app.notion.com/p/3a859293e35e8128ac1ec0669798fbf3"/>
## Périmètre
- standard `OBSERVABILITY_STANDARD.md` ;
- conventions de nommage et attributs communs ;
- instrumentation Python, TypeScript et C# ;
- OpenTelemetry Collector gateway ;
- logs JSON et propagation W3C Trace Context ;
- redaction, allowlists, sampling et contrôle de cardinalité ;
- exports Prometheus/Loki/Tempo ;
- exporter Datadog désactivé par défaut ;
- tests CI et règles `guideline-checker` ;
- POC comparatif LOGOS/Paperclip + n8n + PostgreSQL/Redis/Qdrant.
## Livrables
- [ ] `standards/OBSERVABILITY_STANDARD.md`
- [ ] `templates/observability/otel-collector.yaml`
- [ ] profil Python avec instrumentation FastAPI/Django/workers
- [ ] profil TypeScript avec Node/HTTP/workers
- [ ] profil C# avec [ASP.NET](http://ASP.NET) Core/workers
- [ ] processors de redaction et allowlist
- [ ] exemples logs structurés et corrélation trace/log
- [ ] dashboard Grafana de référence
- [ ] exporter Datadog facultatif documenté
- [ ] règle CI interdisant une dépendance Datadog directe non approuvée
- [ ] règles exécutables dans `guideline-checker`
- [ ] rapport du POC avec coûts, surcharge et temps de diagnostic
## Attributs minimums
```yaml
service.name: required
service.namespace: required
service.version: required
deployment.environment: required
chrysa.project: required
chrysa.component: required
chrysa.owner: required
correlation.id: required
workflow.id: optional
workflow.run_id: optional
agent.id: optional
agent.role: optional
task.id: optional
```
## Scénarios du POC
1. agent en boucle ;
2. erreur d’un outil MCP ;
3. latence PostgreSQL ou Redis ;
4. dépassement de budget LLM ;
5. fallback de provider ;
6. tentative d’export d’une donnée sensible ;
7. indisponibilité de Datadog ;
8. indisponibilité partielle du Collector.
## Critères d’acceptation
- zéro secret ou donnée personnelle exportée ;
- zéro dépendance Datadog dans le domaine métier ;
- retrait de Datadog sans réinstrumentation ;
- fonctionnement nominal sans Internet ;
- corrélation traces, métriques et logs fonctionnelle ;
- surcharge CPU/RAM mesurée ;
- coûts projetés documentés ;
- incidents injectés diagnostiqués dans Grafana/Mirador et Datadog ;
- décision finale documentée par ADR.
## Kill-test
Abandonner l’intégration Datadog permanente si elle impose un SDK propriétaire, rend les coûts imprévisibles, reçoit une donnée sensible, devient nécessaire au fonctionnement ou n’apporte aucune capacité décisive face à Grafana + Mirador.
