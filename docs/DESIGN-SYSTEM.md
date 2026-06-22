# chrysa Design System — Brand Themes

> The **visual layer** for every chrysa web surface. Companion to
> `docs/UX-UI-GUIDELINES.md` (which owns ergonomics, a11y, i18n, the four states)
> and the `ui-ux` skill. This document owns the *look*: a small, immutable shared
> **contract** plus a **per-app brand theme** that owns every value.
>
> **Status:** adopted 2026-06-22. **Supersedes the personas model** (Console /
> Arcade / Editorial / Signal). See [ADR 0003](adr/0003-brand-themes.md) — the 3rd
> revision of the system (Neon Brutalist → Personas → Brand Themes).
>
> **Distribution:** the contract ships as `templates/contract.css` (token names +
> neutral fallbacks + the a11y floor) and, for primitives, as the `@chrysa/ui`
> class-name + behavior + prop API (full contract in
> `chrysa-lib/packages/typescript/ui/CONTRACT.md`). Each app imports the contract,
> then supplies its own theme values.

---

## 0. Why brand themes (not personas)

The personas model (ADR 0002) replaced one uniform aesthetic with four genre
bundles. It reproduced the same uniformity trap one rung up:

- **The genre + single-accent trap.** 11 of 16 apps mapped to **Console**, so they
  shared the same persona axes and differed only by accent hue — structurally
  identical to the accent-only differentiation the audit set out to fix.
- **The doctrine ↔ code gap.** The old doc claimed `@chrysa/ui` primitives *read
  the semantic tokens* and rendered per-persona automatically. They do not — the
  primitives are **class-name-only** and ship no colors or fonts, so persona token
  axes never reached the components.
- **The IA rule had no teeth.** "Layout serves the project" was prose with no
  enforcing mechanism, so layouts stayed generic regardless of persona.

The conclusion: identity cannot be allocated at the genre level. It is now
**designed per app**, over a contract small enough to actually hold and audit.

---

## 1. The contract (shared, immutable)

Three parts. Apps **import** `templates/contract.css` and honor the `@chrysa/ui`
API; they never edit either.

### (a) The accessibility & i18n floor

Defers entirely to `docs/UX-UI-GUIDELINES.md` §6 — WCAG 2.1 AA (text contrast
≥ 4.5:1 / 3:1 large), visible focus on every interactive element,
`prefers-reduced-motion` honored, and FR + EN from V1. Every theme value below
must clear this floor; the floor itself is not re-stated per app, it is inherited.
`contract.css` carries the reduced-motion `@media` block so it applies to every
brand by default.

### (b) The `@chrysa/ui` component contract

`@chrysa/ui` primitives are **class-name + behavior + prop API only** — they emit
class names and ship **no colors or fonts**. The app supplies the CSS for those
classes. The primitives emit:

`chrysa-btn`, `chrysa-card`, `chrysa-input`, `chrysa-badge`, `chrysa-loader`.

Behavior (focus handling, four states, keyboard, ARIA) and the prop API are fixed
by the contract; the *look* is the app's. The full, authoritative contract lives in
`chrysa-lib/packages/typescript/ui/CONTRACT.md`.

### (c) The semantic token NAME registry

The contract fixes the **names** of the semantic tokens. **Names are fixed; values
are free.** Apps import `contract.css` (neutral fallbacks) then override every
value in their own `theme.css`. The 20 names:

```
--bg            --surface       --surface-2     --fg
--muted         --border        --accent        --accent-ink
--signal        --warning       --danger        --ring
--radius        --border-weight --shadow        --font-display
--font-body     --font-mono     --density       --motion
```

Color roles: `--bg`, `--surface`, `--surface-2`, `--fg`, `--muted`, `--border`,
`--accent`, `--accent-ink`, `--signal`, `--warning`, `--danger`, `--ring`.
Shape / depth / type / density / motion roles: `--radius`, `--border-weight`,
`--shadow`, `--font-display`, `--font-body`, `--font-mono`, `--density`, `--motion`.

No app may invent a new token name or drop one of these; that is the line that keeps
`@chrysa/ui` and the audit working across the fleet.

---

## 2. The brand theme (per app)

Everything below is the app's to design. Seven elements:

1. **Brand brief** — the 6-prompt discovery (§3) that derives the identity. Lives
   in `<repo>/BRAND-BRIEF.md` from `templates/brand-brief.template.md`.
2. **Theme tokens** — every value for the 20 names, in **light + dark**, each
   text/bg pair **AA-verified** with a stated ratio. Starter:
   `templates/theme.template.css`.
3. **Type system** — display, body, mono. The **display (brand) face must be a
   non-reflex font** — not Inter, DM Sans, Outfit or another default sans. Inter is
   allowed as `--font-body` only.
4. **Shape & depth** — `--radius`, `--border-weight`, `--shadow` chosen as one
   coherent material language, not picked per component.
5. **Motion personality** — the app's `--motion` timing and feel (calm / snappy /
   expressive). Must be **reduced-motion-safe** (the floor disables it under
   `prefers-reduced-motion`).
6. **Signature element** — one memorable visual device unique to the app. This is
   **the anti-uniformity lever**: the thing a user remembers after closing it. Every
   app names exactly one.
7. **IA brief** — primary view, central object, primary action, density. **The
   layout serves the job.** It is never a default stat-cards-on-top + one-flat-table
   shell; that shell is the smell this element exists to catch.

