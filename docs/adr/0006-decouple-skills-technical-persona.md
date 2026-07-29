# ADR 0006 — Decouple skills by distribution model: fan-out technical vs load-on-demand persona

- **Status:** Proposed
- **Date:** 2026-07-29
- **Deciders:** chrysa
- **Pillars touched:** none (internal DevEx architecture)
- **Supersedes / Superseded by:** —

## Context

Skills live in two repos with two distribution models that have silently overlapped.

- **`shared-standards/.claude/skills`** — 11 transverse technical DevEx skills
  (`agent-patterns`, `api-design`, `async-patterns`, `clean-architecture`,
  `contract-testing`, `council`, `dockerfile-multistage`, `error-handling`,
  `gitnexus`, `testing-pytest`, `ui-ux`). YAML frontmatter (`name` + `description`).
  Fanned out verbatim into **every** repo by `distribute-standards.sh` (`SKILLS_SRC`).
- **`chrysa-skills`** — a load-on-demand library: 13 technical skills under
  `.claude/skills` (the same 11 **plus** `best-practices-review`, `security-review`),
  plus `identity/` (18 persona), `functional/` (39 domain), `specialty/` (5). Its
  technical skills use a `# Skill: …` + `## When to invoke` prose header — **no
  frontmatter**. Not fanned out.

Two facts force the decision now:

1. **The 11 technical skills are duplicated across both repos.** Inventory
   (2026-07-29): 9 of the common skills have **byte-identical bodies** — the entire
   difference is the header format. `testing-pytest` **did drift** — the `chrysa-skills`
   copy was enriched (status codes, file structure, message-carrying assertions,
   coverage) while the `shared-standards` copy stayed behind — so the predicted
   double-maintenance failure has already happened once. It has since been **resolved by
   back-porting the enrichment into the canon** (`#230`): the two bodies are now
   content-identical (only section order + header differ), and the `chrysa-skills` copy
   is a pure duplicate awaiting removal. This is why validation gate (a) is already
   satisfied at this ADR's opening.
2. **The format split is a latent defect.** The Claude Code / Cowork skill loader
   auto-triggers on YAML frontmatter (`name` + `description`). The `chrysa-skills`
   technical skills, lacking frontmatter, **do not auto-trigger** — only the
   `shared-standards` framed copies do. `chrysa-skills`' own technical skills are
   effectively inert for auto-invocation.

`distribute-standards.sh` (lines 35–39) already documents *"SKILLS_SRC intentionally
NOT chrysa-skills — fanning it out would push identity/persona skills to every repo."*
The instinct is right; the granularity is wrong — it conflates **the repo** with the
**persona subset**. The technical subset can be canonical and fanned out; only the
persona/domain subsets must stay local.

## Decision

Split skills by **distribution model**, one canonical home each.

1. **Transverse technical DevEx skills** → canonical in `shared-standards/.claude/skills`,
   YAML frontmatter, the **sole** set fanned out by `distribute-standards.sh`. This is
   the authoritative copy; no repo hand-vendors it.
2. **Persona (`identity/`) + domain (`functional/`, `specialty/`) skills** → canonical
   in `chrysa-skills`, load-on-demand, **never** fanned out.
3. **`chrysa-skills` stops vendoring** hand-maintained duplicates of the 11 fan-out
   skills. Its `testing-pytest` enrichment was **already back-ported to the
   `shared-standards` canon** (`#230`), so nothing is lost; the duplicates are dropped.
   The references to those skills inside `chrysa-skills` are **documentation only**
   (`README.md` persona table, `CLAUDE.md` skill list + inline mentions) — no persona
   composes a technical skill at runtime — so they are repointed to the fan-out canon in
   the **same change**, leaving no stale reference.
4. The 2 `chrysa-skills`-exclusive technical skills (`best-practices-review`,
   `security-review`) are **both transverse** (generic pre-merge PR / security gates,
   repo-agnostic) → **both move to the `shared-standards` fan-out**, converted to YAML
   frontmatter. Neither lands in `chrysa-skills/functional`.
5. **All skills carry YAML frontmatter** (`name` + `description`). The `# Skill:`
   no-frontmatter format is non-conformant and is fixed.

## Fatal hypothesis

The 11 transverse technical skills are genuinely repo-agnostic — every repo uses them
unchanged, so a single fanned-out canon suffices and **no repo needs a locally-forked
variant** of one.

## Kill-test

Mechanise a fleet drift check. The mechanism **already exists** — `deploy_dir` runs
`distribute-standards.sh --check` and diffs each repo's fanned-out skill file against the
canon (`cmp -s` → `mark_drift`); the remaining work is to **wire it into CI on every
distribute and into the monthly fleet audit**, not to write a differ. **Signal of
falsity:** after one full distribution cycle, ≥1 repo
carries a hand-edited divergent copy of a transverse skill that must **persist** (a real
repo-specific need, not staleness). **Threshold:** >0 persistent forks. **Action on
breach:** replace the flat fan-out with a per-repo override layer (base skill + repo
patch), rather than duplicating whole skills again.

## Validation gate

Written before implementation — the migration is unlocked only when **all** hold:
(a) the `shared-standards` canon carries the enriched `testing-pytest`, no content lost
    — **already met at opening** (`#230`);
(b) `chrysa-skills/.claude/skills` has **0 name-collisions** with the fan-out set;
(c) `best-practices-review` + `security-review` are each reassigned (both → fan-out);
(d) `distribute-standards.sh --check` is green on **all** target repos;
(e) every distributed skill file has valid YAML frontmatter;
(f) no stale reference to a removed technical skill remains in `chrysa-skills` — the
    `README.md` persona table and `CLAUDE.md` skill list are repointed to the fan-out canon.

## Options considered

| Option | Why not |
| ------ | ------- |
| Make `shared-standards` **consume** `chrysa-skills` (the original "point 1") | `chrysa-skills` technical skills lack frontmatter → distributing them ships non-auto-triggering skills to every repo, and fans out persona skills unless filtered. It inverts the canon toward the malformed copy and still requires fixing the format first. |
| Keep both copies, add a `chrysa-skills → shared-standards` sync script | Two physical copies remain → the drift surface persists; a sync script is machinery built to maintain a duplication that should not exist. |
| Status quo (the documented "don't consume chrysa-skills") | Leaves the 11-skill duplication, the format split, and the already-observed `testing-pytest` drift unaddressed. |

## Consequences

- One source of truth per skill class; the `testing-pytest` drift is resolved at the root.
- `chrysa-skills` shrinks to its real mission — a persona + domain load-on-demand library;
  its README is reframed accordingly.
- **Accepted cost:** a one-time migration touching the ~26 skill references, removal of the
  duplicated directories from `chrysa-skills`, and repointing the `README.md` / `CLAUDE.md`
  doc references to the fan-out canon. The `testing-pytest` back-port is **already done**
  (`#230`), not a pending cost.
- **Debt created:** the fan-out model has no per-repo override yet. If the kill-test fires,
  that layer must be built — paid then, not now.
- **Blast radius if Killed:** revert to per-repo skill copies behind an override layer;
  `distribute-standards.sh` `SKILLS_SRC` logic changes.
