# n8n · Notion comment agent (conflict resolver)

> Agent qui écoute les commentaires posés dans Notion et répond automatiquement si un conflit est détecté avec une autre partie du document.

**Status** : Design (pending infra n8n)
**Déploiement** : self-host sur server Kimsufi · docker compose
**Déclenchement** : Notion webhook (comments) → n8n workflow

## Valeur

Tu poses un commentaire dans une page Notion (ex: "Aelys porte une dague runique ici")
alors qu'une autre section de la même page dit "Aelys perd sa dague au ch07".
L'agent détecte le conflit et répond au commentaire avec :
- Le passage conflictuel (lien direct)
- 2-3 options de résolution
- Propose de mettre à jour le canon si nécessaire

Supprime 80% du back-and-forth manuel de vérification de cohérence.

## Pré-requis

- n8n auto-hébergé sur server Kimsufi (dans server/docker-compose.yml)
- Notion integration avec scope `read:content + insert:comments`
- Webhook Notion configuré (Settings → Integrations → Webhooks)
- Claude API (via ai-aggregator pour limiter tokens)

## Architecture du workflow n8n

```
┌──────────────────────────────────────────────────────────────┐
│ Notion Webhook Trigger                                       │
│ Event: comment.created                                       │
│ Filter: workspace_id = chrysa                                │
└─────────┬────────────────────────────────────────────────────┘
          ↓
┌──────────────────────────────────────────────────────────────┐
│ Node 1 · Fetch Comment Context                               │
│ · GET /v1/comments/{comment_id}                              │
│ · GET /v1/blocks/{parent_block_id}/children                  │
│ · GET /v1/pages/{page_id}  (full content)                    │
└─────────┬────────────────────────────────────────────────────┘
          ↓
┌──────────────────────────────────────────────────────────────┐
│ Node 2 · Extract Claims                                      │
│ · Envoyer le commentaire + contexte à Claude via ai-agg      │
│ · Extraire les "claims" = assertions factuelles              │
│   (ex: "Aelys porte X" · "chapitre Y se passe à Z")          │
│ · Output : JSON list of claims                               │
└─────────┬────────────────────────────────────────────────────┘
          ↓
┌──────────────────────────────────────────────────────────────┐
│ Node 3 · Scan Full Document                                  │
│ · Récupérer TOUS les blocks de la page                       │
│ · Pour chaque claim, chercher assertions contradictoires     │
│   via embedding (Qdrant local · server stack)                │
│ · Score similarité · seuil 0.75                              │
└─────────┬────────────────────────────────────────────────────┘
          ↓
┌──────────────────────────────────────────────────────────────┐
│ Node 4 · Classify Conflict                                   │
│ · Si 0 conflit → skip (don't post)                           │
│ · Si 1-2 conflits → post réponse "Attention"                 │
│ · Si 3+ conflits → post réponse "Review" + flag page         │
└─────────┬────────────────────────────────────────────────────┘
          ↓
┌──────────────────────────────────────────────────────────────┐
│ Node 5 · Generate Response                                   │
│ · Prompt Claude (template fixed · voir prompts/)             │
│ · Output max 150 mots · format structuré                     │
│ · Inclut liens vers passages conflictuels                    │
└─────────┬────────────────────────────────────────────────────┘
          ↓
┌──────────────────────────────────────────────────────────────┐
│ Node 6 · Post Reply + Update Ops DB                          │
│ · POST /v1/comments (reply to original comment)              │
│ · Create task in Ops Tasks DB si conflit MAJEUR              │
│ · Push ntfy notification                                     │
└──────────────────────────────────────────────────────────────┘
```

## Template prompt (prompts/conflict-detect.md)

```
[Task] Détecter contradictions entre commentaire utilisateur et contenu du document
[Data]
 - Commentaire : "{{ comment_body }}"
 - Passage ciblé : "{{ target_block_content }}"
 - Document complet : voir blocks joints
[Goal] Identifier conflits factuels (pas stylistiques) · préserver l'intention utilisateur
[Output]
 - Format : JSON { "conflicts": [{ "with_block": "uuid", "summary": "...", "severity": "low|medium|high" }] }
 - Max 3 conflits
 - Severity high si incompatibilité logique (personnage mort vs présent)
```

## Template réponse (prompts/reply-template.md)

```markdown
🤖 Conflict check · agent n8n

{{#if conflicts}}
**{{ conflicts.length }} conflit(s) détecté(s)** avec d'autres sections :

{{#each conflicts}}
- ⚠️ **{{ severity }}** : {{ summary }}
  → Section : [voir passage]({{ link }})
  → Options : {{ options[0] }} · {{ options[1] }}

{{/each}}

Résolution manuelle si souhaitée · ou réponds avec "ignore" pour clore.
{{else}}
✅ Aucun conflit détecté · claim intégré au canon.
{{/if}}

---
*Généré par chrysa/n8n-notion-comment-agent · {{ timestamp }}*
```

## Configuration (config.yml)

```yaml
listeners:
  - workspace: chrysa-perso
    pages_filter:
      include_databases:
        - "FabForge GDD"
        - "Discordium V3 lore"
        - "Campagnes D-D"
        - "Writing drafts"
      exclude_pages:
        - "Sandbox"

conflict_detection:
  embedding_model: nomic-embed-text   # via Ollama local
  similarity_threshold: 0.75
  max_context_blocks: 200
  use_qdrant: true                     # vector store self-hosted

response:
  post_reply: true
  min_severity_to_post: medium
  create_ops_task_if: high
  max_response_words: 150

rate_limit:
  max_responses_per_page_per_day: 10   # évite spam sur discussions longues
  cooldown_minutes: 5

notifications:
  ntfy_topic: chrysa-morning
  push_on_conflict: high
```

## Safety

- **Opt-in par database** via `include_databases` (pas global)
- **Rate limiting** (max 10 réponses/page/jour)
- **Pas d'édition de contenu** · uniquement des commentaires en réponse
- **Severity threshold** : ne répond jamais sur severity low (évite bruit)
- **Signature** : chaque réponse signée `🤖 Conflict check` pour reconnaître l'agent
- **Opt-out** : répondre "ignore" au commentaire → l'agent marque et skip
- **Budget tokens** : via ai-aggregator · réduit coûts 30-50% sinon Claude direct

## Intégration portefeuille

- **Dépend de** :
  - `server` (Kimsufi · n8n docker · Qdrant)
  - `ai-aggregator` (proxy Claude · compression doc · budget tracking)
  - `chrysa-lib/auth` (pas direct · mais pour l'UI admin n8n)
- **Consomme** : Notion API (webhook + comments)
- **Exporte** : tâches dans Ops Tasks DB Notion

## Effort estimé

- Design + docker-compose : 2h
- Webhook Notion setup : 1h
- 6 nodes n8n : 6h
- Prompt templates + tests : 3h
- Qdrant embedding pipeline : 4h
- Tests integration : 2h

**Total** : ~18h · P2 après server/n8n ready

## Décisions attendues

- D-0001 : embedding model = Ollama nomic-embed-text (local, gratuit) vs OpenAI ada-002
- D-0002 : Qdrant vs Pgvector vs Weaviate
- D-0003 : Réponse en français (défaut) vs langue du commentaire auto-détectée
- D-0004 : Historique embedding persisté ou recalculé à chaque comment
- D-0005 : Integration avec writing-coherence skill (données partagées ?)
