# Brand-Themes Design System Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the 4-persona design system with a per-app **brand-themes** model over a shared behavioral contract, then prove it on the `linkendin-resume` pilot.

**Architecture:** A frozen *contract* (WCAG AA + i18n floor, `@chrysa/ui` class-name/behavior API, the *names* of semantic tokens) is shared by every app. Each app owns the *values* (color/type/shape/motion), a signature element, and an IA designed for its job. Identity is derived per-app via a repeatable **brand-brief** method, not assigned by genre.

**Tech Stack:** Markdown docs + ADR, plain CSS custom properties, Bash (audit script), React 19 + Vite 7 + plain CSS (pilot), Docker/`node:22` container for frontend verification.

**Source spec:** `~/.claude/plans/je-veux-qu-on-revois-shimmying-hellman.md` (approved 2026-06-22).

---

## Governance & sequencing (read first)

- **Rule 1+2** (max 1 Socle + 2 Actifs in flight). This plan spans 3 repos:
  - `shared-standards` (Socle) — Phase A foundation.
  - `chrysa-lib` (lib) — Task A5 only (`@chrysa/ui` contract). **Do A5 in its own session/PR** to avoid holding two Socle-class repos at once.
  - `linkendin-resume` (Actif) — Phase B pilot.
- **Branches:** `shared-standards` is currently on `chore/container-runtime-policy`. **Branch new work off `origin/main`**, not the current HEAD. Suggested branches: `feat/brand-themes-foundation` (A), `docs/chrysa-ui-contract` (A5), `feat/brand-theme-pilot` (B).
- All committed files in **English**. All changes land via **PR**. Frontend verification runs in a `node:22` container (never on host).
- Each Phase produces independently reviewable, working output. Phase B depends on Phase A being merged (it imports `contract.css` and is checked by the audit).

---

## File structure

**Phase A — `shared-standards`:**
- `docs/adr/0003-brand-themes.md` (new) — decision record, supersedes `0002-design-personas.md`.
- `templates/contract.css` (new) — token *name* registry + neutral fallbacks + a11y/reduced-motion. Imported unchanged by every app.
- `templates/theme.template.css` (new) — same names, values to fill (per-app starter, copy-and-diverge).
- `templates/brand-brief.template.md` (new) — the 6-prompt discovery method.
- `templates/DESIGN.template.md` (new) — per-repo brand-theme doc skeleton.
- `templates/design-tokens.css` (delete) — replaced by the two split files above.
- `docs/DESIGN-SYSTEM.md` (rewrite) — brand-themes model.
- `scripts/audit-design-conformance.sh` (new) — verifiable conformance check.
- `docs/INTERFACE-REVIEW-LEDGER.md` (modify) — retarget tracking columns to brand-brief + signature.

**Task A5 — `chrysa-lib`:**
- `packages/typescript/ui/CONTRACT.md` (new) — the guaranteed classes / states / props.
- `packages/typescript/ui/src/contract.css` (new, optional) — unstyled structural + focus a11y only.

**Phase B — `linkendin-resume`:**
- `app/BRAND-BRIEF.md` (new) — filled brand brief.
- `app/src/styles/tokens.css` (rewrite values, keep names; import `contract.css`).
- `app/src/styles/animations.css` + the relevant component CSS (signature element).
- `app/src/components/ui/DemoBanner.tsx`, `app/src/components/ui/TerminalEasterEgg.tsx` (fix hard-coded hex if they clash).
- `app/index.html` (remove `data-persona="editorial"`).
- `app/DESIGN.md` (rewrite to brand-theme format).

---

# Phase A — Foundation (`shared-standards`, branch `feat/brand-themes-foundation` off `origin/main`)

### Task A0: Branch setup

- [ ] **Step 1: Create the branch off origin/main**

```bash
cd /home/anthony/Documents/perso/projects/chrysa/shared-standards
git fetch origin
git switch -c feat/brand-themes-foundation origin/main
```

Expected: new branch tracking origin/main, clean tree.

---

### Task A1: ADR 0003 — brand-themes decision

**Files:**
- Create: `docs/adr/0003-brand-themes.md`

- [ ] **Step 1: Write the ADR**

