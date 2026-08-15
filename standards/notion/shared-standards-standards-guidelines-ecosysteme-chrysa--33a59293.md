---
fka_managed: true
source: notion
notion_id: 33a59293-e35e-8196-bb37-e8f5dd4050d6
notion_url: https://app.notion.com/p/shared-standards-Standards-Guidelines-cosyst-me-chrysa-33a59293e35e8196bb37e8f5dd4050d6
notion_last_edited_time: 2026-08-03T12:35:00.000Z
---
<callout icon="🏛️">
	**Autorité — lire avant toute utilisation de cette page.** Le canon exécutable est `chrysa/shared-standards` : le socle `standards/STANDARDS.chrysa.md` (inliné dans le bloc managé `<!-- chrysa:standards -->` du `CLAUDE.md` de chaque repo) et ses 7 annexes normatives `standards/annexes/`. Cette page est une **vue de gouvernance et de décision** : elle ne gouverne aucun repo et n'est jamais distribuée. En cas de divergence, **le repo fait foi**. Vérifié le 2026-07-31.
</callout>
<table_of_contents/>
## 📝 Reste à faire — état au 2026-07-31
Vue de pilotage. Le détail technique vit dans les issues des repos concernés ; cette liste ne garde que le bloqueur et le levier.
- **R1 · 🔴 bloquant — Facturation Actions sur les repos privés. **45 des 49 repos privés sont rouges sur leur branche par défaut. Les jobs meurent en 2 s, sans exécuter une seule étape, avec une archive de logs vide : ils ne démarrent pas. Les 3 repos passés au vert le 2026-07-31 (pre-commit-tools, shared-standards, github-actions) sont tous publics. À confirmer par une lecture du billing ; si c'est avéré, le levier est les runners self-hosted (P0 déjà identifié), pas une correction repo par repo.
- **R2 · ⏸ en pause, dépend de R1 — Sweep quality-gate. **12 repos appellent des cibles Makefile bannies (make test-coverage / make type-check alors que les Makefile définissent test-cov / typecheck) : agent-config, ai-aggregator, chrysa-lib, coach, dev-nexus, doc-gen, floating-agent, lifeos, mediavault, PO-GO-DEX, project-init, usefull-containers. 33 callers sont encore épinglés github-actions@v1.4.4, sans l'install pyproject ni workflow_call. Script de sweep écrit et pilote coach instrumenté — inutile de dérouler tant que les jobs privés ne démarrent pas.
- **R3 — Ids stables pour les règles du socle. **GV-010 impose un identifiant unique et stable par règle. Les 7 annexes l'appliquent (FE-\*, AR-\*, AG-\*, DC-\*, CT-\*, TS-\*, GV-\*) ; le socle distribué, lui, n'a aucun id. Schéma SO-\* proposé dans la console des standards, pas encore inscrit au repo.
- **R4 — Contrat chiffré unique (GV-030). **Les seuils, versions d'outillage et noms de cibles doivent venir d'un standards.yml versionné dont dérivent .claude/thresholds.json, .quality-gate.json et guideline-checker. Aujourd'hui la prose et les fichiers machine se recopient — c'est la cause racine des divergences C1/C2/C6.
- **R5 — Arbitrage des items Deferred de FRONTEND.md. **Sept candidats en attente de décision : factory de clés de cache, gating de permissions centralisé, code-splitting par route, source unique pour l'auth, système i18n unique, emplacement canonique par composant, mémoïsation laissée au compilateur.
- **R6 — FE-070 n'a aucun contrôle mécanique. **Le lazy loading et la forme du squelette ne se détectent pas statiquement. Le vrai levier serait un budget CLS en Lighthouse CI, pas un hook.
- **R7 — Vérification dynamique du hot-reload. **Le hook compose-dev-hot-reload ne couvre que compose : un Dockerfile dev faisant COPY . . sans mount reste invisible. Complément prévu : une cible make docker-dev-verify qui démarre le service dev, touche un fichier et vérifie le rechargement.
- **R8 — Collision d'identifiant résiduelle. **Un troisième « D-0005 » subsiste dans docs/specs/spec-v1.md (série différente, sens différent). À renommer ou à acter explicitement.
## Fiche de suivi dev-friendly
### But du projet
- fournir la source de vérité des standards partagés de l’écosystème
- homogénéiser conventions, hooks, skills, templates et workflows réutilisables
### Prochaine action dev
- réaligner explicitement `shared-standards` avec la règle : **pas de local/venv sauf pre-commit**, logique **service/container/shared/remote-first**
### Dépendances
- backlog central
- standard d’exécution transverse
- `github-actions`
- `project-init`
### Ordre recommandé
- après **Notion**, **plateforme live** et **FileOrganizer / Google Drive**
- dans le bloc **socle transverse**, avant industrialisation large de `project-init`
### Synergies
- `project-init`
- `github-actions`
- tous les repos actifs
- cohérence Claude / Copilot / skills / templates
### Ressenti IA
- utilité produit : très forte comme socle de cohérence
- utilité fonctionnalités : forte sur templates, hooks, workflows, skills, consignes partagées
- point de vigilance : un standard trop large ou trop abstrait peut devenir difficile à appliquer réellement
### Blocages
- besoin de prioriser les standards vraiment utilisés avant de multiplier les variantes
### État live / monitoring
- doit remonter : standards actifs, standards à stabiliser, dépendances avec `project-init` et `github-actions`
### Raccordement opérationnel
- **Tasks Manager** : tâches légères de clarification, standardisation, exceptions et documentation utile
- **GitHub Issues** : tickets repo liés aux templates, hooks, guidelines, skills et conventions partagées
- **Plateforme live** : afficher standards stabilisés, standards à adopter, écarts importants et prochaine action
- **DEV Nexus** : afficher dette de standardisation, signaux de qualité et impacts CI/workflows quand pertinent
- **Flux de pilotage** : remonter au backlog central tout arbitrage qui change le standard transverse commun
## Vue d'ensemble
Standards GitHub Copilot, hooks Claude Code DevEx, templates CI réutilisables et conventions communes pour tout l'écosystème chrysa. Source de vérité des guidelines partagées.
## Contenu
- .claude/hooks/ — Circuit breaker, secret scanner, DevEx hooks
- .claude/skills/ — Skills Claude par domaine (pytest, dockerfile, api-design)
- copilot-instructions/ — Templates copilot-instructions.md par type de projet
- templates/ — Bootstrap CLAUDE.md, .gitignore, dependabot.yml
- workflows/ — Templates GitHub Actions réutilisables
## Liens
- GitHub : [https://github.com/chrysa/shared-standards](https://github.com/chrysa/shared-standards)
---
## Standard transverse — capacités agentiques et actions (2026-07-23)
> ✅ Rapatrié dans le canon exécutable le 2026-07-31 — `standards/annexes/AGENTIC-CAPABILITIES.md`. Le texte ci-dessous est une vue de gouvernance ; le repo fait foi.
✅ Rapatrié dans le canon — annexes AGENTIC-CAPABILITIES.md (AG-000…AG-011), PROJECT-DECOUPLING.md (DC-000…DC-008), CONTAINERS-K3S.md (CT-000…CT-024) + ARCHITECTURE-DDD.md (AR-030…AR-033). Ancré dans le socle. PR chrysa/shared-standards#242.
Référence : [Audit Mark-L — impacts portfolio & architecture](https://app.notion.com/p/3a659293e35e81acaf6fecefc85ad61f).
### Règles obligatoires
- Aucun SDK fournisseur LLM dans une feature : utiliser `ai-aggregator`.
- Toute action agentique possède un manifeste versionné, des entrées/sorties typées et un propriétaire métier.
- Permissions minimales, allowlist des ressources et refus propre hors périmètre.
- Risque R0–R5, confirmation proportionnée, dry-run lorsque possible.
- Idempotence, timeout, limites de ressources, circuit breaker et rollback documentés.
- Secrets, clés et certificats privés hors Git ; génération et rotation par installation/environnement.
- Suppression logique, corbeille ou quarantaine préférées à la destruction définitive.
- Code généré, installation de dépendances et commandes système exécutés dans DEV Nexus ou une sandbox non privilégiée.
- Réseau désactivé par défaut pour les exécutions ; dépendances épinglées et provenance enregistrée.
- Journal corrélé `session_id` / `plan_id` / `request_id` / `action_id` envoyé vers Mirador ou l’audit-log.
- Aucun merge automatique sur `main` par un agent.
- Aucun contrôle physique ou d’accès sans politique métier, confirmation forte et audit immuable.
- Une capacité naît dans son premier projet consommateur ; extraction en brique partagée seulement au deuxième consommateur réel.
### Gates CI à ajouter progressivement
- détection des imports directs de SDK LLM ;
- détection de secrets, certificats et clés privées versionnés ;
- détection des appels shell non encapsulés par un adapter ;
- validation des manifestes de capacités ;
- tests de dry-run, idempotence, timeout et rollback ;
- contrôle que les actions R3–R5 exigent la confirmation attendue.
---
## Standard transverse — indépendance et découplage des projets (2026-07-23)
> ✅ Rapatrié dans le canon exécutable le 2026-07-31 — `standards/annexes/PROJECT-DECOUPLING.md`. Le texte ci-dessous est une vue de gouvernance ; le repo fait foi.
✅ Rapatrié dans le canon — annexes AGENTIC-CAPABILITIES.md (AG-000…AG-011), PROJECT-DECOUPLING.md (DC-000…DC-008), CONTAINERS-K3S.md (CT-000…CT-024) + ARCHITECTURE-DDD.md (AR-030…AR-033). Ancré dans le socle. PR chrysa/shared-standards#242.
<callout icon="🔌" color="orange_bg">
	**Règle obligatoire : chaque projet doit rester autonome, remplaçable et distribuable indépendamment.** Aucun projet ne doit dépendre de l’organisation interne, des fichiers, de la base de données ou du code source d’un autre projet.
</callout>
### Principes obligatoires
- Chaque projet possède son propre cycle de vie, son versionnage, son déploiement, sa documentation, ses données et sa politique de licence.
- Les communications inter-projets passent exclusivement par des **contrats publics versionnés** : SDK publié, API documentée ou WebSocket documenté.
- Aucun import direct depuis un dépôt voisin, aucune dépendance par chemin local, aucun sous-module servant de liaison runtime et aucune copie de code inter-projets.
- Aucun accès direct à la base de données, aux fichiers internes, aux tables ou aux modèles privés d’un autre projet.
- Un SDK partagé est un produit versionné avec API publique minimale, changelog, compatibilité déclarée et politique de dépréciation ; il ne donne pas accès aux internals du fournisseur.
- Les consommateurs utilisent un adapter local autour du contrat externe afin de pouvoir remplacer, désactiver ou supprimer le fournisseur sans réécriture métier globale.
- Les contrats doivent préciser : schémas d’entrée et sortie, erreurs, authentification, timeouts, limites, compatibilité, reprise et comportement en indisponibilité.
- Les dépendances réseau doivent être explicitement déclarées et ne doivent pas être confondues avec une dépendance structurelle au code du fournisseur.
- Lorsqu’un service devient indisponible ou déprécié, le consommateur doit échouer proprement, désactiver la capacité concernée ou utiliser un adapter alternatif sans compromettre son fonctionnement principal.
### Motivations
Cette règle protège la possibilité qu’un projet soit :
- déprécié ou remplacé ;
- publié en open source ;
- commercialisé séparément ;
- déployé chez un tiers ;
- maintenu avec une cadence ou une stack différente ;
- extrait du portfolio sans casser les autres projets.
### Interdictions CI à contrôler progressivement
- imports depuis un dépôt frère ou un namespace interne non publié ;
- dépendances `path`, liens symboliques ou montages de code entre projets en production ;
- accès direct à la base ou au stockage privé d’un autre projet ;
- URLs, ports, chemins ou identifiants de services codés en dur ;
- copie d’un modèle métier appartenant à un autre projet sans contrat de compatibilité ;
- dépendance à une API non versionnée ou sans politique de dépréciation.
### Exigences minimales d’un contrat inter-projets
- propriétaire et consommateurs identifiés ;
- version du contrat ;
- documentation et exemples ;
- tests de contrat côté fournisseur et consommateur ;
- mock ou fake local pour le développement hors ligne ;
- stratégie de migration et période de compatibilité ;
- politique de licence et séparation claire entre éléments OSS et commerciaux.
### Conséquence architecturale
Les relations documentées dans Notion représentent des **relations de contrat ou de consommation**, jamais une autorisation de créer une liaison en dur entre les codebases.
---
## Standard transverse — Python, Dockerfile et responsabilité des conteneurs (2026-07-23)
> ✅ Rapatrié dans le canon exécutable le 2026-07-31 — `standards/annexes/CONTAINERS-K3S.md` (stages, responsabilité conteneur, workload k3s) + socle `STANDARDS.chrysa.md` (pyproject, multi-stage `production`/`dev`). Le repo fait foi.
✅ Rapatrié dans le canon — annexes AGENTIC-CAPABILITIES.md (AG-000…AG-011), PROJECT-DECOUPLING.md (DC-000…DC-008), CONTAINERS-K3S.md (CT-000…CT-024) + ARCHITECTURE-DDD.md (AR-030…AR-033). Ancré dans le socle. PR chrysa/shared-standards#242.
<callout icon="📦" color="blue_bg">
	**Règle obligatoire :** la configuration Python est centralisée dans `pyproject.toml`, les images utilisent des builds multi-stage par environnement, et chaque conteneur conserve une responsabilité unique. Le routage HTTP externe du cluster est assuré par Traefik dans k3s, jamais embarqué dans les conteneurs applicatifs.
</callout>
### 1. Python — exploiter `pyproject.toml` au maximum
`pyproject.toml` constitue la source de vérité principale de chaque projet Python pour :
- les métadonnées du projet et la version Python supportée ;
- les dépendances runtime et groupes de dépendances de développement, test, documentation ou tooling ;
- les scripts et points d’entrée ;
- la configuration du build et du packaging ;
- la configuration des outils lorsqu’ils supportent nativement `pyproject.toml` : Ruff, pytest, coverage, mypy ou Pyright, import-linter, deptry et outils équivalents ;
- les URLs du projet, auteurs, licence, classifiers et capacités publiées.
#### Règles
- Ne pas créer de fichiers de configuration séparés lorsqu’un outil supporte correctement `pyproject.toml`.
- Ne pas maintenir manuellement plusieurs sources de dépendances concurrentes.
- Les fichiers `requirements*.txt` ne sont autorisés que comme **exports générés**, fichiers de compatibilité ou entrées imposées par un outil externe ; leur source reste `pyproject.toml` et le lockfile retenu.
- Les configurations spécifiques à un environnement doivent rester minimales et référencer la configuration canonique plutôt que la recopier.
- Toute exception doit être justifiée par une limitation technique documentée ou un ADR.
#### Contrôles CI
- validation de la syntaxe et des métadonnées de `pyproject.toml` ;
- détection de configurations dupliquées ou divergentes ;
- contrôle que les exports de dépendances ont été régénérés ;
- vérification des dépendances manquantes, transitives ou inutilisées ;
- contrôle que les outils standards utilisent la configuration canonique.
### 2. Dockerfile — builds multi-stage par environnement
Les Dockerfiles applicatifs doivent utiliser des **stages nommés** afin de mutualiser les couches communes et de séparer clairement les environnements.
Structure de référence adaptable :
```docker
FROM python:3.14-slim AS base

FROM base AS dependencies

FROM dependencies AS development

FROM dependencies AS test

FROM dependencies AS build

FROM base AS runtime

FROM runtime AS production
```
Les noms exacts peuvent varier, mais les responsabilités doivent rester explicites.
#### Règles
- Mutualiser les éléments communs dans un stage `base` ou équivalent.
- Isoler l’installation et la construction des dépendances dans des stages dédiés afin d’exploiter le cache Docker.
- Le stage de développement peut inclure les outils de debug, de qualité et de test.
- Le stage de test doit permettre une exécution reproductible de la suite de tests.
- Le stage de build produit uniquement les artefacts nécessaires au runtime.
- Le stage de production doit être minimal, non privilégié, sans compilateurs, caches, sources inutiles ni outils de développement.
- Utiliser `COPY` de manière ciblée pour ne pas invalider inutilement les couches de dépendances.
- Les secrets de build ne doivent jamais être persistés dans une couche ; utiliser les mécanismes de secrets BuildKit ou l’injection du pipeline.
- Chaque cible doit pouvoir être construite explicitement avec `--target` lorsque cela est pertinent.
#### Contrôles CI
- présence de stages nommés pour les projets possédant plusieurs environnements ;
- existence d’une cible de production distincte ;
- utilisateur non root dans le runtime sauf justification documentée ;
- absence d’outils de compilation et de développement dans l’image finale ;
- analyse de vulnérabilités, taille et contenu de l’image finale ;
- build et test des cibles nécessaires avant publication.
### 3. Conteneurs — responsabilité unique et scope strict
Un conteneur applicatif contient uniquement l’application et les processus indispensables à son fonctionnement direct.
#### Règles obligatoires
- Un conteneur applicatif ne doit pas embarquer de reverse proxy HTTP ou TCP tel que Traefik, Nginx, Caddy, Apache ou HAProxy.
- Le conteneur expose son port applicatif interne et ne gère ni certificat public, ni terminaison TLS externe, ni routage multi-domaines, ni découverte globale des services.
- **Toute application ou interface exposée depuis le cluster doit obligatoirement utiliser le reverse proxy commun du cluster — actuellement Traefik.**
- Le routage entrant HTTP, HTTPS, TCP ou WebSocket, les domaines, les certificats TLS et les règles d’exposition sont déclarés au travers des ressources Kubernetes compatibles avec Traefik : `Ingress`, `IngressRoute`, `Service` et middlewares associés.
- Une application ne doit pas être exposée directement sur Internet par son conteneur, son pod, un port hôte ou un `NodePort`. Toute exception d’infrastructure doit être limitée, justifiée par un ADR, sécurisée et documentée.
- Les politiques transverses d’accès, redirection HTTPS, sécurité des en-têtes, limitation de débit, journalisation et intégration au SSO doivent être appliquées au niveau de Traefik lorsque cela est pertinent.
- Le produit reste indépendant de Traefik dans son code métier : il expose uniquement un port interne standard et reçoit sa configuration d’URL publique et de proxy par l’environnement de déploiement.
- Un pod peut contenir un sidecar seulement lorsqu’il remplit une responsabilité technique étroitement liée et explicitement justifiée ; il ne doit pas servir à contourner la séparation des projets ou à embarquer un reverse proxy applicatif.
- Les workers, schedulers ou traitements asynchrones doivent être déployés comme workloads séparés lorsqu’ils possèdent un cycle de vie, un scaling ou des ressources distinctes.
- Les bases de données, brokers, observabilité et autres services d’infrastructure restent des composants séparés et ne sont jamais intégrés à l’image applicative.
- Les adresses, ports externes, domaines et certificats sont fournis par la configuration de déploiement, jamais codés en dur dans l’image.
### Architecture attendue dans k3s
```plain text
Internet / réseau
        ↓
Traefik du cluster k3s
        ↓
Ingress / IngressRoute / Service
        ↓
Pod applicatif scopé
        ↓
Processus applicatif uniquement
```
### Anti-pattern interdit
```plain text
Pod ou conteneur applicatif
├── application
├── reverse proxy embarqué
├── gestion TLS publique
└── routage vers d’autres projets
```
### Contrôles CI et déploiement
- détection des installations ou configurations de reverse proxy dans une image applicative ;
- contrôle des processus lancés par l’image et du nombre de responsabilités embarquées ;
- validation que l’exposition Kubernetes passe par un `Service` et une ressource de routage compatible avec Traefik ;
- interdiction des certificats privés et configurations TLS publiques dans les images ;
- détection des domaines, IP ou ports d’infrastructure codés en dur ;
- vérification de la présence des probes, limites de ressources et politiques de sécurité attendues.
### Exceptions
Une distribution réellement standalone hors k3s peut nécessiter une topologie différente. Elle doit alors être fournie comme un profil ou un artefact séparé, avec un ADR explicite, sans modifier l’image applicative canonique ni imposer ce couplage aux déploiements du portfolio.
---
# Architecture & Engineering Standards V1 — DDD proportionné et profils de projet (2026-07-23)
Correspondance avec les annexes du repo — §1–2 profils & niveaux DDD → AR-000…AR-002 · §2 couches → AR-010…AR-013 · §3 frontières → AR-020…AR-022 · §4 Python → AR-030…AR-033 · §5 TypeScript → FE-010…FE-012 · §6 React → FE-020…FE-022 · §7 C#/Unity → AR-040…AR-044 · §8 Docker → CT-000…CT-014 · §9 k3s → CT-020…CT-024 · §10 tests → TS-000…TS-006 · §11 gouvernance → GV-010…GV-030 · §12 ordre de déploiement → GV-020.
<callout icon="🏛️" color="purple_bg">
	**Décision canonique :** les projets utilisent une architecture DDD/hexagonale proportionnée à leur complexité métier. Le domaine reste indépendant des frameworks et des infrastructures, mais les petits outils ne doivent pas être sur-architecturés.
</callout>
### Table de correspondance — où vit réellement chaque section (vérifié le 2026-07-31)
<table header-row="true">
<tr>
<td>Section de cette page</td>
<td>Source canonique dans `chrysa/shared-standards`</td>
<td>Distribuée aux repos ?</td>
</tr>
<tr>
<td>§1 Profils · §2 Architecture commune · §3 Frontières / bounded contexts</td>
<td>`standards/annexes/ARCHITECTURE-DDD.md`</td>
<td>Oui (annexe normative)</td>
</tr>
<tr>
<td>§4 Standard Python</td>
<td>Socle `standards/STANDARDS.chrysa.md`</td>
<td>Oui (bloc managé `chrysa:standards`)</td>
</tr>
<tr>
<td>§5 Standard TypeScript · §6 Standard React</td>
<td>`standards/annexes/FRONTEND.md`</td>
<td>Oui (annexe normative)</td>
</tr>
<tr>
<td>§7 Standard C# / .NET (dont cas Unity)</td>
<td>Socle `standards/STANDARDS.chrysa.md` — **aucune annexe dédiée à ce jour**</td>
<td>Partiel — à instruire</td>
</tr>
<tr>
<td>§8 Docker et environnements · §9 Standard k3s</td>
<td>`standards/annexes/CONTAINERS-K3S.md`</td>
<td>Oui (annexe normative)</td>
</tr>
<tr>
<td>§10 Standard de tests commun</td>
<td>`standards/annexes/TESTING.md`</td>
<td>Oui (annexe normative)</td>
</tr>
<tr>
<td>§11 Gouvernance des standards</td>
<td>`standards/annexes/GOVERNANCE.md`</td>
<td>Oui (annexe normative)</td>
</tr>
<tr>
<td>§12 Ordre de déploiement</td>
<td>Aucune — plan d'exécution historique, non normatif</td>
<td>Non</td>
</tr>
</table>
## 1. Profils obligatoires
Chaque dépôt doit déclarer un profil principal et, lorsque pertinent, un niveau DDD.
### Profils
- `library` : package publié, API publique minimale, compatibilité et versionnage sémantique ;
- `service` : API ou service réseau autonome ;
- `frontend` : application TypeScript/React consommant des contrats publics ;
- `worker` : traitement asynchrone, scheduler ou consumer indépendant ;
- `cli` : outil en ligne de commande ;
- `game` : projet C#/Unity ou moteur équivalent avec séparation domaine/runtime ;
- `infrastructure` : chart, manifests, opérateur ou composant de plateforme.
### Niveaux DDD
<table fit-page-width="true" header-row="true">
<tr>
<td>Niveau</td>
<td>Usage</td>
<td>Exigence</td>
</tr>
<tr>
<td>DDD-0</td>
<td>Scripts, migrations, petits outils techniques</td>
<td>Structure simple, fonctions testables, aucune cérémonie imposée</td>
</tr>
<tr>
<td>DDD-1</td>
<td>CRUD avec règles limitées</td>
<td>Séparation domaine/application/adapters lorsque cela clarifie les responsabilités</td>
</tr>
<tr>
<td>DDD-2</td>
<td>Domaine métier significatif</td>
<td>Entités, value objects, agrégats, invariants et événements de domaine</td>
</tr>
<tr>
<td>DDD-3</td>
<td>Domaine complexe ou distribué</td>
<td>Bounded contexts, anti-corruption layers, événements d’intégration et CQRS ciblé</td>
</tr>
</table>
### Déclaration de référence
```yaml
project_profile: service
architecture_style: ddd-hexagonal
ddd_level: 2
bounded_context: task-management
standards_version: "1"
```
## 2. Architecture commune à tous les langages
```plain text
Entrées / Présentation
          ↓
      Application
          ↓
        Domaine
          ↑
Infrastructure / Adapters
```
### Domaine
- contient le langage métier, les règles et les invariants ;
- ne dépend d’aucun framework web, ORM, système de fichiers, transport réseau ou SDK fournisseur ;
- ne dépend jamais des DTO d’API ou des modèles de persistance ;
- protège les transitions d’état par des méthodes métier explicites ;
- utilise des value objects lorsque l’identité, l’unité, la validation ou l’immutabilité ont une signification métier.
### Application
- orchestre les cas d’usage et les transactions ;
- coordonne les ports sans contenir les invariants fondamentaux ;
- gère les autorisations applicatives, l’idempotence et les unités de travail ;
- n’introduit commandes, handlers ou CQRS que lorsque la complexité le justifie.
### Infrastructure
- implémente les ports de persistance, transport, fichiers, cache, broker et services externes ;
- traduit les erreurs techniques vers les erreurs applicatives ;
- ne fuit pas dans le domaine ;
- reste remplaçable derrière des interfaces ou adapters locaux.
### Agrégats
- un agrégat possède une seule racine ;
- les invariants sont protégés par la racine ;
- les setters publics et mutations incontrôlées sont interdits ;
- une transaction métier modifie idéalement un seul agrégat ;
- les relations entre agrégats utilisent des identifiants plutôt que des graphes persistants complets ;
- les agrégats doivent rester petits et cohérents.
## 3. Frontières entre projets et bounded contexts
- Les entités, agrégats, repositories métier et modèles ORM d’un projet ne sont jamais partagés avec un autre projet.
- Deux bounded contexts peuvent avoir des concepts homonymes avec des modèles différents.
- Les échanges utilisent des SDK, API ou WebSocket versionnés et des DTO de contrat dédiés.
- Chaque consommateur possède une Anti-Corruption Layer ou un adapter local traduisant le contrat externe vers son propre domaine.
- Les événements de domaine restent internes ; seuls des événements d’intégration versionnés traversent les frontières.
## 4. Standard Python
### Structure recommandée pour DDD-2 et DDD-3
```plain text
src/<package>/
├── domain/
│   ├── entities/
│   ├── value_objects/
│   ├── aggregates/
│   ├── events/
│   └── services/
├── application/
│   ├── use_cases/
│   ├── commands/
│   ├── queries/
│   └── ports/
├── infrastructure/
│   ├── persistence/
│   ├── messaging/
│   └── external/
└── interfaces/
    ├── api/
    ├── cli/
    └── workers/
```
### Règles Python
- `pyproject.toml` reste la source canonique ;
- utiliser `[project]` pour le runtime et les groupes de dépendances pour test, lint, documentation et développement ;
- un seul lockfile canonique est versionné pour les applications et services ;
- les bibliothèques publiées déclarent des contraintes compatibles sans imposer leur résolution locale aux consommateurs ;
- Ruff assure formatage et lint ; choisir mypy ou Pyright comme vérificateur de référence ;
- `import-linter` protège les couches et imports interdits ; `deptry` contrôle la déclaration des dépendances ;
- Pydantic sert principalement aux frontières et DTO, pas comme substitut systématique aux objets du domaine ;
- aucun import FastAPI, Django ORM, SQLAlchemy, client HTTP ou broker dans `domain` ;
- temps, UUID, hasard et effets externes sont injectables ;
- `Any` hors adapter doit être justifié.
### Correction FastAPI
- `async def` est utilisé lorsque le chemin d’exécution est réellement non bloquant et awaitable ;
- `def` ou une isolation explicite est utilisée pour les bibliothèques bloquantes ;
- une route `async def` ne doit jamais masquer un appel bloquant important.
### Gate Python minimale
```plain text
ruff format --check
ruff check
mypy ou pyright
lint-imports
deptry .
pytest
lockfile check
```
## 5. Standard TypeScript
> ⛔ Corps normatif retiré le 2026-07-31 (duplication du canon). Source unique : `standards/annexes/FRONTEND.md` §1 — repo `chrysa/shared-standards`.
## 6. Standard React
> ⛔ Corps normatif retiré le 2026-07-31 (duplication du canon). Source unique : `standards/annexes/FRONTEND.md` §2–§4 — repo `chrysa/shared-standards`.
## 7. Standard C# / .NET
> ⛔ Corps normatif retiré le 2026-07-31 (duplication du canon). Source unique : socle `standards/STANDARDS.chrysa.md` — repo `chrysa/shared-standards`. Aucune annexe C#/.NET dédiée à ce jour : à créer avant toute nouvelle règle.
## 8. Docker et environnements
> ⛔ Corps normatif retiré le 2026-07-31 (duplication du canon). Source unique : `standards/annexes/CONTAINERS-K3S.md` + socle `STANDARDS.chrysa.md` (multi-stage `production`/`dev`) — repo `chrysa/shared-standards`.
## 9. Standard k3s
> ⛔ Corps normatif retiré le 2026-07-31 (duplication du canon). Source unique : `standards/annexes/CONTAINERS-K3S.md` (workload k3s, probes, sécurité, exposition Traefik) — repo `chrysa/shared-standards`.
## 10. Standard de tests commun
> ⛔ Corps normatif retiré le 2026-07-31 (duplication du canon). Source unique : `standards/annexes/TESTING.md` (pyramide de tests, règles, statut de gate E2E) — repo `chrysa/shared-standards`.
## 11. Gouvernance des standards
- toute règle possède un identifiant unique et stable ;
- toute collision d’identifiant est une erreur bloquante ;
- toute règle indique son profil, sa cible, son niveau DDD et son mode d’application ;
- les exceptions exigent un ADR, un propriétaire et une date d’expiration ;
- chaque règle indique si elle est automatisée ou contrôlée manuellement ;
- chaque dépôt expose la version de standards qu’il applique ;
- les règles sont versionnées et peuvent être dépréciées avec une période de migration ;
- les standards vivent dans le repo ; Notion reste une vue de gouvernance et de décision.
## 12. Ordre de déploiement
1. Corriger la règle FastAPI et les collisions d’identifiants.
2. Ajouter `csharp`, `docker`, `k3s`, `ddd` et `profiles` au référentiel.
3. Stabiliser les profils `library`, `service`, `frontend`, `worker`, `cli`, `game`, `infrastructure`.
4. Mettre à jour `project-init` pour générer ces profils.
5. Tester en anneau canari sur un projet Python, un projet React/TypeScript et un projet C#/Unity.
6. Passer progressivement de `info` à `warning`, puis à `error` après correction de la dette existante.
## Revue transverse des standards — 2026-07-27
> ⚠️ **Statut réel au 2026-07-31 : inventaire de gouvernance, non exécutable.** Aucun des 212 items n'est distribué ni gaté depuis cette page — seul `standards/STANDARDS.chrysa.md` (+ annexes) est inliné dans les repos. Les items 🔧 dérivé / 💡 suggestion / ⚖️ à-arbitrer n'ont ni identifiant stable, ni propriétaire, ni gate CI : à instruire un par un avant d'entrer au canon.
État au 2026-07-31 : les ✅ adopté et l'essentiel des 🔧 dérivé sont désormais dans le canon (socle + annexes). Cette section reste la file d'arbitrage des 💡 suggestion et ⚖️ à-arbitrer — voir aussi la section « Deferred » de standards/annexes/FRONTEND.md.
Sortie de la revue interactive des standards chrysa (artefact « Revue des standards chrysa »). **212 standards** répartis en 24 domaines. Cette page est la **vue de gouvernance** (§11) ; le canon exécutable vit dans `standards/STANDARDS.chrysa.md`.
**Maturité** : ✅ adopté (canon/pilier) · 🔧 dérivé (extrait des repos réels, validé) · 💡 suggestion (à instruire) · ⚖️ à-arbitrer.
**Bilan** : 85 ✅ adopté · 53 🔧 dérivé · 56 💡 suggestion · 18 ⚖️ à-arbitrer.
### Python & Backend (10)
*Runtime serveur : version, framework HTTP, ORM, tests, packaging, tooling.*
- ✅ adopté — **Python 3.14 (matrice CI 3.12 + 3.14)**
- ✅ adopté — **FastAPI ≥ 0.115 + Pydantic v2**
- ✅ adopté — **SQLAlchemy 2.0 async + Alembic**
- ✅ adopté — **Tests : pytest uniquement**
- ✅ adopté — **Packaging — pyproject.toml source unique**
- ✅ adopté — **Jamais de virtualenv dans un repo**
- ✅ adopté — **Linting Ruff + Mypy**
- ✅ adopté — **Skill async-patterns**
- ✅ adopté — **requirements\*.txt proscrits — pyproject + lockfile uniquement**
- 💡 suggestion — **Discipline de code Python stricte**
### Configs d'outils — Python (base commune) (12)
*Base extraite du pyproject.toml padam-av, nettoyée du spécifique Django. À arbitrer là où les valeurs divergent du canonique chrysa.*
- 🔧 dérivé — **Ruff — familles de règles (select)**
- 🔧 dérivé — **Ruff — ignore commun**
- ✅ adopté — **Ruff format**
- ✅ adopté — **Ruff isort**
- ⚖️ à-arbitrer — **Ruff limites — mccabe / pylint** · ⚠️ absent aujourd’hui
- ⚖️ à-arbitrer — **Mypy — strictness** · ⚠️ absent aujourd’hui
- ✅ adopté — **codespell**
- 🔧 dérivé — **pytest — core options**
- ✅ adopté — **coverage**
- ✅ adopté — **interrogate (docstrings)**
- 💡 suggestion — **vulture (dead code)**
- 💡 suggestion — **hypothesis + pytest-benchmark**
### Frontend — React / TypeScript (9)
*Interface : base React, UI, état, accessibilité, navigation, i18n.*
- ✅ adopté — **React 19 + TypeScript 7 + Vite 8**
- ✅ adopté — **shadcn/ui + Tailwind CSS**
- ✅ adopté — **TanStack Query + Zustand**
- ⚖️ à-arbitrer — **État client : lib dédiée, pas de singletons maison** · ⚠️ absent aujourd’hui
- ✅ adopté — **Dark mode + Accessibilité WCAG 2.1 AA**
- ✅ adopté — **L'état UI survit au reload & focus**
- ✅ adopté — **Navigation URL-addressable**
- ✅ adopté — **URLs & code sémantiques**
- ✅ adopté — **i18n react-i18next + fastapi-babel (FR + EN dès V1)**
### Configs Frontend — dérivé backoffice (3)
*Extrait de padam-av-backoffice (app/). Bases React/TS/Vitest réutilisables, avec les valeurs à réaligner sur le canonique.*
- ⚖️ à-arbitrer — **ESLint flat config**
- ✅ adopté — **tsconfig strict**
- ⚖️ à-arbitrer — **Vitest coverage**
### API design — REST (10)
*Contrat d'API : versioning, schéma, permissions, pagination. Dérivé des ViewSets/permissions réels, complété des manques connus.*
- 🔧 dérivé — **Versioning d'API par URL + versions autorisées explicites**
- 🔧 dérivé — **Schéma OpenAPI documenté par endpoint**
- 💡 suggestion — **Changelog d'API versionné dans la doc**
- 🔧 dérivé — **Permissions au niveau objet, résolues depuis la ressource**
- 🔧 dérivé — **Permissions composables (OR / AND)**
- 💡 suggestion — **Pagination + throttling par défaut sur les collections**
- 🔧 dérivé — **Réponses hypermedia (_links) pour découpler le front**
- 🔧 dérivé — **Contrat d'API standardisé et versionné (source des tests)**
- 💡 suggestion — **Serializers par action + projection des colonnes**
- 💡 suggestion — **Format d'erreur d'API standardisé**
### Base de données (5)
*Stockage relationnel et cache.*
- ✅ adopté — **PostgreSQL 16 + Redis 7**
- 🔧 dérivé — **Cache ORM avec dégradation transparente**
- 💡 suggestion — **Historique d'état borné (liste TTL + throttle d'écriture)**
- 💡 suggestion — **Anti N+1 : select_related / prefetch_related systématique**
- 💡 suggestion — **Migrations revues : linter, budget de temps, patterns sûrs**
### Conteneurs & Docker (11)
*Images, compose, hygiène de build, politique runtime, hébergement.*
- ✅ adopté — **Dockerfiles multi-stage (production + dev)**
- ✅ adopté — **Le stage dev doit hot-reload**
- ✅ adopté — **.dockerignore + HEALTHCHECK + pin**
- ✅ adopté — **Caches & artefacts générés hors arbre projet**
- ✅ adopté — **Conteneur app = app seule, pas de reverse proxy**
- 🔧 dérivé — **Conteneurisation par défaut — exemption réservée au besoin système direct**
- ✅ adopté — **Politique runtime (repos.yml)**
- ✅ adopté — **Hébergement self-hosted : principes stables, fournisseur interchangeable**
- ✅ adopté — **Registry GHCR privé**
- ✅ adopté — **Skill dockerfile-multistage**
- 💡 suggestion — **Sauvegardes testées + restauration vérifiée**
### Git · CI/CD · Release (11)
*Commits, branches, PR, versioning, changelog, qualité automatisée, docs.*
- ✅ adopté — **Conventional Commits**
- ✅ adopté — **Branches + merge (develop + squash)**
- ✅ adopté — **1 PR par issue + enforce-issue-link**
- ✅ adopté — **Versioning GitVersion (ContinuousDeployment)**
- ✅ adopté — **Changelog git-cliff**
- ✅ adopté — **Fichiers canoniques anti-drift**
- ✅ adopté — **SonarCloud (rating A, 0 hotspot)**
- ✅ adopté — **Pre-commit (detect-secrets + ruff + mypy + commitlint)**
- ✅ adopté — **Docs MkDocs → GitHub Pages**
- 💡 suggestion — **Squelette documentaire canonique par repo**
- 💡 suggestion — **Feature flags / rollout progressif**
### Configs partagées — lint / sécurité / CI (13)
*Fichiers de config transverses (uploadés + dérivés des repos). La plupart sont réutilisables tels quels ; deux divergences majeures à trancher.*
- ✅ adopté — **yamllint**
- ✅ adopté — **markdownlint**
- ✅ adopté — **hadolint**
- ✅ adopté — **zizmor (sécurité GitHub Actions)**
- ⚖️ à-arbitrer — **gitleaks**
- ⚖️ à-arbitrer — **quality-gate.json**
- ⚖️ à-arbitrer — **GitVersion — stratégie** · ⚠️ absent aujourd’hui
- ⚖️ à-arbitrer — **cliff.toml**
- 💡 suggestion — **csslintrc**
- 🔧 dérivé — **actionlint — lint des workflows CI**
- 🔧 dérivé — **Zéro instruction de debug committée**
- 🔧 dérivé — **.env.example synchronisé avec les variables réelles**
- 🔧 dérivé — **Blocage des gros fichiers & artefacts binaires**
### Hooks pre-commit — chrysa/pre-commit-tools (2)
*Dérivé des .pre-commit-config des deux repos. Ton propre repo de hooks applique déjà une grande partie des standards prose — c'est le socle déterministe.*
- 🔧 dérivé — **chrysa/pre-commit-tools — hooks maison**
- ⚖️ à-arbitrer — **Hooks standards (taplo, pygrep, texthooks)**
### Quality gates (métriques) (7)
*Seuils chiffrés vérifiables automatiquement.*
- ✅ adopté — **Couverture ≥ 85 %**
- ✅ adopté — **0 warning lint · Mypy clean · Sonar A**
- ✅ adopté — **Fonction ≤ 50 · fichier ≤ 500 · complexité ≤ 10**
- 🔧 dérivé — **Code documenté — docstrings obligatoires**
- 💡 suggestion — **Nommage sémantique — noms génériques bannis**
- 💡 suggestion — **Budgets de performance / SLO**
- 🔧 dérivé — **Baseline qualité — gate anti-régression**
### Tests & fixtures (7)
*Conventions de test dérivées des deux repos : factories, property-based, marqueurs, tests négatifs.*
- 🔧 dérivé — **Factories de test auto-découvertes + base async**
- 🔧 dérivé — **Property-based testing profilé (ci/dev/fast)**
- 🔧 dérivé — **Marqueurs pytest stricts (unit / redis / mqtt / integration)**
- 💡 suggestion — **Au moins un test négatif par API**
- 💡 suggestion — **Performance des tests : transaction et scope maîtrisés**
- 💡 suggestion — **Conventions de test unifiées**
- 💡 suggestion — **Sélecteurs de test stables (data-testid)**
### IA & Agents (6)
*Modèles, orchestration, indépendance provider.*
- ✅ adopté — **Claude API (primary) + Ollama (fallback)**
- ✅ adopté — **LangGraph (stateful) + PydanticAI (structured)**
- ✅ adopté — **Skill agent-patterns**
- ✅ adopté — **Pilier : indépendance provider LLM**
- 🔧 dérivé — **Projet utilisant l'IA → RTK + graphify obligatoires**
- 💡 suggestion — **Sécurité des actions agentiques (manifeste, risque, sandbox)**
### Async, tâches & scheduling (7)
*Exécution asynchrone et jobs planifiés. Patterns dérivés du worker réel + garde-fous de robustesse connus.*
- 🔧 dérivé — **Config de scheduler pilotée par la BDD (re-registration à chaud)**
- 🔧 dérivé — **Découverte automatique des tâches (factory + globbing)**
- 🔧 dérivé — **Dédup + verrou d'exécution sur les tâches planifiées**
- 🔧 dérivé — **Rapport de tâche structuré (statut / durée / erreurs)**
- 🔧 dérivé — **Fan-out résilient (collecte des exceptions)**
- 💡 suggestion — **Politique de retry/backoff + dead-letter**
- 🔧 dérivé — **Seed de config par migration réversible idempotente**
### Sécurité applicative (6)
*Protection des accès et des secrets. Dérivé du code auth/secrets + en-têtes et rate-limiting à généraliser.*
- 🔧 dérivé — **Chiffrement au repos des secrets en base**
- 🔧 dérivé — **Anti brute-force sur l'auth, en fail-open**
- 💡 suggestion — **En-têtes de sécurité explicites (CORS / CSP / HSTS)**
- 💡 suggestion — **Throttling global des endpoints**
- 💡 suggestion — **Rotation des secrets**
- 🔧 dérivé — **Hooks statiques anti-patterns de sécurité au commit**
### Observabilité & Erreurs (12)
*Remontée d'erreurs, monitoring, automations.*
- ✅ adopté — **Pattern withErrorHandling**
- ✅ adopté — **Sentry → GitHub issues (norme)**
- ✅ adopté — **Monitoring Sentry + Uptime Kuma (self-hosted)**
- 🔧 dérivé — **Logs JSON structurés**
- 💡 suggestion — **ID de corrélation par requête**
- 💡 suggestion — **Télémétrie vendor-neutral (collector) + attributs obligatoires**
- 💡 suggestion — **Endpoints health / readiness standard**
- 💡 suggestion — **Politique de niveaux de log**
- 💡 suggestion — **Zéro secret / PII dans les logs**
- 💡 suggestion — **Agrégation centralisée + rétention bornée**
- 💡 suggestion — **Tout bug = une issue tracée et dédupliquée**
- 💡 suggestion — **Test de non-régression avant clôture d'un bug**
### Outillage & cycle projet (8)
*Interface Makefile, skills partagés, continuité de session agent.*
- ✅ adopté — **Makefile — nommage canonique**
- ✅ adopté — **Makefile — socle minimal + zéro install locale en conteneur**
- ✅ adopté — **Skills partagés (à la demande)**
- ✅ adopté — **Session lifecycle (primer + memory + hindsight)**
- 🔧 dérivé — **Toute base de dev provient du générateur canonique**
- ✅ adopté — **Catalogue d'outillage canonique — un outil par fonction**
- ✅ adopté — **Versions d'outillage épinglées et synchronisées**
- 🔧 dérivé — **Actions CI épinglées par SHA**
### Architecture & DDD — backend (10)
*Découpage domaine, isolation des dépendances, frontières typées. Conventions à porter en standard de flotte : elles rendent la stabilité mécanique plutôt que disciplinaire.*
- 🔧 dérivé — **Un module = un bounded context**
- 🔧 dérivé — **Services stateless — pas d'état, pas de DI**
- 🔧 dérivé — **Logique d'accès aux données confinée à une couche requête**
- 🔧 dérivé — **Ports & adapters pour les intégrations tierces**
- 🔧 dérivé — **DTO de frontière séparés des entités de persistance**
- 🔧 dérivé — **Value objects immuables pour les concepts métier**
- 🔧 dérivé — **Constantes via enums, jamais de magic value**
- 🔧 dérivé — **Config éclatée : un fichier par intégration**
- 🔧 dérivé — **Couche utilitaire = infrastructure pure, zéro métier**
- 💡 suggestion — **Profil de projet + niveau DDD déclarés par repo**
### Robustesse backend — suggestions (6)
*Renforcements à rendre mécaniques plutôt que disciplinaires. Chacun transforme une garantie de stabilité en check ou en construction impossible à contourner.*
- 💡 suggestion — **Contrats de dépendance (import-linter)**
- 💡 suggestion — **Hiérarchie d'exceptions à racine commune**
- 💡 suggestion — **Factory client HTTP : timeout + retry + circuit-breaker**
- 💡 suggestion — **Idempotence des commandes et handlers**
- 💡 suggestion — **Machine à états formelle pour les cycles de vie**
- 💡 suggestion — **Interrupteur de dégradation gracieuse**
### Architecture frontend (10)
*Fondations à standardiser comme conventions de flotte front : point d'entrée réseau unique, frontière données/rendu, état serveur maîtrisé.*
- 🔧 dérivé — **Un seul client API (singleton)**
- 🔧 dérivé — **Couche services entre UI et réseau**
- 🔧 dérivé — **Une lib de cache pour TOUT l'état serveur**
- 🔧 dérivé — **Split container / présentational + pages fines**
- 🔧 dérivé — **Error boundary + remontée observable en racine**
- 🔧 dérivé — **Provider + hook colocalisés, garde de contexte typée**
- 🔧 dérivé — **Routes protégées via wrappers symétriques**
- 🔧 dérivé — **Triade loading / error / empty par conteneur**
- 🔧 dérivé — **Indicateur de progression global piloté par le client API**
- 🔧 dérivé — **Navigation sans rechargement + services sans effet de navigation**
### Robustesse frontend — suggestions & points chauds (15)
*Manques et incohérences typiques du front. Plusieurs points chauds (⚠️) valent arbitrage : ils créent un risque réel de bug silencieux.*
- ⚖️ à-arbitrer — **Factory de clés de cache**
- 💡 suggestion — **Validation runtime au bord du client API**
- ⚖️ à-arbitrer — **Source unique pour l'auth** · ⚠️ absent aujourd’hui
- 💡 suggestion — **i18n jusque dans le fallback d'erreur**
- ⚖️ à-arbitrer — **Adopter ou supprimer les patterns non utilisés** · ⚠️ absent aujourd’hui
- 💡 suggestion — **Code-splitting par route**
- 💡 suggestion — **Mock réseau au niveau transport pour les tests**
- ⚖️ à-arbitrer — **Un seul système i18n** · ⚠️ absent aujourd’hui
- ⚖️ à-arbitrer — **Variables d'env typées et validées, sans échappatoire**
- 💡 suggestion — **Mutations : invalidation systématique du cache serveur**
- 💡 suggestion — **Gating de permission centralisé (hook)**
- 💡 suggestion — **Notifications via un service unique**
- 💡 suggestion — **Formatage date / nombre localisé**
- ⚖️ à-arbitrer — **Un seul emplacement canonique par composant** · ⚠️ absent aujourd’hui
- 💡 suggestion — **Laisser le compilateur gérer la mémoïsation**
### Design — UX / UI & identité (10)
*Socle pour des applications professionnelles à identité forte : design system tokenisé, marque cohérente, patterns d'interaction et bonnes pratiques UX. Absent des repos scannés — à établir comme canon de flotte (complète l'a11y WCAG déjà actée côté frontend).*
- ✅ adopté — **Design tokens = source unique du style**
- ✅ adopté — **Brand kit versionné (palette, typo, logo, iconographie)**
- ✅ adopté — **Design system vivant (composants documentés)**
- ✅ adopté — **Échelle d'espacement & grille systématiques**
- ✅ adopté — **Hiérarchie typographique définie**
- ✅ adopté — **États d'interaction & feedback systématiques**
- ✅ adopté — **UX writing cohérent (voix, ton, messages actionnables)**
- ✅ adopté — **Motion standardisé + prefers-reduced-motion**
- ✅ adopté — **Responsive / mobile-first, breakpoints partagés**
- ✅ adopté — **Contrat design ↔ dev (specs + tokens exportés)**
### Mes suggestions — configs manquantes (5)
*Ce que je recommande d'ajouter à la base commune, absent des repos scannés.*
- 💡 suggestion — **.editorconfig**
- 💡 suggestion — **commitlint config committée**
- ⚖️ à-arbitrer — **Décision line-length canonique**
- 💡 suggestion — **pip-audit / osv-scanner en CI + hook**
- 💡 suggestion — **Renovate/Dependabot canonique**
### Transverse & Gouvernance (17)
*Règles qui traversent toute la flotte : langue, auth, config, souveraineté, décisions.*
- ✅ adopté — **Langue : anglais partout**
- ✅ adopté — **Auth 4 modes**
- ✅ adopté — **Zéro constante hardcodée**
- ⚖️ à-arbitrer — **Logging Notion (source de vérité)** · ⚠️ absent aujourd’hui
- ✅ adopté — **Pilier : indépendance GAFAM**
- ✅ adopté — **Pilier : données de perso portables**
- ✅ adopté — **Pilier : config k8s in-project**
- ✅ adopté — **Pilier : couche d'adaptation**
- ✅ adopté — **Format ADR réfutable**
- 💡 suggestion — **Découplage inter-projets : contrats versionnés uniquement**
- 💡 suggestion — **Gates de cycle de vie par type de projet**
- ✅ adopté — **Pilier : multilingue par design**
- ✅ adopté — **Pilier : multi-thème par design**
- ✅ adopté — **Pilier : responsive téléphone par design**
- ✅ adopté — **Pilier : espace de gestion de profil par défaut**
- ✅ adopté — **Pilier : zéro duplication → libs transverses, sans les multiplier**
- 💡 suggestion — **Confidentialité & RGPD par design**
---
## Standard transverse — gestion fine des erreurs, résilience et remontées d’information (2026-07-31)
> ✅ Livré dans le canon le 2026-07-31 — PR chrysa/shared-standards #254 (`standards/STANDARDS.chrysa.md`), mergée à 14:40 UTC et distribuée via le bloc managé.
✅ Livré dans le canon le 2026-07-31 — socle : « Failures are contained, and observable » et « Identity goes through the cluster SSO first » (+ ligne Auth de la table de stack), annexe FRONTEND.md FE-038 pour l'indicateur global. PR chrysa/shared-standards#254, propagé aux 63 repos.
<callout icon="🛟" color="orange_bg">
	**Règle obligatoire : une erreur locale ne doit pas provoquer une panne globale lorsque le fonctionnement principal peut continuer.** Les systèmes doivent préserver autant que possible le travail, la progression et la capacité d’action de l’utilisateur, tout en remontant un diagnostic exploitable aux équipes et aux outils de supervision.
