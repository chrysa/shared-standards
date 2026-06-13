# chrysa Design System — Personas

> The **visual layer** for every chrysa web surface. Companion to
> `docs/UX-UI-GUIDELINES.md` (which owns ergonomics, a11y, i18n, the four states)
> and the `ui-ux` skill. This document owns the *look*: one token contract, **four
> aesthetic personas**, per-app accent.
>
> **Status:** adopted 2026-06. **Supersedes** the single "Neon Brutalist" DNA
> (2026-06, ecosystem re-skin) after the [2026-06 design audit](audits/DESIGN-AUDIT-2026-06.md)
> found that one uniform aesthetic + accent-only differentiation gave every app the
> same identity and forced genres that fight brutalism (a résumé, content tools)
> into it. See [ADR 0002](adr/0002-design-personas.md).
> **Distribution:** tokens + primitives live in `chrysa-lib` → `@chrysa/ui`.
> Tailwind repos consume the `@theme` mapping; SCSS/Bootstrap repos consume the
> same CSS custom properties.

---

## 0. Why a system, why personas

The frontends had diverged across ~6 styling stacks with no shared identity. The
first answer (one aesthetic, one accent per app) over-corrected: it unified the
*skin* so hard that a CI dashboard, a doc generator, and a résumé became the same
product in different highlighter colors — and the two apps with real identity
(`sport-intelligence-hub`, `discordium`) got there by routing *around* the system.

The fix keeps the part that worked — **one semantic token contract + per-app
accent + the ergonomics/a11y floor** — and replaces the single DNA with **four
personas**. A persona is a genre-appropriate bundle of *typography, density,
radius, depth, and motion*. **Identity = persona + accent**, never accent alone.
Apps in the same genre *should* feel related; the bug was cross-genre apps feeling
identical.

---

## 1. The four personas

Each persona fixes five axes. The axes are **tokens** (§3) so a repo adopts a
persona by setting one block, and all components inherit.

| Axis | **Console** | **Arcade** | **Editorial** | **Signal** |
|---|---|---|---|---|
| **Genre** | dev tools, dashboards, data utilities | games & playful surfaces | personal / portfolio / content | live data, sport, scoreboards |
| **Display font** | Space Grotesk | Chakra Petch / heavy grotesk | Fraunces / Newsreader (serif) | Space Grotesk |
| **Body font** | Inter / system sans | Inter | the serif's sans companion (e.g. Inter) | Inter |
| **Data font** | JetBrains Mono | JetBrains Mono | JetBrains Mono (figures) | JetBrains Mono (tabular) |
| **Radius** | `4px` | `0–2px` | `10px` | `6px` |
| **Depth** | hairline border + small soft shadow | hard offset shadow (the "press") | soft blurred shadow | border + medium shadow |
| **Border** | `1px` | `2px` (structural) | `1px` | `1px` |
| **Density** | compact (control `h-9`) | normal (`h-10`) | comfortable (`h-11`, generous spacing) | compact, tabular |
| **Case** | labels uppercase, body normal | uppercase-forward | all normal case | labels uppercase, figures tabular |
| **Motion** | quick fade/press (120ms) | expressive press-translate + accent pulse | calm fade/slide (200–260ms) | live-update flash, value count |
| **Accent use** | small fills + focus + key numbers | large saturated blocks | restrained, one warm accent | semantic + per-entity palette |

Brutalism is **not deleted** — it survives as **Arcade**, where loud structure
fits. The other three genres get type/density/depth tuned to how they're read.

Persona rules are **RULE** (binding); deviations need a documented reason in
`<repo>/DECISIONS.md`.

### 1.1 Persona is the surface — the layout serves the project

A persona governs the **surface only**: typography, density, radius, depth, motion,
and accent. It deliberately makes same-genre apps *feel related*. It does **not**
prescribe a layout. Eleven apps share the Console persona; that is correct — and it
is also why surface conformance alone is not done.

