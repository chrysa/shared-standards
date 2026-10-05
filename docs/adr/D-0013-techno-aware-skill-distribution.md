# D-0013: Scope the skill fan-out to each repo's profiles

- **Status:** Proposed
- **Date:** 2026-09-18
- **Deciders:** chrysa
- **Pillars touched:** none (internal DevEx architecture)
- **Supersedes / Superseded by:** refines [0006](0006-decouple-skills-technical-persona.md) (single fan-out canon kept; flat → profile-scoped)

## Context

ADR 0006 established one canonical home for the transverse technical skills
(`shared-standards/.claude/skills`) and made it the sole set `distribute-standards.sh`
fans out. It fans out **flat**: every repo receives **all** 19 skills, whatever its
stack. Its fatal hypothesis is that the skills are "genuinely repo-agnostic — every
repo uses them unchanged".

The 2026-09-18 fleet audit shows that hypothesis holds for *content* but not for
*relevance*: a backend-only repo (e.g. `discord-bot-back`) receives `ui-ux` and
`accessibility`; a pure frontend repo (`chrysa-portfolio-viz`) receives
`api-design`, `async-patterns`, `testing-pytest`, `dockerfile-multistage`. The
extra skills are inert (they never auto-trigger on an irrelevant surface) but they
are noise: they enlarge each repo's `.claude/skills`, blur "which skills does this
repo actually use", and make the skill index a poorer signal for humans and agents.

`repos.yml` already classifies every repo into profiles (`ai`, `back`, `front`,
`infra`, `lib`, `config`) — a repo can hold several. That taxonomy already exists
and is maintained; nothing new to invent.

This is orthogonal to 0006's kill-test. 0006 guards against a repo needing a
**forked** copy of a skill and answers it with a per-repo override layer. This ADR
does **not** fork any skill: the canon stays single and byte-identical everywhere it
lands. It only chooses **which** canonical skills a repo receives, by profile
intersection. No duplication is introduced, so 0006's "don't duplicate whole skills
again" constraint is respected.

## Decision

Fan out a skill to a repo iff the skill targets `all`, or its declared profiles
intersect the repo's profiles (`repos.yml`).

- Skills declare their target profiles in `shared-standards/.claude/skills/skills-profiles.yml`
  (one map, not per-file frontmatter — the map is reviewable in one place and never
  travels into target repos).
- The workflow core (`plan`, `spec`, `implement`, `check`, `hunt`,
  `verification-loop`, `council`, `gitnexus`, `standards-authoring`) is `all`.
- Stack skills are scoped: backend/API (`back`), frontend surfaces (`front`),
  containers (`back`+`infra`), library contracts (`back`+`lib`), agents (`ai`+`back`).
- A skill **absent from the map defaults to `all`** (fail-open): a newly added skill
  reaches every repo until it is classified, so the mechanism never silently
  withholds a skill by omission.

## Fatal hypothesis

Profile membership in `repos.yml` is an accurate predictor of skill relevance: a
skill scoped away from a repo would never have usefully auto-triggered there.

## Kill-test

**Signal of falsity:** within one distribution cycle after adoption, a maintainer
wants a scoped-out skill in a repo (e.g. asks why `ui-ux` is missing from a repo that
turns out to have a human-facing surface). **Threshold:** >0 such requests that are
legitimate (the repo genuinely needed the skill, i.e. its profile set was wrong or
too coarse). **When checked:** at each fleet standards audit. **Action on breach:**
if the miss is a mis-tagged repo → fix `repos.yml`; if profiles are structurally too
coarse to express relevance → revert to flat fan-out (one-line change: call
`deploy_dir` instead of `deploy_skills`) and record that profiles are the wrong axis.

## Validation gate

Written before implementation — adoption is unlocked only when **all** hold:
(a) the selector yields, for a `back`-only repo, the universal core + backend skills
    and **excludes** `ui-ux`/`accessibility`; for a `front`-only repo, the core +
    `ui-ux`/`accessibility` and **excludes** the backend skills — verified on
    `discord-bot-back`, `chrysa-portfolio-viz`, `django-app-forge`, `agent-config`;
(b) a repo in **no** profile still receives the 9 universal skills (never zero);
(c) `pyyaml` absent → the selector falls back to the previous flat fan-out (no repo
    is left skill-less by a missing dependency);
(d) `distribute-standards.sh --dry-run` and `--check` still run clean end-to-end.

## Options considered

| Option | Why not |
| ------ | ------- |
| Keep flat fan-out (0006 status quo) | Ships irrelevant skills to every repo; the `.claude/skills` index stops signalling what a repo actually uses. |
| Per-file `profiles:` frontmatter on each SKILL.md | Adds a field the Claude skill loader may surface in target repos; 19 files to touch vs one map; harder to review the whole policy at a glance. |
| Per-repo skill override layer (0006's kill-test remedy) | Solves a different problem (forked *content*). Heavier: base+patch machinery for a need not yet observed. Profiles solve *selection* without any fork. |

## Consequences

- Each repo's `.claude/skills` carries only skills relevant to its stack; the index
  becomes an honest signal.
- **Accepted cost:** `repos.yml` profile accuracy now matters for skills too — a
  mis-tagged repo gets the wrong skill set (mitigated: universal core always lands;
  kill-test catches misses).
- **Debt created:** `skills-profiles.yml` must be updated when a new skill is added
  (mitigated by fail-open default `all`).
- **Blast radius if Killed:** one-line revert (`deploy_skills` → `deploy_dir`) plus
  deleting `skills-profiles.yml`; no repo data lost, canon unchanged.
