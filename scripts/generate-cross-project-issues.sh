#!/usr/bin/env bash
# generate-cross-project-issues.sh
# Génère un batch de commandes `gh issue create` pour les dépendances inter-repos
# Source : shared-standards/docs/cross-project-dependencies.md
#
# Output : cross-project-issues.sh (à exécuter avec gh auth configuré)

set -uo pipefail

CHRYSA_ROOT="${CHRYSA_ROOT:-/home/anthony/Documents/perso/projects/chrysa}"
OUT="$CHRYSA_ROOT/cross-project-issues.sh"

cat > "$OUT" <<'HEADER'
#!/usr/bin/env bash
# cross-project-issues.sh — généré automatiquement
# Lancer avec : bash cross-project-issues.sh
# Prérequis : gh auth login
set -euo pipefail

ORG=chrysa

create_issue() {
    local repo=$1
    local title=$2
    local body=$3
    shift 3
    local labels=()
    for label in "$@"; do
        labels+=("--label" "$label")
    done
    echo "→ Creating issue on $ORG/$repo : $title"
    if gh issue create --repo "$ORG/$repo" --title "$title" --body "$body" "${labels[@]}" 2>&1; then
        echo "  ✅ created"
    else
        echo "  ❌ failed (repo may not exist or permissions)"
    fi
}

HEADER

# X-1 · chrysa-lib bloque 4 repos
for target in dev-nexus my-fridge lifeos doc-gen; do
cat >> "$OUT" <<EOF
create_issue "$target" \\
    "[P0] Blocked by chrysa-lib Sprint 1 (@chrysa/auth)" \\
    "## Context