> **RULE** Persona ≠ interface. Each app's **information architecture** — its primary
> view, the object it puts at the center, the primary action, and the right density —
> is **designed for that app's job**, not inherited. Same-genre apps share the token
> contract; **they never share the layout.** A log-proxy inspector, a content feed and
> a tree browser are all Console, and must not be the same screen in three accents.

> **RULE** "Stat-cards on top + one flat table" is **not** a default. Reaching for it
> without a reason is the smell this rule exists to catch. The right primary view comes
> from the app's job-to-be-done (`mirrador` → a request inspector; a reader → a reading
> column; a browser → a tree/detail split).

The IA layer lives in `docs/UX-UI-GUIDELINES.md` (§1 core principles, §3 layout) and
is captured per repo as a short **IA brief** in `<repo>/DESIGN.md` (§7). Surface
migration (the persona token sweep) and the IA pass are **two distinct steps**: a repo
is not done when it merely wears the right tokens.

---

## 2. App → persona map

16 web frontends (`my-resume` has no shippable frontend; dropped). One accent each
(§4). Migration is one repo per session (rule 1+2); deltas in §8.

| App | Persona | Accent | Current `main` | Migration weight |
|---|---|---|---|---|
| dev-nexus | Console | cyan | brutalist | light (relax radius/border, add body sans) |
| devtool | Console | cyan | brutalist | light |
| container-webview | Console | cyan | brutalist | light |
| cdn-explorer | Console | magenta | brutalist | light |
| audit-platform | Console | azure | brutalist | light |
| doc-gen | Console | violet | brutalist | medium (content density) |
| mirrador | Console | orange | brutalist | light |
| chrysa-portfolio-viz | Console | chrome | brutalist | light |
| ai-aggregator | Console | violet | **soft slop** | medium (drop Inter-as-brand, adopt Console) |
| link-reader-bot | Console | magenta | brutalist | light |
| satisfactory-factory-manager | Console | orange | brutalist | light (dense planner; keep industrial orange) |
| gaming-os | **Arcade** | lime | brutalist | minimal (already close) |
| studioverse | **Arcade** | lime | brutalist | minimal |
| discordium | **Arcade** | per-theme | 4 in-app themes | keep themes; map chrome to Arcade |
| linkendin-resume | **Editorial** | warm amber | brutalist | **heavy** (full re-skin; pilot) |
| sport-intelligence-hub | **Signal** | per-team | bespoke (untouched) | none (it *is* the Signal reference) |

`sport-intelligence-hub` is the canonical Signal implementation — formalize its
existing tokens, don't rebuild them.

---

## 3. Token contract

The single source of truth. Names are **semantic roles**, never raw colors. Dark
is canonical; light meets the same contrast bar. The **neutral frame is shared by
all personas**; the **persona block** sets the five axes.