Mirror the structure of `docs/adr/0002-design-personas.md` (Status / Context / Decision / Consequences). Content must state:
- **Status:** Accepted 2026-06-22. **Supersedes** ADR 0002 (design-personas).
- **Context:** the persona model allocates identity at genre + single accent; 11/16 apps are Console → near-identical, the same trap the 2026-06 audit claimed to fix. Doctrine-heavy, little shipped. `@chrysa/ui` is class-name-only (no token-reading primitives as DESIGN-SYSTEM.md claimed). IA rule had no enforcing mechanism.
- **Decision:** per-app brand themes over a shared behavioral contract. Shared = WCAG AA + i18n floor, `@chrysa/ui` class/behavior API, semantic token *names*. Per-app = all token *values*, fonts, shape, motion, a signature element, IA. Identity derived via the brand-brief method.
- **Consequences:** stronger per-app identity; more per-app design effort; existing persona-migrated apps (gaming-os, studioverse, ai-aggregator) fold in retroactively during rollout; DESIGN-SYSTEM.md rewritten; conformance becomes a verifiable audit.

- [ ] **Step 2: Mark ADR 0002 superseded**

Edit `docs/adr/0002-design-personas.md` — change its Status line to `Superseded by ADR 0003 (2026-06-22)`. Do not delete it (history).

- [ ] **Step 3: Commit**

```bash
git add docs/adr/0003-brand-themes.md docs/adr/0002-design-personas.md
git commit -m "docs(adr): add ADR 0003 brand-themes, supersede 0002 personas"
```

---

### Task A2: Split token CSS into contract + theme template

**Files:**
- Create: `templates/contract.css`
- Create: `templates/theme.template.css`
- Delete: `templates/design-tokens.css`

- [ ] **Step 1: Write `templates/contract.css`** (shared, imported unchanged)

```css
/*
 * chrysa Design System — CONTRACT (shared by every app, do not edit per-app).
 * Spec: docs/DESIGN-SYSTEM.md
 *
 * Declares the semantic token NAMES (the registry) with neutral fallback values,
 * plus the a11y floor. Each app imports this, then overrides the VALUES in its own
 * theme.css (see theme.template.css). Names are fixed; values are free.
 */

:root {
  /* color roles — neutral fallbacks; apps override every one in theme.css */
  --bg: #0e0e10;
  --surface: #18181b;
  --surface-2: #242428;   /* must differ >=4% L from --surface */
  --fg: #fafafa;          /* >=4.5:1 on --bg */
  --muted: #a1a1aa;       /* >=4.5:1 on --bg */
  --border: #2e2e33;
  --accent: #c8ff00;
  --accent-ink: #0e0e10;  /* text/icon ON an --accent fill */
  --signal: #22c55e;
  --warning: #fbbf24;
  --danger: #ff4d4d;
  --ring: var(--accent);

  /* shape / depth / type / density / motion roles — apps set these freely */
  --radius: 6px;
  --border-weight: 1px;
  --shadow: 0 1px 3px rgb(0 0 0 / 0.24);
  --font-display: system-ui, sans-serif;
  --font-body: system-ui, -apple-system, sans-serif;
  --font-mono: ui-monospace, monospace;
  --density: 2.5rem;      /* control height */
  --motion: 160ms;
}

:root.light {
  --bg: #fafafa;
  --surface: #ffffff;
  --surface-2: #f0f0f0;
  --fg: #0e0e10;
  --muted: #52525b;
  --border: #d4d4d8;
  --accent: #a3e000;
  --accent-ink: #0e0e10;
  --signal: #15803d;
  --warning: #b45309;
  --danger: #dc2626;
}

/* a11y floor — applies to every brand, do not remove */
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.001ms !important;
    transition-duration: 0.001ms !important;
  }
}
```

- [ ] **Step 2: Write `templates/theme.template.css`** (per-app starter to copy + diverge)

