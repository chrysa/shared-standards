# opencode multi-provider fleet — design

- **Date**: 2026-09-25
- **Auteur**: owner + Claude
- **Statut**: proposé (en attente revue)
- **Dépôt canon**: `chrysa/shared-standards`

## Intention

Intégrer **opencode** (agent de code terminal, provider-agnostic) dans tous les
repos du portfolio chrysa, configuré pour trois backends LLM interchangeables —
**Claude, ChatGPT, Ollama** — avec Ollama en défaut (offline-first) et le cloud
en opt-in. Le modèle par défaut d'Ollama est un modèle *coder* (`qwen2.5-coder`),
c'est le "ollama-coder" demandé.

Aligné doctrine chrysa : offline-first + `LLMProvider` pluggable + mandat
multi-modèle (standards AI pilier 1 / AG-017).

## État existant (constaté)

- `opencode.json` présent dans ~92 sous-repos chrysa. **84 identiques** au hash du
  template `shared-standards/templates/opencode.json`, **8 périmés/variants**.
- Config actuelle = **github-copilot uniquement** (`model: github-copilot`,
  `type: copilot`, `claude-sonnet-4-6`). Pas d'Ollama, pas d'OpenAI, pas de
  multi-provider.
- `opencode.json` **n'est PAS géré** par `scripts/distribute-standards.sh` →
  cause de la dérive (84 alignés + 8 stales). Le script gère aujourd'hui
  CLAUDE.md, AGENTS.md, vues Copilot, `.claude/{agents,commands}`.
- `AGENTS.md` déjà présent dans ~90 repos.
- Variables Ollama déjà standardisées fleet : `OLLAMA_URL=http://127.0.0.1:11434`,
  `OLLAMA_MODEL=qwen3:8b`.
- opencode installé localement : **1.18.32** (schéma v1 : clé `provider`).

Conséquence : la tâche est une **reconfiguration** (copilot-only → 4 providers)
+ **mise sous gestion** de `opencode.json` par distribute-standards.

## Décisions (verrouillées par l'utilisateur)

1. **Défaut = Ollama** (offline-first), cloud en opt-in.
2. **Secrets = refs env only** (`{env:VAR}`) + `.env.example` mis à jour. Aucune
   clé committée (règle sécurité CLAUDE.md non-négociable).
3. **Distribution = ajout à `distribute-standards.sh`** (managed, idempotent,
   overwrite chaque run) → corrige la dérive fleet-wide.
4. Scope = **tous les repos** de `repos.yml` (87), aucun filtre profil (config LLM
   universelle).

## Architecture

### 1. Nouveau `templates/opencode.json`

Schéma v1 (compatible opencode 1.18.x). Bloc `mcp` (github + notion) **inchangé**
(garde `${VAR}` shell dans `mcp.*.environment`, déjà fonctionnel).

```json
{
  "$schema": "https://opencode.ai/config.json",
  "_comment_model": "Offline-first: default = local Ollama coder model. Claude & ChatGPT opt-in via API keys. Do not hardcode cloud model versions.",
  "instructions": "You are an expert software engineer. Default to English in code, docs, and issues. Respect CLAUDE.md per repo. Offline-first: local Ollama is the default; Claude and ChatGPT are opt-in via API keys.",
  "model": "ollama/qwen2.5-coder",
  "provider": {
    "ollama": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "Ollama (local)",
      "options": { "baseURL": "{env:OLLAMA_URL}/v1" },
      "models": {
        "qwen2.5-coder": { "name": "Qwen2.5 Coder (local)" },
        "qwen3:8b":      { "name": "Qwen3 8B (local)" }
      }
    },
    "anthropic": {
      "options": { "apiKey": "{env:ANTHROPIC_API_KEY}" }
    },
    "openai": {
      "options": { "apiKey": "{env:OPENAI_API_KEY}" }
    },
    "github-copilot": {
      "type": "copilot",
      "options": { "model": "claude-sonnet-4-6" }
    }
  },
  "mcp": {
    "github": {
      "type": "local",
      "enabled": true,
      "command": ["npx", "-y", "@modelcontextprotocol/server-github"],
      "environment": { "GITHUB_PERSONAL_ACCESS_TOKEN": "${GITHUB_TOKEN}" }
    },
    "notion": {
      "type": "local",
      "enabled": true,
      "command": ["npx", "-y", "@notionhq/notion-mcp-server"],
      "environment": { "OPENAPI_MCP_HEADERS": "{\"Authorization\": \"Bearer ${NOTION_API_KEY}\", \"Notion-Version\": \"2022-06-28\"}" }
    }
  }
}
```

