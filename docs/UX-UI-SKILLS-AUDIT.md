# UX/UI Skills — Adoption Audit & Wiring Plan

> Date: 2026-05-31. Scope: front-end projects under `projects/chrysa/`.
> Goal: verify the UX/UI guidelines and design skills are actually wired into projects.

## Verdict

**Gap is total.** Across 19 front-end-bearing projects, **none** reference a UX/UI or
accessibility skill in their `CLAUDE.md`, **none** has a `## Skills` entry pointing at UX, and
there was **no `ui-ux` skill module** in `shared-standards/.claude/skills/` before this work.
Only 3 projects even mention `shadcn`/`tailwind` in their `CLAUDE.md`.

This means the V1 non-negotiables (WCAG 2.1 AA, dark mode, FR+EN i18n) are not enforced at the
agent-context level for any UI project — they rely entirely on memory.

## What was created

| Artifact | Location | Status |
|----------|----------|--------|
| Full guideline | `shared-standards/docs/UX-UI-GUIDELINES.md` | ✅ written |
| Skill module | `ui-ux.SKILL.md` (outputs) → copy to `shared-standards/.claude/skills/ui-ux/SKILL.md` | ⚠️ `.claude/` protected — manual copy needed |
| This audit | `shared-standards/docs/UX-UI-SKILLS-AUDIT.md` | ✅ written |

## Per-project adoption

Legend: `Skills§` = has a `## Skills` section · `UX ref` = references UX/a11y skill · `shadcn` = mentions shadcn/Tailwind.

| Project                       | CLAUDE.md | Skills§ | UX ref | shadcn | Action |
|-------------------------------|:---------:|:-------:|:------:|:------:|--------|
| cdn-explorer                  | ✅ | – | – | – | add `ui-ux` ref |
| chrysa-portfolio-viz          | ✅ | – | – | – | add `ui-ux` ref |
| container-webview             | ✅ | – | – | – | add `ui-ux` ref |
| D-D                           | ✅ | – | – | – | add `ui-ux` ref |
| dev-nexus  (Actif)            | ✅ | – | – | – | **priority** — add `ui-ux` ref |
| devtool                       | ✅ | – | – | – | add `ui-ux` ref |
| discordium (V3)               | ✅ | – | – | – | add `ui-ux` ref |
| doc-gen   (Actif, PR#1)       | ✅ | – | – | – | **priority** — add `ui-ux` ref |
| floating-agent                | ✅ | – | – | – | add `ui-ux` ref |
| gaming-os                     | ✅ | – | – | ✅ | add `ui-ux` ref |
| linkendin-resume              | ✅ | – | – | – | add `ui-ux` ref |
| link-reader-bot               | ✅ | – | – | – | add `ui-ux` ref |
| mirrador                      | ✅ | – | – | – | add `ui-ux` ref |
| my-resume                     | ✅ | – | – | – | add `ui-ux` ref |
| PO-GO-DEX                     | ✅ | – | – | – | add `ui-ux` ref |
| satisfactory-factory-manager  | ✅ | – | – | ✅ | add `ui-ux` ref |
| sport-intelligence-hub        | ✅ | – | – | – | add `ui-ux` ref |
| studioverse                   | ✅ | – | – | ✅ | add `ui-ux` ref |
| chrysa-lib (Socle)            | ✅ | – | – | – | add if it ships UI components |

## Recommendations (priority order)

1. **Land the skill module.** Copy `ui-ux.SKILL.md` into `shared-standards/.claude/skills/ui-ux/SKILL.md`.
   (Blocked here because `.claude/` is write-protected in this session.)

2. **Update the bootstrap template** so every *new* project ships the reference. In
   `shared-standards/templates/CLAUDE.md`, under `## Skills`, add:
   ```
   - `ui-ux/SKILL.md` — UX/UI/ergonomics + WCAG 2.1 AA + dark mode + i18n (load when building UI)
   ```

3. **Back-fill existing front projects.** Add a `## Skills` block (or extend it) to each project in
   the table with the snippet below. Start with the **Actifs** (`dev-nexus`, `doc-gen`) then the
   shadcn projects (`gaming-os`, `studioverse`, `satisfactory-factory-manager`).

   Snippet to paste into each project `CLAUDE.md`:
   ```markdown
   ## Skills

   Shared skills from `shared-standards/.claude/skills/`:
   - `ui-ux/SKILL.md` — UX/UI/ergonomics, WCAG 2.1 AA, dark mode, i18n FR+EN (load when building UI)
   ```

4. **Map to Cowork design skills.** For deeper work the `ui-ux` module defers to the built-in
   Cowork skills: `design:design-system`, `design:accessibility-review`, `design:ux-copy`,
   `design:design-critique`, `design:design-handoff`. No wiring needed — they auto-trigger by topic.

5. **Enforce in CI (optional, follow-up).** Extend `guideline-checker` to fail when a project with a
   `package.json` containing `react` lacks the `ui-ux` skill reference, mirroring the existing
   skill-reference checks.

## Note on scope

Per your instruction this audit produces **recommendations only** — no existing project `CLAUDE.md`
files were modified. The snippet in §3 and the template edit in §2 are ready to apply on request.