```css
/*
 * <APP_NAME> brand theme — VALUES only. Copy into the app, fill every value.
 * Keep the token NAMES exactly as declared in contract.css. Import order:
 *   @import "contract.css";   (or the app's vendored copy)
 *   then this file.
 * Every text/bg pair below MUST be WCAG AA verified in both themes.
 */

:root {
  /* --- color: replace ALL of these with the brand palette --- */
  --bg: /* TODO brand dark bg */;
  --surface: /* TODO */;
  --surface-2: /* TODO; >=4% L from --surface */;
  --fg: /* TODO; >=4.5:1 on --bg */;
  --muted: /* TODO; >=4.5:1 on --bg */;
  --border: /* TODO */;
  --accent: /* TODO brand accent */;
  --accent-ink: /* TODO; >=4.5:1 on --accent fill */;

  /* --- shape / depth --- */
  --radius: /* TODO */;
  --border-weight: /* TODO */;
  --shadow: /* TODO brand shadow language */;

  /* --- type: display must be a non-reflex face (not Inter/DM Sans as brand) --- */
  --font-display: /* TODO */;
  --font-body: /* TODO (Inter allowed here) */;
  --font-mono: /* TODO */;

  /* --- density / motion personality --- */
  --density: /* TODO */;
  --motion: /* TODO */;
}

:root.light {
  --bg: /* TODO */;
  --surface: /* TODO */;
  --surface-2: /* TODO */;
  --fg: /* TODO */;
  --muted: /* TODO */;
  --border: /* TODO */;
  --accent: /* TODO light-mode accent (often darker for fill contrast) */;
  --accent-ink: /* TODO */;
}
```

- [ ] **Step 3: Remove the old combined file**

```bash
git rm templates/design-tokens.css
```

- [ ] **Step 4: Commit**

```bash
git add templates/contract.css templates/theme.template.css
git commit -m "feat(design): split tokens into shared contract.css + per-app theme template"
```

---

### Task A3: Brand-brief + DESIGN doc templates

**Files:**
- Create: `templates/brand-brief.template.md`
- Create: `templates/DESIGN.template.md`

- [ ] **Step 1: Write `templates/brand-brief.template.md`** (the identity mechanism)

```markdown
# <APP_NAME> — Brand Brief

> The repeatable discovery that derives this app's identity from its job, not a genre.
> Fill all 6 prompts, then translate the answers into the design decisions at the bottom.

## 1. Job-to-be-done
<What does a user come here to accomplish, in one sentence?>

## 2. Audience
<Who are they? Expertise, context of use, device.>

## 3. Three mood words
<e.g. precise / quiet / industrial — pick 3, no more.>

## 4. Metaphor
<One concrete metaphor for the product: "a control room", "a field notebook", "a scoreboard".>

## 5. References (2-3)
<Products/objects whose feel is close. Name them + what specifically to borrow.>

## 6. Remembered for
<If a user remembers one visual thing after closing the app, what is it? This becomes the signature element.>

---

## Derived decisions
- **Type:** display = <font + why>; body = <font>; data = <font>.
- **Color:** accent = <hue + why it fits the mood>; surface mood = <warm/cool/neutral>.
- **Shape & depth:** radius = <>, border = <>, shadow = <>.
- **Motion personality:** <calm/snappy/expressive>; signature transition = <>.
- **Signature element:** <the one memorable device from prompt 6>.
- **IA:** primary view = <>; central object = <>; primary action = <>; density = <>.
```

- [ ] **Step 2: Write `templates/DESIGN.template.md`** (per-repo design doc)

```markdown
# <APP_NAME> — Design (Brand Theme)

> Conforms to the chrysa Brand-Themes Design System
> (`shared-standards/docs/DESIGN-SYSTEM.md`). No persona — this app is its own brand.

## Brand brief
See `BRAND-BRIEF.md`. Summary: <2-3 lines>.

## Contract conformance
- Imports `contract.css` (semantic token names + a11y floor): yes/no + path.
- `@chrysa/ui` class/behavior contract honored (if used): yes/no.
- WCAG AA verified both themes: yes/no + how (axe/manual ratios).

## Theme tokens
<Link to the app's theme css. State the brand palette + the AA ratios for fg/muted/accent-fill in both themes.>

## Signature element
<Describe and locate the one memorable device.>

## Information architecture
- Primary view: <>
- Central object: <>
- Primary action: <>
- Density: <>
- Why this serves the job (not a generic stat-cards + table shell): <>
```

- [ ] **Step 3: Commit**

```bash
git add templates/brand-brief.template.md templates/DESIGN.template.md
git commit -m "feat(design): add brand-brief + DESIGN brand-theme templates"
```

---

### Task A4: Rewrite `DESIGN-SYSTEM.md`

**Files:**
- Modify (rewrite): `docs/DESIGN-SYSTEM.md`

- [ ] **Step 1: Replace the document body**

Keep the doc's role as the visual-layer source of truth, but rewrite to the brand-themes model. The new structure:

