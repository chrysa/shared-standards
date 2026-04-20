# Session report chrysa · 2026-04-20T21:58:17+02:00

**Durée** : 435s · **Log** : `/home/anthony/Documents/perso/projects/chrysa/.chrysa-master-20260420-2151.log`
**Flags** : dry=false · parallel=false · retry=1 · cron=false


## Résultats

| Stage | Statut | Durée | Exit | Attempts |
|-------|--------|-------|------|----------|
| 0-preflight | ✓ OK | 4s | 0 | 1 |
| 1-fix-terminal | ✓ OK | 1s | 0 | [0;34m→[0m Scan des rc files pour 'auto_install.py'

[0;33m⚠[0m  2 occurrence(s) trouvée(s) :
  \033[0;90m/home/anthony/.zshrc:166\033[0m
        # disabled 2026-04-20 · fichier manquant · # disabled 2026-04-20 · fichier manquant · # disabled 2026-04-20 · fichier manquant · # disabled 2026-04-20 · fichier manquant · && python3 scripts/auto_install.py 2>/dev/null
  \033[0;90m/home/anthony/.zshrc:178\033[0m
            # disabled 2026-04-20 · fichier manquant · # disabled 2026-04-20 · fichier manquant · # disabled 2026-04-20 · fichier manquant · # disabled 2026-04-20 · fichier manquant · (python3 "$HOME/Documents/perso/projects/chrysa/agent-config/scripts/auto_install.py" --quiet && touch "$marker") &

[0;34m→[0m Recherche du vrai auto_install.py sur le disque
[0;32m✓[0m auto_install.py trouvé :
  · /home/anthony/Documents/perso/projects/chrysa/_archived/agent-config/scripts/auto_install.py

[0;34m→[0m Action auto : comment
[0;34m→[0m Backup : /home/anthony/.zshrc.bak-20260420-215107
[0;32m✓[0m /home/anthony/.zshrc · lignes commentées
[0;34m→[0m Backup : /home/anthony/.zshrc.bak-20260420-215107
[0;32m✓[0m /home/anthony/.zshrc · lignes commentées

[0;34m→[0m Vérif · recherche restes d'erreur
/home/anthony/Documents/perso/projects/chrysa/fix-terminal-auto_install.sh: ligne 186: [[: 0
0 : erreur de syntaxe dans l'expression (le symbole erroné est « 0 »)
/home/anthony/Documents/perso/projects/chrysa/fix-terminal-auto_install.sh: ligne 186: [[: 0
0 : erreur de syntaxe dans l'expression (le symbole erroné est « 0 »)
/home/anthony/Documents/perso/projects/chrysa/fix-terminal-auto_install.sh: ligne 186: [[: 0
0 : erreur de syntaxe dans l'expression (le symbole erroné est « 0 »)

[0;32m✓[0m Fix appliqué

Test :
  exec $SHELL -l
  # ou ouvre un nouveau terminal

Si l'erreur persiste · rollback :
  cp /home/anthony/.zshrc.bak-20260420-215107
  cp /home/anthony/.zshrc.bak-20260420-215030
  cp /home/anthony/.zshrc.bak-20260420-213830
  cp /home/anthony/.zshrc.bak-20260420-212456
1 |
| 2-fix-all | ✓ OK | 325s | 0 |
[0;34m══ Preflight checks ══[0m
[0;32m✓[0m gh CLI authentifié
[0;32m✓[0m CHRYSA_ROOT = /home/anthony/Documents/perso/projects/chrysa
[0;33m⚠[0m  ai-aggregator : 1 fichiers modifiés (non committés)
[0;33m⚠[0m  chrysa-lib : 34 fichiers modifiés (non committés)
[0;33m⚠[0m  coach : 1 fichiers modifiés (non committés)
[0;33m⚠[0m  container-webview : 36 fichiers modifiés (non committés)
[0;33m⚠[0m  D-D : 433 fichiers modifiés (non committés)
[0;33m⚠[0m  dev-nexus : 38 fichiers modifiés (non committés)
[0;33m⚠[0m  discord-bot-back : 20 fichiers modifiés (non committés)
[0;33m⚠[0m  diy-stream-deck : 36 fichiers modifiés (non committés)
[0;33m⚠[0m  doc-gen : 18 fichiers modifiés (non committés)
[0;33m⚠[0m  epub-sorter : 1 fichiers modifiés (non committés)
[0;33m⚠[0m  genealogy-validator : 38 fichiers modifiés (non committés)
[0;33m⚠[0m  github-actions : 1 fichiers modifiés (non committés)
[0;33m⚠[0m  guideline-checker : 1 fichiers modifiés (non committés)
[0;33m⚠[0m  lifeos : 39 fichiers modifiés (non committés)
[0;33m⚠[0m  linkendin-resume : 14 fichiers modifiés (non committés)
[0;33m⚠[0m  my-fridge : 19 fichiers modifiés (non committés)
[0;33m⚠[0m  notion-automation : 20 fichiers modifiés (non committés)
[0;33m⚠[0m  PO-GO-DEX : 36 fichiers modifiés (non committés)
[0;33m⚠[0m  pre-commit-tools : 19 fichiers modifiés (non committés)
[0;33m⚠[0m  project-init : 21 fichiers modifiés (non committés)
[0;33m⚠[0m  pycharm_settings : 1 fichiers modifiés (non committés)
[0;33m⚠[0m  satisfactory-automated_calculator : 36 fichiers modifiés (non committés)
[0;33m⚠[0m  server : 36 fichiers modifiés (non committés)
[0;33m⚠[0m  shared-standards : 2 fichiers modifiés (non committés)
[0;33m⚠[0m  usefull-containers : 18 fichiers modifiés (non committés)
[0;33m⚠[0m  windows-docker-state-notification : 41 fichiers modifiés (non committés)
[0;33m⚠[0m  26 repos dirty — recommandé de committer ou stash avant de continuer
? Continuer quand même ? → auto-yes
[0;33m⚠[0m  AUTO-YES activé · toutes les étapes seront confirmées automatiquement

[0;34m══ 1/7 · Standardize GitHub settings (all repos) ══[0m
[0;90mCommande : bash /home/anthony/Documents/perso/projects/chrysa/shared-standards/scripts/standardize-repo-settings.sh --all[0m
? Exécuter cette étape ? → auto-yes
→ Fetching all repos for org/user chrysa...
╔══════════════════════════════════════════════════════════╗
║ Standardization chrysa GitHub settings (v2)              ║
╚══════════════════════════════════════════════════════════╝
Targets: 46 repo(s)

━━ chrysa/shared-standards ━━
  Visibility: public
  ⚠️  has_discussions rejeté, retry sans...
  ❌ core settings FAILED: Allow forks can only be changed on org-owned repositories
━━ chrysa/epub-sorter ━━
  Visibility: public
  ⚠️  has_discussions rejeté, retry sans...
  ❌ core settings FAILED: Allow forks can only be changed on org-owned repositories
━━ chrysa/ai-aggregator ━━
  Visibility: private
  ✅ core settings applied
  Branch protection: master:skip(403) main:skip(403)
━━ chrysa/pycharm_settings ━━
  Visibility: private
  ✅ core settings applied
  Branch protection: master:skip(403)
━━ chrysa/guideline-checker ━━
  Visibility: public
  ⚠️  has_discussions rejeté, retry sans...
  ❌ core settings FAILED: Allow forks can only be changed on org-owned repositories
━━ chrysa/github-actions ━━
  Visibility: public
  ⚠️  has_discussions rejeté, retry sans...
  ❌ core settings FAILED: Allow forks can only be changed on org-owned repositories
━━ chrysa/coach ━━
  Visibility: private
  ✅ core settings applied
  Branch protection: master:skip(403) main:skip(403)
━━ chrysa/doc-gen ━━
  Visibility: private
  ✅ core settings applied
  Branch protection: master:skip(403) main:skip(403)
━━ chrysa/D-D ━━
  Visibility: private
  ✅ core settings applied
  Branch protection: master:skip(403) main:skip(403)
━━ chrysa/pre-commit-tools ━━
  Visibility: public
  ⚠️  has_discussions rejeté, retry sans...
  ❌ core settings FAILED: Allow forks can only be changed on org-owned repositories
━━ chrysa/PO-GO-DEX ━━
  Visibility: private
  ✅ core settings applied
  Branch protection: master:skip(403) main:skip(403)
━━ chrysa/windows-docker-state-notification ━━
  Visibility: private
  ✅ core settings applied
  Branch protection: master:skip(403) main:skip(403)
━━ chrysa/server ━━
  Visibility: private
  ✅ core settings applied
  Branch protection: master:skip(403) main:skip(403) develop:skip(403)
━━ chrysa/satisfactory-automated_calculator ━━
  Visibility: public
  ⚠️  has_discussions rejeté, retry sans...
  ❌ core settings FAILED: Allow forks can only be changed on org-owned repositories
━━ chrysa/notion-automation ━━
  Visibility: private
  ✅ core settings applied
  Branch protection: master:skip(403) main:skip(403)
━━ chrysa/chrysa-lib ━━
  Visibility: private
  ✅ core settings applied
  Branch protection: master:skip(403) main:skip(403) develop:skip(403)
━━ chrysa/dev-nexus ━━
  Visibility: private
  ✅ core settings applied
  Branch protection: master:skip(403) main:skip(403) develop:skip(403)
━━ chrysa/diy-stream-deck ━━
  Visibility: public
  ⚠️  has_discussions rejeté, retry sans...
  ❌ core settings FAILED: Allow forks can only be changed on org-owned repositories
━━ chrysa/my-fridge ━━
  Visibility: private
  ✅ core settings applied
  Branch protection: master:skip(403)
━━ chrysa/discord-bot-back ━━
  Visibility: private
  ✅ core settings applied
  Branch protection: master:skip(403) main:skip(403)
━━ chrysa/usefull-containers ━━
  Visibility: public
  ⚠️  has_discussions rejeté, retry sans...
  ❌ core settings FAILED: Allow forks can only be changed on org-owned repositories
━━ chrysa/genealogy-validator ━━
  Visibility: private
  ✅ core settings applied
  Branch protection: master:skip(403) main:skip(403)
━━ chrysa/linkendin-resume ━━
  Visibility: public
  ⚠️  has_discussions rejeté, retry sans...
  ❌ core settings FAILED: Allow forks can only be changed on org-owned repositories
━━ chrysa/windows-autonome ━━
  📦 Repo déjà archivé sur GitHub, skip
━━ chrysa/my-resume ━━
  Visibility: private
  ✅ core settings applied
  Branch protection: master:skip(403) main:skip(403)
━━ chrysa/project-init ━━
  Visibility: public
  ⚠️  has_discussions rejeté, retry sans...
  ❌ core settings FAILED: Allow forks can only be changed on org-owned repositories
━━ chrysa/container-webview ━━
  Visibility: public
  ⚠️  has_discussions rejeté, retry sans...
  ❌ core settings FAILED: Allow forks can only be changed on org-owned repositories
━━ chrysa/lifeos ━━
  Visibility: public
  ⚠️  has_discussions rejeté, retry sans...
  ❌ core settings FAILED: Allow forks can only be changed on org-owned repositories
━━ chrysa/DJango-CustomeCommands ━━
  📦 Repo déjà archivé sur GitHub, skip
━━ chrysa/agent-config ━━
  📦 Repo déjà archivé sur GitHub, skip
━━ chrysa/live-platform ━━
  Visibility: private
  ✅ core settings applied
  Branch protection: master:skip(403) main:skip(403)
━━ chrysa/django_evolve ━━
  📦 Repo déjà archivé sur GitHub, skip
━━ chrysa/pre-commit-hooks-changelog ━━
  📦 Repo déjà archivé sur GitHub, skip
━━ chrysa/test-figma-to-gh ━━
  📦 Repo déjà archivé sur GitHub, skip
━━ chrysa/izeberg-test ━━
  📦 Repo déjà archivé sur GitHub, skip
━━ chrysa/foodle-test ━━
  📦 Repo déjà archivé sur GitHub, skip
━━ chrysa/django-test ━━
  📦 Repo déjà archivé sur GitHub, skip
━━ chrysa/dj-custom_struct_app ━━
  📦 Repo déjà archivé sur GitHub, skip
━━ chrysa/unixpackage.github.io ━━
  📦 Repo déjà archivé sur GitHub, skip
━━ chrysa/unixpackage ━━
  📦 Repo déjà archivé sur GitHub, skip
━━ chrysa/framewok42 ━━
  📦 Repo déjà archivé sur GitHub, skip
━━ chrysa/django-struct ━━
  📦 Repo déjà archivé sur GitHub, skip
━━ chrysa/42_save ━━
  📦 Repo déjà archivé sur GitHub, skip
━━ chrysa/gae-toolbox-2 ━━
  📦 Repo déjà archivé sur GitHub, skip
━━ chrysa/Al-Cu ━━
  📦 Repo déjà archivé sur GitHub, skip
━━ chrysa/Balsa ━━
  📦 Repo déjà archivé sur GitHub, skip

╔══════════════════════════════════════════════════════════╗
║ RÉSUMÉ                                                    ║
╚══════════════════════════════════════════════════════════╝
Total repos scannés :                46
✅ Core settings appliqués :          16
   dont sans has_discussions :       0
📦 Déjà archivés sur GitHub :         18
❌ Core settings échecs :             12
⚠️  Branch protect HTTP 403 :         33 (repos privés Free)

📦 Repos archivés (pas de modification possible, normal) :
  - chrysa/windows-autonome
  - chrysa/DJango-CustomeCommands
  - chrysa/agent-config
  - chrysa/django_evolve
  - chrysa/pre-commit-hooks-changelog
  - chrysa/test-figma-to-gh
  - chrysa/izeberg-test
  - chrysa/foodle-test
  - chrysa/django-test
  - chrysa/dj-custom_struct_app
  - chrysa/unixpackage.github.io
  - chrysa/unixpackage
  - chrysa/framewok42
  - chrysa/django-struct
  - chrysa/42_save
  - chrysa/gae-toolbox-2
  - chrysa/Al-Cu
  - chrysa/Balsa

❌ Échecs réels à investiguer :
  - chrysa/shared-standards: Allow forks can only be changed on org-owned repositories
  - chrysa/epub-sorter: Allow forks can only be changed on org-owned repositories
  - chrysa/guideline-checker: Allow forks can only be changed on org-owned repositories
  - chrysa/github-actions: Allow forks can only be changed on org-owned repositories
  - chrysa/pre-commit-tools: Allow forks can only be changed on org-owned repositories
  - chrysa/satisfactory-automated_calculator: Allow forks can only be changed on org-owned repositories
  - chrysa/diy-stream-deck: Allow forks can only be changed on org-owned repositories
  - chrysa/usefull-containers: Allow forks can only be changed on org-owned repositories
  - chrysa/linkendin-resume: Allow forks can only be changed on org-owned repositories
  - chrysa/project-init: Allow forks can only be changed on org-owned repositories
  - chrysa/container-webview: Allow forks can only be changed on org-owned repositories
  - chrysa/lifeos: Allow forks can only be changed on org-owned repositories

⚠️  Terminé avec 12 erreurs réelles
[0;33m⚠[0m  step returned non-zero (non-bloquant)
[0;32m✓[0m Étape terminée

[0;34m══ 2/7 · Commit + push pending sur repos ACTIFS (skip archive targets) ══[0m
[0;90mCommande : bash /home/anthony/Documents/perso/projects/chrysa/shared-standards/scripts/repos-push-pending.sh[0m
? Exécuter cette étape ? → auto-yes
detect bare except clauses...........................(no files to check)Skipped
detect FastAPI routes without response_model.........(no files to check)Skipped
sort yaml files......................................(no files to check)Skipped
  💾 ai-aggregator · auto-committed 1 fichiers
To https://github.com/chrysa/ai-aggregator.git
   b51dd37..9f86bcd  chore/quality-uniformization -> chore/quality-uniformization
✅ ai-aggregator · 1 commits pushed sur chore/quality-uniformization
If you still have problems after following the migration guide, please stop by
https://eslint.org/chat/help to chat with the team.

❌ chrysa-lib · auto-commit échoué
mixed line ending........................................................Passed
trim trailing whitespace.................................................Passed
Detect hardcoded secrets.................................................Passed
  💾 coach · auto-committed 1 fichiers
To https://github.com/chrysa/coach.git
   fab7c74..da92381  chore/quality-uniformization -> chore/quality-uniformization
✅ coach · 1 commits pushed sur chore/quality-uniformization
    RuntimeError: failed to find interpreter for Builtin discover of python_spec='python3.12'
stderr: (none)
Check the log at /home/anthony/.cache/pre-commit/pre-commit.log
❌ container-webview · auto-commit échoué
mdformat.................................................................Failed
- hook id: mdformat
- files were modified by this hook
❌ D-D · auto-commit échoué
opencode.json

eslint...............................................(no files to check)Skipped
❌ dev-nexus · auto-commit échoué
black................................................(no files to check)Skipped
blacken-docs.............................................................Passed
interrogate..........................................(no files to check)Skipped
❌ discord-bot-back · auto-commit échoué
  8:1       warning  truthy value should be one of [false, true]  (truthy)
  35:81     error    line too long (82 > 80 characters)  (line-length)

❌ diy-stream-deck · auto-commit échoué
detect-secrets-hook: error: argument --baseline: Invalid path: .secrets.baseline

Detect hardcoded secrets.................................................Passed
❌ doc-gen · auto-commit échoué
detect pprint on python code.........................(no files to check)Skipped
detect unreachable code..............................(no files to check)Skipped
sort yaml files......................................(no files to check)Skipped
  💾 epub-sorter · auto-committed 1 fichiers
To https://github.com/chrysa/epub-sorter.git
   21e9e68..3fa4f4f  chore/quality-uniformization -> chore/quality-uniformization
✅ epub-sorter · 1 commits pushed sur chore/quality-uniformization
    RuntimeError: failed to find interpreter for Builtin discover of python_spec='python3.12'
stderr: (none)
Check the log at /home/anthony/.cache/pre-commit/pre-commit.log
❌ genealogy-validator · auto-commit échoué
sort yaml files......................................(no files to check)Skipped
sort json files......................................(no files to check)Skipped
check env files for secrets..........................(no files to check)Skipped
❌ github-actions · auto-commit échoué
detect pprint on python code.........................(no files to check)Skipped
detect unreachable code..............................(no files to check)Skipped
sort yaml files......................................(no files to check)Skipped
  💾 guideline-checker · auto-committed 1 fichiers
To https://github.com/chrysa/guideline-checker.git
   97ad941..8d1ac2f  chore/quality-uniformization -> chore/quality-uniformization
✅ guideline-checker · 1 commits pushed sur chore/quality-uniformization
  9:5       warning  comment not indented like content  (comments-indentation)

markdownlint.............................................................Passed
❌ lifeos · auto-commit échoué
⊘ linkendin-resume · destiné à archivage · skip
🛑 my-fridge · branche master (défaut) · 19 dirty · 0 ahead · skip (utilise --include-default pour forcer)
✓ my-resume · rebase/pr-12 · rien à push
- exit code: 1
- files were modified by this hook
check env files for secrets..........................(no files to check)Skipped
❌ notion-automation · auto-commit échoué

csslint..............................................(no files to check)Skipped
mdformat.................................................................Passed
❌ PO-GO-DEX · auto-commit échoué
check env files for secrets..........................(no files to check)Skipped
detect root logger usage.............................(no files to check)Skipped
detect unreachable code..............................(no files to check)Skipped
❌ pre-commit-tools · auto-commit échoué
🛑 project-init · branche main (défaut) · 21 dirty · 0 ahead · skip (utilise --include-default pour forcer)
  💾 pycharm_settings · auto-committed 1 fichiers
To https://github.com/chrysa/pycharm_settings.git
   2b3c7b0..ef71236  chore/quality-uniformization -> chore/quality-uniformization
✅ pycharm_settings · 1 commits pushed sur chore/quality-uniformization
    RuntimeError: failed to find interpreter for Builtin discover of python_spec='python3.12'
stderr: (none)
Check the log at /home/anthony/.cache/pre-commit/pre-commit.log
❌ satisfactory-automated_calculator · auto-commit échoué
                           [filenames ...]
detect-secrets-hook: error: argument --baseline: Invalid path: .secrets.baseline

❌ server · auto-commit échoué
sort json files......................................(no files to check)Skipped
check env files for secrets..........................(no files to check)Skipped
check .env/.env.example sync.........................(no files to check)Skipped
  💾 shared-standards · auto-committed 2 fichiers
To https://github.com/chrysa/shared-standards.git
   7fb1b56..e894329  chore/claude-code-optimization -> chore/claude-code-optimization
✅ shared-standards · 1 commits pushed sur chore/claude-code-optimization
🛑 usefull-containers · branche develop (défaut) · 18 dirty · 0 ahead · skip (utilise --include-default pour forcer)
stderr:
    failed to connect to the docker API at unix:///home/anthony/.docker/desktop/docker.sock; check if the path is correct and if the daemon is running: dial unix /home/anthony/.docker/desktop/docker.sock: connect: no such file or directory
Check the log at /home/anthony/.cache/pre-commit/pre-commit.log
❌ windows-docker-state-notification · auto-commit échoué

═══════════════════════════════════
✅ Pushed              : 6
✓ Clean/rien à faire   : 1
🛑 Branches défaut skip : 3
⊘ Archive targets skip : 1
⏭️  No remote/detached : 0
❌ Failed              : 16

Repos en échec :
  - chrysa-lib
  - container-webview
  - D-D
  - dev-nexus
  - discord-bot-back
  - diy-stream-deck
  - doc-gen
  - genealogy-validator
  - github-actions
  - lifeos
  - notion-automation
  - PO-GO-DEX
  - pre-commit-tools
  - satisfactory-automated_calculator
  - server
  - windows-docker-state-notification

ℹ️  Relance avec --include-default pour pousser aussi main/master/develop
[0;32m✓[0m Étape terminée

[0;34m══ 3/7 · Archive obsolete repos (auto-rollback dirty) ══[0m
[0;90mCommande : bash /home/anthony/Documents/perso/projects/chrysa/shared-standards/scripts/archive-obsolete-repos.sh[0m
? Exécuter cette étape ? → auto-yes
=== Batch 1 · repos _archived/ local ===
📦 chrysa/Al-Cu déjà archivé
📦 chrysa/django_evolve déjà archivé
📦 chrysa/django-struct déjà archivé
📦 chrysa/dj-custom_struct_app déjà archivé
📦 chrysa/foodle-test déjà archivé
📦 chrysa/framewok42 déjà archivé
📦 chrysa/gae-toolbox-2 déjà archivé
📦 chrysa/izeberg-test déjà archivé
📦 chrysa/test-figma-to-gh déjà archivé

=== Batch 2 · legacy inconnus ===
📦 chrysa/Balsa déjà archivé
📦 chrysa/django-test déjà archivé
📦 chrysa/unixpackage déjà archivé
📦 chrysa/unixpackage.github.io déjà archivé
📦 chrysa/42_save déjà archivé

=== Batch 3 · obsolètes confirmés user ===
📦 chrysa/DJango-CustomeCommands déjà archivé

✅ Done
[0;32m✓[0m Étape terminée

[0;34m══ 4/7 · Archive merged repos (ADR-0010, ADR-0011/0025 · ADR-0014 révoqué) ══[0m
[0;90mCommande : bash /home/anthony/Documents/perso/projects/chrysa/shared-standards/scripts/archive-merged-repos.sh[0m
? Exécuter cette étape ? → auto-yes
📦 chrysa/pre-commit-hooks-changelog déjà archivé (ADR-0010)
⚠️  Target chrysa/resume n'existe pas encore → skip linkendin-resume (pas sûr de la fusion)

✅ Done

ℹ️  ADRs en vigueur pour ce script :
   - ADR-0010 : pre-commit-hooks-changelog → pre-commit-tools (fusionné)
   - ADR-0011 + ADR-0025 : linkendin-resume → resume (frozen)
   - ADR-0014 : RÉVOQUÉ par ADR-0026 · windows-autonome + agent-config restent séparés en Socle
   - ADR-0015 / ADR-0024 : doc-gen séparé de CodeDoc AI → pas d'archive
[0;32m✓[0m Étape terminée

[0;34m══ 5/7 · Cleanup my-assistant zombie folder ══[0m
[0;90mCommande : bash /home/anthony/Documents/perso/projects/chrysa/shared-standards/scripts/cleanup-my-assistant-zombie.sh[0m
? Exécuter cette étape ? → auto-yes
✅ /home/anthony/Documents/perso/projects/chrysa/my-assistant n'existe pas, rien à faire
[0;32m✓[0m Étape terminée

[0;34m══ 6/7 · Pull all active repos ══[0m
[0;90mCommande : bash /home/anthony/Documents/perso/projects/chrysa/shared-standards/scripts/repos-pull-all.sh[0m
? Exécuter cette étape ? → auto-yes
✓ ai-aggregator · up to date
🟠 chrysa-lib · DIRTY · skip (utilise --force pour stash+pull)
✓ coach · up to date
🟠 container-webview · DIRTY · skip (utilise --force pour stash+pull)
🟠 D-D · DIRTY · skip (utilise --force pour stash+pull)
🟠 dev-nexus · DIRTY · skip (utilise --force pour stash+pull)
🟠 discord-bot-back · DIRTY · skip (utilise --force pour stash+pull)
🟠 diy-stream-deck · DIRTY · skip (utilise --force pour stash+pull)
🟠 doc-gen · DIRTY · skip (utilise --force pour stash+pull)
✓ epub-sorter · up to date
🟠 genealogy-validator · DIRTY · skip (utilise --force pour stash+pull)
🟠 github-actions · DIRTY · skip (utilise --force pour stash+pull)
✓ guideline-checker · up to date
🟠 lifeos · DIRTY · skip (utilise --force pour stash+pull)
🟠 linkendin-resume · DIRTY · skip (utilise --force pour stash+pull)
🟠 my-fridge · DIRTY · skip (utilise --force pour stash+pull)
❌ my-resume · pull échoué
    fatal : impossible de trouver la référence distante rebase/pr-12
🟠 notion-automation · DIRTY · skip (utilise --force pour stash+pull)
🟠 PO-GO-DEX · DIRTY · skip (utilise --force pour stash+pull)
🟠 pre-commit-tools · DIRTY · skip (utilise --force pour stash+pull)
🟠 project-init · DIRTY · skip (utilise --force pour stash+pull)
✓ pycharm_settings · up to date
🟠 satisfactory-automated_calculator · DIRTY · skip (utilise --force pour stash+pull)
🟠 server · DIRTY · skip (utilise --force pour stash+pull)
✓ shared-standards · up to date
🟠 usefull-containers · DIRTY · skip (utilise --force pour stash+pull)
🟠 windows-docker-state-notification · DIRTY · skip (utilise --force pour stash+pull)

═══════════════════════════
✅ Success : 6
🟠 Dirty   : 20 (non pull)
⏭️  Skipped : 0
❌ Failed  : 1

Repos en échec :
  - my-resume
[0;32m✓[0m Étape terminée

[0;34m══ 7a/10 · Regenerate portfolio.html (interne, tout inclus) ══[0m
[0;90mCommande : bash /home/anthony/Documents/perso/projects/chrysa/shared-standards/scripts/generate-portfolio-html.sh[0m
? Exécuter cette étape ? → auto-yes
→ Mode INTERNE · tout inclus
✅ Portfolio généré : /home/anthony/Documents/perso/projects/chrysa/portfolio.html
   128 lignes · 17557 bytes
   Ouvre avec : xdg-open /home/anthony/Documents/perso/projects/chrysa/portfolio.html
[0;32m✓[0m Étape terminée

[0;34m══ 7b/10 · Regenerate portfolio-public.html (externe, filtré) ══[0m
[0;90mCommande : bash /home/anthony/Documents/perso/projects/chrysa/shared-standards/scripts/generate-portfolio-html.sh --external[0m
? Exécuter cette étape ? → auto-yes
→ Mode EXTERNE · filtrage travaux/aménagement/tooling activé
  ⊘ exclu (externe, public=false) : container-webview
  ⊘ exclu (externe, public=false) : github-actions
  ⊘ exclu (externe, public=false) : linkendin-resume
  ⊘ exclu (externe, public=false) : my-resume
  ⊘ exclu (externe) : notion-automation
  ⊘ exclu (externe, public=false) : project-init
  ⊘ exclu (externe) : pycharm_settings
  ⊘ exclu (externe, public=false) : server
  ⊘ exclu (externe, public=false) : shared-standards
  ⊘ exclu (externe, public=false) : windows-docker-state-notification
✅ Portfolio généré : /home/anthony/Documents/perso/projects/chrysa/portfolio-public.html
   128 lignes · 13961 bytes
   Ouvre avec : xdg-open /home/anthony/Documents/perso/projects/chrysa/portfolio-public.html
[0;32m✓[0m Étape terminée

[0;34m══ 8/10 · Appliquer templates standards aux repos actifs ══[0m
[0;90mCommande : bash /home/anthony/Documents/perso/projects/chrysa/shared-standards/scripts/apply-standards.sh --dry-run[0m
? Exécuter cette étape ? → auto-yes
[0;34m═══════════════════════════════════════[0m
[0;34m  apply-standards.sh · mode DRY-RUN[0m
[0;34m═══════════════════════════════════════[0m

[0;34m══ ai-aggregator (python) ══[0m
  \033[0;90m=\033[0m GitVersion déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m README déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m CLAUDE.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m DECISIONS.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m ROADMAP.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m ARCHITECTURE.md déjà présent · skip (utilise --force pour écraser)
[0;33m⚠[0m  .gitignore (python) : 34 lignes template absentes dans .gitignore · envisage merge manuel
  \033[0;90m=\033[0m _reusable-ci (shared) déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m pre-commit (python) déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m CI (python) déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m Makefile (python) déjà présent · skip (utilise --force pour écraser)
[0;33m⚠[0m  template absent : /home/anthony/Documents/perso/projects/chrysa/shared-standards/templates/makefile/quality.makefile
[0;33m⚠[0m  template absent : /home/anthony/Documents/perso/projects/chrysa/shared-standards/templates/makefile/install.makefile
[0;33m⚠[0m  template absent : /home/anthony/Documents/perso/projects/chrysa/shared-standards/templates/makefile/docker.makefile
  \033[0;90m=\033[0m Dockerfile (python) déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m dependabot déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m CODEOWNERS déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m PR template déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labeler rules déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labels palette déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m dependabot-auto-merge déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m branch-auto-update déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m enforce-issue-link déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labeler workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m sync-labels workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m pr-size-label workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude config déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude settings déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude secret-allowlist déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude thresholds déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude quality-hook déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m check-standards-sync déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m _lib.sh déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue bug déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue chore déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue feature déjà présent · skip (utilise --force pour écraser)
\033[0;90m⊘ _archived · skip-list\033[0m

[0;34m══ chrysa-lib (unknown) ══[0m
[0;33m⚠[0m  stack indétecté · skip templates spécifiques
  \033[0;90m=\033[0m GitVersion déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m README déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m CLAUDE.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m DECISIONS.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m ROADMAP.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m ARCHITECTURE.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m _reusable-ci (shared) déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m dependabot déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m CODEOWNERS déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m PR template déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labeler rules déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labels palette déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m dependabot-auto-merge déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m branch-auto-update déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m enforce-issue-link déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labeler workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m sync-labels workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m pr-size-label workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude config déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude settings déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude secret-allowlist déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude thresholds déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude quality-hook déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m check-standards-sync déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m _lib.sh déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue bug déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue chore déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue feature déjà présent · skip (utilise --force pour écraser)

[0;34m══ coach (unknown) ══[0m
[0;33m⚠[0m  stack indétecté · skip templates spécifiques
  \033[0;90m=\033[0m GitVersion déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m README déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m CLAUDE.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m DECISIONS.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m ROADMAP.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m ARCHITECTURE.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m _reusable-ci (shared) déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m dependabot déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m CODEOWNERS déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m PR template déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labeler rules déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labels palette déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m dependabot-auto-merge déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m branch-auto-update déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m enforce-issue-link déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labeler workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m sync-labels workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m pr-size-label workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude config déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude settings déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude secret-allowlist déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude thresholds déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude quality-hook déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m check-standards-sync déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m _lib.sh déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue bug déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue chore déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue feature déjà présent · skip (utilise --force pour écraser)

[0;34m══ container-webview (unknown) ══[0m
[0;33m⚠[0m  stack indétecté · skip templates spécifiques
  \033[0;90m=\033[0m GitVersion déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m README déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m CLAUDE.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m DECISIONS.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m ROADMAP.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m ARCHITECTURE.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m _reusable-ci (shared) déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m dependabot déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m CODEOWNERS déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m PR template déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labeler rules déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labels palette déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m dependabot-auto-merge déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m branch-auto-update déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m enforce-issue-link déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labeler workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m sync-labels workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m pr-size-label workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude config déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude settings déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude secret-allowlist déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude thresholds déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude quality-hook déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m check-standards-sync déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m _lib.sh déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue bug déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue chore déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue feature déjà présent · skip (utilise --force pour écraser)

[0;34m══ D-D (node) ══[0m
  \033[0;90m=\033[0m GitVersion déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m README déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m CLAUDE.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m DECISIONS.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m ROADMAP.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m ARCHITECTURE.md déjà présent · skip (utilise --force pour écraser)
[0;33m⚠[0m  .gitignore (node) : 42 lignes template absentes dans .gitignore · envisage merge manuel
  \033[0;90m=\033[0m _reusable-ci (shared) déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m pre-commit (node) déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m CI (node) déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m Makefile (node) déjà présent · skip (utilise --force pour écraser)
[0;33m⚠[0m  template absent : /home/anthony/Documents/perso/projects/chrysa/shared-standards/templates/makefile/quality.makefile
[0;33m⚠[0m  template absent : /home/anthony/Documents/perso/projects/chrysa/shared-standards/templates/makefile/install.makefile
[0;33m⚠[0m  template absent : /home/anthony/Documents/perso/projects/chrysa/shared-standards/templates/makefile/docker.makefile
  \033[0;90m=\033[0m Dockerfile (node) déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m dependabot déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m CODEOWNERS déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m PR template déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labeler rules déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labels palette déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m dependabot-auto-merge déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m branch-auto-update déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m enforce-issue-link déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labeler workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m sync-labels workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m pr-size-label workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude config déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude settings déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude secret-allowlist déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude thresholds déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude quality-hook déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m check-standards-sync déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m _lib.sh déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue bug déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue chore déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue feature déjà présent · skip (utilise --force pour écraser)

[0;34m══ dev-nexus (unknown) ══[0m
[0;33m⚠[0m  stack indétecté · skip templates spécifiques
  \033[0;90m=\033[0m GitVersion déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m README déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m CLAUDE.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m DECISIONS.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m ROADMAP.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m ARCHITECTURE.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m _reusable-ci (shared) déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m dependabot déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m CODEOWNERS déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m PR template déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labeler rules déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labels palette déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m dependabot-auto-merge déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m branch-auto-update déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m enforce-issue-link déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labeler workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m sync-labels workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m pr-size-label workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude config déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude settings déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude secret-allowlist déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude thresholds déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude quality-hook déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m check-standards-sync déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m _lib.sh déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue bug déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue chore déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue feature déjà présent · skip (utilise --force pour écraser)

[0;34m══ discord-bot-back (python) ══[0m
  \033[0;90m=\033[0m GitVersion déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m README déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m CLAUDE.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m DECISIONS.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m ROADMAP.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m ARCHITECTURE.md déjà présent · skip (utilise --force pour écraser)
[0;33m⚠[0m  .gitignore (python) : 61 lignes template absentes dans .gitignore · envisage merge manuel
  \033[0;90m=\033[0m _reusable-ci (shared) déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m pre-commit (python) déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m CI (python) déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m Makefile (python) déjà présent · skip (utilise --force pour écraser)
[0;33m⚠[0m  template absent : /home/anthony/Documents/perso/projects/chrysa/shared-standards/templates/makefile/quality.makefile
[0;33m⚠[0m  template absent : /home/anthony/Documents/perso/projects/chrysa/shared-standards/templates/makefile/install.makefile
[0;33m⚠[0m  template absent : /home/anthony/Documents/perso/projects/chrysa/shared-standards/templates/makefile/docker.makefile
  \033[0;90m=\033[0m Dockerfile (python) déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m dependabot déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m CODEOWNERS déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m PR template déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labeler rules déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labels palette déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m dependabot-auto-merge déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m branch-auto-update déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m enforce-issue-link déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labeler workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m sync-labels workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m pr-size-label workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude config déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude settings déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude secret-allowlist déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude thresholds déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude quality-hook déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m check-standards-sync déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m _lib.sh déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue bug déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue chore déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue feature déjà présent · skip (utilise --force pour écraser)

[0;34m══ diy-stream-deck (python) ══[0m
  \033[0;90m=\033[0m GitVersion déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m README déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m CLAUDE.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m DECISIONS.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m ROADMAP.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m ARCHITECTURE.md déjà présent · skip (utilise --force pour écraser)
[0;33m⚠[0m  .gitignore (python) : 28 lignes template absentes dans .gitignore · envisage merge manuel
  \033[0;90m=\033[0m _reusable-ci (shared) déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m pre-commit (python) déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m CI (python) déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m Makefile (python) déjà présent · skip (utilise --force pour écraser)
[0;33m⚠[0m  template absent : /home/anthony/Documents/perso/projects/chrysa/shared-standards/templates/makefile/quality.makefile
[0;33m⚠[0m  template absent : /home/anthony/Documents/perso/projects/chrysa/shared-standards/templates/makefile/install.makefile
[0;33m⚠[0m  template absent : /home/anthony/Documents/perso/projects/chrysa/shared-standards/templates/makefile/docker.makefile
  \033[0;90m=\033[0m Dockerfile (python) déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m dependabot déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m CODEOWNERS déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m PR template déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labeler rules déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labels palette déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m dependabot-auto-merge déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m branch-auto-update déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m enforce-issue-link déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labeler workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m sync-labels workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m pr-size-label workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude config déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude settings déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude secret-allowlist déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude thresholds déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude quality-hook déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m check-standards-sync déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m _lib.sh déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue bug déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue chore déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue feature déjà présent · skip (utilise --force pour écraser)

[0;34m══ doc-gen (python) ══[0m
  \033[0;90m=\033[0m GitVersion déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m README déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m CLAUDE.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m DECISIONS.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m ROADMAP.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m ARCHITECTURE.md déjà présent · skip (utilise --force pour écraser)
[0;33m⚠[0m  .gitignore (python) : 37 lignes template absentes dans .gitignore · envisage merge manuel
  \033[0;90m=\033[0m _reusable-ci (shared) déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m pre-commit (python) déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m CI (python) déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m Makefile (python) déjà présent · skip (utilise --force pour écraser)
[0;33m⚠[0m  template absent : /home/anthony/Documents/perso/projects/chrysa/shared-standards/templates/makefile/quality.makefile
[0;33m⚠[0m  template absent : /home/anthony/Documents/perso/projects/chrysa/shared-standards/templates/makefile/install.makefile
[0;33m⚠[0m  template absent : /home/anthony/Documents/perso/projects/chrysa/shared-standards/templates/makefile/docker.makefile
  \033[0;90m=\033[0m Dockerfile (python) déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m dependabot déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m CODEOWNERS déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m PR template déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labeler rules déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labels palette déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m dependabot-auto-merge déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m branch-auto-update déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m enforce-issue-link déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labeler workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m sync-labels workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m pr-size-label workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude config déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude settings déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude secret-allowlist déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude thresholds déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude quality-hook déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m check-standards-sync déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m _lib.sh déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue bug déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue chore déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue feature déjà présent · skip (utilise --force pour écraser)
[0;33m⚠[0m  drive-cleanup · pas un git repo · skip
[0;33m⚠[0m  ecosystem-reorg · pas un git repo · skip

[0;34m══ epub-sorter (python) ══[0m
  \033[0;90m=\033[0m GitVersion déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m README déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m CLAUDE.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m DECISIONS.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m ROADMAP.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m ARCHITECTURE.md déjà présent · skip (utilise --force pour écraser)
[0;33m⚠[0m  .gitignore (python) : 59 lignes template absentes dans .gitignore · envisage merge manuel
  \033[0;90m=\033[0m _reusable-ci (shared) déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m pre-commit (python) déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m CI (python) déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m Makefile (python) déjà présent · skip (utilise --force pour écraser)
[0;33m⚠[0m  template absent : /home/anthony/Documents/perso/projects/chrysa/shared-standards/templates/makefile/quality.makefile
[0;33m⚠[0m  template absent : /home/anthony/Documents/perso/projects/chrysa/shared-standards/templates/makefile/install.makefile
[0;33m⚠[0m  template absent : /home/anthony/Documents/perso/projects/chrysa/shared-standards/templates/makefile/docker.makefile
  \033[0;90m=\033[0m Dockerfile (python) déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m dependabot déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m CODEOWNERS déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m PR template déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labeler rules déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labels palette déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m dependabot-auto-merge déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m branch-auto-update déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m enforce-issue-link déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labeler workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m sync-labels workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m pr-size-label workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude config déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude settings déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude secret-allowlist déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude thresholds déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude quality-hook déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m check-standards-sync déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m _lib.sh déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue bug déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue chore déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue feature déjà présent · skip (utilise --force pour écraser)

[0;34m══ genealogy-validator (python) ══[0m
  \033[0;90m=\033[0m GitVersion déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m README déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m CLAUDE.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m DECISIONS.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m ROADMAP.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m ARCHITECTURE.md déjà présent · skip (utilise --force pour écraser)
[0;33m⚠[0m  .gitignore (python) : 28 lignes template absentes dans .gitignore · envisage merge manuel
  \033[0;90m=\033[0m _reusable-ci (shared) déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m pre-commit (python) déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m CI (python) déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m Makefile (python) déjà présent · skip (utilise --force pour écraser)
[0;33m⚠[0m  template absent : /home/anthony/Documents/perso/projects/chrysa/shared-standards/templates/makefile/quality.makefile
[0;33m⚠[0m  template absent : /home/anthony/Documents/perso/projects/chrysa/shared-standards/templates/makefile/install.makefile
[0;33m⚠[0m  template absent : /home/anthony/Documents/perso/projects/chrysa/shared-standards/templates/makefile/docker.makefile
  \033[0;90m=\033[0m Dockerfile (python) déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m dependabot déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m CODEOWNERS déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m PR template déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labeler rules déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labels palette déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m dependabot-auto-merge déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m branch-auto-update déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m enforce-issue-link déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labeler workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m sync-labels workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m pr-size-label workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude config déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude settings déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude secret-allowlist déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude thresholds déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude quality-hook déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m check-standards-sync déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m _lib.sh déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue bug déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue chore déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue feature déjà présent · skip (utilise --force pour écraser)

[0;34m══ github-actions (unknown) ══[0m
[0;33m⚠[0m  stack indétecté · skip templates spécifiques
  \033[0;90m=\033[0m GitVersion déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m README déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m CLAUDE.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m DECISIONS.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m ROADMAP.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m ARCHITECTURE.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m _reusable-ci (shared) déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m dependabot déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m CODEOWNERS déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m PR template déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labeler rules déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labels palette déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m dependabot-auto-merge déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m branch-auto-update déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m enforce-issue-link déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labeler workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m sync-labels workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m pr-size-label workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude config déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude settings déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude secret-allowlist déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude thresholds déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude quality-hook déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m check-standards-sync déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m _lib.sh déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue bug déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue chore déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue feature déjà présent · skip (utilise --force pour écraser)

[0;34m══ guideline-checker (python) ══[0m
  \033[0;90m=\033[0m GitVersion déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m README déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m CLAUDE.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m DECISIONS.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m ROADMAP.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m ARCHITECTURE.md déjà présent · skip (utilise --force pour écraser)
[0;33m⚠[0m  .gitignore (python) : 28 lignes template absentes dans .gitignore · envisage merge manuel
  \033[0;90m=\033[0m _reusable-ci (shared) déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m pre-commit (python) déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m CI (python) déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m Makefile (python) déjà présent · skip (utilise --force pour écraser)
[0;33m⚠[0m  template absent : /home/anthony/Documents/perso/projects/chrysa/shared-standards/templates/makefile/quality.makefile
[0;33m⚠[0m  template absent : /home/anthony/Documents/perso/projects/chrysa/shared-standards/templates/makefile/install.makefile
[0;33m⚠[0m  template absent : /home/anthony/Documents/perso/projects/chrysa/shared-standards/templates/makefile/docker.makefile
  \033[0;90m=\033[0m Dockerfile (python) déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m dependabot déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m CODEOWNERS déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m PR template déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labeler rules déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labels palette déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m dependabot-auto-merge déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m branch-auto-update déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m enforce-issue-link déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labeler workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m sync-labels workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m pr-size-label workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude config déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude settings déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude secret-allowlist déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude thresholds déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude quality-hook déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m check-standards-sync déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m _lib.sh déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue bug déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue chore déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue feature déjà présent · skip (utilise --force pour écraser)

[0;34m══ lifeos (python) ══[0m
  \033[0;90m=\033[0m GitVersion déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m README déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m CLAUDE.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m DECISIONS.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m ROADMAP.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m ARCHITECTURE.md déjà présent · skip (utilise --force pour écraser)
[0;33m⚠[0m  .gitignore (python) : 35 lignes template absentes dans .gitignore · envisage merge manuel
  \033[0;90m=\033[0m _reusable-ci (shared) déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m pre-commit (python) déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m CI (python) déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m Makefile (python) déjà présent · skip (utilise --force pour écraser)
[0;33m⚠[0m  template absent : /home/anthony/Documents/perso/projects/chrysa/shared-standards/templates/makefile/quality.makefile
[0;33m⚠[0m  template absent : /home/anthony/Documents/perso/projects/chrysa/shared-standards/templates/makefile/install.makefile
[0;33m⚠[0m  template absent : /home/anthony/Documents/perso/projects/chrysa/shared-standards/templates/makefile/docker.makefile
  \033[0;90m=\033[0m Dockerfile (python) déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m dependabot déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m CODEOWNERS déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m PR template déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labeler rules déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labels palette déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m dependabot-auto-merge déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m branch-auto-update déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m enforce-issue-link déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labeler workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m sync-labels workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m pr-size-label workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude config déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude settings déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude secret-allowlist déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude thresholds déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude quality-hook déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m check-standards-sync déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m _lib.sh déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue bug déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue chore déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue feature déjà présent · skip (utilise --force pour écraser)
\033[0;90m⊘ linkendin-resume · skip-list\033[0m

[0;34m══ my-fridge (unknown) ══[0m
[0;33m⚠[0m  stack indétecté · skip templates spécifiques
  \033[0;90m=\033[0m GitVersion déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m README déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m CLAUDE.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m DECISIONS.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m ROADMAP.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m ARCHITECTURE.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m _reusable-ci (shared) déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m dependabot déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m CODEOWNERS déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m PR template déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labeler rules déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labels palette déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m dependabot-auto-merge déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m branch-auto-update déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m enforce-issue-link déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labeler workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m sync-labels workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m pr-size-label workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude config déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude settings déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude secret-allowlist déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude thresholds déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude quality-hook déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m check-standards-sync déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m _lib.sh déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue bug déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue chore déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue feature déjà présent · skip (utilise --force pour écraser)
\033[0;90m⊘ my-resume · skip-list\033[0m

[0;34m══ notion-automation (node) ══[0m
  \033[0;90m=\033[0m GitVersion déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m README déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m CLAUDE.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m DECISIONS.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m ROADMAP.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m ARCHITECTURE.md déjà présent · skip (utilise --force pour écraser)
[0;33m⚠[0m  .gitignore (node) : 40 lignes template absentes dans .gitignore · envisage merge manuel
  \033[0;90m=\033[0m _reusable-ci (shared) déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m pre-commit (node) déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m CI (node) déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m Makefile (node) déjà présent · skip (utilise --force pour écraser)
[0;33m⚠[0m  template absent : /home/anthony/Documents/perso/projects/chrysa/shared-standards/templates/makefile/quality.makefile
[0;33m⚠[0m  template absent : /home/anthony/Documents/perso/projects/chrysa/shared-standards/templates/makefile/install.makefile
[0;33m⚠[0m  template absent : /home/anthony/Documents/perso/projects/chrysa/shared-standards/templates/makefile/docker.makefile
  \033[0;90m=\033[0m Dockerfile (node) déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m dependabot déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m CODEOWNERS déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m PR template déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labeler rules déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labels palette déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m dependabot-auto-merge déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m branch-auto-update déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m enforce-issue-link déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labeler workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m sync-labels workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m pr-size-label workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude config déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude settings déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude secret-allowlist déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude thresholds déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude quality-hook déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m check-standards-sync déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m _lib.sh déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue bug déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue chore déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue feature déjà présent · skip (utilise --force pour écraser)

[0;34m══ PO-GO-DEX (unknown) ══[0m
[0;33m⚠[0m  stack indétecté · skip templates spécifiques
  \033[0;90m=\033[0m GitVersion déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m README déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m CLAUDE.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m DECISIONS.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m ROADMAP.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m ARCHITECTURE.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m _reusable-ci (shared) déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m dependabot déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m CODEOWNERS déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m PR template déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labeler rules déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labels palette déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m dependabot-auto-merge déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m branch-auto-update déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m enforce-issue-link déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labeler workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m sync-labels workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m pr-size-label workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude config déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude settings déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude secret-allowlist déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude thresholds déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude quality-hook déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m check-standards-sync déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m _lib.sh déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue bug déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue chore déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue feature déjà présent · skip (utilise --force pour écraser)

[0;34m══ pre-commit-tools (python) ══[0m
  \033[0;90m=\033[0m GitVersion déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m README déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m CLAUDE.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m DECISIONS.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m ROADMAP.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m ARCHITECTURE.md déjà présent · skip (utilise --force pour écraser)
[0;33m⚠[0m  .gitignore (python) : 57 lignes template absentes dans .gitignore · envisage merge manuel
  \033[0;90m=\033[0m _reusable-ci (shared) déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m pre-commit (python) déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m CI (python) déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m Makefile (python) déjà présent · skip (utilise --force pour écraser)
[0;33m⚠[0m  template absent : /home/anthony/Documents/perso/projects/chrysa/shared-standards/templates/makefile/quality.makefile
[0;33m⚠[0m  template absent : /home/anthony/Documents/perso/projects/chrysa/shared-standards/templates/makefile/install.makefile
[0;33m⚠[0m  template absent : /home/anthony/Documents/perso/projects/chrysa/shared-standards/templates/makefile/docker.makefile
  \033[0;90m=\033[0m Dockerfile (python) déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m dependabot déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m CODEOWNERS déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m PR template déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labeler rules déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labels palette déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m dependabot-auto-merge déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m branch-auto-update déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m enforce-issue-link déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labeler workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m sync-labels workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m pr-size-label workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude config déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude settings déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude secret-allowlist déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude thresholds déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude quality-hook déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m check-standards-sync déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m _lib.sh déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue bug déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue chore déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue feature déjà présent · skip (utilise --force pour écraser)

[0;34m══ project-init (unknown) ══[0m
[0;33m⚠[0m  stack indétecté · skip templates spécifiques
  \033[0;90m=\033[0m GitVersion déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m README déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m CLAUDE.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m DECISIONS.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m ROADMAP.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m ARCHITECTURE.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m _reusable-ci (shared) déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m dependabot déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m CODEOWNERS déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m PR template déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labeler rules déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labels palette déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m dependabot-auto-merge déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m branch-auto-update déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m enforce-issue-link déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labeler workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m sync-labels workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m pr-size-label workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude config déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude settings déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude secret-allowlist déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude thresholds déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude quality-hook déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m check-standards-sync déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m _lib.sh déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue bug déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue chore déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue feature déjà présent · skip (utilise --force pour écraser)

[0;34m══ pycharm_settings (unknown) ══[0m
[0;33m⚠[0m  stack indétecté · skip templates spécifiques
  \033[0;90m=\033[0m GitVersion déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m README déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m CLAUDE.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m DECISIONS.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m ROADMAP.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m ARCHITECTURE.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m _reusable-ci (shared) déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m dependabot déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m CODEOWNERS déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m PR template déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labeler rules déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labels palette déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m dependabot-auto-merge déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m branch-auto-update déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m enforce-issue-link déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labeler workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m sync-labels workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m pr-size-label workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude config déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude settings déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude secret-allowlist déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude thresholds déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude quality-hook déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m check-standards-sync déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m _lib.sh déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue bug déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue chore déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue feature déjà présent · skip (utilise --force pour écraser)

[0;34m══ satisfactory-automated_calculator (node) ══[0m
  \033[0;90m=\033[0m GitVersion déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m README déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m CLAUDE.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m DECISIONS.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m ROADMAP.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m ARCHITECTURE.md déjà présent · skip (utilise --force pour écraser)
[0;33m⚠[0m  .gitignore (node) : 37 lignes template absentes dans .gitignore · envisage merge manuel
  \033[0;90m=\033[0m _reusable-ci (shared) déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m pre-commit (node) déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m CI (node) déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m Makefile (node) déjà présent · skip (utilise --force pour écraser)
[0;33m⚠[0m  template absent : /home/anthony/Documents/perso/projects/chrysa/shared-standards/templates/makefile/quality.makefile
[0;33m⚠[0m  template absent : /home/anthony/Documents/perso/projects/chrysa/shared-standards/templates/makefile/install.makefile
[0;33m⚠[0m  template absent : /home/anthony/Documents/perso/projects/chrysa/shared-standards/templates/makefile/docker.makefile
  \033[0;90m=\033[0m Dockerfile (node) déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m dependabot déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m CODEOWNERS déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m PR template déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labeler rules déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labels palette déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m dependabot-auto-merge déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m branch-auto-update déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m enforce-issue-link déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labeler workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m sync-labels workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m pr-size-label workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude config déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude settings déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude secret-allowlist déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude thresholds déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude quality-hook déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m check-standards-sync déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m _lib.sh déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue bug déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue chore déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue feature déjà présent · skip (utilise --force pour écraser)

[0;34m══ server (unknown) ══[0m
[0;33m⚠[0m  stack indétecté · skip templates spécifiques
  \033[0;90m=\033[0m GitVersion déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m README déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m CLAUDE.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m DECISIONS.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m ROADMAP.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m ARCHITECTURE.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m _reusable-ci (shared) déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m dependabot déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m CODEOWNERS déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m PR template déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labeler rules déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labels palette déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m dependabot-auto-merge déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m branch-auto-update déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m enforce-issue-link déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labeler workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m sync-labels workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m pr-size-label workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude config déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude settings déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude secret-allowlist déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude thresholds déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude quality-hook déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m check-standards-sync déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m _lib.sh déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue bug déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue chore déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue feature déjà présent · skip (utilise --force pour écraser)
[0;33m⚠[0m  server-ci-assets · pas un git repo · skip
[0;33m⚠[0m  _session_archive · pas un git repo · skip
\033[0;90m⊘ shared-standards · skip-list\033[0m
\033[0;90m⊘ skills · skip-list\033[0m
\033[0;90m⊘ standards-updates · skip-list\033[0m

[0;34m══ usefull-containers (unknown) ══[0m
[0;33m⚠[0m  stack indétecté · skip templates spécifiques
  \033[0;90m=\033[0m GitVersion déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m README déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m CLAUDE.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m DECISIONS.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m ROADMAP.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m ARCHITECTURE.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m _reusable-ci (shared) déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m dependabot déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m CODEOWNERS déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m PR template déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labeler rules déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labels palette déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m dependabot-auto-merge déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m branch-auto-update déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m enforce-issue-link déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labeler workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m sync-labels workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m pr-size-label workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude config déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude settings déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude secret-allowlist déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude thresholds déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude quality-hook déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m check-standards-sync déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m _lib.sh déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue bug déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue chore déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue feature déjà présent · skip (utilise --force pour écraser)

[0;34m══ windows-docker-state-notification (python) ══[0m
  \033[0;90m=\033[0m GitVersion déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m README déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m CLAUDE.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m DECISIONS.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m ROADMAP.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m ARCHITECTURE.md déjà présent · skip (utilise --force pour écraser)
[0;33m⚠[0m  .gitignore (python) : 59 lignes template absentes dans .gitignore · envisage merge manuel
  \033[0;90m=\033[0m _reusable-ci (shared) déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m pre-commit (python) déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m CI (python) déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m Makefile (python) déjà présent · skip (utilise --force pour écraser)
[0;33m⚠[0m  template absent : /home/anthony/Documents/perso/projects/chrysa/shared-standards/templates/makefile/quality.makefile
[0;33m⚠[0m  template absent : /home/anthony/Documents/perso/projects/chrysa/shared-standards/templates/makefile/install.makefile
[0;33m⚠[0m  template absent : /home/anthony/Documents/perso/projects/chrysa/shared-standards/templates/makefile/docker.makefile
  \033[0;90m=\033[0m Dockerfile (python) déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m dependabot déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m CODEOWNERS déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m PR template déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labeler rules déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labels palette déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m dependabot-auto-merge déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m branch-auto-update déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m enforce-issue-link déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labeler workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m sync-labels workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m pr-size-label workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude config déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude settings déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude secret-allowlist déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude thresholds déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude quality-hook déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m check-standards-sync déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m _lib.sh déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue bug déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue chore déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue feature déjà présent · skip (utilise --force pour écraser)

[0;32m✓[0m apply-standards terminé
[0;33m⚠[0m  mode dry-run · aucune modif réelle
[0;32m✓[0m Étape terminée

[0;34m══ 9/10 · Générer rollup roadmap + graphe dépendances + index docs ══[0m
[0;90mCommande : bash /home/anthony/Documents/perso/projects/chrysa/shared-standards/scripts/generate-roadmap-rollup.sh[0m
? Exécuter cette étape ? → auto-yes
✅ Rollup généré : /home/anthony/Documents/perso/projects/chrysa/shared-standards/docs/ROADMAP-ROLLUP.md
   Taille : 1718 lignes
[0;32m✓[0m Étape terminée

[0;34m══ 10/10 · Graphe dépendances + index docs ══[0m
[0;90mCommande : bash /home/anthony/Documents/perso/projects/chrysa/shared-standards/scripts/generate-deps-graph.sh[0m
? Exécuter cette étape ? → auto-yes
✅ Graphe Mermaid généré : /home/anthony/Documents/perso/projects/chrysa/shared-standards/docs/diagrams/dependencies-2026-04-20.mmd
   Pour rendre en SVG : mmdc -i /home/anthony/Documents/perso/projects/chrysa/shared-standards/docs/diagrams/dependencies-2026-04-20.mmd -o ${OUT_MMD%.mmd}.svg
[0;32m✓[0m Étape terminée

[0;34m══ ✅ fix-all terminé ══[0m

Récapitulatif :
  - Settings GitHub standardisés (hors 403 GitHub Free)
  - Repos obsolètes archivés
  - Fusions ADRs appliquées (hors ADR-0014 révoqué par ADR-0026)
  - Dossier zombie my-assistant nettoyé
  - Repos synchronisés (pull)
  - portfolio.html régénéré

📌 Actions NON scriptables restantes :
   Voir shared-standards/docs/remaining-manual-actions.md

1 |
| 3-apply-standards | ✗ FAILED | 9s | 1 | [0;34m═══════════════════════════════════════[0m
[0;34m  apply-standards.sh · mode LIVE[0m
[0;34m═══════════════════════════════════════[0m

[0;34m══ ai-aggregator (python) ══[0m
  \033[0;90m=\033[0m GitVersion déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m README déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m CLAUDE.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m DECISIONS.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m ROADMAP.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m ARCHITECTURE.md déjà présent · skip (utilise --force pour écraser)
[0;33m⚠[0m  .gitignore (python) : 34 lignes template absentes dans .gitignore · envisage merge manuel
  \033[0;90m=\033[0m _reusable-ci (shared) déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m pre-commit (python) déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m CI (python) déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m Makefile (python) déjà présent · skip (utilise --force pour écraser)
[0;33m⚠[0m  template absent : /home/anthony/Documents/perso/projects/chrysa/shared-standards/templates/makefile/quality.makefile
[0;33m⚠[0m  template absent : /home/anthony/Documents/perso/projects/chrysa/shared-standards/templates/makefile/install.makefile
[0;33m⚠[0m  template absent : /home/anthony/Documents/perso/projects/chrysa/shared-standards/templates/makefile/docker.makefile
  \033[0;90m=\033[0m Dockerfile (python) déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m dependabot déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m CODEOWNERS déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m PR template déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labeler rules déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labels palette déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m dependabot-auto-merge déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m branch-auto-update déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m enforce-issue-link déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labeler workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m sync-labels workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m pr-size-label workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude config déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude settings déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude secret-allowlist déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude thresholds déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude quality-hook déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m check-standards-sync déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m _lib.sh déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue bug déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue chore déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue feature déjà présent · skip (utilise --force pour écraser)
\033[0;90m⊘ _archived · skip-list\033[0m

[0;34m══ chrysa-lib (unknown) ══[0m
[0;33m⚠[0m  stack indétecté · skip templates spécifiques
  \033[0;90m=\033[0m GitVersion déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m README déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m CLAUDE.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m DECISIONS.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m ROADMAP.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m ARCHITECTURE.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m _reusable-ci (shared) déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m dependabot déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m CODEOWNERS déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m PR template déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labeler rules déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labels palette déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m dependabot-auto-merge déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m branch-auto-update déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m enforce-issue-link déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labeler workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m sync-labels workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m pr-size-label workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude config déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude settings déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude secret-allowlist déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude thresholds déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude quality-hook déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m check-standards-sync déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m _lib.sh déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue bug déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue chore déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue feature déjà présent · skip (utilise --force pour écraser)

[0;34m══ coach (unknown) ══[0m
[0;33m⚠[0m  stack indétecté · skip templates spécifiques
  \033[0;90m=\033[0m GitVersion déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m README déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m CLAUDE.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m DECISIONS.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m ROADMAP.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m ARCHITECTURE.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m _reusable-ci (shared) déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m dependabot déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m CODEOWNERS déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m PR template déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labeler rules déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labels palette déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m dependabot-auto-merge déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m branch-auto-update déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m enforce-issue-link déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labeler workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m sync-labels workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m pr-size-label workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude config déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude settings déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude secret-allowlist déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude thresholds déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude quality-hook déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m check-standards-sync déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m _lib.sh déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue bug déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue chore déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue feature déjà présent · skip (utilise --force pour écraser)

[0;34m══ container-webview (unknown) ══[0m
[0;33m⚠[0m  stack indétecté · skip templates spécifiques
  \033[0;90m=\033[0m GitVersion déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m README déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m CLAUDE.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m DECISIONS.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m ROADMAP.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m ARCHITECTURE.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m _reusable-ci (shared) déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m dependabot déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m CODEOWNERS déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m PR template déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labeler rules déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labels palette déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m dependabot-auto-merge déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m branch-auto-update déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m enforce-issue-link déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labeler workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m sync-labels workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m pr-size-label workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude config déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude settings déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude secret-allowlist déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude thresholds déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude quality-hook déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m check-standards-sync déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m _lib.sh déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue bug déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue chore déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue feature déjà présent · skip (utilise --force pour écraser)

[0;34m══ D-D (node) ══[0m
  \033[0;90m=\033[0m GitVersion déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m README déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m CLAUDE.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m DECISIONS.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m ROADMAP.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m ARCHITECTURE.md déjà présent · skip (utilise --force pour écraser)
[0;33m⚠[0m  .gitignore (node) : 42 lignes template absentes dans .gitignore · envisage merge manuel
  \033[0;90m=\033[0m _reusable-ci (shared) déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m pre-commit (node) déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m CI (node) déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m Makefile (node) déjà présent · skip (utilise --force pour écraser)
[0;33m⚠[0m  template absent : /home/anthony/Documents/perso/projects/chrysa/shared-standards/templates/makefile/quality.makefile
[0;33m⚠[0m  template absent : /home/anthony/Documents/perso/projects/chrysa/shared-standards/templates/makefile/install.makefile
[0;33m⚠[0m  template absent : /home/anthony/Documents/perso/projects/chrysa/shared-standards/templates/makefile/docker.makefile
  \033[0;90m=\033[0m Dockerfile (node) déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m dependabot déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m CODEOWNERS déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m PR template déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labeler rules déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labels palette déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m dependabot-auto-merge déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m branch-auto-update déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m enforce-issue-link déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labeler workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m sync-labels workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m pr-size-label workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude config déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude settings déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude secret-allowlist déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude thresholds déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude quality-hook déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m check-standards-sync déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m _lib.sh déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue bug déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue chore déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue feature déjà présent · skip (utilise --force pour écraser)

[0;34m══ dev-nexus (unknown) ══[0m
[0;33m⚠[0m  stack indétecté · skip templates spécifiques
  \033[0;90m=\033[0m GitVersion déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m README déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m CLAUDE.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m DECISIONS.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m ROADMAP.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m ARCHITECTURE.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m _reusable-ci (shared) déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m dependabot déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m CODEOWNERS déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m PR template déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labeler rules déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labels palette déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m dependabot-auto-merge déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m branch-auto-update déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m enforce-issue-link déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labeler workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m sync-labels workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m pr-size-label workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude config déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude settings déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude secret-allowlist déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude thresholds déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude quality-hook déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m check-standards-sync déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m _lib.sh déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue bug déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue chore déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue feature déjà présent · skip (utilise --force pour écraser)

[0;34m══ discord-bot-back (python) ══[0m
  \033[0;90m=\033[0m GitVersion déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m README déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m CLAUDE.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m DECISIONS.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m ROADMAP.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m ARCHITECTURE.md déjà présent · skip (utilise --force pour écraser)
[0;33m⚠[0m  .gitignore (python) : 61 lignes template absentes dans .gitignore · envisage merge manuel
  \033[0;90m=\033[0m _reusable-ci (shared) déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m pre-commit (python) déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m CI (python) déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m Makefile (python) déjà présent · skip (utilise --force pour écraser)
[0;33m⚠[0m  template absent : /home/anthony/Documents/perso/projects/chrysa/shared-standards/templates/makefile/quality.makefile
[0;33m⚠[0m  template absent : /home/anthony/Documents/perso/projects/chrysa/shared-standards/templates/makefile/install.makefile
[0;33m⚠[0m  template absent : /home/anthony/Documents/perso/projects/chrysa/shared-standards/templates/makefile/docker.makefile
  \033[0;90m=\033[0m Dockerfile (python) déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m dependabot déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m CODEOWNERS déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m PR template déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labeler rules déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labels palette déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m dependabot-auto-merge déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m branch-auto-update déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m enforce-issue-link déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labeler workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m sync-labels workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m pr-size-label workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude config déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude settings déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude secret-allowlist déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude thresholds déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude quality-hook déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m check-standards-sync déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m _lib.sh déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue bug déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue chore déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue feature déjà présent · skip (utilise --force pour écraser)

[0;34m══ diy-stream-deck (python) ══[0m
  \033[0;90m=\033[0m GitVersion déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m README déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m CLAUDE.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m DECISIONS.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m ROADMAP.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m ARCHITECTURE.md déjà présent · skip (utilise --force pour écraser)
[0;33m⚠[0m  .gitignore (python) : 28 lignes template absentes dans .gitignore · envisage merge manuel
  \033[0;90m=\033[0m _reusable-ci (shared) déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m pre-commit (python) déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m CI (python) déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m Makefile (python) déjà présent · skip (utilise --force pour écraser)
[0;33m⚠[0m  template absent : /home/anthony/Documents/perso/projects/chrysa/shared-standards/templates/makefile/quality.makefile
[0;33m⚠[0m  template absent : /home/anthony/Documents/perso/projects/chrysa/shared-standards/templates/makefile/install.makefile
[0;33m⚠[0m  template absent : /home/anthony/Documents/perso/projects/chrysa/shared-standards/templates/makefile/docker.makefile
  \033[0;90m=\033[0m Dockerfile (python) déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m dependabot déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m CODEOWNERS déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m PR template déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labeler rules déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labels palette déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m dependabot-auto-merge déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m branch-auto-update déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m enforce-issue-link déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labeler workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m sync-labels workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m pr-size-label workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude config déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude settings déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude secret-allowlist déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude thresholds déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude quality-hook déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m check-standards-sync déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m _lib.sh déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue bug déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue chore déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue feature déjà présent · skip (utilise --force pour écraser)

[0;34m══ doc-gen (python) ══[0m
  \033[0;90m=\033[0m GitVersion déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m README déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m CLAUDE.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m DECISIONS.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m ROADMAP.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m ARCHITECTURE.md déjà présent · skip (utilise --force pour écraser)
[0;33m⚠[0m  .gitignore (python) : 37 lignes template absentes dans .gitignore · envisage merge manuel
  \033[0;90m=\033[0m _reusable-ci (shared) déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m pre-commit (python) déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m CI (python) déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m Makefile (python) déjà présent · skip (utilise --force pour écraser)
[0;33m⚠[0m  template absent : /home/anthony/Documents/perso/projects/chrysa/shared-standards/templates/makefile/quality.makefile
[0;33m⚠[0m  template absent : /home/anthony/Documents/perso/projects/chrysa/shared-standards/templates/makefile/install.makefile
[0;33m⚠[0m  template absent : /home/anthony/Documents/perso/projects/chrysa/shared-standards/templates/makefile/docker.makefile
  \033[0;90m=\033[0m Dockerfile (python) déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m dependabot déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m CODEOWNERS déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m PR template déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labeler rules déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labels palette déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m dependabot-auto-merge déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m branch-auto-update déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m enforce-issue-link déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labeler workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m sync-labels workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m pr-size-label workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude config déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude settings déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude secret-allowlist déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude thresholds déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude quality-hook déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m check-standards-sync déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m _lib.sh déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue bug déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue chore déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue feature déjà présent · skip (utilise --force pour écraser)
[0;33m⚠[0m  drive-cleanup · pas un git repo · skip
[0;33m⚠[0m  ecosystem-reorg · pas un git repo · skip

[0;34m══ epub-sorter (python) ══[0m
  \033[0;90m=\033[0m GitVersion déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m README déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m CLAUDE.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m DECISIONS.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m ROADMAP.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m ARCHITECTURE.md déjà présent · skip (utilise --force pour écraser)
[0;33m⚠[0m  .gitignore (python) : 59 lignes template absentes dans .gitignore · envisage merge manuel
  \033[0;90m=\033[0m _reusable-ci (shared) déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m pre-commit (python) déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m CI (python) déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m Makefile (python) déjà présent · skip (utilise --force pour écraser)
[0;33m⚠[0m  template absent : /home/anthony/Documents/perso/projects/chrysa/shared-standards/templates/makefile/quality.makefile
[0;33m⚠[0m  template absent : /home/anthony/Documents/perso/projects/chrysa/shared-standards/templates/makefile/install.makefile
[0;33m⚠[0m  template absent : /home/anthony/Documents/perso/projects/chrysa/shared-standards/templates/makefile/docker.makefile
  \033[0;90m=\033[0m Dockerfile (python) déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m dependabot déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m CODEOWNERS déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m PR template déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labeler rules déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labels palette déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m dependabot-auto-merge déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m branch-auto-update déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m enforce-issue-link déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labeler workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m sync-labels workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m pr-size-label workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude config déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude settings déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude secret-allowlist déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude thresholds déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude quality-hook déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m check-standards-sync déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m _lib.sh déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue bug déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue chore déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue feature déjà présent · skip (utilise --force pour écraser)

[0;34m══ genealogy-validator (python) ══[0m
  \033[0;90m=\033[0m GitVersion déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m README déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m CLAUDE.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m DECISIONS.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m ROADMAP.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m ARCHITECTURE.md déjà présent · skip (utilise --force pour écraser)
[0;33m⚠[0m  .gitignore (python) : 28 lignes template absentes dans .gitignore · envisage merge manuel
  \033[0;90m=\033[0m _reusable-ci (shared) déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m pre-commit (python) déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m CI (python) déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m Makefile (python) déjà présent · skip (utilise --force pour écraser)
[0;33m⚠[0m  template absent : /home/anthony/Documents/perso/projects/chrysa/shared-standards/templates/makefile/quality.makefile
[0;33m⚠[0m  template absent : /home/anthony/Documents/perso/projects/chrysa/shared-standards/templates/makefile/install.makefile
[0;33m⚠[0m  template absent : /home/anthony/Documents/perso/projects/chrysa/shared-standards/templates/makefile/docker.makefile
  \033[0;90m=\033[0m Dockerfile (python) déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m dependabot déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m CODEOWNERS déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m PR template déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labeler rules déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labels palette déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m dependabot-auto-merge déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m branch-auto-update déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m enforce-issue-link déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labeler workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m sync-labels workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m pr-size-label workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude config déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude settings déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude secret-allowlist déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude thresholds déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude quality-hook déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m check-standards-sync déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m _lib.sh déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue bug déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue chore déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue feature déjà présent · skip (utilise --force pour écraser)

[0;34m══ github-actions (unknown) ══[0m
[0;33m⚠[0m  stack indétecté · skip templates spécifiques
  \033[0;90m=\033[0m GitVersion déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m README déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m CLAUDE.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m DECISIONS.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m ROADMAP.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m ARCHITECTURE.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m _reusable-ci (shared) déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m dependabot déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m CODEOWNERS déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m PR template déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labeler rules déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labels palette déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m dependabot-auto-merge déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m branch-auto-update déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m enforce-issue-link déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labeler workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m sync-labels workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m pr-size-label workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude config déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude settings déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude secret-allowlist déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude thresholds déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude quality-hook déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m check-standards-sync déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m _lib.sh déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue bug déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue chore déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue feature déjà présent · skip (utilise --force pour écraser)

[0;34m══ guideline-checker (python) ══[0m
  \033[0;90m=\033[0m GitVersion déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m README déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m CLAUDE.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m DECISIONS.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m ROADMAP.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m ARCHITECTURE.md déjà présent · skip (utilise --force pour écraser)
[0;33m⚠[0m  .gitignore (python) : 28 lignes template absentes dans .gitignore · envisage merge manuel
  \033[0;90m=\033[0m _reusable-ci (shared) déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m pre-commit (python) déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m CI (python) déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m Makefile (python) déjà présent · skip (utilise --force pour écraser)
[0;33m⚠[0m  template absent : /home/anthony/Documents/perso/projects/chrysa/shared-standards/templates/makefile/quality.makefile
[0;33m⚠[0m  template absent : /home/anthony/Documents/perso/projects/chrysa/shared-standards/templates/makefile/install.makefile
[0;33m⚠[0m  template absent : /home/anthony/Documents/perso/projects/chrysa/shared-standards/templates/makefile/docker.makefile
  \033[0;90m=\033[0m Dockerfile (python) déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m dependabot déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m CODEOWNERS déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m PR template déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labeler rules déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labels palette déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m dependabot-auto-merge déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m branch-auto-update déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m enforce-issue-link déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labeler workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m sync-labels workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m pr-size-label workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude config déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude settings déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude secret-allowlist déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude thresholds déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude quality-hook déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m check-standards-sync déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m _lib.sh déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue bug déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue chore déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue feature déjà présent · skip (utilise --force pour écraser)

[0;34m══ lifeos (python) ══[0m
  \033[0;90m=\033[0m GitVersion déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m README déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m CLAUDE.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m DECISIONS.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m ROADMAP.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m ARCHITECTURE.md déjà présent · skip (utilise --force pour écraser)
[0;33m⚠[0m  .gitignore (python) : 35 lignes template absentes dans .gitignore · envisage merge manuel
  \033[0;90m=\033[0m _reusable-ci (shared) déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m pre-commit (python) déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m CI (python) déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m Makefile (python) déjà présent · skip (utilise --force pour écraser)
[0;33m⚠[0m  template absent : /home/anthony/Documents/perso/projects/chrysa/shared-standards/templates/makefile/quality.makefile
[0;33m⚠[0m  template absent : /home/anthony/Documents/perso/projects/chrysa/shared-standards/templates/makefile/install.makefile
[0;33m⚠[0m  template absent : /home/anthony/Documents/perso/projects/chrysa/shared-standards/templates/makefile/docker.makefile
  \033[0;90m=\033[0m Dockerfile (python) déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m dependabot déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m CODEOWNERS déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m PR template déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labeler rules déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labels palette déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m dependabot-auto-merge déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m branch-auto-update déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m enforce-issue-link déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labeler workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m sync-labels workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m pr-size-label workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude config déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude settings déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude secret-allowlist déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude thresholds déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude quality-hook déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m check-standards-sync déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m _lib.sh déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue bug déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue chore déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue feature déjà présent · skip (utilise --force pour écraser)
\033[0;90m⊘ linkendin-resume · skip-list\033[0m

[0;34m══ my-fridge (unknown) ══[0m
[0;33m⚠[0m  stack indétecté · skip templates spécifiques
  \033[0;90m=\033[0m GitVersion déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m README déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m CLAUDE.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m DECISIONS.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m ROADMAP.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m ARCHITECTURE.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m _reusable-ci (shared) déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m dependabot déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m CODEOWNERS déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m PR template déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labeler rules déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labels palette déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m dependabot-auto-merge déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m branch-auto-update déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m enforce-issue-link déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labeler workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m sync-labels workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m pr-size-label workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude config déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude settings déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude secret-allowlist déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude thresholds déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude quality-hook déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m check-standards-sync déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m _lib.sh déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue bug déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue chore déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue feature déjà présent · skip (utilise --force pour écraser)
\033[0;90m⊘ my-resume · skip-list\033[0m

[0;34m══ notion-automation (node) ══[0m
  \033[0;90m=\033[0m GitVersion déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m README déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m CLAUDE.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m DECISIONS.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m ROADMAP.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m ARCHITECTURE.md déjà présent · skip (utilise --force pour écraser)
[0;33m⚠[0m  .gitignore (node) : 40 lignes template absentes dans .gitignore · envisage merge manuel
  \033[0;90m=\033[0m _reusable-ci (shared) déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m pre-commit (node) déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m CI (node) déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m Makefile (node) déjà présent · skip (utilise --force pour écraser)
[0;33m⚠[0m  template absent : /home/anthony/Documents/perso/projects/chrysa/shared-standards/templates/makefile/quality.makefile
[0;33m⚠[0m  template absent : /home/anthony/Documents/perso/projects/chrysa/shared-standards/templates/makefile/install.makefile
[0;33m⚠[0m  template absent : /home/anthony/Documents/perso/projects/chrysa/shared-standards/templates/makefile/docker.makefile
  \033[0;90m=\033[0m Dockerfile (node) déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m dependabot déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m CODEOWNERS déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m PR template déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labeler rules déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labels palette déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m dependabot-auto-merge déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m branch-auto-update déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m enforce-issue-link déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labeler workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m sync-labels workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m pr-size-label workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude config déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude settings déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude secret-allowlist déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude thresholds déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude quality-hook déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m check-standards-sync déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m _lib.sh déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue bug déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue chore déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue feature déjà présent · skip (utilise --force pour écraser)

[0;34m══ PO-GO-DEX (unknown) ══[0m
[0;33m⚠[0m  stack indétecté · skip templates spécifiques
  \033[0;90m=\033[0m GitVersion déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m README déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m CLAUDE.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m DECISIONS.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m ROADMAP.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m ARCHITECTURE.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m _reusable-ci (shared) déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m dependabot déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m CODEOWNERS déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m PR template déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labeler rules déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labels palette déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m dependabot-auto-merge déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m branch-auto-update déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m enforce-issue-link déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labeler workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m sync-labels workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m pr-size-label workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude config déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude settings déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude secret-allowlist déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude thresholds déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude quality-hook déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m check-standards-sync déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m _lib.sh déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue bug déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue chore déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue feature déjà présent · skip (utilise --force pour écraser)

[0;34m══ pre-commit-tools (python) ══[0m
  \033[0;90m=\033[0m GitVersion déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m README déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m CLAUDE.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m DECISIONS.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m ROADMAP.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m ARCHITECTURE.md déjà présent · skip (utilise --force pour écraser)
[0;33m⚠[0m  .gitignore (python) : 57 lignes template absentes dans .gitignore · envisage merge manuel
  \033[0;90m=\033[0m _reusable-ci (shared) déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m pre-commit (python) déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m CI (python) déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m Makefile (python) déjà présent · skip (utilise --force pour écraser)
[0;33m⚠[0m  template absent : /home/anthony/Documents/perso/projects/chrysa/shared-standards/templates/makefile/quality.makefile
[0;33m⚠[0m  template absent : /home/anthony/Documents/perso/projects/chrysa/shared-standards/templates/makefile/install.makefile
[0;33m⚠[0m  template absent : /home/anthony/Documents/perso/projects/chrysa/shared-standards/templates/makefile/docker.makefile
  \033[0;90m=\033[0m Dockerfile (python) déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m dependabot déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m CODEOWNERS déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m PR template déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labeler rules déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labels palette déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m dependabot-auto-merge déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m branch-auto-update déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m enforce-issue-link déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labeler workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m sync-labels workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m pr-size-label workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude config déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude settings déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude secret-allowlist déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude thresholds déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude quality-hook déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m check-standards-sync déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m _lib.sh déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue bug déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue chore déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue feature déjà présent · skip (utilise --force pour écraser)

[0;34m══ project-init (unknown) ══[0m
[0;33m⚠[0m  stack indétecté · skip templates spécifiques
  \033[0;90m=\033[0m GitVersion déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m README déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m CLAUDE.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m DECISIONS.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m ROADMAP.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m ARCHITECTURE.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m _reusable-ci (shared) déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m dependabot déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m CODEOWNERS déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m PR template déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labeler rules déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labels palette déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m dependabot-auto-merge déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m branch-auto-update déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m enforce-issue-link déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labeler workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m sync-labels workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m pr-size-label workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude config déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude settings déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude secret-allowlist déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude thresholds déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude quality-hook déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m check-standards-sync déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m _lib.sh déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue bug déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue chore déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue feature déjà présent · skip (utilise --force pour écraser)

[0;34m══ pycharm_settings (unknown) ══[0m
[0;33m⚠[0m  stack indétecté · skip templates spécifiques
  \033[0;90m=\033[0m GitVersion déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m README déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m CLAUDE.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m DECISIONS.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m ROADMAP.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m ARCHITECTURE.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m _reusable-ci (shared) déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m dependabot déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m CODEOWNERS déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m PR template déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labeler rules déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labels palette déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m dependabot-auto-merge déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m branch-auto-update déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m enforce-issue-link déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labeler workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m sync-labels workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m pr-size-label workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude config déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude settings déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude secret-allowlist déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude thresholds déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude quality-hook déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m check-standards-sync déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m _lib.sh déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue bug déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue chore déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue feature déjà présent · skip (utilise --force pour écraser)

[0;34m══ satisfactory-automated_calculator (node) ══[0m
  \033[0;90m=\033[0m GitVersion déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m README déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m CLAUDE.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m DECISIONS.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m ROADMAP.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m ARCHITECTURE.md déjà présent · skip (utilise --force pour écraser)
[0;33m⚠[0m  .gitignore (node) : 37 lignes template absentes dans .gitignore · envisage merge manuel
  \033[0;90m=\033[0m _reusable-ci (shared) déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m pre-commit (node) déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m CI (node) déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m Makefile (node) déjà présent · skip (utilise --force pour écraser)
[0;33m⚠[0m  template absent : /home/anthony/Documents/perso/projects/chrysa/shared-standards/templates/makefile/quality.makefile
[0;33m⚠[0m  template absent : /home/anthony/Documents/perso/projects/chrysa/shared-standards/templates/makefile/install.makefile
[0;33m⚠[0m  template absent : /home/anthony/Documents/perso/projects/chrysa/shared-standards/templates/makefile/docker.makefile
  \033[0;90m=\033[0m Dockerfile (node) déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m dependabot déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m CODEOWNERS déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m PR template déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labeler rules déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labels palette déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m dependabot-auto-merge déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m branch-auto-update déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m enforce-issue-link déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labeler workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m sync-labels workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m pr-size-label workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude config déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude settings déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude secret-allowlist déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude thresholds déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude quality-hook déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m check-standards-sync déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m _lib.sh déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue bug déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue chore déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue feature déjà présent · skip (utilise --force pour écraser)

[0;34m══ server (unknown) ══[0m
[0;33m⚠[0m  stack indétecté · skip templates spécifiques
  \033[0;90m=\033[0m GitVersion déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m README déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m CLAUDE.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m DECISIONS.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m ROADMAP.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m ARCHITECTURE.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m _reusable-ci (shared) déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m dependabot déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m CODEOWNERS déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m PR template déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labeler rules déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labels palette déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m dependabot-auto-merge déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m branch-auto-update déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m enforce-issue-link déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labeler workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m sync-labels workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m pr-size-label workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude config déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude settings déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude secret-allowlist déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude thresholds déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude quality-hook déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m check-standards-sync déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m _lib.sh déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue bug déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue chore déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue feature déjà présent · skip (utilise --force pour écraser)
[0;33m⚠[0m  server-ci-assets · pas un git repo · skip
[0;33m⚠[0m  _session_archive · pas un git repo · skip
\033[0;90m⊘ shared-standards · skip-list\033[0m
\033[0;90m⊘ skills · skip-list\033[0m
\033[0;90m⊘ standards-updates · skip-list\033[0m

[0;34m══ usefull-containers (unknown) ══[0m
[0;33m⚠[0m  stack indétecté · skip templates spécifiques
  \033[0;90m=\033[0m GitVersion déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m README déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m CLAUDE.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m DECISIONS.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m ROADMAP.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m ARCHITECTURE.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m _reusable-ci (shared) déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m dependabot déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m CODEOWNERS déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m PR template déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labeler rules déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labels palette déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m dependabot-auto-merge déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m branch-auto-update déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m enforce-issue-link déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labeler workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m sync-labels workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m pr-size-label workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude config déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude settings déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude secret-allowlist déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude thresholds déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude quality-hook déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m check-standards-sync déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m _lib.sh déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue bug déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue chore déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue feature déjà présent · skip (utilise --force pour écraser)

[0;34m══ windows-docker-state-notification (python) ══[0m
  \033[0;90m=\033[0m GitVersion déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m README déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m CLAUDE.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m DECISIONS.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m ROADMAP.md déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m ARCHITECTURE.md déjà présent · skip (utilise --force pour écraser)
[0;33m⚠[0m  .gitignore (python) : 59 lignes template absentes dans .gitignore · envisage merge manuel
  \033[0;90m=\033[0m _reusable-ci (shared) déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m pre-commit (python) déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m CI (python) déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m Makefile (python) déjà présent · skip (utilise --force pour écraser)
[0;33m⚠[0m  template absent : /home/anthony/Documents/perso/projects/chrysa/shared-standards/templates/makefile/quality.makefile
[0;33m⚠[0m  template absent : /home/anthony/Documents/perso/projects/chrysa/shared-standards/templates/makefile/install.makefile
[0;33m⚠[0m  template absent : /home/anthony/Documents/perso/projects/chrysa/shared-standards/templates/makefile/docker.makefile
  \033[0;90m=\033[0m Dockerfile (python) déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m dependabot déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m CODEOWNERS déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m PR template déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labeler rules déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labels palette déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m dependabot-auto-merge déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m branch-auto-update déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m enforce-issue-link déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m labeler workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m sync-labels workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m pr-size-label workflow déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude config déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude settings déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude secret-allowlist déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude thresholds déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m claude quality-hook déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m check-standards-sync déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m _lib.sh déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue bug déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue chore déjà présent · skip (utilise --force pour écraser)
  \033[0;90m=\033[0m issue feature déjà présent · skip (utilise --force pour écraser)

[0;32m✓[0m apply-standards terminé
1 |
| 4-cross-project | ✓ OK | 17s | 0 | → Creating issue on chrysa/dev-nexus : [P0] Blocked by chrysa-lib Sprint 1 (@chrysa/auth)
could not add label: 'cross-project' not found
  ❌ failed (repo may not exist or permissions)
→ Creating issue on chrysa/my-fridge : [P0] Blocked by chrysa-lib Sprint 1 (@chrysa/auth)
could not add label: 'cross-project' not found
  ❌ failed (repo may not exist or permissions)
→ Creating issue on chrysa/lifeos : [P0] Blocked by chrysa-lib Sprint 1 (@chrysa/auth)
could not add label: 'cross-project' not found
  ❌ failed (repo may not exist or permissions)
→ Creating issue on chrysa/doc-gen : [P0] Blocked by chrysa-lib Sprint 1 (@chrysa/auth)
could not add label: 'cross-project' not found
  ❌ failed (repo may not exist or permissions)
→ Creating issue on chrysa/chrysa-lib : [P0] Sprint 1 — livrer @chrysa/auth (4 modes)
could not add label: 'cross-project' not found
  ❌ failed (repo may not exist or permissions)
→ Creating issue on chrysa/doc-gen : [P0] Résoudre PR #1 python-jose → joserfc
could not add label: 'priority/p0' not found
  ❌ failed (repo may not exist or permissions)
→ Creating issue on chrysa/ai-aggregator : [P1] Livrer module prompt-optimizer
could not add label: 'cross-project' not found
  ❌ failed (repo may not exist or permissions)
→ Creating issue on chrysa/server : [P1] Déployer stack monitoring local-first
could not add label: 'cross-project' not found
  ❌ failed (repo may not exist or permissions)
→ Creating issue on chrysa/shared-standards : [P2] Workflow auto-PR-handler
could not add label: 'cross-project' not found
  ❌ failed (repo may not exist or permissions)
→ Creating issue on chrysa/windows-autonome : [P2] Créer DECISIONS.md local (ADR-0026)
could not add label: 'cross-project' not found
  ❌ failed (repo may not exist or permissions)
→ Creating issue on chrysa/agent-config : [P2] Créer DECISIONS.md local (ADR-0026)
could not add label: 'cross-project' not found
  ❌ failed (repo may not exist or permissions)
→ Creating issue on chrysa/shared-standards : [P3] Fusions ADRs non exécutées — récapitulatif
could not add label: 'priority/p3' not found
  ❌ failed (repo may not exist or permissions)
→ Creating issue on chrysa/ai-aggregator : [P2] Installer Ollama self-hosted
could not add label: 'cross-project' not found
  ❌ failed (repo may not exist or permissions)

⚠️  Issue X-11 (Notion DB Bugs + Dette technique) = action manuelle UI Notion
    Voir shared-standards/docs/notion-restructure-plan.md P1.1-3
1 |
| 5-audit-issues | ✓ OK | 56s | 0 | ai-aggregator : 4 ouvertes · 0 stale · enhancement(3) · documentation(1) · research(1)
coach : 3 ouvertes · 0 stale ·
container-webview : 1 ouvertes · 0 stale · documentation(1) · research(1)
D-D : 1 ouvertes · 0 stale · question(1) · architecture(1)
dev-nexus : 12 ouvertes · 0 stale · v2+(11) · enhancement(9) · documentation(2)
discord-bot-back : 1 ouvertes · 0 stale · documentation(1) · research(1)
diy-stream-deck : 11 ouvertes · 0 stale · enhancement(10) · documentation(3)
genealogy-validator : 8 ouvertes · 0 stale · architecture(6) · documentation(5) · enhancement(2)
github-actions : 1 ouvertes · 0 stale · enhancement(1) · chore(1)
my-fridge : 4 ouvertes · 0 stale · enhancement(2) · bug(1) · documentation(1)
notion-automation : 7 ouvertes · 0 stale · chore(3) · automation(2) · ci(2)
pre-commit-tools : 1 ouvertes · 0 stale · bug(1)
project-init : 10 ouvertes · 0 stale · enhancement(2)
satisfactory-automated_calculator : 10 ouvertes · 0 stale · enhancement(7) · documentation(2) · architecture(2)
server : 21 ouvertes · 0 stale · M1-Foundation(6) · M4-DevTooling(4) · M3-Security(4)
shared-standards : 4 ouvertes · 0 stale ·

✅ Rapport : /home/anthony/Documents/perso/projects/chrysa/shared-standards/docs/issues-audit-2026-04-20.md
Total ouvertes : 99 · stale : 0
1 |
| 6-manual-actions | ✗ FAILED | 23s | 130 |
[0;34m═══════════════════════════════════════════════════[0m
[0;34m  chrysa · actions manuelles interactives[0m
[0;34m═══════════════════════════════════════════════════[0m

Commandes : y=done · n=skip · d=skip+deps · l=later · ?=détails · q=quit


[0;34m[[0mD1[0;34m][0m Trancher décisions D6-D11 (Breakline · Discordium V3 · Shadow Mandate · Life Roguelike · V5 Architecture)
> [0;33m⚠[0m  Commande inconnue · tâche marquée 'later'

[0;34m[[0mD2[0;34m][0m Commander TP-Link Deco X20/X50 (~120€)
> [0;32m✓[0m D2 marqué done

[0;34m[[0mD3[0;34m][0m Commander Shelly 1 Plus × 3 + reeds (~75€)
   [0;90mdeps: D2[0m
>  |

## Synthèse

- ✓ OK : 5
- ✗ Failed : 2
- ⚠ Skipped : 0
- Total : 7

## Prochaines actions (ordre reprio 2026-04-20)

**P0 (cette semaine)** — voir Notion ⚡ Chrysa Ops Tasks filtré P0
1. Commander TP-Link Deco (~120€) + Shelly × 3 (~75€)
2. Trancher D6-D11 (5 décisions)
3. Fix issue #83 pre-commit-tools
4. Server Phase 0 : audit Kimsufi + Tailscale + backup + monitoring

**P1 (2 sem)** — ntfy + Notion DBs + install TP-Link/Shelly/HA + Phase 1 parallèle (ai-aggregator V0 // dev-nexus V0 scaffold)

**P2+** — chrysa-lib Sprint 1 · doc-gen PR#1 · Vaultwarden · DECISIONS.md

## Liens

- 🔸 INDEX Wiki : https://www.notion.so/34859293e35e81839c77d381a2db7a16
- 🎯 Repriorisation : https://www.notion.so/34859293e35e81f9b015db5d9307877d
- ⚡ Ops Tasks : https://www.notion.so/0fa827fa2ef7496aa1292860a401d8ac

## Reprise

```bash
bash /home/anthony/Documents/perso/projects/chrysa/shared-standards/scripts/manual-actions.sh --status   # état 42 tâches
bash /home/anthony/Documents/perso/projects/chrysa/shared-standards/scripts/check-standards-sync.sh      # drift templates
bash /home/anthony/Documents/perso/projects/chrysa/shared-standards/scripts/repos-push-pending.sh        # push actifs
```
