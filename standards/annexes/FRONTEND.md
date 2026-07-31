# Annexe FE — Frontend (TypeScript · React)

> **Normative annexe.** Authority: `standards/STANDARDS.chrysa.md`. This file details the
> frontend rules the distributed socle states in short form; where the two disagree, the
> socle wins. Rule ids (`FE-nnn`) are stable — never reuse an id for a different rule.
> Applies to the `frontend` project profile and to any repo shipping a React surface.

## FE-000 — Stack (settled, do not relitigate)

React 19 · TypeScript 7 · Vite 8 · shadcn/ui + Tailwind CSS · TanStack Query + Zustand ·
react-i18next (FR + EN from V1). See the socle's stack table.

______________________________________________________________________

## 1. TypeScript

### FE-010 — Minimum compiler configuration

Every `tsconfig.json` enables, without exception:

```jsonc
{
  "compilerOptions": {
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "exactOptionalPropertyTypes": true,
    "noImplicitOverride": true,
    "noImplicitReturns": true,
    "useUnknownInCatchVariables": true,
    "isolatedModules": true,
    "verbatimModuleSyntax": true // when the toolchain supports it
  }
}
```

### FE-011 — Typing rules

- No implicit `any`. An explicit `any` is localised, justified by a comment, and never
  crosses a module boundary.
- `unknown` is preferred to `any` at boundaries.
- Double assertions (`as unknown as`) are restricted to documented adapters.
- External data is **validated at runtime** (schema validator) even when static types exist —
  a type is a compile-time claim, not a guarantee about the wire.
- Contract types are **generated or validated from OpenAPI / AsyncAPI / a published schema**,
  never hand-copied from the provider.

### FE-012 — Dependency & workspace hygiene

- Exactly **one committed lockfile**; CI installs are frozen (`--frozen-lockfile`).
- No `latest` dependency in a reproducible build.
- Large workspaces use TypeScript project references (or equivalent enforced boundaries).

______________________________________________________________________

## 2. React — layering

React is a **presentation layer**, not the domain.

### FE-020 — Directory structure

```text
src/
├── domain/
├── application/
├── infrastructure/
│   └── api/
└── presentation/
    ├── components/
    ├── features/
    ├── pages/
    └── routes/
```

### FE-021 — Layering rules

- `domain/` and `application/` **never import React** — no hook, no JSX, no React type.
- No `fetch`, browser storage, or vendor SDK inside `domain/`.
- Significant business rules do not live in components.
- Generic UI components know nothing of the domain; features are organised by business
  capability, not by technical kind.

### FE-022 — Component rules

- Components and hooks stay pure; props and state are immutable.
- Derived state is **computed**, never duplicated into another state.
- `useEffect` synchronises with an **external** system — it does not orchestrate local
  business logic. User events are handled in handlers.
- `StrictMode` is enabled on every new application.

______________________________________________________________________

## 3. Frontend architecture (fleet conventions)

### FE-030 — Single API client

One API client singleton per app. Components never call `fetch`/`axios` directly.

### FE-031 — Service layer

A service layer sits between UI and network: UI calls services, services call the API
client. A service performs **no navigation** and produces no UI side effect.

### FE-032 — One cache library for all server state

All server state goes through the single cache library (TanStack Query) — no parallel
hand-rolled cache, no server data duplicated into a client store.

### FE-033 — Container / presentational split

Containers own data and state; presentational components own rendering. Pages stay thin
(composition + routing), holding no business logic.

### FE-034 — Root error boundary

An error boundary at the root, reporting to the observability backend (Sentry). An
uncaught render error must never yield a blank page.

### FE-035 — Colocated provider + hook, typed context guard

A context ships with its provider and its consumer hook in one module; the hook throws an
explicit error when used outside the provider.

### FE-036 — Protected routes via symmetric wrappers

Route protection is a wrapper, applied symmetrically (a "requires-auth" wrapper has an
"anonymous-only" counterpart). No inline redirect logic scattered in components.

### FE-037 — loading / error / empty triad

Every container handles the three states explicitly. A container that only handles the
happy path is a defect.

### FE-038 — Global progress indicator

A single **full-page loading indicator** (a global progress bar / top-loader) provided by the
**root shell/layout**, driven by the API client (request in flight) — not re-implemented per
screen. It shows on **initial application load** and on **navigation transitions that must fetch
data before the view can render**, and it **complements** the per-container local skeletons of
FE-037/FE-070 rather than replacing them (global = "the app is working"; local = "this block is
arriving"). It toggles `aria-busy="true" → "false"` on the region it governs and honours
`prefers-reduced-motion`. A frontend Definition of Done includes this global loading state.

### FE-039 — Navigation never reloads

Navigation goes through the router (see the socle's *URL-addressable navigation*); a full
page reload as a navigation mechanism is a defect.

______________________________________________________________________

## 4. Frontend tests

### FE-040 — Mandatory test stack

**Vitest + Testing Library + MSW (or explicit fakes), present from the scaffold** — not
added later. The socle's *pytest only* rule governs Python; it does not exempt the frontend
from having tests.

### FE-041 — Test rules

- Test behaviour through the accessible tree (role/label), not implementation details.
- Network is mocked **at transport level** (MSW), not by stubbing the service layer, so the
  serialisation boundary is exercised.
- Stable selectors: prefer roles/labels; `data-testid` only when no accessible query fits.
- Every fixed bug ships a regression test.
- E2E (Playwright) covers **critical journeys only**. Its gate status is declared per repo in
  the local `CLAUDE.md` — the fleet default is **non-blocking** until the repo states otherwise.

______________________________________________________________________

## 5. Accessibility, design system, i18n

These are stated in the socle and are not restated here:

- Dark mode from V1 · WCAG 2.1 AA · Lighthouse a11y ≥ 90 · full keyboard navigation.
- Design tokens as the single source of style; no style literal in a component.
- UI state survives reload and focus; navigation is URL-addressable.
- i18n from V1 — **including error and fallback screens**, which are localised like any
  other surface (FE-050). Dates and numbers are formatted with the active locale (FE-051).

______________________________________________________________________

## 6. Environment & configuration

### FE-060 — Typed, validated environment variables

Environment variables are read once, validated against a schema at startup, and exposed as
a typed module. No `import.meta.env.X` scattered through the code, no untyped escape hatch.
This is the frontend half of the socle's *no hardcoded constants* rule.

______________________________________________________________________

## 7. Perceived performance

### FE-070 — Lazy loading with shape-accurate placeholders

Anything not needed for the first meaningful paint is **loaded lazily** — routes are
code-split, below-the-fold images carry `loading="lazy"`, heavy components mount on demand.

While the content loads, the container renders a **placeholder that matches the shape of the
final element** (skeleton blocks sized like the real rows, cards, or media), not a spinner and
not an empty area. The placeholder reserves the final dimensions, so arrival causes **no
layout shift** — width/height or `aspect-ratio` is set on media, and the skeleton occupies the
same box as the content it replaces.

This is the *loading* leg of the FE-037 triad made concrete, and it is what keeps CLS near
zero. Skeleton animation honours `prefers-reduced-motion`; a placeholder is marked
`aria-busy="true"` on its container so assistive tech announces the pending state rather than
reading empty boxes.

______________________________________________________________________

## Deferred (not canon yet)

Listed so they are not silently lost — these need an arbitration before becoming rules:
cache-key factory, centralised permission gating hook, single notification service,
route-level code splitting, systematic cache invalidation on mutation, single canonical
location per component, compiler-managed memoisation, single auth source of truth.