</callout>
### Principes obligatoires
- Toute erreur doit être **classifiée**, **typée** et associée à un code stable ; aucune exception générique ne doit traverser les frontières applicatives sans traduction.
- Une erreur doit être contenue dans le plus petit périmètre possible : composant, requête, tâche, lot, fonctionnalité ou intégration concernée.
- Une fonctionnalité secondaire indisponible ne doit pas bloquer le parcours principal ; le produit doit préférer une **dégradation contrôlée** à une indisponibilité complète.
- Les opérations longues ou multi-étapes doivent sauvegarder leur progression, supporter la reprise et distinguer succès total, succès partiel et échec.
- Les données déjà saisies ou produites doivent être préservées autant que possible : brouillon, checkpoint, file d’attente locale, reprise idempotente ou export de secours.
- Aucun échec ne doit être silencieux : l’utilisateur, l’opérateur ou le système de supervision doit recevoir une information adaptée à son rôle.
- Les mécanismes de résilience ne doivent jamais masquer durablement une panne ; fallback, cache ou retry doivent produire des métriques et événements observables.
### Taxonomie minimale des erreurs
Chaque erreur exposée par un contrat public doit préciser au minimum :
- `code` stable et documenté ;
- catégorie : validation, métier, authentification, autorisation, conflit, dépendance externe, ressource, timeout, indisponibilité, corruption ou erreur interne ;
- sévérité ;
- caractère `retryable` ou définitif ;
- périmètre et fonctionnalité impactés ;
- `correlation_id` ou identifiant de trace ;
- message utilisateur actionnable ;
- message opérateur suffisamment précis pour le diagnostic ;
- cause technique conservée dans la télémétrie, jamais exposée brute à l’utilisateur.
### Résilience et continuité de service
- Définir des timeouts explicites pour toute opération réseau, disque, base de données, modèle IA, commande système ou appel inter-service.
- Utiliser des retries bornés uniquement pour les erreurs transitoires, avec backoff exponentiel, jitter et respect de l’idempotence.
- Mettre en place circuit breaker, bulkhead, limitation de concurrence et file d’attente lorsque la dépendance ou la charge le justifie.
- Prévoir un fallback explicite : cache récent, données locales, mode lecture seule, fonctionnalité réduite, traitement différé ou fournisseur alternatif.
- Les intégrations externes doivent être désactivables indépendamment sans empêcher le démarrage ou l’usage des fonctions cœur.
- Les traitements par lots doivent isoler les éléments en erreur, poursuivre les éléments valides et produire un rapport de succès partiel.
- Les opérations destructives ou irréversibles doivent être transactionnelles, compensables ou protégées par une stratégie de rollback.
- Les erreurs en boucle doivent être détectées afin d’éviter retry storms, spam d’alertes, surcharge d’une dépendance ou consommation incontrôlée de ressources.
### Expérience utilisateur
- Afficher un message clair indiquant **ce qui n’a pas fonctionné**, **ce qui reste disponible** et **l’action possible** : réessayer, corriger, continuer en mode dégradé, reprendre plus tard ou contacter le support.
- Ne jamais afficher de stack trace, secret, token, chemin interne, requête brute ou détail d’infrastructure à l’utilisateur final.
- Fournir un identifiant d’incident ou de corrélation copiable lorsque le problème nécessite une investigation.
- Éviter les modales bloquantes lorsque l’erreur ne bloque qu’une zone de l’interface ; préférer un état local, une bannière, une notification ou un statut contextualisé.
- Ne pas perdre la navigation, le formulaire, le brouillon ou la sélection en cours à cause d’un échec récupérable.
- Indiquer clairement les données potentiellement périmées, incomplètes ou issues d’un fallback.
- En mode hors ligne ou connexion instable, permettre la consultation locale et mettre en file les actions compatibles pour synchronisation ultérieure.
### Remontées d’information et observabilité
- Produire des logs structurés avec timestamp, environnement, service, version, sévérité, code d’erreur, `correlation_id`, opération et contexte technique utile.
- Corréler logs, métriques, traces distribuées, événements métier et audit-log sur un même identifiant de requête ou d’action.
- Centraliser les remontées dans la couche d’observabilité retenue, notamment Mirador ou le backend compatible, sans rendre le code métier dépendant d’un fournisseur précis.
- Définir des métriques minimales : taux d’erreur, latence, saturation, retries, timeouts, ouvertures de circuit breaker, fallbacks utilisés, files en attente, succès partiels et abandons utilisateur.
- Les alertes doivent être dédupliquées, regroupées et déclenchées sur des seuils ou SLO pertinents ; un événement isolé récupéré ne doit pas systématiquement réveiller un opérateur.
- Toute alerte doit préciser : service, environnement, sévérité, impact utilisateur estimé, début, fréquence, version déployée, lien vers traces/logs et propriétaire responsable.
- Les erreurs critiques, corruptions, pertes de données, violations de sécurité et indisponibilités du parcours cœur doivent générer une remontée prioritaire et persistante.
- Les erreurs récurrentes non critiques doivent alimenter le backlog qualité avec fréquence, impact cumulé et proposition de correction.
- Logs, traces et événements ne doivent contenir ni secret ni donnée personnelle non nécessaire ; appliquer masquage, minimisation, rétention et contrôle d’accès.
### Contrats API, CLI et tâches asynchrones
- Les API doivent retourner des statuts cohérents et un schéma d’erreur stable ; les exceptions internes ne doivent jamais devenir directement la réponse publique.
- Les SDK doivent exposer des exceptions ou résultats typés permettant au consommateur de décider entre retry, fallback, message utilisateur ou abandon.
- Les CLI doivent écrire les résultats sur `stdout`, les diagnostics sur `stderr`, utiliser des codes de sortie documentés et proposer des erreurs actionnables ; les modes `--json` ne doivent pas mélanger logs et sortie structurée.
- Les jobs asynchrones doivent exposer leur état, leur progression, les erreurs par élément, la possibilité de reprise et un résultat final consultable.
- Les webhooks et consommateurs de messages doivent être idempotents, gérer les doublons, les messages empoisonnés et une dead-letter queue ou quarantaine équivalente.
### Tests et gates CI à ajouter progressivement
- tests unitaires des traductions d’erreurs et codes publics ;
- tests de timeout, retry borné, circuit breaker, fallback et reprise ;
- tests de succès partiel et d’isolation des éléments en échec ;
- tests garantissant la conservation des données utilisateur lors d’une erreur récupérable ;
- tests de contrat sur les schémas d’erreur API et SDK ;
- contrôle de l’absence de `except` ou `catch` silencieux et d’exceptions génériques non justifiées ;
- contrôle de l’absence de stack traces, secrets et données sensibles dans les réponses et logs ;
- scénarios de chaos ciblés sur les dépendances critiques ;
- vérification qu’une fonctionnalité secondaire indisponible n’empêche pas le démarrage ou le parcours principal ;
- validation que les alertes critiques ont un propriétaire et une procédure de diagnostic ou runbook.
### Definition of Done minimale
Une fonctionnalité n’est pas terminée tant que ses erreurs attendues ne sont pas documentées, testées, présentées correctement à l’utilisateur, corrélées dans l’observabilité et accompagnées d’un comportement de reprise, de fallback ou d’échec propre adapté à leur impact.
---
## Standard transverse — authentification SSO, OAuth et comptes locaux (2026-07-31)
> ✅ Livré dans le canon le 2026-07-31 — PR chrysa/shared-standards #254 (`standards/STANDARDS.chrysa.md`), mergée à 14:40 UTC et distribuée via le bloc managé.
✅ Livré dans le canon le 2026-07-31 — socle : « Failures are contained, and observable » et « Identity goes through the cluster SSO first » (+ ligne Auth de la table de stack), annexe FRONTEND.md FE-038 pour l'indicateur global. PR chrysa/shared-standards#254, propagé aux 63 repos.
<callout icon="🔐" color="blue_bg">
	**Règle obligatoire : tout produit déployé dans le cluster doit être intégré au SSO commun.** Le SSO constitue le mode d’authentification principal de l’écosystème, sans supprimer les connexions OAuth externes ni les comptes locaux lorsque ceux-ci sont nécessaires au produit, à son autonomie ou à la continuité de service.
