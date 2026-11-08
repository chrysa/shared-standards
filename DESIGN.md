# shared-standards — Design contract

> Contract for this repository's one human-facing surface, the **standards console**
> (`console/`). The fleet-wide design rules live in the canon (`standards/STANDARDS.chrysa.md`,
> *Design system*), the method in [docs/DESIGN-CONTRACT.md](docs/DESIGN-CONTRACT.md) and the
> template in [templates/DESIGN.template.md](templates/DESIGN.template.md) — they are not
> repeated here.
>
> Status: **[implemented]** links the code · **[decided]** names who and when ·
> **[proposed]** is not agreed yet. This file documents the console; it does not redesign it.

## 1. Surface and status

- **Surface:** local web app — FastAPI JSON API + React 19/Vite SPA. **[implemented]**
  ([console/README.md](console/README.md))
- **Lifecycle:** shipped as a local, single-operator tool. Monitoring data comes from the
  hosted guideline-checker server when configured.
- **Detailed specs:** none beyond this file and the console README.

## 2. Users, devices and priority tasks

| User | Context and device | Priority tasks |
| ---- | ------------------ | -------------- |
| Fleet owner / maintainer | Desktop browser on the workstation, own GitHub token, occasional sessions | 1. see each repo's status and compliance · 2. check or apply a standards distribution · 3. edit the canon and open a PR |

Primary action per view: **Fleet** — change a repo's status and save; **Distribution** — run
*check* (safe) before *apply*; **Standard** — submit the edit as a PR.

## 3. Journeys and navigation

- **J1 — Review the fleet:** open Fleet → scan compliance badges → open a repo on GitHub or
  change its status → save → row refreshes. Failure: an error banner shows the API message.
  **[implemented]** ([Fleet.tsx](console/web/src/pages/Fleet.tsx))
- **J2 — Distribute:** Distribution → optional repo subset → *check* or *apply* (apply asks for
  confirmation) → result banner → recent runs and open sync PRs. **[implemented]**
  ([Distribution.tsx](console/web/src/pages/Distribution.tsx))
- **J3 — Edit the canon:** Standard → edit → submit → banner with the opened PR.
  **[implemented]** ([Standard.tsx](console/web/src/pages/Standard.tsx))
- **Information architecture:** three top-level sections in a header tab bar
  ([Nav.tsx](console/web/src/components/Nav.tsx)), one content column (`max-w-5xl`).
- **Density:** compact tables — the content is a list of ~100 repositories scanned by an expert.

## 4. Identity

- A neutral operational tool: system font stack, blue primary, success/destructive roles, light
  and dark themes. **[implemented]** No brand brief exists; none is needed for a
  single-operator tool unless it is published. **[proposed]**

## 5. Tokens and components (owned elsewhere)

| Concern | Source of truth | Rules of use |
| ------- | --------------- | ------------ |
| Colour roles, themes | [console/web/src/index.css](console/web/src/index.css), mapped in [tailwind.config.js](console/web/tailwind.config.js) | semantic names only (`primary`, `muted`, `destructive`, `success`) |
| Typography | system stack in `index.css`; monospace for paths and identifiers | no ad-hoc sizes outside Tailwind's scale |
| Components | [console/web/src/components/ui/](console/web/src/components/ui/) | reuse `Button`, `Badge`, `Table`, `Select`, `Banner` |

- **Shared contract:** `contract.css` is **not** imported; token names follow the shadcn
  convention, not the brand-theme registry. Known drift. **[implemented]**

## 6. Interaction and states

- **Feedback:** mutations disable their button while pending; results show a `Banner`
  (`role="alert"` / `role="status"`). Per-row status saves show only ✓/✗. **[implemented]**
- **Data states:** loading is a text line; load errors show a banner on Fleet and Standard;
  Distribution shows no load-error state. No offline / stale / reconnect handling. **[implemented]**
- **Motion:** none. **[implemented]**

## 7. Responsive and support conventions

Desktop-first, single centred column; tables are not adapted to narrow widths. **[implemented]**

## 8. Accessibility

Labelled section navigation with `aria-current`, labelled per-row selects, live-region banners,
FR/EN switch. Contrast of the token pairs has not been measured in this pass.

## 9. Assets

No image, icon font or webfont is shipped; the header glyph is a Unicode character.

## 10. Acceptance criteria and evidence

- **Criteria:** the observable list in [docs/DESIGN-CONTRACT.md](docs/DESIGN-CONTRACT.md) §3
  applies; J1–J3 are the representative journeys.
- **Evidence log:**

  | Date | Change | Checks run | Result | Not run, and why |
  | ---- | ------ | ---------- | ------ | ---------------- |
  | 2026-11-08 | contract written from the code | source review of `console/web/src` | gaps listed in §11 | no browser run: documentation-only change |

## 11. Open choices, known gaps and maintenance

- **Known gaps (from the code, 2026-11-08):** active tab and theme are not persisted or
  URL-addressable (canon *UI state survives reload & focus*); per-row save feedback is a bare
  ✓/✗; Distribution lacks a load-error state; no API-down banner (FE-050); loading is text, not a
  skeleton (FE-070); `apply` uses `window.confirm`; no content entrance motion (FE-053).
- **Open choices [proposed]:** adopt `contract.css` names or record the console as exempt from
  the brand-theme registry; fix the gaps above in a scoped UI change with a browser check.
- **Maintenance:** console changes update this file in the same PR.
