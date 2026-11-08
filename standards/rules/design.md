<!-- GENERATED from standards/STANDARDS.chrysa.md by scripts/gen_agent_views.py — do not edit.
Canonical source of truth is the canon; edit there, then run `make gen-agent-views` to regenerate every view.
-->
# Design system

> Detail for the slim core in `CLAUDE.md`. **Generated** from `standards/STANDARDS.chrysa.md` — do not edit here; edit the canon and regenerate.

- **Before UI work, read the product's `DESIGN.md` and the specs it links.** Any change to an
  interface, component, style, navigation, interaction or asset starts from the repository's root
  `DESIGN.md` (and the detailed specs it links, e.g. `frontend/DESIGN.md`) and keeps them true in
  the same change. No agent loads a file because of its name: this rule is the pointer, delivered
  through the generated views, so repository instructions add at most the location of a spec the
  root file does not already link — never a copy of the contract. A repository without a
  human-facing surface has no `DESIGN.md`. Detail: *Design system* below and
  `docs/DESIGN-CONTRACT.md`.

## Design system

**Every product with a human-facing interface keeps a versioned `DESIGN.md` contract.** A
repository that ships, prototypes or actively builds such a surface — web app, Django Admin
customisation, native or overlay app, browser/editor extension, interactive TUI, game menu/HUD,
UI library, configured dashboard — keeps a root `DESIGN.md` started from
`templates/DESIGN.template.md`. A repository without one needs no placeholder; a retired or
migrating surface records that status instead of new requirements. The contract:

- **Starts from the product, not an aesthetic** — users, devices, priority tasks, journeys and
  navigation come first; the visual identity is then chosen for that product and justified (the
  brand-brief method in `docs/DESIGN-SYSTEM.md`). No uniform dashboard, palette or library is
  imposed across products. Public `DESIGN.md` catalogues and other references are inspiration
  only: no third-party logo, proprietary typeface, trade dress or layout is copied.
- **Owns no token values** — colours, type, spacing, radii, motion and component variants live
  once, in code (CSS variables, theme files, `@chrysa/ui`, engine assets); `DESIGN.md` links that
  source and records intent and usage rules. Machine-readable token front matter (the Google
  `DESIGN.md` format) is allowed only when the file is the declared source and the code tokens
  are generated from it. A UI library owns a component contract; its consumers keep their own
  identity and journeys.
- **Separates facts from intent** — each statement is marked *implemented* (with a source
  link), *decided* (by whom, when) or *proposed*; known gaps and open choices are listed, never
  presented as shipped.
- **Turns "modern and ergonomic" into observable criteria** — the acceptance list of
  `docs/DESIGN-CONTRACT.md`, adapted to the support: identifiable primary action, predictable
  navigation, density fitted to the content, explicit forms that keep input after an error,
  keyboard use with visible focus, understandable action feedback, behaviour across screen or
  window sizes, functional motion with reduced-motion support, and loading / empty / error /
  offline / stale-data / reconnect states.
- **Records asset provenance** — source or generator, author, licence, required attribution,
  permitted use, formats and location for every font, icon, image and generated asset; assets
  are served locally where feasible. A generated asset is not assumed free of third-party rights.
- **Is one entry point** — the root file may link detailed specs kept next to the frontend
  (`frontend/DESIGN.md`, `web/DESIGN.md`, …); a statement lives in one of them, never both.
- **Ships proof** — a UI change updates the contract and records what was verified (journey,
  viewport or window sizes, keyboard, contrast, failure states, reduced motion) and what could
  not be run. Static lint — `prism-ai-lint` included — checks that the document is well-formed
  and its references resolve; it does not certify usability, visual quality or accessibility.

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
- **Standardised, functional motion** — durations and easing are tokens (e.g. 150/250 ms);
  motion explains a change (state transition, feedback, arrival of content) and never decorates.
  Interfaces are **dynamic: content is introduced with a basic entrance effect** — a view, panel,
  list or newly arrived item appears with a short fade and/or small translate (opacity and
  transform only, ≤ 250 ms per element, a stagger capped so a group settles within 400 ms). An
  entrance never delays interactivity, never shifts layout, and is not replayed when content
  already on screen refreshes. Under `prefers-reduced-motion` (or the platform's reduce-motion
  setting) it becomes instant or a plain cross-fade. Detail: annexe `FRONTEND.md` FE-053.
- **Mobile-first responsive** — mobile-first design, breakpoints from tokens, touch targets
  **≥ 44 px**, no fixed widths.
- **Design ↔ dev handoff contract** — design ships exported tokens, component specs (measures,
  states, behaviours) and edge cases; dev consumes the tokens, never redefines the values.
