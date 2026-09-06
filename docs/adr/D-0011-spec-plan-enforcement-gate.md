# D-0011 — Spec→Plan enforcement gate: opt-in, off by default

- **Status:** Accepted
- **Date:** 2026-09-05
- **Series:** D (standards-governance decisions)
- **Owner:** standards maintainers (`chrysa/shared-standards`)
- **Pillars touched:** none (a workflow policy, not a pillar exception)
- **Supersedes:** none
- **Related:** the padam-av extraction (`.claude/_extracted/padam-av/`, staged in #505); the `hunt`/`check` promotions (#519); `git-safety-guard` (#520)

______________________________________________________________________

## Context

The extraction from the padam-av example surfaced a spec→plan→implement workflow with a
**blocking** PreToolUse hook, `enforce-spec-plan`: it denies any source edit
(Write/Edit/MultiEdit) unless the active feature has **both** an approved spec and an
approved plan (`reports/specs/<feature>.md`, `reports/plans/<feature>.md`, each with
`status: approved`). The workflow matches chrysa's governance culture — falsifiable,
gate-first development — and the skills `spec`/`plan`/`implement`/`verification-loop`
are its human-facing half.

But the hook as mined is unfit to ship as-is:

1. **Padam-specific.** Its gated roots are hard-coded `["padam_av/", "docker/",
   "makefiles/"]`, so it would gate nothing on a chrysa repo (no `padam_av/`).
2. **No off switch.** Wired into `settings.json` it blocks source edits **immediately and
   fleet-wide**, for every agent and human-driving-an-agent, on day one.

A blocking gate that changes how *every* repo is edited is exactly the kind of decision
that must be refutable before it is fleet default — not adopted by reflex because the
workflow "feels right".

## Decision

Adopt the spec→plan→implement workflow into the canon, but ship the enforcement gate
**disabled by default and opt-in per repo**. Concretely:

- Promote `spec`/`plan`/`implement`/`verification-loop` as **on-demand skills** and the
  `plan-*` commands — non-activating, exactly like `hunt`/`check`.
- Promote `enforce-spec-plan.cjs`, but generalised: **gated roots are read from
  `.claude/config/hooks-config.json`** (`enforceSpecPlan.gatedRoots`, `sourceExts`), and
  the gate runs **only when `enforceSpecPlan.enabled === true`** in that file — default
  **false**. Absent config, or `enabled: false`, the hook is a no-op (exit 0).
- A repo turns it on deliberately, one repo at a time, starting with a single **pilot**.

## Fatal hypothesis

Gating source edits behind an approved spec + plan, on a real chrysa repo, **reduces
rework/defects without materially slowing the developer loop**. (If the gate mostly adds
ceremony — the same edits happen, just later, with no drop in rework — it is not worth
its friction.)

## Kill-test

On the **pilot repo**, over **4 weeks** from enablement, checked **weekly**:

- **Slowdown:** if the median wall-clock time from "feature branch created" to
  "first source edit allowed" rises **> 2×** versus the 4 weeks before enablement, **or**
- **False blocks:** if **≥ 3 legitimate source edits per week** are wrongly denied (the
  spec/plan existed and were approved, or the path should not have been gated),

then the hypothesis is false → set `enforceSpecPlan.enabled: false` on the pilot, mark
this ADR **Killed**, and keep the skills/commands as non-blocking suggestions.
Mechanised: the hook appends each block decision (feature, path, allowed/denied,
timestamp) to `reports/.spec-plan-gate.log`; a weekly `make spec-plan-gate-report` tallies
false-block count and the time-to-first-edit distribution.

## Validation gate

Before enabling the gate on a **second** repo, both must hold over the pilot's first
**2 weeks**:

- at least **one** recorded instance where the gate caught a missing/again-drafted spec
  or plan that would otherwise have shipped an unplanned change (evidence the gate does
  something), **and**
- the kill-test thresholds are **not** breached.

Written before implementation, on purpose.

## Options considered

| Option | Why not |
| ------ | ------- |
| Enforce hard, fleet-wide, on merge | Blocks every repo's edit loop on day one; the mined hook is padam-specific so it would silently gate nothing on chrysa repos anyway; an un-piloted fleet rollout has no kill-test — unfalsifiable. |
| Do not adopt; drop the bundle | Loses a governance workflow that fits chrysa (spec-first, falsifiable). The skills are cheap to keep as suggestions even if the gate is never turned on. |
| **Opt-in, off by default, pilot-gated** (chosen) | Keeps the workflow available everywhere, makes the *enforcement* a per-repo, measured decision with a kill-test — the only version that can be proven wrong. |

## Consequences

- **Accepted costs:** the gate adds friction on repos that opt in (a spec + a plan before
  code); the `reports/specs|plans/` convention and the config flag must be documented and
  maintained; the hook needs the generalisation work (config-driven roots) before it is
  useful on any chrysa repo.
- **Gains:** a falsifiable, spec-first development loop available fleet-wide, enforced only
  where it has been shown to pay for itself.
- **Debt created:** the padam-specific `GATED_ROOTS`/`SOURCE_EXTS` must move to config
  (paid in the implementing PR); the weekly report tooling must exist for the kill-test to
  fire by itself (paid before the pilot is enabled), else the kill-test is a doc that waits
  to be re-read.
- **Blast radius if Killed:** flip one config flag on the pilot (`enabled: false`); the
  skills, commands and hook file stay in place as inert suggestions — no fleet change, no
  revert of merged code.