1. **Why brand themes (not personas)** — the genre+accent uniformity trap; doctrine↔code gap; identity now per-app. Reference ADR 0003.
2. **The contract (shared, immutable)** — three parts verbatim from the spec: (a) a11y/i18n floor → defers to `UX-UI-GUIDELINES.md` §6; (b) `@chrysa/ui` class-name + behavior + prop API (links `chrysa-lib/.../ui/CONTRACT.md`); (c) the semantic token NAME registry (list every name from `contract.css`). State: names fixed, values free.
3. **The brand theme (per app)** — the 7 elements: brand brief, theme tokens, type system, shape & depth, motion personality, signature element, IA brief. Point to `templates/brand-brief.template.md`, `templates/theme.template.css`, `templates/DESIGN.template.md`.
4. **Brand-brief method** — summarize the 6 prompts; this is how identity is derived (replaces the persona table).
5. **Adoption checklist (per repo)** — import `contract.css`; define every token name in the app theme (light+dark); display font non-reflex; AA verified both themes with stated ratios; `@chrysa/ui` contract honored if used; brand brief present; signature element named; IA brief present; `DESIGN.md` from template; **no `data-persona`**.
6. **Accessibility** — keep §6 rules from the old doc (accent-as-fill, body font normal-case, adjacent-surface step, focus ring, reduced-motion).

**Remove:** the four persona blocks (§1 table), the persona CSS blocks (§3 persona variants), and the App→persona map (§2). The Tailwind `@theme` mapping stays as an *optional* note for Tailwind repos, but reword it so it maps the token NAMES (not personas).

- [ ] **Step 2: Verify no dangling persona references**

Run: `grep -rni "persona" docs/DESIGN-SYSTEM.md`
Expected: only historical mentions in the "Why brand themes (not personas)" section + the "no `data-persona`" checklist item. No live persona spec.

- [ ] **Step 3: Commit**

```bash
git add docs/DESIGN-SYSTEM.md
git commit -m "docs(design): rewrite DESIGN-SYSTEM to brand-themes model"
```

---

### Task A6: Conformance audit script (TDD)

**Files:**
- Create: `scripts/audit-design-conformance.sh`
- Test: inline fixture-based self-check (bash), described below.

> Note: no design audit exists yet (only makefile/quality-gate/repo-standard). This is a NEW script, modeled on `scripts/audit-repo-standard.sh` for style/exit-code conventions.

- [ ] **Step 1: Write a failing smoke test**

Create a throwaway fixture and assert the not-yet-written script fails on a non-conformant app and passes on a conformant one.

```bash
mkdir -p /tmp/da-bad /tmp/da-good
# bad: sets data-persona, no contract import, no DESIGN.md
printf '<html data-persona="console">\n' > /tmp/da-bad/index.html
# good: imports contract, no persona, has the required docs + token names
printf '<html>\n' > /tmp/da-good/index.html
printf '@import "contract.css";\n:root{--bg:#111;--surface:#222;--surface-2:#333;--fg:#fff;--muted:#aaa;--border:#444;--accent:#0f0;--accent-ink:#000;--signal:#0a0;--warning:#fa0;--danger:#f00;--ring:var(--accent);--radius:6px;--border-weight:1px;--shadow:none;--font-display:serif;--font-body:sans-serif;--font-mono:monospace;--density:2.5rem;--motion:160ms;}\n' > /tmp/da-good/theme.css
printf '# x\n' > /tmp/da-good/DESIGN.md
printf '# x\n' > /tmp/da-good/BRAND-BRIEF.md

bash scripts/audit-design-conformance.sh /tmp/da-bad   # expect EXIT 1
bash scripts/audit-design-conformance.sh /tmp/da-good  # expect EXIT 0
```

Run now (before writing the script).
Expected: FAIL — `audit-design-conformance.sh: No such file`.

- [ ] **Step 2: Write `scripts/audit-design-conformance.sh`**