</callout>
### Principes obligatoires
- Toute application interactive déployée dans le cluster doit proposer une connexion par le fournisseur d’identité commun du cluster.
- L’intégration SSO doit utiliser en priorité un protocole standard et interopérable, notamment **OpenID Connect** sur OAuth 2.x ; SAML peut être supporté lorsqu’un contexte d’entreprise l’impose.
- Aucun produit ne doit développer son propre mécanisme SSO propriétaire ni dépendre directement des internals du fournisseur d’identité.
- L’application conserve son propre modèle métier d’utilisateur, de profil, de préférences et de droits applicatifs ; l’identité externe est liée au compte local par un identifiant stable et versionné.
- Les méthodes OAuth externes — par exemple GitHub, Google, Microsoft ou autres fournisseurs autorisés — peuvent rester disponibles en complément du SSO.
- Les connexions locales peuvent rester disponibles pour les installations autonomes, le mode hors ligne, les utilisateurs externes, les comptes techniques explicitement autorisés ou la reprise d’urgence.
- Un même utilisateur doit pouvoir relier plusieurs méthodes d’authentification à un seul compte sans créer de doublons de profil, de droits ou de données.
- La désactivation d’une méthode d’authentification ne doit pas supprimer le compte ni ses données ; elle retire uniquement le moyen de connexion concerné.
### Hiérarchie des modes de connexion
1. **SSO du cluster** : méthode principale pour les utilisateurs internes et les produits intégrés à l’écosystème.
2. **OAuth externe** : méthode complémentaire pour les utilisateurs ou partenaires autorisés.
3. **Compte local** : méthode autonome ou de secours, disponible selon le contexte produit et la politique de sécurité.
Cette hiérarchie ne doit pas empêcher un produit destiné à être distribué séparément, publié en open source ou installé chez un tiers de fonctionner sans le SSO chrysa.
### Autorisation et cycle de vie des identités
- L’authentification prouve l’identité ; les autorisations restent gérées par des rôles, permissions et politiques métier explicites.
- Les groupes ou rôles provenant du SSO doivent être traduits par un adapter vers les rôles applicatifs ; aucune logique métier ne doit dépendre directement du nom interne d’un groupe du fournisseur d’identité.
- Le provisionnement automatique à la première connexion est autorisé uniquement avec une politique claire de rôle initial et de périmètre d’accès.
- Le départ, la suspension ou la révocation d’un utilisateur doit invalider ses sessions et ses jetons selon un délai défini.
- Les comptes administrateurs, comptes de secours et comptes techniques doivent être séparés des comptes humains ordinaires, fortement protégés et audités.
- Les communications machine-à-machine utilisent des identités de service, certificats ou flux OAuth adaptés ; elles ne doivent jamais réutiliser les identifiants d’un utilisateur humain.
### Sécurité et continuité de service
- Les mots de passe locaux sont stockés avec un algorithme de hachage moderne, une politique de migration et une protection contre le credential stuffing et le brute force.
- MFA ou authentification renforcée doit pouvoir être imposée par le SSO pour les rôles sensibles.
- Les jetons doivent avoir une durée de vie limitée, une audience explicite, des scopes minimaux et une rotation documentée.
- Les secrets clients, clés de signature et certificats sont injectés par la gestion de secrets du cluster et ne sont jamais versionnés dans les dépôts.
- Une indisponibilité du SSO ne doit pas provoquer de perte de données ni interrompre les traitements non interactifs déjà autorisés.
- Les sessions existantes peuvent continuer dans une fenêtre limitée et documentée lorsque cela reste compatible avec le niveau de risque.
- Le mode de secours local ne doit pas devenir un contournement permanent du SSO : son activation, son usage et sa désactivation sont tracés.
### Expérience utilisateur
- La page de connexion présente clairement le SSO comme méthode recommandée, puis les fournisseurs OAuth et la connexion locale autorisés.
- Une erreur du fournisseur d’identité doit être expliquée sans exposer de données sensibles et proposer une action utile : réessayer, utiliser une autre méthode autorisée ou contacter le support.
- Les redirections après authentification doivent ramener l’utilisateur à l’action ou à la page initialement demandée.
- Les conflits de comptes et les tentatives de liaison entre identités doivent utiliser une procédure explicite de vérification afin d’éviter la prise de contrôle d’un compte existant.
### Observabilité et audit
- Les succès, échecs, révocations, liaisons de comptes, changements de rôle et usages du mode de secours doivent produire des événements d’audit structurés.
- Les événements doivent inclure au minimum un identifiant de corrélation, le produit, l’environnement, la méthode d’authentification, le résultat et la catégorie d’échec.
- Les journaux ne doivent contenir ni mot de passe, ni jeton complet, ni secret, ni donnée d’identité non nécessaire.
- Les anomalies importantes — hausse d’échecs, boucles de redirection, fournisseur indisponible, tentatives répétées ou changements de privilèges — doivent remonter vers la plateforme d’observabilité et d’alerte.
### Contrôles CI et conformité
- vérifier la présence de l’intégration SSO pour tout produit interactif destiné au cluster ;
- interdire les implémentations cryptographiques ou protocolaires maison lorsqu’une bibliothèque standard maintenue existe ;
- vérifier la validation de l’issuer, de l’audience, de l’état OAuth, du nonce, des redirections et de la signature des jetons ;
- tester la première connexion, la reconnexion, la déconnexion, la révocation, la liaison de comptes et les conflits d’identité ;
- tester l’indisponibilité du fournisseur d’identité et le comportement du mode de secours ;
- contrôler que les rôles applicatifs ne dépendent pas directement des internals du fournisseur SSO ;
- contrôler l’absence de secrets ou de jetons dans les logs, traces, URLs et dépôts.
### Definition of Done
Un produit déployable dans le cluster n’est pas considéré comme prêt tant que :
- son intégration au SSO commun est fonctionnelle et testée ;
- ses méthodes OAuth et locales autorisées sont documentées ;
- la liaison entre identités évite les doublons et les prises de contrôle ;
- les rôles, révocations, erreurs et modes de secours sont testés ;
- les événements d’authentification et d’autorisation sont observables et auditables ;
- le produit peut toujours être distribué ou déployé indépendamment au moyen d’un adapter ou d’une configuration d’identité alternative.
---
## Standard TypeScript / JavaScript — chargement global des pages (2026-07-31)
<callout icon="⏳" color="blue_bg">
	**Règle obligatoire : toute application web TypeScript ou JavaScript doit afficher un indicateur de chargement global couvrant l’intégralité de la page lors du chargement initial et des transitions de navigation nécessitant des données.**
