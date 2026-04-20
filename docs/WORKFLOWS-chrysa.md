# Workflows opérationnels chrysa

> Workflows reproductibles · exploitent ce qui est installé (scripts, hooks, labels, agents).
> Source de vérité · publiés aussi en Notion Wiki Engineering.

---

## W-1 · Daily routine (08h → 20h)

```mermaid
flowchart LR
    M[☀️ 08h réveil] --> B[briefing-agent auto 08h05<br/>Notion digest]
    B --> V[daily-veille 07h auto<br/>3 bullets top veille]
    V --> D[08h30 · bash claude-daily-routine.sh<br/>pull all + status dirty]
    D --> P{Priorité jour<br/>règle 1+2}
    P -->|Socle P0| S[server Phase 0<br/>ou chrysa-lib]
    P -->|Actif| A[1 feature fond<br/>+ 1 outillage léger]
    S --> C[Code · commit · push<br/>hooks quality-check actif]
    A --> C
    C --> PR[PR créée<br/>enforce-issue-link check]
    PR --> CI[CI verte + auto-merge<br/>si dependabot patch/minor]
    CI --> W[20h · fix-all.sh<br/>push pending + portfolio.html]
    W --> J[Journal auto<br/>~/.chrysa/journal/YYYY-MM-DD.md]
```

**Commandes** :
```bash
bash shared-standards/scripts/claude-daily-routine.sh  # 08h30
# … code · commit · push pendant la journée …
bash shared-standards/scripts/fix-all.sh               # 20h, option --dry-run d'abord
```

**Agents impliqués** : `briefing-agent` · `daily-veille-technique` · `health-agent`

---

## W-2 · Feature flow (issue → PR → merge)

```mermaid
sequenceDiagram
    participant U as User
    participant GH as GitHub
    participant CI as Actions CI
    participant AM as auto-merge
    U->>GH: gh issue create #N
    U->>U: git checkout -b feature/N-short-desc
    U->>U: code + commit (Conv. Commits)
    U->>U: git push
    U->>GH: gh pr create (template inclut "Closes #N")
    GH->>CI: enforce-issue-link ✓ · labeler auto-label · pr-size-label
    CI->>CI: _reusable-ci : quality · test · sonar
    CI->>AM: Si branch default updated: auto-rebase
    CI-->>U: ✅ Tout vert
    U->>GH: gh pr review --approve · merge --squash
    GH->>GH: GitVersion tag prd-X.Y.Z + changelog
```

**Commandes** :
```bash
gh issue create --repo chrysa/REPO --title "..." --body "..." --label "priority/p1"
git checkout -b feature/123-short-desc
# ... travail ...
gh pr create --fill   # utilise le template avec Closes #123
# attendre CI verte
gh pr merge --auto --squash
```

**Workflows actifs** : `_reusable-ci.yml` · `enforce-issue-link.yml` · `labeler.yml` · `pr-size-label.yml` · `branch-auto-update.yml`

---

## W-3 · Dependabot cycle (auto-merge patch/minor)

```mermaid
flowchart TD
    D[Dependabot<br/>lundi 06h00] --> G[Group patch+minor<br/>max 3 PR/écosystème]
    G --> P[PR ouverte<br/>label: dependencies · auto-merge]
    P --> CI[CI verte ?]
    CI -->|Oui + semver ≤ minor| AM[dependabot-auto-merge<br/>approve + merge --squash]
    CI -->|Oui + semver major| REV[review manuelle requise]
    CI -->|Non| F[Fail notification<br/>label: tests failing]
    AM --> M[Merge · tag auto · Changelog]
```

**Config** : `.github/dependabot.yml` (rate-limité) + `dependabot-auto-merge.yml` (workflow)
**Budget CI** : ~5 min/mois par repo.

---

## W-4 · Hotfix urgent (bypass review)

```mermaid
flowchart LR
    P[🔴 Incident prod] --> H[git checkout -b hotfix/desc]
    H --> F[Fix minimal]
    F --> PR[gh pr create --label hotfix]
    PR --> S{enforce-issue-link}
    S -->|label hotfix| B[bypass check ✓]
    B --> CI[CI rapide sur hotfix seulement]
    CI --> M[merge direct main<br/>squash + tag patch]
    M --> D[deploy auto]
    D --> I[Créer issue post-mortem]
```

**Règle** : label `hotfix` permet le bypass de la convention issue-link. Post-mortem obligatoire dans les 48h.

---

## W-5 · Release flow (GitVersion + changelog)

```mermaid
flowchart TD
    C[commit feat/fix sur main] --> R[release.yml trigger]
    R --> CH[Check conventional commits<br/>depuis dernier tag]
    CH -->|aucun| SKIP[skip release]
    CH -->|oui| GV[GitVersion calc semVer]
    GV --> CLI[git-cliff changelog]
    CLI --> T[Create tag prd-X.Y.Z]
    T --> REL[softprops action-gh-release<br/>+ body changelog]
    REL --> N[MCP Notion : sync release<br/>DB Projets]
```

**Fixe issue #83** : voir `pre-commit-tools/ISSUE-83-DIAGNOSTIC.md`.

---

## W-6 · Veille technique journalière

```mermaid
flowchart LR
    S[Scheduled task<br/>daily-veille 07h] --> F[WebFetch sources daily<br/>veille-sources.md]
    F --> FI[Filtre 30-derniers digests<br/>anti-doublon]
    FI --> R[Résumé catégorisé<br/>Top 3 / Suivre / Inspiration / Anti-signaux]
    R --> N[Post Notion DB Veille tech]
    R --> B[Bullets dans briefing 08h05]
    N --> V{User valide hebdo<br/>propositions nouvelles sources}
    V -->|Valide| ADD[sources-sync dimanche<br/>MAJ veille-sources.md]
    V -->|Rejette| END[ignore]
```