```bash
#!/usr/bin/env bash
# Audit one app directory for Brand-Themes Design System conformance.
# Usage: audit-design-conformance.sh <app-dir>
# Exit 0 = conformant, 1 = violations found, 2 = usage error.
set -euo pipefail

APP_DIR="${1:-}"
[ -n "$APP_DIR" ] && [ -d "$APP_DIR" ] || { echo "usage: $0 <app-dir>" >&2; exit 2; }

REQUIRED_TOKENS=(--bg --surface --surface-2 --fg --muted --border --accent \
  --accent-ink --signal --warning --danger --ring --radius --border-weight \
  --shadow --font-display --font-body --font-mono --density --motion)

fail=0
note() { echo "FAIL: $1"; fail=1; }

# 1. no data-persona anywhere
if grep -rqs 'data-persona' "$APP_DIR"; then
  note "data-persona present (brand themes have no persona)"
fi

# 2. contract.css imported somewhere
if ! grep -rqs 'contract.css' "$APP_DIR"; then
  note "contract.css not imported"
fi

# 3. every semantic token name defined somewhere in the app's CSS
css_blob="$(grep -rhs -- '--' "$APP_DIR" --include='*.css' 2>/dev/null || true)"
for tok in "${REQUIRED_TOKENS[@]}"; do
  printf '%s\n' "$css_blob" | grep -qs -- "${tok}:" || note "token ${tok} not defined"
done

# 4. required design docs
[ -f "$APP_DIR/DESIGN.md" ]      || note "DESIGN.md missing"
[ -f "$APP_DIR/BRAND-BRIEF.md" ] || note "BRAND-BRIEF.md missing"

if [ "$fail" -eq 0 ]; then echo "conformant: $APP_DIR"; fi
exit "$fail"
```

- [ ] **Step 3: Make executable + re-run the smoke test**

```bash
chmod +x scripts/audit-design-conformance.sh
bash scripts/audit-design-conformance.sh /tmp/da-bad;  echo "bad exit=$?"
bash scripts/audit-design-conformance.sh /tmp/da-good; echo "good exit=$?"
```

Expected: bad → prints FAILs, `exit=1`; good → `conformant: …`, `exit=0`.

- [ ] **Step 4: shellcheck the script** (matches repo "No nested named functions > 5 lines" + bash hygiene)

```bash
docker run --rm -v "$PWD:/work" -w /work koalaman/shellcheck:stable scripts/audit-design-conformance.sh
```

Expected: no errors (warnings acceptable; fix SC2317 / 5+ line nested helpers per CLAUDE.md if any).

- [ ] **Step 5: Commit**

```bash
git add scripts/audit-design-conformance.sh
git commit -m "feat(design): add brand-theme conformance audit script"
```

---

### Task A7: Retarget the interface ledger

**Files:**
- Modify: `docs/INTERFACE-REVIEW-LEDGER.md`

- [ ] **Step 1: Update the tracking table**

Replace the per-app `Persona` column with `Brand brief` (link/✓) and `Signature` (one-word device + ✓), and add a `Contract` column (imports contract.css + audit pass ✓). Add a short header note: tracking switched from persona to brand-theme per ADR 0003; rollout is one repo per session (rule 1+2): brand-brief → theme tokens → signature → IA → a11y → PR. Mark the 3 already-migrated apps (gaming-os, studioverse, ai-aggregator) as "persona-migrated, brand-brief pending".

- [ ] **Step 2: Commit + open the foundation PR**

```bash
git add docs/INTERFACE-REVIEW-LEDGER.md
git commit -m "docs(design): retarget interface ledger to brand-theme tracking"
gh auth switch -u chrysa
git push -u origin feat/brand-themes-foundation
gh pr create --fill --base main --title "feat(design): brand-themes design system foundation"
```

Expected: PR opened against `main`.

---

# Task A5 — `@chrysa/ui` contract (separate session: `chrysa-lib`, branch `docs/chrysa-ui-contract`)