```css
/* @chrysa/ui — tokens.css : shared neutral frame (all personas) */
:root {                         /* dark — canonical */
  --bg:         #0e0e10;
  --surface:    #18181b;
  --surface-2:  #242428;        /* must differ >=4% L from --surface */
  --fg:         #fafafa;        /* 18:1 on --bg */
  --muted:      #a1a1aa;        /* 7:1 on --bg */
  --border:     #2e2e33;        /* hairline default; personas may raise to --fg */
  --accent:     #c8ff00;        /* PER-APP override (§4) */
  --accent-ink: #0e0e10;        /* text/icon ON an accent block */
  --signal:     #22c55e;
  --warning:    #fbbf24;
  --danger:     #ff4d4d;
  --ring:       var(--accent);
}

:root.light {
  --bg:#fafafa; --surface:#ffffff; --surface-2:#f0f0f0;
  --fg:#0e0e10; --muted:#52525b; --border:#d4d4d8;
  --accent:#a3e000; --accent-ink:#0e0e10;
  --signal:#15803d; --warning:#b45309; --danger:#dc2626;
}

/* --- PERSONA BLOCK: pick ONE. Sets the five axes. --- */

/* Console */
:root[data-persona="console"] {
  --radius: 4px;
  --border-weight: 1px;
  --shadow: 0 1px 3px rgb(0 0 0 / 0.24), 0 1px 2px rgb(0 0 0 / 0.16);
  --font-display: "Space Grotesk", system-ui, sans-serif;
  --font-body:    "Inter", system-ui, -apple-system, sans-serif;
  --font-mono:    "JetBrains Mono", ui-monospace, monospace;
  --density: 2.25rem;           /* control height (h-9) */
  --motion: 120ms;
}

/* Arcade — brutalism lives here */
:root[data-persona="arcade"] {
  --radius: 2px;
  --border-weight: 2px;
  --border: var(--fg);          /* loud structural border */
  --shadow: 4px 4px 0 #000000;  /* hard offset; light: 4px 4px 0 var(--fg) */
  --font-display: "Chakra Petch", "Space Grotesk", sans-serif;
  --font-body:    "Inter", system-ui, sans-serif;
  --font-mono:    "JetBrains Mono", ui-monospace, monospace;
  --density: 2.5rem;            /* h-10 */
  --motion: 100ms;
}

/* Editorial */
:root[data-persona="editorial"] {
  --radius: 10px;
  --border-weight: 1px;
  --shadow: 0 4px 24px rgb(0 0 0 / 0.18);
  --font-display: "Fraunces", "Newsreader", Georgia, serif;
  --font-body:    "Inter", system-ui, -apple-system, sans-serif;
  --font-mono:    "JetBrains Mono", ui-monospace, monospace;
  --density: 2.75rem;          /* h-11, generous */
  --motion: 220ms;
}

/* Signal */
:root[data-persona="signal"] {
  --radius: 6px;
  --border-weight: 1px;
  --shadow: 0 2px 8px rgb(0 0 0 / 0.28);
  --font-display: "Space Grotesk", system-ui, sans-serif;
  --font-body:    "Inter", system-ui, sans-serif;
  --font-mono:    "JetBrains Mono", ui-monospace, monospace;
  --density: 2.25rem;
  --motion: 140ms;
}
```

### 3.1 Tailwind v4 mapping (1:1)

```css
/* index.css (Tailwind repos) */
@import "tailwindcss";
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
`font-mono`, `rounded-card`.

### 3.2 Spacing & type scale

- Spacing: 4/8px rhythm (Tailwind default). Console/Signal sections `space-y-4`;
  Editorial `space-y-8`+.
- Type scale: `text-xs` label → `text-sm` body-dense → `text-base` body →
  `text-lg`/`text-xl` section → `text-2xl`+ page title. Editorial bumps body to
  `text-base`/`text-lg` with `leading-relaxed`.

---

## 4. Per-app accent

Each app overrides **only** `--accent` (`--ring` follows). This table is
**authoritative** — adding/changing an accent is a PR to this section, not an
ad-hoc repo choice.

| App | `--accent` (dark / light) |
|---|---|
| gaming-os / studioverse | `#c8ff00` / `#a3e000` acid lime |
| dev-nexus / devtool / container-webview | `#00e5ff` / `#0891b2` cyan |
| ai-aggregator / doc-gen | `#b388ff` / `#7c3aed` electric violet |
| satisfactory-factory-manager / mirrador | `#ff8a00` / `#c2410c` industrial orange |
| cdn-explorer / link-reader-bot | `#ff4dff` / `#c026d3` magenta |
| audit-platform | `#00b3ff` / `#0088cc` azure |
| chrysa-portfolio-viz | `#d4d4d8` / `#52525b` chrome |
| linkendin-resume | `#f0a830` / `#b45309` warm amber (Editorial — not acid) |
| sport-intelligence-hub | per-team palette (existing) |
| discordium | per-theme (Discorde / Ordre / Vide / Néon) |

**RULE** Accent is a **fill with `accent-ink` text** — never thin acid text on
`--bg`. Verify fill contrast ≥ 4.5:1 (large UI ≥ 3:1) for each app accent in both
themes. Editorial uses its accent sparingly (links, one CTA), not as large blocks.

---

## 5. Component conventions

Primitives ship from `@chrysa/ui` and read the tokens, so the same component
renders per-persona automatically. SCSS/Bootstrap repos mirror them with the same
classes + tokens.

