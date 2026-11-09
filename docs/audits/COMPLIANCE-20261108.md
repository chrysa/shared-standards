# Fleet standards compliance audit — 2026-11-08

_95 non-archived `chrysa/*` repositories · 842 open pull requests · remediation in progress_

Canon: `dev-kit` (ADR-0001, MD-029) for authority, `shared-standards` for the rules it still
distributes (`standards/STANDARDS.chrysa.md`, `standards/annexes/SCM.md`, `standards/rules/scm.md`).
Previous audit: [`COMPLIANCE-20260615.md`](COMPLIANCE-20260615.md).

## 1. Method

- One GraphQL snapshot of every non-archived repository: default branch, branch protection,
  merge settings, presence of the distributed files, and every open PR with its last 30
  commits (title, branch, body, labels, commit authors and messages).
- Rules checked mechanically: Conventional Commit PR title, branch prefix, Shortcut story link
  (`sc-N`, story URL, `[sc-N]`, or the `no-story` label), assistant attribution
  (`Co-authored-by` naming an assistant, `Generated with …`, `Claude-Session:`), and commits
  authored by a non-chrysa identity.
- Merge settings were confirmed with `scripts/apply-repo-settings.sh --check`, not only read
  from the snapshot.
- Positive control for the attribution check: 51 PRs merged in August–September 2026 were
  sampled; 33 had leaked assistant trailers into `develop`. The detector finds real cases.

## 2. Repository checks

| Check | Before | After remediation | Remaining gap |
|---|---|---|---|
| Default branch is `develop` | 90/95 | 93/95 | `agent-panel` (fork), `homeassistant-config` (diverged, see §3) |
| `main` and `develop` protected | 87/95 | 94/95 | `agent-panel` (fork) |
| Squash title/body = PR title/body, rebase off, branch deleted on merge | 85/95 | 94/95 | `agent-panel` (fork) |
| Registered in `repos.yml` | 87/95 | 95/95 once #642 merges | — |
| `.claude/settings.json` disables attribution | 85/95 | 85/95 | 8 repos without the file; `second-souffle`, `game-solver-platform` lack the block |
| PR template | 69/95 | 69/95 | 19 of the 26 gaps are covered by an open `chore/sync-shared-standards` PR |
| Pre-commit config | 82/95 | 82/95 | same pattern as the PR template |
| `SECURITY.md` | 13/95 | 13/95 | not distributed by the socle (no template) |
| Issue forms | 25/95 | 25/95 | not distributed by the socle |

The eight repositories missing from `repos.yml` had never received a distribution: they explain
most of the template, pre-commit and settings gaps (#642 registers all eight, the last one being
`steamdeck-config`). The 10 entries that match no live repository are not ghosts: they carry
`status: archived` or `status: migrated` (with the new home in a comment), and
`list-dev-repos.sh` already excludes them from distribution.

## 3. Branch-model drift