> Do this in its own session/PR to respect rule 1+2 (don't hold shared-standards + chrysa-lib together).

**Files:**
- Create: `packages/typescript/ui/CONTRACT.md`
- Create (optional): `packages/typescript/ui/src/contract.css`

- [ ] **Step 1: Branch off main**

```bash
cd /home/anthony/Documents/perso/projects/chrysa/chrysa-lib
git fetch origin && git switch -c docs/chrysa-ui-contract origin/main
```

- [ ] **Step 2: Write `CONTRACT.md`**

Document the guaranteed surface of every primitive (Button, Card, Input, Badge, Loader, HealthBadge, DataTable, PageLayout, ErrorBoundary): the class names it emits (`chrysa-btn`, `chrysa-btn--{variant}`, `chrysa-card`, `chrysa-input`, `chrysa-badge`, `chrysa-loader--{size}`, …), the prop API, and the behaviors (focus trap + ESC for overlays, the four states, `:focus-visible` ring). State explicitly: **primitives ship no colors/fonts; the app supplies the CSS for these classes via its brand theme.** This is the shared contract referenced by DESIGN-SYSTEM.md §2(b).

- [ ] **Step 3 (optional): Write `src/contract.css`** — structural + focus a11y only

```css
/* @chrysa/ui contract.css — STRUCTURAL + focus a11y only. No brand colors/fonts.
   Apps layer their brand CSS on top of these class names. */
.chrysa-btn:focus-visible,
.chrysa-input:focus-visible,
.chrysa-card:focus-visible {
  outline: 2px solid var(--ring, currentColor);
  outline-offset: 2px;
}
.chrysa-btn { display: inline-flex; align-items: center; justify-content: center; }
```

- [ ] **Step 4: Verify the package still builds (in container)**

```bash
docker run --rm -v "$PWD:/work" -w /work node:22 sh -c "npm ci && npm run build -w @chrysa/ui"
```

Expected: build succeeds (this task adds docs/CSS only; no TS API change).

- [ ] **Step 5: Commit + PR**

```bash
git add packages/typescript/ui/CONTRACT.md packages/typescript/ui/src/contract.css
git commit -m "docs(ui): document @chrysa/ui class/behavior contract for brand themes"
git push -u origin docs/chrysa-ui-contract
gh pr create --fill --base main --title "docs(ui): @chrysa/ui brand-theme contract"
```

---

# Phase B — Pilot `linkendin-resume` (after Phase A merged; branch `feat/brand-theme-pilot` off `origin/main`)

> Stack: React 19 + Vite 7 + plain CSS, already fully tokenized. Re-skin is mechanically light; the real work is **designing a distinctive personal brand**. Side-by-side it must read as a deliberate brand, not a genre default.

### Task B0: Branch setup

- [ ] **Step 1**

```bash
cd /home/anthony/Documents/perso/projects/chrysa/linkendin-resume
git fetch origin && git switch -c feat/brand-theme-pilot origin/main
```

### Task B1: Brand brief

**Files:**
- Create: `app/BRAND-BRIEF.md` (from `shared-standards/templates/brand-brief.template.md`)

- [ ] **Step 1: Fill the 6 prompts** for a personal CV/identity piece. Job = present one person credibly + memorably; audience = recruiters/peers on desktop+mobile; pick 3 mood words; one metaphor (e.g. "a printed monograph" or "a personal terminal"); 2-3 references; the one remembered thing → the signature element. Then complete the *Derived decisions* block (type/color/shape/motion/signature/IA).
- [ ] **Step 2: Commit**

```bash
git add app/BRAND-BRIEF.md
git commit -m "docs(design): brand brief for linkendin-resume"
```

### Task B2: Theme tokens (keep names, replace values)

**Files:**
- Modify: `app/src/styles/tokens.css`

- [ ] **Step 1: Import the contract + rewrite values**

At the top of `tokens.css`, vendor/import the shared `contract.css` (copy the file into `app/src/styles/contract.css` and `@import "./contract.css";`, since the app has no shared-package link). Then redefine **every** semantic token *name* (the registry from Task A2) with the brand's values, in both `:root` (dark) and the light variant. Map the app's existing `--clr-*` names to the semantic names, or migrate components to the semantic names — do not leave two parallel token systems.
- [ ] **Step 2: Verify no orphan token names**

```bash
docker run --rm -v "$PWD/app:/work" -w /work node:22 \
  sh -c "grep -rno 'var(--[a-z0-9-]*)' src | sort -u | head -50"
```
Cross-check every `var(--x)` used resolves to a name defined in `tokens.css`/`contract.css`.
- [ ] **Step 3: Commit**

```bash
git add app/src/styles/contract.css app/src/styles/tokens.css
git commit -m "feat(design): adopt brand-theme tokens (contract + values) in linkendin-resume"
```

### Task B3: Signature element

**Files:**
- Modify: the component/CSS that carries the signature (likely `app/src/styles/animations.css` + a layout/header component under `app/src/components/`)

- [ ] **Step 1: Implement the one memorable device** named in the brief (a recurring motif, a distinctive header/layout device, or a signature interaction). Keep it token-driven and reduced-motion-safe.
- [ ] **Step 2: Commit**

```bash
git add -A app/src
git commit -m "feat(design): add brand signature element to linkendin-resume"
```

### Task B4: IA check

- [ ] **Step 1:** Confirm the single CV page's primary view serves the job (the person / a readable column), not a generic shell. Document the IA decisions in `app/DESIGN.md` (Task B6). If the current layout is already job-appropriate, record *why*; only restructure if it defaults to stat-cards + table.

### Task B5: A11y + hard-coded cleanup

**Files:**
- Modify: `app/src/components/ui/DemoBanner.tsx`, `app/src/components/ui/TerminalEasterEgg.tsx` (only if their hard-coded hex clashes with the new palette)

- [ ] **Step 1: Replace clashing hard-coded hex** with semantic tokens where they break the new brand. Keep the easter-egg ANSI colors if intentional and still legible.
- [ ] **Step 2: Run an axe/contrast pass in both themes** (see Task B7 run harness); assert AA for fg/muted/accent-fill. Fix until green.
- [ ] **Step 3: Commit**

```bash
git add -A app/src/components
git commit -m "fix(a11y): tokenize hard-coded colors for brand theme, verify AA"
```

### Task B6: DESIGN.md + drop persona attr

**Files:**
- Modify: `app/DESIGN.md` (rewrite to brand-theme format), `app/index.html`

- [ ] **Step 1: Rewrite `app/DESIGN.md`** from `shared-standards/templates/DESIGN.template.md` — brand brief summary, contract conformance, theme tokens + stated AA ratios, signature element, IA.
- [ ] **Step 2: Remove the persona attribute**

In `app/index.html`, delete `data-persona="editorial"` from the `<html>` tag.

- [ ] **Step 3: Commit**

```bash
git add app/DESIGN.md app/index.html
git commit -m "docs(design): brand-theme DESIGN.md, drop data-persona"
```

### Task B7: Verify end-to-end + PR

- [ ] **Step 1: Run the app in a container, capture before/after**

```bash
cd /home/anthony/Documents/perso/projects/chrysa/linkendin-resume
docker run --rm -p 5173:5173 -v "$PWD/app:/work" -w /work node:22 \
  sh -c "npm ci && npm run dev -- --host 0.0.0.0"   # host-ok
```
Open `http://localhost:5173`, toggle dark/light, screenshot both. Compare against the old Editorial look — must read as a distinct brand.

- [ ] **Step 2: Run tests (vitest, in container)**

```bash
docker run --rm -v "$PWD/app:/work" -w /work node:22 \
  sh -c "npm ci && npm test"   # host-ok
```
Expected: existing tests green (test selectors were preserved).

- [ ] **Step 3: Run the conformance audit against the app**

```bash
bash /home/anthony/Documents/perso/projects/chrysa/shared-standards/scripts/audit-design-conformance.sh \
  /home/anthony/Documents/perso/projects/chrysa/linkendin-resume/app
```
Expected: `conformant: …`, exit 0.

- [ ] **Step 4: Open the pilot PR**

```bash
gh auth switch -u chrysa
git push -u origin feat/brand-theme-pilot
gh pr create --fill --base main \
  --title "feat(design): brand-theme pilot — linkendin-resume"
```

---

## Verification (whole plan)

- **Foundation (A):** ADR 0003 + rewritten DESIGN-SYSTEM.md + `contract.css`/`theme.template.css` + brand-brief/DESIGN templates + audit script committed; audit smoke test green; `grep persona docs/DESIGN-SYSTEM.md` shows only historical/checklist mentions; PR open against main.
- **Contract (A5):** `CONTRACT.md` committed; `@chrysa/ui` still builds in container; PR open.
- **Pilot (B):** app builds + runs in container; tests green; axe/contrast AA in both themes; `audit-design-conformance.sh` returns conformant; before/after screenshots show a distinct, intentional brand; PR open.

## Self-review notes (done)

- Spec coverage: every spec section maps to a task (contract → A2/A5/A4; brand theme + method → A3/A4; foundation deliverables 1-6 → A1/A2/A3/A4/A5/A6 + A7 ledger; pilot → B1-B7; existing-migrated apps → A7 ledger note; rollout → A7).
- Token names are identical across `contract.css`, `theme.template.css`, the audit `REQUIRED_TOKENS`, and the pilot — single registry, no drift.
- No persona spec survives in DESIGN-SYSTEM.md (A4 step 2 guard).
- chrysa rules honored: English files, container-only frontend test/run, `# host-ok` markers, PRs to main, `gh auth switch -u chrysa`, rule 1+2 via A5-in-own-session.