Notes :
- `model` racine = `ollama/qwen2.5-coder` (défaut offline).
- `ollama` via provider openai-compatible sur `{env:OLLAMA_URL}/v1` (défaut local si
  var absente → chaîne vide ; à documenter dans `.env.example`).
- `anthropic`/`openai` = providers built-in opencode, modèles auto-découverts, clé
  `{env:...}`. Aucune version cloud en dur (respecte no-pin).
- `github-copilot` gardé comme 4e provider switchable (capacité actuelle préservée).
- Syntaxe confirmée : `{env:VAR}` pour `provider.options` ; `${VAR}` seulement dans
  `mcp.*.environment`.

### 2. Câblage `scripts/distribute-standards.sh`

- Déclarer `OPENCODE_TPL="$STD_ROOT/templates/opencode.json"`.
- Ajouter étape managed par repo : `cp "$OPENCODE_TPL" "$repo/opencode.json"`
  (idempotent, overwrite, comme les vues AGENTS/CLAUDE).
- `opencode.json` rejoint la liste "managed paths — overwritten every run".
- Effet : 100% des repos alignés ; les 8 stales écrasés.

### 3. `.env.example` (template distribué / append)

```
# opencode LLM providers
OLLAMA_URL=http://127.0.0.1:11434   # défaut local, offline-first
ANTHROPIC_API_KEY=                  # opt-in Claude (cloud)
OPENAI_API_KEY=                     # opt-in ChatGPT (cloud)
```

Aucune valeur secrète. Scan secrets sur le diff avant merge.

## Flux de données

opencode charge `opencode.json` → substitue `{env:*}` depuis l'environnement du
shell (ou `.env` chargé par l'outil) → sélectionne `model` racine (`ollama/...`)
si provider dispo, sinon fallback opencode → l'utilisateur switch de session vers
`anthropic/*`, `openai/*`, ou `github-copilot/*` à la volée (sans réécrire le
fichier).

## Gestion d'erreurs / cas limites

- **Ollama absent** : `model` racine indisponible → opencode fallback newest
  available. Cloud utilisable si clé présente. Pas de crash.
- **Clé cloud absente** : `{env:...}` → chaîne vide → provider cloud inactif ;
  Ollama reste dispo. Comportement voulu (opt-in).
- **8 configs stales** : écrasées par l'étape managed (idempotent).
- **JSON invalide** : valider `jq . opencode.json` sur chaque repo post-run.

## Rollout (doctrine : pas de mass-push local)

1. **PR unique shared-standards** (cette branche) : template + step script +
   `.env.example`.
2. **Pilote noesis** : lancer `distribute-standards.sh` localement, vérifier
   `opencode` démarre sur ollama, switch claude/chatgpt OK.
3. **Merge** PR shared-standards (develop).
4. **Fan-out fleet** via GitHub Action `distribute-standards` (mécanisme canon),
   PRs par repo. Pas de push local massif.

## Rollback

`git revert` du template/step ; re-run distribute restaure l'état précédent
(github-copilot only).

## Tests / vérification

- `opencode --version` (1.18.32 ✓).
- Spike syntaxe env `{env:VAR}` ✓ (confirmé docs opencode).
- `jq .` valide sur template + repos touchés.
- Pilote noesis : lancement réel opencode, 4 providers listés.
- Scan secrets (règle CLAUDE.md) sur diff avant merge.

## Gotchas (constatés au pilote)

- **`instructions` doit être un array** en opencode 1.18 (l'ancien template string
  était rejeté `Configuration is invalid`). Corrigé.
- **Ollama models à pull** : `opencode models` liste `ollama/qwen2.5-coder` mais le
  serveur local peut n'avoir aucun modèle (`{"models":[]}`). Prérequis run :
  `ollama pull qwen2.5-coder`. À documenter dans README/onboarding.
- Pilote validé hors-repo (répertoire scratchpad jetable) car noesis working tree
  sale — pas de pollution du vrai repo.

## Hors scope

- Runtime applicatif `LLMProvider` des apps (déjà couvert par doctrine offline-first
  existante ; ce spec = couche outil opencode). Si extension runtime voulue → spec
  séparé par app.
- Distribution des skills/agents (déjà géré ailleurs).

## Documentation

- Fiche Notion (DB Projets / page transverse) à créer/annoter — mécanisme
  `notion-github-bridge`. Serveur Notion MCP en échec de connexion cette session
  (CONNECT_TIMEOUT) → à faire dès reconnexion.