ce repo dépend de \\\`@chrysa/auth\\\` livré par chrysa-lib. Sprint 1 pas démarré.

## Bloqueurs
- auth 4 modes (Google OAuth2 · local bcrypt · LDAP · VCS OAuth)

## Critères d'acceptation
- [ ] \\\`@chrysa/auth\\\` publié en package interne ou submodule
- [ ] Tests 4 modes verts
- [ ] README chrysa-lib à jour

## Liens
- Décision : chrysa-lib/DECISIONS.md D-0001
- Source blocage : ../chrysa-lib" \\
    "cross-project" "priority/p0" "blocked"

EOF
done

# X-1 bis · issue sur chrysa-lib elle-même
cat >> "$OUT" <<'EOF'
create_issue "chrysa-lib" \
    "[P0] Sprint 1 — livrer @chrysa/auth (4 modes)" \
    "## Context
chrysa-lib = Socle bloquant pour 4+ projets aval.

## Scope Sprint 1
- Module @chrysa/auth avec 4 modes (Google OAuth2, local bcrypt, LDAP, VCS OAuth)
- Tests unitaires ≥ 85% coverage
- Documentation API complète

## Projets bloqués
- dev-nexus, my-fridge, lifeos, doc-gen

## Liens
- Décision : DECISIONS.md D-0001 (auth 4 modes), D-0002 (Socle bloquant)" \
    "cross-project" "priority/p0" "sprint-1"

EOF

# X-2 · doc-gen PR #1
cat >> "$OUT" <<'EOF'
create_issue "doc-gen" \
    "[P0] Résoudre PR #1 python-jose → joserfc" \
    "## Context
PR #1 ouverte depuis longtemps. Migration python-jose vers joserfc. Bloque toute évolution de doc-gen.

## Critères d'acceptation
- [ ] PR #1 mergée
- [ ] Tests verts
- [ ] Dépendances compatibles

## Alerte
Voir CLAUDE.md global section ALERTES CRITIQUES." \
    "priority/p0" "blocker" "dependency-migration"

EOF

# X-3 · ai-aggregator prompt-optimizer
cat >> "$OUT" <<'EOF'
create_issue "ai-aggregator" \
    "[P1] Livrer module prompt-optimizer" \
    "## Context
prompt-optimizer = module interne ai-aggregator (D-0001). Optimise prompts selon modèle cible.

## Pré-requis
- Ollama self-hosted (voir cross-dep X-10)

## Scope
- Fork claude-code-prompt-optimizer
- Interface optimize(prompt, target_model) -> optimized_prompt
- Router model-aware en aval

## Projets bloqués
- dev-nexus (rate limit tokens), auto-PR-handler" \
    "cross-project" "priority/p1"

EOF

# X-4 · server monitoring
cat >> "$OUT" <<'EOF'
create_issue "server" \
    "[P1] Déployer stack monitoring local-first" \
    "## Context
D-0001 server : Prometheus + Grafana + Loki + Qdrant + mirror-docs sur Kimsufi.

## Budget
~4 Go RAM supplémentaires

## Critères d'acceptation
- [ ] docker-compose.monitoring.yml
- [ ] Dashboards Grafana auto-provisionnés
- [ ] Qdrant accessible pour RAG local
- [ ] Runbook docs/runbooks/monitoring.md

## Impact aval
briefing-agent, health-agent, tous projets déployés (alertes)" \
    "cross-project" "priority/p1" "infra"

EOF

# X-5 · auto-PR-handler
cat >> "$OUT" <<'EOF'
create_issue "shared-standards" \
    "[P2] Workflow auto-PR-handler" \
    "## Context
D-0005 shared-standards. Automatisation : issue → PR draft → review → merge → déblocage issues dépendantes.

## Pré-requis (bloquants)
- GitHub MCP configuré
- prompt-optimizer livré (ai-aggregator D-0001)
- Convention labels déployée sur tous repos chrysa

## Labels à standardiser
auto-handle, blocked-by:REPO#N, blocks:REPO#N" \
    "cross-project" "priority/p2"

EOF

# X-6 · windows-autonome + agent-config DECISIONS
for target in windows-autonome agent-config; do
cat >> "$OUT" <<EOF
create_issue "$target" \\
    "[P2] Créer DECISIONS.md local (ADR-0026)" \\
    "## Context
ADR-0026 révoque ADR-0014 (pas de fusion en chrysa-workstation). Les 2 repos restent séparés, rôle Socle.

## Action
- [ ] Créer DECISIONS.md basé sur shared-standards/templates/docs/DECISIONS.template.md
- [ ] Consigner D-0001 : 'Repo séparé, rôle Socle (ADR-0026)'
- [ ] Si besoin : ajouter D-0002 sur la frontière fonctionnelle avec l'autre repo

## Liens
- shared-standards/docs/DECISIONS-MIGRATION-MAP.md" \\
    "cross-project" "priority/p2" "documentation"

EOF
done

# X-7/X-8/X-9 · fusions non exécutées
cat >> "$OUT" <<'EOF'
create_issue "shared-standards" \
    "[P3] Fusions ADRs non exécutées — récapitulatif" \
    "## Context
3 fusions décidées mais pas exécutées sur disque :

- D-0011/D-0025 : linkendin-resume + my-resume → resume (frozen)
- D-0012 : coaching-sport + coaching-guitare → coaching-tracker
- D-0016 : guideline-checker (repo standalone) → package shared-standards/packages/guideline-checker

## Priorité
P3 car non bloquant.

## Actions
- [ ] Créer repo cible + migrer contenu
- [ ] Archiver repos sources (via archive-merged-repos.sh)
- [ ] Mettre à jour DECISIONS.md concernés" \
    "priority/p3" "tech-debt" "portfolio-hygiene"

EOF

# X-10 · Ollama
cat >> "$OUT" <<'EOF'
create_issue "ai-aggregator" \
    "[P2] Installer Ollama self-hosted" \
    "## Context
Prérequis pour prompt-optimizer D-0001 (fallback local) et local-first policy chrysa.

## Infra
- Host Kimsufi ou machine locale avec GPU
- RAM ~8 Go pour modèles 7B
- docker-compose ou install native

## Critères d'acceptation
- [ ] Modèle 7B (llama3/qwen2) accessible sur http://localhost:11434
- [ ] Intégration testée avec prompt-optimizer" \
    "cross-project" "priority/p2" "infra"

EOF

# X-11 · Notion DBs
cat >> "$OUT" <<'EOF'
echo ""
echo "⚠️  Issue X-11 (Notion DB Bugs + Dette technique) = action manuelle UI Notion"
echo "    Voir shared-standards/docs/notion-restructure-plan.md P1.1-3"

EOF

chmod +x "$OUT"

echo "✅ Script généré : $OUT"
echo ""
echo "Prévisualiser : less $OUT"
echo "Exécuter      : gh auth login && bash $OUT"