- **Button** — `border-[length:var(--border-weight)] border-border rounded-card`,
  `bg-accent text-accent-ink` (primary, one per region), height `var(--density)`.
  Console/Editorial/Signal: subtle `shadow-card`, `hover:brightness-110`,
  `active:scale-[0.98]`. Arcade: `shadow-card` (hard) that presses on
  hover/active (`translate-x-[3px] translate-y-[3px] shadow-none`).
- **Card / Panel** — `border-[length:var(--border-weight)] border-border
  bg-surface rounded-card shadow-card`. Nested surface uses `--surface-2`.
- **StatCard** — mono value (`font-mono`), label `text-xs` (uppercase in
  Console/Signal, normal in Editorial), optional accent corner.
- **Badge** — `rounded-card`, solid tone fill, label + icon.
- **Input / Select / Textarea** — `border-[length:var(--border-weight)]
  border-border bg-bg`, `focus:border-accent`, focus ring = `--ring`.
- **Table / List** — `divide-y divide-border`, header row `font-mono` uppercase
  (Console/Signal). Signal tables use tabular figures.
- **Overlay (dialog/sheet)** — `shadow-card`, focus-trapped, `Esc` closes.

---

## 6. Accessibility (binding floor, all personas)

Inherits WCAG 2.1 AA from `UX-UI-GUIDELINES.md` §6. Persona-independent rules —
these are the **display/ergonomics fixes** from the audit, now mechanical:

- **RULE** Accent only as a fill with `accent-ink` text; fill + every text/bg pair
  carries a stated, AA-verified ratio. Shared frame: `--fg` 18:1, `--muted` 7:1.
- **RULE** **Body text is `--font-body` in normal case.** Mono is for data/labels,
  never paragraphs; uppercase is for short labels, never sentences.
- **RULE** No reflex font as the **display/brand** face (Inter, DM Sans, Outfit…).
  Inter is allowed as `--font-body` only.
- **RULE** No gradient text, no glow. Flat fills.
- **RULE** Adjacent nested surfaces must differ — `--surface` vs `--surface-2`
  ≥ 4% lightness step, or a real `--shadow`.
- **RULE** Focus = 2px offset outline in `--ring` on every interactive element;
  never `outline:none` without a replacement.
- **RULE** Honor `prefers-reduced-motion` — disable press-translate, pulse, and
  live-flash animations there.

---

## 7. Adoption checklist (per repo)

A frontend conforms when:

- [ ] Shared neutral frame present (light + dark), no hard-coded hex in components — §3
- [ ] **One `data-persona` set** per §2; five axes inherited (not re-declared) — §1, §3
- [ ] Tailwind `@theme` maps 1:1 / same CSS vars (SCSS) — §3.1
- [ ] Body is `--font-body` normal-case; display font is non-reflex; mono = data — §6
- [ ] One per-app accent from §4, used per persona's accent rule
- [ ] Primitives per §5; four states still handled (UX-UI-GUIDELINES §5)
- [ ] WCAG AA verified both themes; accent fill + text/bg ratios stated — §6
- [ ] **IA brief in `DESIGN.md`** — names the job-to-be-done, the primary view, and the
      primary action; the layout serves the job, not a generic stat-cards + table shell — §1.1
- [ ] `DESIGN.md` in the repo names its persona + accent and links this system

---

## 8. Rollout

- **Foundation:** this doc + `templates/design-tokens.css` (shared frame + the four
  persona blocks) + `@chrysa/ui` primitives reading the axis tokens.
- **Migration:** per §2, one repo per session (rule 1+2). **Pilot: linkendin-resume
  → Editorial** (worst current clash; proves a persona yields a visibly different,
  better result than uniform brutalism). Then the Console batch (lightest deltas),
  then Arcade (gaming-os/studioverse already close), then formalize Signal
  (sport-intelligence-hub) and Arcade-map discordium.
- Per-repo work tracked under the campaign Epic
  (`37759293e35e81e1973ce30839822b79`), retitled from "Neon Brutalist re-skin".