- `prism-ai-lint`: 13 feature PRs (#94–#106) were merged straight into `main`, and 4 open PRs
  (#107, #109, #110, #111) still target `main`. Back-merge `main` → `develop` is prism-ai-lint#112
  (draft, merge commit required); the four PRs are retargeted to `develop` after it.
- `herdr-cockpit` (#58, #55, #46) and `second-souffle` (#3, #1): PRs opened while `main` was the
  default branch. `develop` was created from `main` by the branch policy, so the retarget is
  conflict-free.
- `homeassistant-config`: `main` and `develop` have diverged (66 and 83 commits). Reconcile by hand.
- `dotfiles`: `main` is 6 commits ahead and 37 behind `develop`; #57 targets `main`. Reconcile by hand.
- 55 open PRs target `main` from a feature branch; 40 of them are the 2026-10-05
  `preservation/` / `wip(...)` drafts.

## 4. Pull-request checks

| Rule | Violations | Note |
|---|---|---|
| Conventional Commit title | 210 | 209 use the `[SKIP CI] [GA] …` prefix of the canonical dependabot template; 1 human title fixed (guideline-checker#487) |
| Shortcut story link | 579 | fan-out families with no story: prism-ai-lint-align 106, sync-shared-standards 78, design-md 57, generate-corpus 51, graphify 15, preservation 95 |
| Assistant attribution in branch commits | 131 PRs | none in PR bodies; leaks on squash regardless of settings (§5) |
| Non-chrysa author identity in branch commits | 7 PRs | fastapi-autoload #151, #136, #147; eka #235, #236; coach #222; dev-kit #21 |

Linking the fan-out PRs to stories means creating one story per family and editing about 360 PR
bodies. Every body edit triggers the `edited` workflows, so the Actions budget comes first.

## 5. Finding: squash-merge re-appends commit co-authors whatever the setting

The assumption going into the audit was that `squash_merge_commit_message: PR_BODY` keeps
branch-commit trailers out of `develop`. It does not.

- **Evidence.** fastapi-autoload#147 was merged on 2026-11-08 with
  `squash_merge_commit_title: PR_TITLE` and `squash_merge_commit_message: PR_BODY`. Its body
  contained no trailer. The squash commit on `develop` ends with a `---------` separator followed
  by `Co-authored-by` lines: one for the non-chrysa commit author, one for the assistant
  co-author trailer carried by a branch commit.
- **Mechanism.** GitHub builds that block from the squashed commits themselves (authors that
  differ from the merger, and their `Co-authored-by` trailers). The squash setting only chooses
  the text above it. `COMMIT_MESSAGES` makes it worse by also copying `Generated with` and
  `Claude-Session:` lines.
- **Consequence.** Every open PR whose branch commits carry an assistant trailer or a foreign
  author leaks it into `develop` on merge, then into `main` on promotion. Canonical merge
  settings are necessary (they stop the `COMMIT_MESSAGES` copy) but not sufficient.
- **Remedy.** Clean the branch before merge (procedure in §7). Removing a leak that already
  reached `develop` means rewriting a protected trunk with a force push: an owner decision, not a
  routine fix. The rule is recorded as `SC-016` in [`SCM.md`](../../standards/annexes/SCM.md).

## 6. Remediation done

| Change | Where | Verification |
|---|---|---|
| Retitled `chore(release): promote develop to main (v1.32.0)` | guideline-checker#487 | title check passes |
| Registered `chrysa-llm`, `pre-commit-hooks-changelog`, `satisfactory-hexa-gfn-assisstant`, `second-souffle` | shared-standards#642 (draft) | `validate-repos-runtime.sh` passes |
| Back-merge `main` → `develop` | prism-ai-lint#112 (merged 2026-11-08) | — |
| Non-regression testing rules TS-012 to TS-016 and the non-regression map | shared-standards#649 (draft) | pre-commit, `gen_agent_views --check`, distribution dry-run |
| Branch policy: `develop` default, `main`/`develop` protected | satisfactory-hexa-gfn-assisstant, herdr-cockpit, second-souffle, arena-techno, chrysa-llm, gource-live, ops-monitoring | re-read through the API: all seven conform |
| Canonical merge settings and labels | chrysa-llm, satisfactory-hexa-gfn-assisstant, second-souffle, herdr-cockpit, ops-monitoring, arena-techno, gource-live, homepage, game-solver-platform | `apply-repo-settings.sh --check`: 9/9 conform |
| Author identity rewritten on branch commits | fastapi-autoload #151, #136; eka #235, #236 | no foreign identity left, trees identical |
| Branch commits cleaned (identity and assistant trailers, procedure of §7) | 122 open-PR branches in 64 repositories; the 22 main-based ones were then rebuilt from their original heads (§7, item 1) | per branch, re-read after the move: no dirty commit left, head tree identical |
| Back-merge `main` → `develop` | herdr-cockpit#62, second-souffle#4 (merged 2026-11-09, merge commits) | `main` 0 commits ahead on both |
| Retarget to `develop` | herdr-cockpit#55, dotfiles#57 | each PR holds only its own commit |
| `chore/sync-shared-standards` PRs merged | 61 of 74; the 13 conflicting ones regenerated by a `distribute-standards.yml` dispatch limited to their repos | 13 now mergeable; red checks classified below (§7, item 4) |
| Local checkouts moved onto the rewritten heads (`git update-ref` with old-value check, no push) | 95 local branches (dirty checkouts with `git reset --keep` after a stash copy); 20 left that need a human choice (local `.claude/` edits that differ from the remote, or local commits) | `status -sb` in sync with `origin`, uncommitted changes intact |

`apply-branch-policy.sh` excluded `agent-panel` (fork, not `status: dev`) and
`homeassistant-config` (diverged branches) on purpose.

## 7. Remaining actions

1. **Done on 2026-11-09: repair the 23 main-based branches, then clean the last three PRs.** The first cleanup
   took a PR's commits as `compare/{base}...{head}`. For a PR that targets `main` from a
   branch cut off `develop`, that list includes every `develop` commit not yet promoted, so
   those were recreated too: 1,789 copies on 23 PRs. Content is unchanged (identical trees),
   but the branches no longer share `develop`'s history, and a retarget to `develop` would
   show hundreds of duplicate commits. The repair rebuilds each branch from its original head
   and recreates only the PR's own commits (procedure below); where every dirty commit was a
   `develop` commit (sport-intelligence-hub #534 to #537, among others) the branch simply
   returns to its original head. The same rule makes chrysa-portfolio-viz#1012 and dev-nexus
   #649 and #650 small enough for the API (66, 5 and 4 own commits). github-actions#337 has
   `main` as its head: out of scope, its trailers sit on the trunk. Two dependabot branches
   were rewritten by mistake (coach#221, gaming-os#367): dependabot no longer rebases an edited
   branch, so ask it to recreate them (`@dependabot recreate`). The tool now refuses trunks,
   `dependabot/` branches and forks.
   Procedure, per PR, through the Git Data API (no clone needed):
   1. Skip the PR if it is not open.
   2. List its own commits: the commits of `GET compare/{trunk}...{head}` for the trunk
      (`develop` or `main`) with the fewest, minus those the other trunk already contains.
      Never use the PR base alone. Abort if `total_commits` exceeds the returned list: the
      endpoint truncates large comparisons.
   3. Walk the commits oldest first. Recreate a commit (`POST git/commits`, same tree, same dates)
      when its author or committer is not a chrysa identity (replaced by the chrysa GitHub
      noreply identity), when its message has an assistant trailer
      (removed; other co-authors such as dependabot are kept), or when one of its parents was
      recreated.
   4. Move the branch to the new head (`PATCH git/refs/heads/{branch}` with `force: true`).
   5. Re-read the comparison: no dirty commit left, and the head tree is identical to the old one.
   The step force-updates each branch: local checkouts and any session working on these branches
   must re-fetch (`git fetch && git branch -f <branch> origin/<branch>`) before working on them again.
2. **Done on 2026-11-09: back-merges and retarget.** herdr-cockpit#62 and second-souffle#4 were
   merged with merge commits, then herdr-cockpit#55 and dotfiles#57 retargeted to `develop`.
   prism-ai-lint needs nothing more: #107, #109, #110 and #111 were merged into `main` on
   2026-11-08 around 12:16Z, and the back-merge #112 (merged 17:20Z) brought them into
   `develop`. herdr-cockpit#58 and second-souffle#1 and #3 were merged into `main` after the
   default-branch switch, and herdr-cockpit#46 was closed.
3. **Decide on the fastapi-autoload#147 leak** already on `develop`: keep it in history, or
   rewrite the protected trunk.
4. **Merge** shared-standards#642, shared-standards#649 (then dispatch `distribute-standards.yml`,
   which only runs on a release or a dispatch), shared-standards#657, github-actions#346, and the
   last 13 `chore/sync-shared-standards` PRs. 61 of the 74 were merged on 2026-11-09; the 13 that
   conflicted were regenerated and are mergeable. Their red checks do not come from their
   content: jobs that never started (item 6), SonarCloud quality gates that already failed, label
   workflows on public repositories, and `shortcut-link`, because sync PRs carry neither a story
   nor the `no-story` label. The one code check that ran and failed, `guideline-check` on
   github-actions#341, flags a docstring that `develop` has already reworded. On private
   repositories, every sync PR merged so far went in without any test having run.
5. **Decide on `homeassistant-config`**: it uses `main` as its trunk (default branch, open PRs to
   `main`; `main` 69 commits ahead and 83 behind `develop` over 93 files). Adopt the develop model
   and reconcile by hand, or exempt it. `dotfiles` needs nothing more: `main` has no commit of
   its own left.
6. **Unblock GitHub Actions billing.** Jobs on private repositories no longer start ("recent
   account payments have failed"), so most PR checks there are red without having run.

## 8. Proposed follow-ups (no story created yet)

1. Link the fan-out PRs to one story per family, then add the reference to about 360 PR bodies;
   budget the Actions minutes of the `edited` workflows first.
2. Switch the dependabot template prefix from `[SKIP CI] [GA]` to `chore(deps):` / `ci(deps):`
   with `[skip ci]` in the body: the prefix breaks the Conventional Commit rule and git-cliff.
3. Distribute `SECURITY.md` and the issue forms from the socle.
4. **Priority.** A PR check that rejects assistant trailers and non-chrysa identities in PR
   commits. §5 shows merge settings cannot do it. Implemented as the `check-commit-hygiene`
   composite action (chrysa/github-actions#346, draft, info-first); the caller template is
   distributed from the socle once it ships in a release tag.
5. Mechanise TS-014 and TS-015 (#649) in `guideline-checker`, at `info` first (GV-020).
6. Have `distribute-standards.yml` label its PRs `no-story` (or link a story): without it the
   blocking `shortcut-link` check fails on every sync PR.

## 9. Notes for the next audit

- Measure against the remote, not local checkouts: local mirrors lag far behind.
- One GraphQL query per repository beats a REST loop; the REST core quota ran out once.
- On private repositories, `gh api` returns intermittent 404s through the local proxy: retry
  GETs, never mutations.
- The assistant's auto-mode classifier refuses repository-setting changes, force ref updates and
  PR base edits. Those steps go into an owner runbook instead of being retried.
- A PR merged between the snapshot and the remediation turns a planned branch fix into a trunk
  leak: re-check PR state immediately before acting.
- A runbook step that rewrites history must fail closed. The cleanup step compared its plan
  flag as an exact string, so a pasted `--plan,` ran the rewrite without a plan. The step now
  plans by default, writes only with `--apply`, and aborts on any extra argument.
- Exclude trunks and bot branches from history rewrites up front. Branch protection rejected the
  one PR whose head was `main`; nothing stopped the two dependabot branches.
- Switching the default branch does not move PRs that already target `main`, and other sessions
  kept merging them. Retarget in the same step as the switch.
- A PR's own commits are the commits on no trunk, not the commits missing from its base. Using
  the base turned 23 main-based PRs into copies of `develop` (1,789 commits) and had to be
  repaired from the original heads.
- The Git Data API (`git/commits/{sha}`) wants full shas; `commits/{sha}` resolves short ones.
  Keep full shas in run logs.
