<!-- GENERATED from standards/STANDARDS.chrysa.md by scripts/gen_agent_views.py — do not edit.
Canonical source of truth is the canon; edit there, then run `make gen-agent-views` to regenerate every view.
-->
# Design system

> Detail for the slim core in `CLAUDE.md`. **Generated** from `standards/STANDARDS.chrysa.md` — do not edit here; edit the canon and regenerate.

## Design system

Every repository with a graphical user interface MUST maintain a root `DESIGN.md` as its
versioned product design contract. Repositories without a graphical interface do not need
an empty placeholder. Existing shared tokens and component libraries remain canonical;
`DESIGN.md` references them rather than duplicating their values.

- Define users, priority tasks, navigation, visual identity, semantic token sources,
  typography, spacing, responsive behaviour, component variants and interaction states.
- Specify loading, empty, error, offline, stale-data and reconnect states. Real-time updates
  preserve input, keyboard focus and scroll position.
- Reference the applicable accessibility standard, UX acceptance scenarios, asset provenance
  and licences; prefer locally served assets. External design inspirations are not official
  brand systems and must be adapted into an original product identity.
- Agent instructions (`AGENTS.md` / `CLAUDE.md`) MUST explicitly direct agents to consult
  `DESIGN.md` before UI work. It is not automatically loaded by its filename. Prefer an
  on-demand reference; use a Claude `@DESIGN.md` import only when always-loaded context is
  justified. Keep detailed journeys and acceptance scenarios in linked documents.
- Update the contract with UI changes and verify representative journeys in a browser,
  including keyboard, responsive layouts and failure states. Static lint cannot certify
  visual quality, ergonomics or accessibility compliance.
- `prism-ai-lint` MUST recognise an existing `DESIGN.md` as an agent-consumable instruction
  document at the root or in nested UI directories, checking its size, imports and dead
  local references. Generic Prism must not
  impose CHRYSA policy or require a design file in repositories without a UI.


Every human-facing surface is built from a shared design system — no ad-hoc style values in
components. This complements *dark mode + WCAG 2.1 AA* and the `ui-ux` skill.

- **Design tokens are the single source of style** — colours, typography, spacing, radii,
  shadows, z-index live as tokens (JSON/CSS vars) consumed by code. **No** hardcoded style
  literals in components (mirrors *no hardcoded constants*).
- **Versioned brand kit** — primary/secondary/semantic palette, **≤ 2 type families**, logo
  (variants + clear space), one icon set. Defined and versioned, not per-repo reinvented.
- **Living component library** — reusable components with documented states and variants
  (Storybook or equivalent); one canonical implementation per component.
- **Systematic spacing scale & grid** — spacing on a fixed scale (4/8 px base), shared grid
  and breakpoints; no arbitrary margins.
- **Defined type hierarchy** — explicit type scale (size, weight, line-height, tracking) with
  named roles (`display/title/body/caption`), never ad-hoc sizes.
- **Systematic interaction states & feedback** — every interactive element exposes
  hover/focus/active/disabled; every action gives visible feedback (< 100 ms); visible keyboard
  focus is mandatory.
- **Consistent UX writing** — voice-and-tone guide; error messages say what to do (no raw
  codes); action-oriented labels and CTAs; terminology aligned to the domain glossary.
- **Numbers are displayed with a space thousands separator** — every human-facing number
  (`1 234 567`, `12 500 €`) groups thousands with a **space**, on every surface: frontend,
  backoffice, generated documents, reports, and CLI output. The separator is a **non-breaking
  space** (`U+202F` narrow no-break, or `U+00A0`) so the number never wraps mid-value; the
  decimal mark stays the locale's own. This is a **display** rule only — stored, serialised,
  logged, and API-transported numbers stay raw (unseparated), and formatting happens at the
  view boundary through a shared formatter, never by hand per component (mirrors *no code
  duplication*). Identifiers, years, ports, and version numbers are not quantities and are
  never separated.
- **Standardised motion** — tokenised durations and easing (e.g. 150/250 ms); animation is
  functional (state transition, feedback), never gratuitous; honours `prefers-reduced-motion`.
- **Mobile-first responsive** — mobile-first design, breakpoints from tokens, touch targets
  **≥ 44 px**, no fixed widths.
- **Design ↔ dev handoff contract** — design ships exported tokens, component specs (measures,
  states, behaviours) and edge cases; dev consumes the tokens, never redefines the values.