</callout>
### Comportement attendu
- Une **barre de progression globale**, visible sur toute la largeur de la page et placée dans une zone stable de l’interface, doit signaler le chargement initial, les changements de route et les rechargements majeurs de données.
- La barre globale complète les états locaux : skeletons, spinners de composants, boutons en attente et placeholders restent utilisés lorsque seule une zone de la page est concernée.
- Le chargement global ne doit pas masquer inutilement une interface déjà exploitable ni bloquer les actions indépendantes. Le contenu précédent peut rester visible tant que sa cohérence est préservée.
- L’indicateur démarre immédiatement pour les opérations perceptibles, progresse de manière crédible et disparaît uniquement lorsque les données indispensables au nouvel écran sont disponibles ou qu’une erreur exploitable est affichée.
- Aucun indicateur ne doit rester bloqué indéfiniment : timeout, annulation, changement de route et erreur doivent toujours terminer explicitement l’état de chargement.
- Les requêtes concurrentes doivent être agrégées par un gestionnaire central afin d’éviter le clignotement, les démarrages multiples et la disparition prématurée de la barre.
- Un délai visuel minimal et un court seuil d’apparition peuvent être appliqués pour éviter les flashs sur les chargements très rapides, sans cacher une attente réelle.
- La navigation arrière, les données en cache, le prefetch et les mises à jour optimistes doivent conserver une expérience fluide ; la barre ne doit apparaître que lorsqu’une attente utilisateur réelle subsiste.
### Accessibilité et UX
- La zone principale concernée utilise `aria-busy="true"` pendant le chargement et revient systématiquement à `false` à la fin.
- L’indicateur ne repose pas uniquement sur la couleur et respecte les préférences `prefers-reduced-motion`.
- Le focus clavier n’est ni perdu ni déplacé vers le loader ; après une navigation, la gestion du focus suit les règles d’accessibilité de la SPA.
- Un chargement long doit pouvoir afficher un libellé utile, puis basculer vers un message d’erreur actionnable avec réessai lorsque nécessaire.
- Les dimensions de la page et des composants doivent rester stables pour limiter le layout shift.
### Architecture recommandée
- Le loader global est fourni par le shell ou layout racine et non réimplémenté dans chaque page.
- Il est raccordé au routeur, à la couche de récupération des données et aux mutations majeures au travers d’une API interne unique.
- L’état de chargement global doit être dérivé d’opérations identifiées et annulables, pas d’un booléen partagé modifié arbitrairement par tous les composants.
- Les bibliothèques choisies restent encapsulées derrière un composant ou service interne afin de pouvoir les remplacer sans modifier toutes les pages.
### Tests obligatoires
- chargement initial de chaque type de page ;
- navigation lente entre routes ;
- plusieurs requêtes concurrentes ;
- données partiellement disponibles ou servies depuis le cache ;
- annulation et navigation rapide successive ;
- timeout, erreur réseau et réessai ;
- absence de loader bloqué après succès ou erreur ;
- conformité clavier, lecteur d’écran et réduction des animations.
### Definition of Done frontend
Une page TypeScript/JavaScript n’est pas considérée terminée si ses chargements initiaux et transitions majeures ne déclenchent pas correctement la barre globale, si ses chargements locaux ne sont pas représentés, ou si une erreur peut laisser l’interface dans un état de chargement permanent.
---
## Standard transverse — Makefiles modulaires et limite de taille (2026-07-31)
> ✅ Livré dans le canon le 2026-08-01 — PR chrysa/shared-standards#277, socle « Modular Makefiles — 500 lines max, split by domain ». Le corps ci-dessous reste la vue de gouvernance ; le canon exécutable est standards/STANDARDS.chrysa.md.
<callout icon="🧩" color="yellow_bg">
	**Règle obligatoire : aucun Makefile maintenu manuellement ne doit dépasser 500 lignes.** Lorsqu’il approche ou dépasse cette limite, il doit être découpé en plusieurs Makefiles thématiques, lisibles et indépendamment maintenables.