The brand theme is captured per repo in `<repo>/DESIGN.md` from
`templates/DESIGN.template.md`.

---

## 3. Brand-brief method

This **replaces the old persona table** as the identity mechanism. Identity is
*derived* from six prompts, not picked off a shelf
(`templates/brand-brief.template.md`):

1. **Job-to-be-done** — what a user comes to accomplish, one sentence.
2. **Audience** — who they are; expertise, context, device.
3. **Three mood words** — exactly three (e.g. precise / quiet / industrial).
4. **Metaphor** — one concrete image for the product (a control room, a field
   notebook, a scoreboard).
5. **References (2-3)** — products/objects whose feel is close, and what
   specifically to borrow.
6. **Remembered for** — the one visual thing a user recalls after closing the app.

These resolve into the design decisions:

- mood words + metaphor → **color** (accent hue, surface warmth) and **shape &
  depth** (the material language);
- job + audience → **type system** (display face, density) and **IA brief**;
- mood words → **motion personality**;
- **remembered-for → the signature element.**

---

## 4. Tailwind v4 note (optional)

For Tailwind repos, map the contract **token names** (not personas) to utilities in
an `@theme inline` block. The app's `theme.css` still supplies the values; this only
exposes them as utilities.

```css
/* index.css (Tailwind repos) */
@import "tailwindcss";
@import "contract.css";   /* token names + a11y floor */
@import "theme.css";      /* this app's values */

@theme inline {
  --color-bg: var(--bg);             --color-surface: var(--surface);
  --color-surface-2: var(--surface-2);
  --color-fg: var(--fg);             --color-muted: var(--muted);
  --color-border: var(--border);     --color-accent: var(--accent);
  --color-accent-ink: var(--accent-ink);
  --color-signal: var(--signal);     --color-warning: var(--warning);
  --color-danger: var(--danger);     --color-ring: var(--ring);
  --radius-card: var(--radius);
  --shadow-card: var(--shadow);
  --font-display: var(--font-display);
  --font-body: var(--font-body);
  --font-mono: var(--font-mono);
}
```

Generated utilities: `bg-surface`, `text-fg`, `text-muted`, `border-border`,
`bg-accent`, `text-accent-ink`, `shadow-card`, `font-display`, `font-body`,
`font-mono`, `rounded-card`. SCSS / Bootstrap repos consume the same CSS custom
properties directly.

---

## 5. Accessibility (binding floor)

Inherits WCAG 2.1 AA from `UX-UI-GUIDELINES.md` §6. These are the display rules
every brand theme must satisfy — they are **RULE** (binding), brand-independent:

- **RULE** Accent is used **only as a fill with `accent-ink` text** — never thin
  accent-colored text on `--bg`. Every fill + text/bg pair carries a stated,
  AA-verified ratio (fill ≥ 4.5:1, large UI ≥ 3:1).
- **RULE** **Body text is `--font-body` in normal case.** Mono (`--font-mono`) is
  for data and labels only, never paragraphs; uppercase is for short labels, never
  sentences.
- **RULE** No reflex font as the **display/brand** face (Inter, DM Sans, Outfit…).
  Inter is allowed as `--font-body` only.
- **RULE** No gradient text, no glow. Flat fills.
- **RULE** Adjacent nested surfaces must differ — `--surface` vs `--surface-2`
  ≥ 4% lightness step, or a real `--shadow`.
- **RULE** Focus = 2px offset outline in `--ring` on every interactive element;
  never `outline:none` without a replacement.
- **RULE** Honor `prefers-reduced-motion` — the motion personality (press,
  pulse, live-flash, transitions) is disabled there.

---

## 6. Adoption checklist (per repo)

A frontend conforms when:

- [ ] Imports `contract.css` (token names + a11y floor); no hard-coded hex in
      components — §1
- [ ] **Every token name defined** in the app theme, **light + dark** — §1, §2
- [ ] Display (brand) font is **non-reflex** — §5
- [ ] **WCAG AA verified in both themes**, with the fg / muted / accent-fill ratios
      stated — §5, UX-UI-GUIDELINES §6
- [ ] `@chrysa/ui` class/behavior/prop contract honored if used — §1(b)
- [ ] **Brand brief present** (`BRAND-BRIEF.md`) — §3
- [ ] **Signature element named** — §2
- [ ] **IA brief present** — primary view / central object / primary action /
      density; the layout serves the job, not a generic stat-cards + table shell — §2
- [ ] `DESIGN.md` present, from `templates/DESIGN.template.md` — §2
- [ ] **No `data-persona` attribute anywhere** in the repo

---

## 7. Rollout

One repo per session (rule 1+2). Per repo, in order:
**brand brief → theme tokens → signature element → IA brief → a11y verification →
PR.**

- **Pilot: linkendin-resume** — the worst current clash; proves a bespoke brand
  theme yields a visibly distinct, better result than the inherited uniform skin.
- **The 3 already persona-migrated apps fold in retroactively.** `gaming-os`,
  `studioverse`, and `ai-aggregator` add a brand brief + a signature element and
  drop the `data-persona` attribute as the rollout reaches them. **No urgency.**

Per-repo work is tracked under the campaign Epic
(`37759293e35e81e1973ce30839822b79`) and in `docs/INTERFACE-REVIEW-LEDGER.md`.
