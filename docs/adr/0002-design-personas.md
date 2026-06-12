# ADR 0002 — Design personas replace the single "Neon Brutalist" DNA

- **Status:** Accepted
- **Date:** 2026-06-12
- **Context:** Design audit 2026-06 (`docs/audits/DESIGN-AUDIT-2026-06.md`),
  supersedes the visual layer of ADR-less campaign `design_campaign_2026_06`
  (Notion epic `37759293e35e81e1973ce30839822b79`)

## Context

The 2026-06 ecosystem re-skin adopted one aesthetic DNA — "Neon Brutalist" (radius
0, 2px foreground-colored borders, hard offset shadows, Space Grotesk + JetBrains
Mono, uppercase labels) — for all web frontends, with **only the accent hue varying
per app**. 13 of 16 frontends shipped it on `main`.

A portfolio review found this is the root of the reported identity / display /
ergonomics problems:

- **Identity:** accent-hue-only differentiation is too thin. A résumé
  (`linkendin-resume`), a CI dashboard (`dev-nexus`), a doc generator (`doc-gen`)
  and a CDN explorer were the same product in different highlighter colors. The two
  apps with genuine identity — `sport-intelligence-hub` (bespoke F1 palette) and
  `discordium` (4 themed skins) — achieved it by routing *around* the uniform system,
  which is the clearest signal that the system was mis-specified.
- **Display:** loud borders + hard shadows + acid fills are high-noise; acid-accent
  fills are contrast-fragile (a white-on-yellow bug shipped and was patched
  reactively).
- **Ergonomics:** uppercase-mono body copy, radius 0, and press-translate as the
  only affordance optimize "loud structure" over reading and discoverability —
  actively wrong for content/personal genres.

Brutalism is not bad; applying it to *every* genre is.

## Decision

1. **Keep the backbone.** The semantic token contract, per-app accent mechanism,
   the WCAG 2.1 AA floor + four-states (`UX-UI-GUIDELINES.md`), the no-hardcoded-hex
   discipline, and the primitive component contracts are retained unchanged.
2. **Replace the single DNA with four personas** — **Console** (dev tools /
   dashboards), **Arcade** (games; brutalism lives here), **Editorial** (personal /
   portfolio / content), **Signal** (live data / sport). Each persona fixes five
   axes: display+body+data typography, radius, depth, border weight, density, and
   motion. **Identity = persona + accent**, never accent alone.
3. **Tokenize the persona axes.** `templates/design-tokens.css` ships the shared
   neutral frame + four `:root[data-persona="…"]` blocks. A repo adopts a persona
   by setting `data-persona` on `<html>`; components inherit. No parallel skin.
4. **Bake the audit's display/ergonomics fixes into binding rules** (DESIGN-SYSTEM
   §6): body is `--font-body` in normal case (mono = data only); no reflex font as
   the display/brand face (Inter allowed for body only); no gradient text/glow;
   nested surfaces must differ ≥4% L or carry a shadow; every accent fill + text/bg
   pair states an AA-verified ratio.
5. **The §4 accent table is authoritative.** Accents are added/changed by PR to
   DESIGN-SYSTEM.md, not ad hoc per repo (closes the azure/yellow drift).
6. **Migrate one repo per session** (rule 1+2). **Pilot: `linkendin-resume` →
   Editorial** — the worst current clash; it proves a persona produces a visibly
   different, better result than uniform brutalism before the batch rolls.

## Consequences

- Apps in the same genre (most are Console) still feel related — intended. The fix
  targets *cross-genre* sameness, not all similarity.
- `sport-intelligence-hub` becomes the canonical **Signal** reference (formalize its
  existing tokens; do not rebuild). `gaming-os`/`studioverse` are near-conformant
  **Arcade** already (minimal migration). `discordium` keeps its 4 in-app themes,
  mapping chrome to Arcade.
- One new token axis set per persona (`--radius`, `--border-weight`, `--shadow`,
  `--font-display`/`--font-body`/`--font-mono`, `--density`, `--motion`). `@chrysa/ui`
  primitives must read these instead of hard-coding brutalist values.
- The brutalist campaign's *merged* work is not reverted wholesale: Arcade apps keep
  most of it; Console/Editorial/Signal apps relax it per the migration weights in §2.
- The Notion epic is retitled from "Neon Brutalist re-skin" to "Design personas
  migration"; per-app tasks are re-scoped to a target persona.

## Alternatives considered

- **Fix display/ergonomics bugs only, keep uniform brutalism.** Rejected: leaves the
  identity root cause (one skin) intact.
- **Fully bespoke design per app.** Rejected: maximizes identity but abandons shared
  tooling, multiplies maintenance across 16 repos, and re-creates the pre-2026-06
  divergence the system was built to solve.