</callout>
### Principes obligatoires
- Le `Makefile` racine reste un **point d’entrée et d’orchestration** : il expose les commandes principales, charge les fichiers thématiques et fournit l’aide globale.
- Les responsabilités sont séparées dans des fichiers dédiés, par exemple :
	- `make/dev.mk` — environnement et commandes de développement ;
	- `make/test.mk` — tests, couverture et qualité ;
	- `make/docker.mk` — build, run, publication et nettoyage des images ;
	- `make/k8s.mk` — déploiement et opérations Kubernetes ;
	- `make/db.mk` — migrations, seeds, sauvegardes et restauration ;
	- `make/release.mk` — versionnement, changelog et publication ;
	- `make/docs.mk` — documentation ;
	- `make/security.mk` — scans et contrôles de sécurité.
- Les fichiers thématiques sont chargés explicitement avec `include` ou `-include` depuis le Makefile racine.
- Une cible ne doit exister qu’à un seul endroit ; les doublons, variantes presque identiques et copier-coller entre fichiers sont interdits.
- Les variables communes, fonctions et conventions partagées sont centralisées dans un fichier dédié tel que `make/common.mk`.
- Les noms de cibles restent cohérents, prévisibles et regroupés par domaine, par exemple `test-unit`, `docker-build`, `k8s-deploy`.
- Les dépendances entre Makefiles doivent rester simples et orientées : un fichier thématique ne doit pas créer de cycle d’inclusion.
- Chaque cible publique doit être documentée dans une commande `make help` générée ou maintenue depuis les commentaires des cibles.
- Les commandes complexes, longues ou métier doivent être déplacées vers des scripts versionnés et testables ; le Makefile ne doit pas devenir un langage applicatif.
### Contrôles CI
- échouer si un Makefile maintenu manuellement dépasse **500 lignes** ;
- vérifier que le Makefile racine charge correctement les fichiers thématiques ;
- détecter les cibles dupliquées et les cycles d’inclusion ;
- exécuter `make help` et un ensemble minimal de cibles de validation ;
- contrôler que les scripts appelés existent, sont exécutables et utilisent des chemins portables.
### Definition of Done
Un système de commandes Make n’est conforme que si le Makefile racine reste lisible, si chaque domaine est isolé dans un fichier thématique, si aucune cible n’est dupliquée et si aucun Makefile maintenu manuellement ne dépasse 500 lignes.
---
## Complément obligatoire — structure canonique des Makefiles basée sur `base-makefile` (2026-07-31)
<callout icon="🧱" color="blue_bg">
	**Tous les Makefiles de l’écosystème doivent dériver de la structure canonique du dépôt ****`Forge-Stack-Workshop/base-makefile`****, et plus précisément du modèle ****`Makefile.with-sub-folder`****.** Ce dépôt constitue la source de vérité de la structure, des conventions d’aide et du mécanisme de chargement des fragments.
