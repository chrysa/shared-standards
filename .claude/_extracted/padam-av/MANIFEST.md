# Extracted from padam-av — staging area (INERT, not wired)

**Status:** staged for triage. Nothing here is wired into `.claude/settings.json`,
the shared-skills list, or the distribution — copying these files changed **no**
runtime behaviour. This is a holding pen; the decision of *what to promote into the
canon / send to claude-graft* is made later, per artifact.

**Origin:** `/home/anthony/Documents/padam/padam-av/.claude/` (an example repo — not
authoritative). Files copied **verbatim**; they still contain padam/Django-specific
wording that must be stripped before any real promotion.

______________________________________________________________________

## What is here (net-new, generic — cited in the extraction analysis)

| Path | Kind | Promote to (later) | Note |
| ---- | ---- | ------------------ | ---- |
| `skills/spec/`            | skill | `.claude/skills/spec/` | Gate 1 of the spec→plan→implement→verify workflow |
| `skills/plan/`            | skill | `.claude/skills/plan/` | Gate 2 |
| `skills/implement/`       | skill | `.claude/skills/implement/` | Gate 3 |
| `skills/verification-loop/` | skill | `.claude/skills/verification-loop/` | Pass/fail loop; usable standalone |
| `skills/hunt/`            | skill | `.claude/skills/hunt/` | Root-cause-before-fix debugging |
| `skills/check/`           | skill | `.claude/skills/check/` | Post-impl diff review + safe auto-fix + reviewer dispatch |
| `hooks/enforce-spec-plan.cjs` | hook | `.claude/hooks/` | **Enforcing** — blocks Write/Edit without an approved spec+plan. Gives the workflow teeth. |
| `hooks/git-safety-guard.cjs`  | hook | `.claude/hooks/` | Blocks force-push / hard-reset / `branch -D`. Pure git, safe, high value. |
| `hooks/lib/circuit-breaker.cjs` | lib | — | Dependency captured for reference (padam's re-architected circuit-breaker lib — a back-port candidate, not a promotion). |
| `commands/plan-start.md`  | command | `.claude/commands/` | Command face of the spec→plan bundle |
| `commands/plan-validate.md` | command | `.claude/commands/` | Adversarial validation gate |
| `commands/plan-execute.md`  | command | `.claude/commands/` | Gated execution |
| `ape/`                    | system | see governance flag | Automatic Prompt Engineering (hook + transform doc + README) |

______________________________________________________________________

## Governance flags — resolve BEFORE promoting

- **`ape/`** rewrites the user's prompt before execution. chrysa already runs an APE
  across the fleet (source ≈ `claude-config/.claude/ape`; this session's is
  `~/.claude-perso/ape-transform.md`). padam's `ape-transform-v2.md` ≈ the chrysa doc
  (formatting only); `ape_hook.py` **differs**. So this is a **reconcile/back-port**
  against the existing chrysa APE, not a fresh extraction. Ship **disabled-by-default**
  and behind an **ADR** if ever wired into the base template — transparency/consent
  concern on a 51-repo fanout.
- **`enforce-spec-plan.cjs`** is a blocking PreToolUse hook. Promoting it activates a
  gated build workflow fleet-wide — a deliberate policy choice, not a silent add. Extract
  the whole spec→plan→implement→verify **set or none** (skills without the hook are just
  suggestions).

## Not extracted (belongs elsewhere)
- Django/DRF/Postgres/provider/recette skills, agents, and commands → a **Django stack
  annex**, not the transverse canon.
- Existing shared-standards hooks that padam has since evolved (`secret-scanner`,
  `memory-consolidate`, `model-debt-scan`, `frustration-detection`, `circuit-breaker`,
  `verifiable-thresholds`, `council`) → **back-port by real diff**, not re-extraction.

## Promoted (out of the pen)
- `skills/hunt/` → promoted to `.claude/skills/hunt/` (cleaned: English-only `when_to_use`, padam gimmick removed).
- `skills/check/` → promoted to `.claude/skills/check/` (renamed `agents/`→`reviewers/` so the persona files are skill-internal, not flagged as unregistered subagents; persona-catalog refs updated).
