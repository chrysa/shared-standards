# ADR-0016 — Guardrails AI dans DEV Nexus

- **Date** : 2026-04-19
- **Statut** : Proposé
- **Décideurs** : @chrysa
- **Scope** : dev-nexus, lifeos, ai-aggregator (tout service qui parle à Claude API ou Ollama)

## Contexte

DEV Nexus V1 intègre plusieurs chemins LLM :

- **Priorisation AI** : NL → ticket structuré (titre, description, priorité, labels)
- **Génération briefings** : synthèse SonarCloud + GitHub state
- **Q&A chatbot** (phase 2) : questions sur repos, CI, incidents

Stack actée : FastAPI 0.115 + Pydantic v2 + Claude API (primary) + Ollama (fallback) + PydanticAI (structured outputs) + LangGraph (stateful orchestration).

Pydantic valide la **structure** des outputs, PydanticAI enveloppe mais n'adresse pas :

- Fuites PII involontaires (emails clients dans tickets, noms collaborateurs)
- Fuites secrets (API key, tokens apparus dans génération)
- Dérive topique (priorisation qui parle d'autre chose)
- Hallucinations (moins critique ici — DEV Nexus opère sur données observables)
- Prompt injection (moins critique — cockpit interne auth'd)

## Décision

**Intégrer Guardrails AI** en couche de sécurité au-dessus de PydanticAI.

Package : `guardrails-ai` (+ `pydantic-ai-guardrails` pour l'intégration).

### Validators P0 (sprint d'intégration, ~4 h)

| Validator              | Application                                   | Mode    |
| ---------------------- | --------------------------------------------- | ------- |
| `valid-json`           | Toute sortie structurée (ticket, briefing)    | exception |
| `detect-pii` (Presidio) | Ticket generation, briefing (redact)         | redact  |
| `no-secrets-present`   | Tout output qui sera stocké ou affiché       | redact  |
| `topic-restriction`    | Priorisation AI (limite aux domaines chrysa) | exception |

### Validators P1 (sprint +1)

- `detect-jailbreak` (quand chatbot Q&A arrive en phase 2)
- `bias-check` (si briefings touchent des personnes nommées)

### Validators différés (coût vs gain)

- `hallucination` (Wiki Provenance) : trop coûteux, DEV Nexus parle données observables
- `competitor-check` : pas pertinent solo-dev portfolio

## Conséquences

### Positives

- Defense in depth sur les outputs LLM (+50-150 ms latence acceptée)
- Conformité RGPD si DEV Nexus stocke des tickets AV (PII client)
- Sécurité des credentials même si prompts/contexte compromis
- Hub de validators réutilisables (70+ disponibles)
- Alignement naturel avec Pydantic v2 (pas de duplication)

### Négatives

- +1 dépendance Python (guardrails-ai + presidio)
- +50-150 ms latence par appel LLM
- Nécessite tests unitaires par validator (mock Guard.validate)
- Hub communautaire variable en qualité (pin les validators officiels)

### Neutres

- Impact CI faible (Guardrails ship des tests unitaires)
- Rollback facile (désactiver Guard via feature flag)

## Architecture de référence

```python
# dev_nexus/core/guards.py
from functools import lru_cache
from guardrails import Guard
from guardrails.validators import ValidJSON, DetectPII, NoSecrets, TopicRestriction
from pydantic import BaseModel

class TicketOutput(BaseModel):
    title: str
    description: str
    priority: str
    labels: list[str]

@lru_cache(maxsize=1)
def get_ticket_guard() -> Guard:
    return Guard.from_pydantic(
        TicketOutput,
        validators=[
            ValidJSON(on_fail="exception"),
            DetectPII(redact=True, on_fail="fix"),
            NoSecrets(redact=True, on_fail="fix"),
            TopicRestriction(
                valid_topics=[
                    "software", "github", "sonarcloud",
                    "ci", "deployment", "incident"
                ],
                on_fail="exception",
            ),
        ],
    )
```

Usage inside a PydanticAI agent :

```python
from pydantic_ai import Agent
from pydantic_ai_guardrails import GuardrailsWrapper

agent = Agent(
    "claude-sonnet-4-6",
    result_type=TicketOutput,
    system_prompt="...",
)
guarded_agent = GuardrailsWrapper(agent, guard=get_ticket_guard())

result = await guarded_agent.run(user_prompt)
```

## Alternatives considérées

| Outil | Verdict | Raison |
| ----- | ------- | ------ |
| NeMo Guardrails (NVIDIA) | ❌ | Lourd pour API structurée (Colang DSL) — utile si chatbot avéré |
| Lakera Guard | ❌ | Vendor lock cloud, coût/appel, budget limité |
| LLM Guard | ⚠️ Fallback | Self-hosted gratuit, moins polished |
| AWS Bedrock Guardrails | ❌ | Pas applicable (Claude API non Bedrock) |

## Métriques de succès

- Aucun PII détecté dans tickets générés (sur 1 mois post-intégration)
- Aucun secret fuité dans briefings
- Latence p95 < 2 s sur endpoint `POST /api/v1/tickets/suggest`
- Coverage tests guards > 90 %

## Plan d'exécution

1. Sprint S4+1 (après DEV Nexus V1 cockpit) : ajouter `guardrails-ai` à pyproject
2. Créer `dev_nexus/core/guards.py` + tests
3. Wrap les 2 premiers agents (ticket-suggest, briefing-generator)
4. Observer 1 semaine en prod avec feature flag `ENABLE_GUARDRAILS=true`
5. Si OK : généraliser à lifeos puis ai-aggregator

## Liens

- Docs : https://docs.guardrailsai.com/
- Hub : https://guardrailsai.com/hub
- GitHub : https://github.com/guardrails-ai/guardrails
- PydanticAI integration : https://ai.pydantic.dev/
- `pydantic-ai-guardrails` : https://pypi.org/project/pydantic-ai-guardrails/