</callout>
Référence canonique : [Forge-Stack-Workshop/base-makefile — Makefile.with-sub-folder](https://github.com/Forge-Stack-Workshop/base-makefile/blob/main/Makefile.with-sub-folder).
### Structure obligatoire
```plain text
project-root/
├── Makefile
└── makefiles/
    ├── common.Makefile
    ├── development.Makefile
    ├── quality.Makefile
    ├── tests.Makefile
    ├── docker.Makefile
    ├── ci.Makefile
    ├── docs.Makefile
    ├── security.Makefile
    ├── database.Makefile
    ├── kubernetes.Makefile
    └── release.Makefile
```
La liste exacte des fragments dépend du projet : seuls les domaines réellement utilisés sont créés. Les noms restent thématiques, explicites et cohérents entre les dépôts.
### Règles obligatoires
- Le `Makefile` racine est dérivé du modèle `Makefile.with-sub-folder` et reste un **orchestrateur léger** : chargement des fragments, cible par défaut, aide globale et contrôles structurels.
- Les cibles fonctionnelles sont placées dans des fichiers `makefiles/*.Makefile`, regroupés par thème.
- Le mécanisme de découverte, d’inclusion et de regroupement de l’aide doit rester compatible avec le modèle canonique.
- Chaque cible publique possède une description `## ...` exploitable par `make help`.
- L’aide regroupe les commandes par catégorie dérivée du nom du fragment.
- Les fragments techniques non destinés à l’utilisateur, comme les variables, fonctions et règles globales, peuvent être exclus de l’affichage de l’aide selon la convention du référentiel.
- Les recettes utilisent les conventions communes du référentiel, notamment la réduction du bruit d’exécution avec `@` lorsque la commande n’a pas besoin d’être affichée.
- Le nom du projet, les chemins, les ports et les paramètres sont configurables ; aucune valeur propre à un ancien projet ne doit être copiée en dur depuis le template.
- Chaque fichier Makefile maintenu manuellement reste limité à **500 lignes maximum**. Au-delà, le fragment est lui-même séparé en sous-domaines cohérents.
- Les commandes complexes, longues ou nécessitant des tests unitaires sont déplacées dans des scripts dédiés ; les Makefiles les orchestrent sans contenir toute leur logique.
- Aucune cible, variable ou fonction commune ne doit être dupliquée dans plusieurs fragments.
- Les inclusions cycliques, l’ordre implicite fragile entre fragments et les dépendances par chemin local vers un autre dépôt sont interdits.
### Mode de dépendance au référentiel
- `Forge-Stack-Workshop/base-makefile` est une **dépendance de standardisation et de génération**, pas une dépendance réseau au runtime.
- Les projets consomment une version **épinglée par tag ou commit** du modèle, directement ou par l’intermédiaire de `project-init`.
- Une copie générée ou vendorée peut être conservée dans le dépôt afin de garantir les usages hors ligne et la reproductibilité.
- Une application ne doit jamais télécharger le Makefile depuis la branche `main` pendant un build de production.
- Les améliorations génériques sont d’abord apportées dans `base-makefile`, puis propagées aux projets ; elles ne doivent pas être réimplémentées séparément dans chaque dépôt.
- Les extensions propres à un projet restent dans ses fragments thématiques et ne modifient pas inutilement le chargeur, l’aide ou les conventions communes.
- Toute divergence structurelle durable nécessite un ADR précisant la limitation du modèle, l’impact et la stratégie de réalignement.
### Contrôles CI et pre-commit
- vérifier la présence du `Makefile` racine et du dossier `makefiles/` dès que le projet comporte plusieurs domaines de commandes ;
- vérifier que le Makefile racine reste compatible avec `Makefile.with-sub-folder` ;
- vérifier que tous les fragments utilisent l’extension `.Makefile` et un nom thématique explicite ;
- bloquer tout fichier Makefile de plus de 500 lignes ;
- vérifier que chaque cible publique possède une description pour `make help` ;
- détecter les cibles dupliquées, inclusions cycliques et variables communes redéfinies de manière incohérente ;
- comparer la structure au référentiel épinglé et signaler la dérive ;
- exécuter au minimum `make help` et les cibles de validation structurelle dans la CI ;
- vérifier qu’aucun téléchargement réseau du template n’est nécessaire pendant le build ou l’exécution.
### Definition of Done
Un Makefile n’est pas conforme tant qu’il n’utilise pas la structure multi-fichiers de `Makefile.with-sub-folder`, que ses commandes ne sont pas regroupées par domaine, que son aide n’est pas générée selon les conventions communes, ou qu’un de ses fichiers dépasse 500 lignes sans découpage documenté.
---
## Extension canonique — gouvernance, données, exploitation et consultation (2026-07-31)
<callout icon="📚" color="blue_bg">
	Les standards transverses prioritaires sont adoptés et regroupés dans la page [Standards transverses prioritaires — gouvernance, données et exploitation](https://app.notion.com/p/3ae59293e35e81fca372e84631c7c2b3).
</callout>
### Nouveaux standards
- `STD-GOV-001` — gouvernance et cycle de vie des standards ;
- `STD-DATA-001` — données, persistance, migrations, sauvegarde et restauration ;
- `STD-OPS-001` — production readiness ;
- `STD-API-001` — API, SDK, événements et webhooks ;
- `STD-SUPPLY-001` — sécurité de la chaîne logicielle ;
- `STD-PRIVACY-001` — vie privée et données personnelles ;
- `STD-DEPLOY-001` — promotion des artefacts et déploiement ;
- `STD-UX-STATE-001` — états comportementaux obligatoires des interfaces ;
- `STD-CONFIG-001` — configuration et feature flags ;
- `STD-TEST-001` — tests fondés sur les risques ;
- `STD-PERF-001` — budgets de performance et de coûts ;
- `STD-AI-QUALITY-001` — qualité et évaluation des fonctions IA.
### Consultation et intégration
Le projet autonome [Standards Hub](https://app.notion.com/p/3ae59293e35e81968bd7c949fe2dbd85) fournit la surface de consultation et d’intégration :
- API HTTP versionnée et OpenAPI ;
- interface web de catalogue, recherche, profils, historique et diff ;
- CLI utilisable contre l’API ou un artefact local hors ligne ;
- export JSON, YAML et Markdown ;
- intégration read-only des résultats de `guideline-checker`.
### Répartition des responsabilités
- `shared-standards` : source normative et profils versionnés ;
- `Standards Hub` : index reconstruisible, API, web et CLI de consultation ;
- `guideline-checker` : évaluation déterministe de conformité ;
- `project-init` et les générateurs : application des profils aux nouveaux dépôts ;
- Notion : documentation, décisions et pilotage, jamais source technique exclusive.
### Exigence machine-readable
Tout nouveau standard doit être publiable sous une forme structurée et stable contenant au minimum : identifiant, version, statut, propriétaire, portée, profils, relations, contrôles automatisés, provenance Git et checksum. Une règle non indexable ou impossible à relier à un profil est considérée incomplète.
---
## STD-NOTION-TASK-001 — Tâches Notion cadrées et prêtes à être exécutées (2026-07-31)
<callout icon="✅" color="green_bg">
	**Règle obligatoire : toute tâche placée dans une file d’exécution doit être suffisamment cadrée pour qu’un humain ou un agent puisse la commencer sans rechercher le contexte implicite, redéfinir le besoin ou prendre une décision métier non documentée.**
</callout>
### Principe
Une idée, une note, une demande vague ou un sujet à explorer peut rester dans l’Inbox ou dans un statut **À cadrer**. En revanche, une tâche ne peut passer à **Prête**, **À faire**, **Planifiée** ou **En cours** que si sa Definition of Ready est satisfaite.
### Definition of Ready obligatoire
Chaque tâche exécutable doit contenir, directement ou par relations explicites :
- un **titre orienté action**, commençant de préférence par un verbe et nommant clairement l’objet concerné ;
- un **objectif** et le résultat attendu ;
- un **périmètre précis**, incluant ce qui est dans le scope et, lorsque l’ambiguïté est possible, ce qui en est exclu ;
- un **livrable identifiable** et son emplacement attendu : dépôt, page Notion, document, environnement, fichier, PR, configuration ou autre artefact ;
- des **critères d’acceptation vérifiables** permettant de déterminer objectivement si la tâche est terminée ;
- le **projet, domaine, chantier ou parent** auquel elle appartient ;
- les **entrées nécessaires** : liens, fichiers, pages, décisions, ADR, standards, exemples, maquettes, identifiants ou données ;
- les **dépendances, prérequis et blocages** connus ;
- un **propriétaire** ou au minimum un rôle d’exécution clairement désigné ;
- une **priorité** et un niveau d’effort ou une taille suffisante pour son ordonnancement ;
- les **contraintes applicables** : sécurité, données, compatibilité, stack, environnement, licence, UX, hors ligne, SSO, Traefik ou autres standards pertinents ;
- la méthode de **validation** attendue : tests, revue, démonstration, contrôle visuel, audit, métrique ou preuve d’exécution.
### Atomicité et découpage
- Une tâche exécutable poursuit **un résultat principal**.
- Si plusieurs résultats peuvent être réalisés, validés ou livrés indépendamment, la tâche doit être séparée en sous-tâches thématiques.
- Une tâche parent utilisée pour regrouper un chantier n’est pas elle-même considérée comme exécutable ; seules ses sous-tâches respectant la Definition of Ready le sont.
- Les travaux de recherche ou d’analyse sont autorisés uniquement si leur question, leurs sources minimales, leur livrable et leur critère de fin sont définis.
- Les décisions encore ouvertes doivent être traitées par une tâche de décision ou un ADR distinct avant de rendre la tâche d’exécution prête.
### Interdictions
Une tâche ne doit pas être considérée comme prête lorsqu’elle :
- utilise uniquement un intitulé vague comme « améliorer X », « continuer Y », « revoir Z », « faire le nécessaire » ou « investiguer » sans résultat attendu ;
- exige de parcourir l’intégralité du workspace pour deviner le contexte pertinent ;
- dépend d’une décision humaine non prise ;
- masque plusieurs projets, livrables ou changements indépendants dans une seule ligne ;
- ne précise pas comment vérifier le résultat ;
- possède un blocage connu non résolu tout en étant placée dans la file d’exécution active.
### Règles de statut
- **Inbox / Idée / À cadrer** : informations incomplètes autorisées, mais la tâche n’est pas exécutable.
- **Prête / À faire / Planifiée** : Definition of Ready complète et prérequis satisfaits.
- **En cours** : tâche prête, propriétaire identifié et travail effectivement commencé.
- **Bloquée** : cause, dépendance attendue, prochaine action et propriétaire du déblocage documentés.
- **Terminée** : critères d’acceptation et Definition of Done validés avec preuve ou lien vers le livrable.
### Cas techniques
Pour une tâche modifiant du code, de l’infrastructure, des données ou une intégration, préciser également lorsque pertinent :
- dépôt, branche ou composant ciblé ;
- fichiers, modules, API ou ressources susceptibles d’être modifiés ;
- tests attendus et commandes de validation ;
- migrations, compatibilité et impacts inter-projets ;
- stratégie de rollback ou de restauration ;
- documentation et observabilité à mettre à jour.
### Agents et automatisations
- Une tâche créée ou enrichie par une IA respecte exactement la même Definition of Ready qu’une tâche humaine.
- Un agent peut proposer le cadrage manquant, mais ne doit pas inventer silencieusement une décision métier, une contrainte ou un critère d’acceptation.
- Une tâche insuffisamment cadrée doit être renvoyée vers **À cadrer** avec la liste explicite des informations manquantes.
- Toute exécution automatique utilise l’identifiant stable de la tâche et journalise le plan, les actions, les résultats et les preuves associées.
### Contrôles recommandés
- propriété ou formule **Prête à exécuter** calculée depuis les champs obligatoires ;
- vue dédiée aux tâches incomplètes ou incohérentes ;
- blocage automatique du passage à un statut exécutable lorsque les informations minimales manquent ;
- détection des titres vagues, tâches sans projet, sans critères d’acceptation, sans livrable ou avec dépendances non résolues ;
- audit régulier des tâches anciennes, surdimensionnées, orphelines ou durablement bloquées.
### Definition of Done du standard
- le template canonique des tâches expose la Definition of Ready ;
- les vues d’exécution n’affichent que des tâches réellement prêtes ;
- les tâches incomplètes restent dans l’Inbox ou une file de cadrage ;
- les assistants, automatisations et intégrations utilisent la même règle de préparation ;
- le futur workspace auto-hébergé conserve ce modèle indépendamment de Notion.
---
## STD-NOTION-MAINT-001 — Maintenance continue des fiches Notion
**Statut : adopté · priorité P0**
<callout icon="🔄" color="blue_bg">
	**Règle obligatoire : les fiches Notion doivent refléter l’état réel et actuel de leur sujet.** Toute avancée, décision, modification de périmètre, apparition de risque ou changement de dépendance significatif entraîne la mise à jour des fiches concernées dans le même flux de travail.
</callout>
### Périmètre
Cette règle s’applique notamment aux :
- fiches projet et produit ;
- tâches et sous-tâches ;
- standards, ADR et décisions ;
- études, roadmaps, gates et kill-tests ;
- hubs, dépendances, relations et pages de suivi ;
- fiches travaux, jeux, services et initiatives d’entreprise.
### Déclencheurs obligatoires de mise à jour
Une fiche doit être révisée lorsqu’un des événements suivants survient :
- tâche commencée, bloquée, débloquée, terminée, abandonnée ou découpée ;
- commit, pull request, merge, release, déploiement ou migration modifiant l’état réel ;
- nouvelle décision humaine ou ADR ;
- changement de scope, d’architecture, de stack, de priorité ou de stratégie ;
- ajout, suppression ou modification d’une dépendance ou d’un consommateur ;
- découverte d’un risque, d’une dette, d’une incohérence ou d’une hypothèse invalidée ;
- franchissement ou échec d’un gate, d’un kill-test ou d’un critère d’acceptation ;
- modification d’une date, d’un budget, d’un responsable ou d’une prochaine action ;
- remplacement, fusion, dépréciation, archivage ou changement de source de vérité.
### Informations à maintenir
Selon la nature de la fiche, la mise à jour doit couvrir les éléments concernés parmi :
- cycle de vie, statut et maturité ;
- description et périmètre réellement retenu ;
- prochaine action immédiatement exécutable ;
- Definition of Done, critères d’acceptation, gates et kill-tests ;
- tâches terminées, restantes, bloquées ou devenues inutiles ;
- dépendances, relations, consommateurs et impacts transverses ;
- risques, dettes, hypothèses et décisions ouvertes ;
- version, branche, release, déploiement ou environnement réellement atteint ;
- preuves : PR, commit, issue, artefact, rapport, capture, ADR ou lien vers la source technique ;
- date de dernière vérification et, lorsque pertinent, prochaine date de revue.
### Règles de cohérence
- La fiche canonique présente d’abord **l’état courant** ; l’historique daté ne doit pas masquer ou contredire la situation actuelle.
- Une ancienne information devenue fausse est corrigée, marquée comme historique ou supersédée ; elle ne reste pas présentée comme vérité active.
- Les avancées ne sont jamais déduites uniquement d’une intention, d’une tâche créée ou d’un plan : elles exigent une preuve vérifiable.
- Une tâche n’est pas considérée terminée si la documentation Notion nécessaire n’a pas été actualisée.
- La clôture d’une tâche doit mettre à jour sa fiche parent, les sous-tâches, les dépendances et la prochaine action lorsque ces éléments sont affectés.
- Les pages liées ne recopient pas tout le contenu : elles mettent à jour leurs responsabilités propres et référencent la source canonique.
- Les décisions humaines récentes priment sur les snapshots et contenus générés plus anciens ; les divergences sont signalées et réconciliées.
- Le code, les contrats publiés et l’état du runtime font foi pour les faits techniques ; Notion doit être réaligné sur ces preuves sans devenir une copie brute du dépôt.
### Automatisations et agents
- Les agents peuvent proposer ou appliquer une mise à jour uniquement à partir de preuves identifiées et traçables.
- Toute mise à jour générée distingue fait vérifié, déduction, hypothèse et opinion.
- Aucun agent ne marque une tâche, un gate ou un projet comme terminé sur la seule base de sa propre production non validée.
- Les mises à jour automatiques doivent être idempotentes, conserver les décisions humaines et éviter l’accumulation de journaux contradictoires.
- Les écarts détectés entre Notion, Git, CI, runtime et documentation sont remontés comme éléments à réconcilier, avec leur date et leur niveau de confiance.
### Cadence minimale
- Projet en développement actif : mise à jour à chaque avancée significative et revue au minimum hebdomadaire.
- Projet en maintenance : mise à jour à chaque changement réel et revue selon sa cadence de maintenance.
- Projet bloqué : mise à jour dès que le blocage, son propriétaire, sa condition de sortie ou son échéance change.
- Projet gelé ou archivé : aucune maintenance régulière, mais raison, date et condition de réactivation doivent rester explicites.
### Definition of Done documentaire
Une évolution n’est complètement livrée que lorsque :
- les fiches Notion concernées reflètent l’état obtenu ;
- les tâches obsolètes sont clôturées, remplacées ou requalifiées ;
- la prochaine action est recalculée ;
- les relations et dépendances impactées sont à jour ;
- les preuves et décisions associées sont accessibles ;
- aucune information active connue comme fausse ou périmée ne subsiste dans la fiche canonique.
### Contrôles recommandés
- détection des fiches actives sans mise à jour depuis leur cadence attendue ;
- détection des projets dont la prochaine action est terminée, vague ou contradictoire avec le statut ;
- comparaison périodique Notion ↔ GitHub ↔ CI ↔ déploiements ;
- détection des tâches terminées dont le parent reste inchangé ;
- détection des dépendances unilatérales ou incohérentes ;
- signalement des snapshots historiques présentés comme état courant ;
- tableau de bord des fiches stale, divergentes ou sans preuve récente.
---
## STD-NOTION-MAINT-001 — Maintenance continue des fiches Notion
<callout icon="🔄" color="blue_bg">
	**Règle obligatoire : les fiches Notion sont des documents vivants.** Elles doivent être maintenues au fil des avancées afin de refléter fidèlement l’état réel du projet, du produit, du chantier ou du standard.
</callout>
### Déclencheurs de mise à jour
Une fiche doit être révisée après tout changement significatif, notamment :
- décision métier ou technique validée ;
- nouvelle fonctionnalité, modification de périmètre ou suppression ;
- évolution d’architecture, de contrat, de dépendance ou de relation ;
- changement de statut, maturité, priorité, gate, risque ou hypothèse mortelle ;
- tâche importante terminée, bloquée, abandonnée ou replanifiée ;
- release, déploiement, migration, incident ou correction structurante ;
- nouveau dépôt, nouvelle URL, nouveau document, ADR, schéma, illustration ou livrable ;
- écart détecté entre Notion, le code, la documentation, le runtime ou les décisions récentes.
### Éléments à maintenir
Selon le type de fiche, vérifier et actualiser au minimum :
- résumé, objectif, périmètre et hors scope ;
- état réel, cycle de vie, maturité et progression ;
- prochaine action réellement exécutable ;
- Definition of Done, gates et critères d’acceptation ;
- risques, blocages, hypothèses et décisions ouvertes ;
- dépendances, consommateurs, projets liés et relations canoniques ;
- roadmap, tâches et priorités ;
- architecture, stack, interfaces publiques et contrats ;
- liens vers le dépôt, versions, releases, documentation et artefacts ;
- date de dernière vérification et source utilisée lorsque l’information peut devenir obsolète.
### Cohérence avec les sources de vérité
- Le code, les contrats versionnés, les ADR et le runtime font foi pour les faits techniques qu’ils possèdent.
- Notion conserve le contexte, le pilotage, les décisions, les relations et la vision consolidée ; il ne doit pas afficher comme actuel un état contredit par une source canonique plus récente.
- Toute divergence détectée doit être corrigée ou marquée explicitement comme écart à résoudre.
- Les informations historiques utiles sont conservées avec une date et une mention `supersédé`, `historique` ou `archive`, plutôt que mélangées à l’état courant.
- Les affirmations telles que `latest`, `terminé`, `production`, `CI verte` ou `déployé` doivent être datées ou reliées à une preuve vérifiable.
### Responsabilité et fréquence
- Le propriétaire du projet ou de la fiche est responsable de sa fraîcheur, même lorsque la mise à jour est proposée par une automatisation ou une IA.
- Les fiches actives sont revues selon leur cadence de maintenance et après chaque jalon significatif.
- Une fiche sans activité peut conserver son contenu, mais son statut, sa date de revue et sa raison d’inactivité doivent rester explicites.
- Une IA ou une automatisation peut détecter et proposer les mises à jour ; les changements structurants, suppressions, fusions et décisions restent soumis à validation humaine.
### Definition of Done documentaire
Une évolution n’est pas considérée comme complètement terminée lorsque :
- la fiche projet ou produit décrit encore l’ancien fonctionnement ;
- les propriétés de pilotage ne correspondent plus à l’état réel ;
- la prochaine action est obsolète ou déjà accomplie ;
- les relations, dépendances ou liens sont incorrects ;
- les décisions et conséquences importantes ne sont pas documentées.
### Contrôles recommandés
- détecter les fiches actives non révisées au-delà de leur cadence ;
- comparer dates de commits, releases, tâches et dernières modifications Notion ;
- signaler les propriétés contradictoires avec le contenu ;
- détecter les prochaines actions déjà terminées ou non exécutables ;
- signaler les liens cassés, versions périmées et références `latest` non datées ;
- produire une file de réconciliation soumise à validation humaine.
---
## Standard transverse — modèle de branches Git (2026-08-01)
> ✅ Livré dans le canon le 2026-08-01 — PR chrysa/shared-standards#277, socle « Branch model ». Appliqué à la flotte : 69/69 dépôts chrysa conformes (audit scripts/audit-branch-policy.sh, ledger compliance/branch-policy.json).
<callout icon="🔒">
	Règle obligatoire : main représente le code déployé en production et est une branche protégée ; develop est la branche par défaut et la branche de travail ; le seul moyen d'envoyer du code sur main est une pull request depuis develop ; la mise en production est déclenchée par une nouvelle release.
</callout>
### Principes obligatoires
- main = le code déployé en production. Branche protégée : aucun push direct, aucun force-push, aucune suppression ; tout changement arrive par pull request.
- develop est la branche par défaut du dépôt (celle que clone GitHub) et la cible d'intégration de tout le travail. Un dépôt dont la branche par défaut est main est un défaut, pas une variante.
- Toute PR feature/bugfix/chore cible develop. Une PR de feature ouverte sur main est fermée ou re-ciblée.
- Le seul chemin vers main est une pull request depuis develop — ou, pour une urgence de production, une branche hotfix/ fusionnée dans le même temps vers develop pour éviter toute divergence.
- La mise en production est déclenchée par une nouvelle release (tag GitVersion + changelog git-cliff + workflow de release), pas par le merge lui-même. Aucun déploiement manuel depuis un poste.
### Mécanisation
- scripts/audit-branch-policy.sh — audit lecture seule de la flotte (une requête GraphQL par page de dépôts) ; sortie 1 en cas de dérive ; ledger compliance/branch-policy.json.
- scripts/apply-branch-policy.sh — application idempotente : création de develop, bascule de la branche par défaut, création de main si absente, protection de main (PR requise, force-push et suppression bloqués).
- Limite connue : GitHub refuse la protection de branche sur un dépôt privé d'un compte/organisation en plan gratuit (cas Forge-Stack-Workshop/fastapi-app-generator) — signalé en avertissement, ce n'est pas un défaut du dépôt.
---
## Standard transverse — assistant flottant intégré (2026-08-01)
> ✅ Livré dans le canon le 2026-08-01 — PR chrysa/shared-standards#281, socle « A floating assistant where it earns its place », release v1.1.0-237 distribuée à la flotte.
<callout icon="🧭">
	Règle obligatoire : tout produit exposant une surface non évidente (cockpit dense, formulaire multi-étapes, console de requête/graphe/config, panneau d'administration à jargon métier) embarque un assistant flottant contextuel. Le test de valeur passe d'abord : une bulle de chat vide est pire que rien.
</callout>
- Contextuel, pas un chat générique : il reçoit la route, la sélection et l'état visible ; sa première proposition porte sur cet écran-là.
- Opt-in, désactivé par défaut derrière un flag documenté ; refermable ; position et état persistés par utilisateur ; ne vole jamais le focus, ne s'ouvre pas d'office à chaque visite.
- Gouverné comme tout agent : Q/R en lecture = R0/R1 ; dès qu'il agit, enveloppe agentique complète (manifeste versionné, E/S typées, moindre privilège, niveau de risque, confirmation, dry-run, journal d'audit).
- Indépendant du fournisseur : inférence via le port local avec au moins 2 adaptateurs testés ; dégradation en panneau d'aide documenté si aucun modèle n'est joignable.
- Accessible et discret : atteignable et fermable au clavier (Échap), annoncé aux technologies d'assistance, respect de prefers-reduced-motion, chargement paresseux derrière un squelette aux bonnes dimensions.
- Cadré et honnête : répond depuis les données et docs du produit, dit « je ne sais pas », annonce ce qu'il a fait après avoir agi.
- Variante bureau (pattern floating-agent) : mêmes règles hors navigateur — overlay uniquement, refermable, aucune capture non consentie.
---
## Standard transverse — architecture de dépôt lisible par un agent (2026-08-01)
> ✅ Livré dans le canon le 2026-08-01 — PR chrysa/shared-standards#282, socle « The repository architecture is legible to an agent », release v1.1.0-237 distribuée à la flotte.
<callout icon="🤖">
	Règle obligatoire : l'architecture du dépôt est optimisée pour un agent IA (Claude), pas seulement pour un humain. Un agent lit par une fenêtre étroite : il ne peut pas parcourir trente fichiers pour déduire une convention. Un dépôt où l'agent doit deviner est un défaut.
</callout>
- Un point d'entrée qui dit quoi faire maintenant : CLAUDE.md (règles du dépôt au-dessus du bloc socle) + primer.md ; AGENTS.md et copilot-instructions.md générés depuis la même source.
- Un README.md par dossier non trivial : rôle, structure, ce qui y va et surtout ce qui n'y va pas.
- Structure prévisible et adressable par le nom : couches nommées comme l'architecture, une classe par fichier portant son nom, chemin de test miroir du chemin source.
- Unités petites par contrat : les seuils 500 / 50 / 10 existent pour qu'une unité tienne en une lecture.
- Coutures lisibles par la machine : signatures typées, contrats OpenAPI/Pydantic, config YAML derrière un loader typé, docs/adr/ pour le pourquoi.
- Outillage sous forme de tâches : cibles make et skills partagés plutôt que des lignes de commande à reconstituer.
- Continuité de session : décisions, problèmes connus et progression dans .claude/memory/.
Test mécanique : un agent neuf, sans historique de conversation, doit trouver le point d'entrée, la couche à toucher, la commande à lancer et la porte de qualité à passer, à partir des seuls fichiers versionnés.
---
## Standard transverse — exposition des ports conteneurs (2026-08-03)
> ✅ Livré dans le canon le 2026-08-03 — PR chrysa/shared-standards#318 : annexe CONTAINERS-K3S.md règle CT-015 + ancrage socle « Only a publicly useful port is published ».
<callout icon="🔌">
	Règle obligatoire : seuls les ports réellement utiles au public sont publiés vers l'extérieur. Tout le reste reste dans le réseau Docker et se joint par nom de service. Publié par défaut : rien.
</callout>
### Principes obligatoires
- Une entrée \`ports:\` n'existe que pour ce qu'un humain ou un système extérieur à la stack consomme vraiment — en pratique le point d'entrée public du produit, et rien d'autre.
- Restent internes, les publier est un défaut : bases de données et leurs ports d'admin, caches, brokers et leurs UI de management, moteurs de recherche, stockage objet, APIs internes et gRPC, endpoints de métriques et /debug, mail catchers, outillage de dev, et le port de l'app quand un reverse proxy est déjà devant.
- Les services se joignent par nom de service sur le réseau du compose (\`expose:\`, voire rien du tout — le DNS de service suffit).
### Pourquoi c'est une règle et pas une préférence
- \`ports:\` est un trou dans le pare-feu : sur un hôte Docker, un port publié est inséré dans nftables/iptables AVANT ufw/firewalld — le pare-feu hôte ne le filtre pas. \`ports: "5432:5432"\` met la base sur Internet même sur une machine qui refuse tout.
- Un port publié en 0.0.0.0 écoute sur toutes les interfaces, y compris celles qu'on a oubliées. Un besoin réel côté hôte se lie explicitement au loopback (\`127.0.0.1:5432:5432\`), dans un override local, jamais dans la stack de base versionnée.
- Deux stacks qui publient le même port entrent en collision : en interne chaque projet garde le port canonique ; publier impose une arithmétique de ports que personne ne documente.
### Équivalent Kubernetes
- Tout \`Service\` est en \`ClusterIP\` sauf le point d'entrée exposé par l'ingress. \`NodePort\`, \`LoadBalancer\`, \`hostPort\` et \`hostNetwork\` sont des recours de dernier ressort exigeant un ADR — un \`hostPort\` contourne en plus silencieusement la \`NetworkPolicy\` (CT-023).
### Contrôle CI
- CT-024 : compter les ports publiés par fichier compose — un \`ports:\` sur une base, un cache, un broker ou un endpoint de métriques échoue le contrôle ; une publication en 0.0.0.0 hors point d'entrée public est signalée.
---
## Standard transverse — exposition des ports Docker (2026-08-03)
> ✅ Livré dans le canon le 2026-08-03 — PR chrysa/shared-standards#318, annexe CONTAINERS-K3S.md règle CT-015 + ancrage socle.
<callout icon="🔌">
	Règle obligatoire : seuls les ports réellement utiles au public sont publiés vers l'extérieur. Tout le reste reste sur le réseau Docker et se joint par nom de service. Une entrée \`ports:\` n'existe que pour le point d'entrée public du produit.
</callout>
### Reste interne — le publier est un défaut
- Bases de données et leurs ports d'admin, caches, brokers et leurs UI de management, moteurs de recherche, stockage objet.
- APIs internes et services gRPC, endpoints de métriques et de debug, mail catchers, outillage de dev.
- Le port de l'application elle-même quand un reverse proxy la sert déjà (cf. la règle « app containers ship the app only »).
### Pourquoi c'est une règle et pas une préférence
- \`ports:\` est un trou dans le pare-feu : un port publié est inséré dans nftables/iptables AVANT ufw/firewalld — le pare-feu de l'hôte ne le filtre pas. \`ports: "5432:5432"\` met la base sur Internet même sur une machine qui refuse tout.
- Publier sur 0.0.0.0 lie toutes les interfaces, y compris celles qu'on a oubliées. Si un outil côté hôte a vraiment besoin d'accès (migration, debugger), lier explicitement la loopback : \`127.0.0.1:5432:5432\`, et c'est un confort de dev local, jamais un défaut de déploiement.
- Deux stacks qui publient le même port entrent en collision ; en interne chaque projet garde son port canonique.
### Équivalent Kubernetes
- Tout \`Service\` est \`ClusterIP\` sauf le point d'entrée servi par l'ingress. \`NodePort\`, \`LoadBalancer\` et \`hostPort\`/\`hostNetwork\` sont des expositions de dernier recours, chacune nécessitant un ADR — et un \`hostPort\` contourne silencieusement les \`NetworkPolicy\` (CT-023).
Les fichiers compose de développement suivent la même règle : un port ouvert « juste pour regarder » est ouvert sur la loopback, dans un fichier d'override, jamais dans la stack de base versionnée.