**Sources** : `shared-standards/docs/veille-sources.md` (dev · domotique · jeux · automatisation).

---

## W-7 · Nouveau projet (idée → repo opérationnel)

```mermaid
flowchart TD
    I[💡 Idée] --> PRD{PRD requis ?<br/>rôle Actif ou candidat ?}
    PRD -->|Oui| WR[Rédiger PRD<br/>templates/docs/PRD.template.md]
    PRD -->|Non| N[Notion : créer page DB Projets<br/>rôle Opportuniste ou Vision]
    WR --> D[Décision D-XXXX<br/>si structurante]
    D --> N
    N --> DIR[mkdir nouveau-repo && cd]
    DIR --> INIT[bash chrysa-init.sh<br/>interactif · stack auto]
    INIT --> PMF[Éditer portfolio-metadata.yml<br/>rôle · valeur · bloqueurs · budget]
    PMF --> GH[gh repo create chrysa/nom --private<br/>--source=. --push]
    GH --> LAB[sync-labels.yml déployé<br/>→ 60+ labels couleurs unifiées]
    LAB --> RUN[Prêt · suivre W-2 feature flow]
```

**Commandes** :
```bash
mkdir mon-nouveau-repo && cd mon-nouveau-repo
bash $CHRYSA/shared-standards/scripts/chrysa-init.sh
# ... remplir les questions ...
gh repo create chrysa/mon-nouveau-repo --private --source=. --push
```

---

## W-8 · Code review (reviewer-agent)

```mermaid
sequenceDiagram
    participant PR as Pull Request
    participant PRA as pr-review-agent
    participant U as User
    PR->>PRA: on pull_request trigger
    PRA->>PRA: Lint check · coverage check · pattern check
    PRA->>PRA: Analyse diff via Claude API
    PRA->>PR: Comment inline si issue
    PR->>U: APPROVE ou REQUEST CHANGES
    alt Request changes
        U->>PR: Fix + re-push
        PR->>PRA: Re-trigger
    else Approve
        U->>PR: gh pr merge --auto
    end
```

**Agent** : `pr-review-agent` (GH Actions déclenché sur `pull_request`).

---

## W-9 · Sprint cycle (10h par sprint)

```mermaid
flowchart LR
    L[Lundi matin<br/>Sprint kickoff 30 min] --> R[Revue ROADMAP.md<br/>règle 1+2 vérifiée]
    R --> T[Sélection items NOW<br/>sprint-agent aide priorisation]
    T --> W[Travail sprint<br/>W-2 feature flow × N]
    W --> LE[Dimanche soir<br/>claude-weekly-review.sh]
    LE --> RE[Sprint review<br/>Mermaid burndown + décisions]
    RE --> A[Archive sprint Notion<br/>📊 Reviews / Sprint]
    A --> L2[Lundi suivant]
```

**Scripts** : `claude-weekly-review.sh` · `generate-roadmap-rollup.sh` · `health-agent`.

---

## W-10 · Incident response

```mermaid
flowchart TD
    A[🚨 Alert Prometheus<br/>ou Sentry] --> T[Triage<br/>P0/P1/P2]
    T -->|P0 critique| H[W-4 hotfix flow]
    T -->|P1 important| I[Créer issue label: blocker<br/>priority/p1]
    T -->|P2 info| B[Backlog]
    H --> PM[Post-mortem 48h<br/>template docs/postmortems/]
    I --> S[Sprint in progress<br/>insertion]
    PM --> L[Lesson learned<br/>DECISIONS.md si structurel]
```

**Runbook** : `server/docs/runbooks/incident-response.md` (à créer).

---

## Index Scripts / Hooks / Agents référencés

### Scripts
- `chrysa-init.sh` — bootstrap nouveau repo
- `apply-standards.sh` — distribuer templates
- `fix-all.sh` — pipeline 10 étapes
- `claude-daily-routine.sh` — routine matin
- `claude-weekly-review.sh` — dimanche soir
- `repos-push-pending.sh` — commit + push actifs
- `archive-obsolete-repos.sh` · `archive-merged-repos.sh` — ménage
- `generate-portfolio-html.sh --external` — partage externe
- `generate-roadmap-rollup.sh` · `generate-deps-graph.sh` · `generate-docs-index.sh`
- `audit-github-issues.sh` — stale closer
- `dev-run.sh` — runner app/test/lint
- `validate-prompt.py` — validateur prompt
- `generate-cross-project-issues.sh` — batch X-1 à X-11

### Workflows GitHub
- `_reusable-ci.yml` — CI unifiée Python+Node
- `dependabot-auto-merge.yml` — auto-merge patch/minor
- `branch-auto-update.yml` — rebase auto
- `enforce-issue-link.yml` — PR ↔ issue obligatoire
- `labeler.yml` · `sync-labels.yml` · `pr-size-label.yml`

### Agents / Scheduled tasks
- `briefing-agent` (08h) · `daily-veille-technique` (07h)
- `pr-review-agent` (on PR) · `sprint-agent` (manuel `/sprint`)
- `health-agent` (lundi 09h) · `notion-sync-agent` (daily)
- `pr-aging` · `ci-sweep` · `notion-comments-processor`
