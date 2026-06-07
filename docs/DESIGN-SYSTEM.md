# chrysa Design System — "Neon Brutalist"

> The **visual layer** for every chrysa web surface. Companion to
> `docs/UX-UI-GUIDELINES.md` (which owns ergonomics, a11y, i18n, the four states)
> and the `ui-ux` skill. This document owns the *look*: one token contract, one
> aesthetic DNA, per-app accent.
>
> **Status:** adopted 2026-06 (ecosystem-wide re-skin, all GUI frontends).
> **Distribution:** tokens + primitives live in `chrysa-lib` → `@chrysa/ui`.
> Tailwind repos consume the `@theme` mapping; SCSS/Bootstrap repos consume the
> same CSS custom properties.

---

## 0. Why a system

The frontends had diverged across ~6 styling stacks with no shared identity.
Rather than unify the *stack* (high-churn migration), we unify the **token
contract + visual DNA**: every app speaks the same semantic vocabulary and wears
the same aesthetic, while keeping its own CSS stack and its own accent hue.

---

## 1. Aesthetic DNA — the rules

Neon Brutalist. Loud structure, flat fills, one acid accent. The rules below are
**RULE** (binding); deviations need a documented reason in `<repo>/DECISIONS.md`.

1. **Radius 0.** No rounded corners anywhere (`--radius: 0px`).
2. **Borders are structure.** Every surface, input and button has a `2px solid`
   border in the `border` token (which equals the foreground — loud, not subtle).
3. **Hard offset shadows, never blur.** `--shadow: 4px 4px 0 #000`. Shadow is the
   border's twin; interactive elements "press" into it on hover/active.
4. **No gradients, no glow.** Flat fills only.
5. **Mono-forward.** JetBrains Mono for data, labels, and UI chrome; Space Grotesk
   for display headings only. No third family.
6. **Accent is a block, not text.** The acid hue fills a region with `accent-ink`
   text on top — never thin acid text on a dark background (keeps WCAG AA).
7. **Loud labels.** Uppercase + `letter-spacing` for eyebrows, KPI labels, buttons.
8. **One accent per app.** A single acid hue carries identity; everything else is
   the shared neutral frame.

---

## 2. Token contract

The single source of truth. Names are **semantic roles**, never raw colors. Dark
is canonical; light is provided and must meet the same contrast bar.

```css
/* @chrysa/ui — tokens.css */
:root {                         /* dark — canonical */
  --bg:         #0e0e10;
  --surface:    #18181b;
  --surface-2:  #242428;
  --fg:         #fafafa;
  --muted:      #a1a1aa;
  --border:     #fafafa;        /* FG-colored, deliberately loud */
  --accent:     #c8ff00;        /* acid lime — PER-APP override */
  --accent-ink: #0e0e10;        /* text/icon ON an accent block */
  --signal:     #22c55e;
  --warning:    #fbbf24;
  --danger:     #ff4d4d;
  --ring:       var(--accent);
  --radius:     0px;
  --shadow:     4px 4px 0 #000000;
  --font-display: "Space Grotesk", system-ui, sans-serif;
  --font-mono:    "JetBrains Mono", ui-monospace, "SFMono-Regular", monospace;
}

:root.light {
  --bg:#fafafa; --surface:#ffffff; --surface-2:#f0f0f0;
  --fg:#0e0e10; --muted:#52525b; --border:#0e0e10;
  --accent:#a3e000; --accent-ink:#0e0e10;
  --signal:#15803d; --warning:#b45309; --danger:#dc2626;
  --shadow:4px 4px 0 #0e0e10;
}
```

### 2.1 Tailwind v4 mapping (1:1)

