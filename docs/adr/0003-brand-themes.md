# ADR 0003 — Per-app brand themes replace design personas

- **Status:** Accepted
- **Date:** 2026-06-22
- **Supersedes:** ADR 0002 (design-personas)

## Context

ADR 0002 replaced the single "Neon Brutalist" DNA with four design personas
(Console, Arcade, Editorial, Signal), allocating identity at **genre + a single
accent hue**. In practice this reproduced the very uniformity trap the 2026-06
design audit set out to fix:

- **Same root cause, one rung up.** 11 of 16 frontends map to **Console**, so they
  share the same persona axes and differ only by accent — structurally identical to
  the accent-only differentiation ADR 0002 rejected, just at the persona level.
- **Doctrine-heavy, little shipped.** The persona model produced extensive
  documentation (`docs/DESIGN-SYSTEM.md`) but few visibly distinct apps; the rules
  out-paced the delivered identity.
- **Reality gaps in the contract.** Two load-bearing claims in DESIGN-SYSTEM.md do
  not hold:
  - `@chrysa/ui` primitives are **class-name-only**. They do not read the semantic
    tokens or compose Tailwind utilities as DESIGN-SYSTEM.md asserts, so persona
    token axes never reached the components.
  - The "layout serves the project" IA rule had **no enforcing mechanism**, so
    layouts stayed generic regardless of persona.

The conclusion is that identity cannot be allocated at the genre level. It has to be
designed per app, over a contract that is small enough to actually hold.

## Decision

Adopt **per-app brand themes over a shared behavioral contract**, replacing the
persona model.

1. **Shared and immutable (the contract).**
   - WCAG 2.1 AA floor + the i18n floor (FR + EN).
   - `@chrysa/ui` class-name + behavior + prop API (the component contract, not its
     look).
   - The **names** of the semantic tokens. Names are fixed; values are free.

2. **Per-app (the brand theme).** Each app owns:
   - Every token **value** — color, shape, depth.
   - Fonts.
   - Motion personality.
   - A **signature element** unique to the app.
   - An **IA designed for the app's job**, not a generic genre layout.

3. **Identity is derived, not assigned.** Each app's brand is produced by a
   repeatable **brand-brief** method — 6 prompts that resolve to type, color, motion,
   and signature — rather than picking a genre persona off a shelf.

## Consequences

- **Stronger per-app identity.** Each app reads as its own product, not a recolored
  sibling.
- **More per-app design effort.** Identity now costs a brand brief per app instead of
  one persona pick; this is the deliberate trade.
- **The 3 already persona-migrated apps fold in retroactively.** `gaming-os`,
  `studioverse`, and `ai-aggregator` adopt the new model during rollout — each needs a
  brand brief + a signature element, and drops the `data-persona` attribute. No
  urgency; they migrate as the rollout reaches them.
- **`docs/DESIGN-SYSTEM.md` gets rewritten** around the contract + brand-theme split
  (a later task), correcting the `@chrysa/ui` and IA-enforcement claims above.
- **Conformance becomes a verifiable audit script** rather than prose doctrine — the
  contract is small and checkable (AA + i18n floor, token names present, signature
  element declared, IA not generic).
- **This is the 3rd revision of the system** — Neon Brutalist → Personas → Brand
  Themes.

## Alternatives considered

- **Keep personas, only fix the reality gaps.** Rejected: wiring tokens into
  `@chrysa/ui` and enforcing IA would make personas *work*, but leaves the identity
  root cause (11/16 apps share one persona) intact.
- **Fully bespoke design per app, no shared contract.** Rejected: maximizes identity
  but abandons the shared `@chrysa/ui` API and the AA/i18n floor, re-creating the
  pre-system divergence. The contract is precisely what keeps bespoke themes
  maintainable across the fleet.