Tokens map **one-to-one** to the Tailwind theme so utilities are generated
directly — no parallel color scale to maintain.

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
  --shadow-brutal: var(--shadow);
  --font-display: var(--font-display);
  --font-mono: var(--font-mono);
}
```

Generated utilities: `bg-surface`, `text-fg`, `text-muted`, `border-border`,
`bg-accent`, `text-accent-ink`, `text-signal`, `shadow-brutal`, `font-mono`,
`font-display`, `rounded-card` (= 0).

### 2.2 Spacing & type scale

- Spacing: 4/8px rhythm (Tailwind default scale). Sections `space-y-6`+.
- Type scale (fixed): `text-xs` label → `text-sm` body-dense → `text-base` body →
  `text-lg`/`text-xl` section → `text-2xl`+ page title. KPI values larger, mono.

---

## 3. Per-app accent

Each app overrides **only** `--accent` (`--ring` follows). One acid hue each:

| App family | `--accent` |
|---|---|
| gaming-os / studioverse | `#c8ff00` acid lime |
| dev-nexus / devtool / container-webview | `#00e5ff` cyan |
| ai-aggregator / doc-gen | `#b388ff` electric violet |
| satisfactory-factory-manager / mirrador | `#ff8a00` industrial orange |
| cdn-explorer / link-reader-bot | `#ff4dff` magenta |
| sport-intelligence-hub | per-team (existing palette) |
| discordium | keeps its 4 in-app themes |

Light-mode accent should be a slightly darker variant of the same hue to preserve
fill contrast with `accent-ink`.

---

## 4. Component conventions

Primitives ship from `@chrysa/ui`; SCSS repos mirror them with the same classes.

**Button** — flat fill, 2px border, hard shadow that presses on interaction.
```tsx
<button class="border-2 border-border bg-accent text-accent-ink font-mono font-semibold
  uppercase tracking-wide px-4 h-10 shadow-brutal
  hover:translate-x-[3px] hover:translate-y-[3px] hover:shadow-none
  active:translate-x-[3px] active:translate-y-[3px] active:shadow-none
  transition-[transform,box-shadow] duration-100
  focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-ring
  disabled:opacity-50 disabled:pointer-events-none" />
```
Variants: `bg-accent` (primary, one per region), `bg-surface` (secondary),
`bg-danger text-fg` (destructive). Secondary/ghost keep the border + shadow.

- **Card / Panel** — `border-2 border-border bg-surface shadow-brutal`, radius 0.
- **StatCard** — uppercase mono label, oversized mono value, optional accent corner block.
- **Badge** — square (no pill), `border-2`, solid tone fill, label + icon.
- **Input / Select / Textarea** — `border-2 border-border bg-bg`, accent border on
  focus (`focus:border-accent`), no soft ring.
- **Table / List** — `border-2` outer, `divide-y-2 divide-border` rows. Header row mono uppercase.
- **Overlay (dialog/sheet)** — `border-2`, `shadow-brutal`, focus-trapped, `Esc` closes.

---

## 5. Accessibility (brutalism is not an excuse)

Inherits the WCAG 2.1 AA floor from `UX-UI-GUIDELINES.md` §6. Brutalist-specific:

- **RULE** Accent only as a fill with `accent-ink` text — never acid text on `bg`.
  Verify fill contrast ≥ 4.5:1 (large UI ≥ 3:1) for every app accent.
- **RULE** `signal`/`warning`/`danger` always pair color with an icon + text.
- **RULE** Focus = a 2px offset outline in `ring` (accent). Visible on every
  interactive element; never `outline: none` without it.
- **RULE** Honor `prefers-reduced-motion` — the press-translate is the only motion
  and must be disabled there.
- Borders/shadows are decorative; semantics live in real HTML elements + ARIA.

---

## 6. Adoption checklist (per repo)

A frontend conforms when:

- [ ] Token contract present (light + dark), no hard-coded hex in components — §2
- [ ] Tailwind `@theme` maps 1:1 (Tailwind repos) / same CSS vars (SCSS repos) — §2.1
- [ ] Radius 0, 2px borders, hard offset shadows, no gradients/glow — §1
- [ ] Mono-forward type, Space Grotesk display only — §1
- [ ] One per-app accent, used as fill blocks — §3
- [ ] Primitives styled per §4; four states still handled (per UX-UI-GUIDELINES §5)
- [ ] WCAG AA verified in both themes, accent fill contrast checked — §5
- [ ] `DESIGN.md` in the repo references this system + records the app accent

---

## 7. Rollout

- **Foundation:** this doc + `@chrysa/ui` token file & Tailwind preset (`chrysa-lib`).
- **Re-skin:** all 17 GUI frontends adopt Neon Brutalist (campaign
  `design_campaign_2026_06`), including the 3 already redesigned
  (gaming-os, ai-aggregator, studioverse) which were shipped on a softer look.
- Per-repo work tracked in DB Tâches under the campaign Epic.
