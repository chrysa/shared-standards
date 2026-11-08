# <APP_NAME> — Design contract

> Product design contract. Rule: `standards/rules/design.md` · method and acceptance criteria:
> `shared-standards/docs/DESIGN-CONTRACT.md` · design system: `shared-standards/docs/DESIGN-SYSTEM.md`.
> Read it before any interface, component, style, navigation, interaction or asset work, and
> update it in the same change.
>
> Status of every statement: **[implemented]** with a link to the code or asset ·
> **[decided]** with who and when · **[proposed]** not yet agreed. A mock-up, a plan or a
> proposal is never described as shipped. Delete the guidance lines in `<…>` once filled.

## 1. Surface and status

- **Surface:** <web app · Django Admin · native/overlay app · browser/editor extension ·
  interactive TUI · game menu/HUD · UI library · configured dashboard>
- **Lifecycle:** <shipped · prototype · planned · migrating to <X> · retired>
- **Detailed specs:** <links to nested specs such as `frontend/DESIGN.md`, journey docs, or
  "none". A statement lives in one file only — link, do not copy.>

## 2. Users, devices and priority tasks

| User | Context and device | Priority tasks (three at most) |
| ---- | ------------------ | ------------------------------ |
| <who> | <where, which device or window, how often> | <task 1 · task 2 · task 3> |

<For each main view: the one primary action a user must be able to identify at a glance.>

## 3. Journeys and navigation

- **Journeys:** <J1 — name: start → steps → success signal → failure and recovery path.
  Keep two to four representative journeys here; link longer ones.>
- **Information architecture:** <primary objects, navigation model, route/URL or window map,
  where each priority task lives.>
- **Density:** <compact · comfortable — and why it fits the content.>

## 4. Identity

- **Brand brief:** <link `BRAND-BRIEF.md` (from `templates/brand-brief.template.md`) or a short
  summary: job, audience, three mood words, metaphor.>
- **Why this identity fits this product:** <the reasoning, not adjectives.>
- **Signature element:** <the one memorable device and where it lives.>
- **References:** <inspirations and what was adapted. No third-party logo, proprietary
  typeface, trade dress or layout is copied.>

## 5. Tokens and components (owned elsewhere)

Token values live once, in code. This section links them and states how to use them.

| Concern | Source of truth | Rules of use |
| ------- | --------------- | ------------ |
| Colour roles and themes | <path, e.g. `src/styles/theme.css`> | <roles, light/dark, contrast pairs> |
| Typography | <path> | <roles: display · title · body · caption · data> |
| Spacing, grid, breakpoints | <path> | <scale, grid, max widths> |
| Shape and elevation | <path> | <radius, borders, shadows> |
| Motion | <path> | <durations, easing, entrance (FE-053)> |
| Components | <library or folder> | <variants; when to use which> |

- **Shared contract:** <`contract.css` imported: yes/no + path · `@chrysa/ui` contract honoured: yes/no>
- **Design debt and drift:** <where code and this contract disagree.>

## 6. Interaction and states

- **Component states:** <default · hover · focus-visible · active · disabled · loading · error.>
- **Action feedback:** <what the user sees for success, failure and pending work.>
- **Forms:** <validation timing, error placement and wording; input is kept after an error.>
- **Data states:**

  | State | Where it appears | Behaviour |
  | ----- | ---------------- | --------- |
  | Loading | | <shape-accurate skeleton or progress> |
  | Empty | | <explains why, offers the next action> |
  | Error | | <says what happened and what to do, with retry> |
  | Offline / backend unreachable | | <banner, disabled actions, input kept> |
  | Stale data | | <how age is shown> |
  | Reconnect | | <backoff, refetch, cleared banner> |

- **Real-time:** <what updates live, and how focus, input, selection, scroll and control
  positions are preserved during an update.>
- **Motion:** <entrance effect for views, panels and new items (FE-053); transitions; the
  reduced-motion behaviour.>

## 7. Responsive and support conventions

<Breakpoints or window sizes tested, touch target size, host or platform conventions to follow
(Django Admin, Qt, VS Code, browser extension, game engine, terminal), and what must not be
imposed (for example, no browser layout inside a native host).>

## 8. Accessibility

- **Target:** <WCAG 2.1 AA for web content (canon floor), or the platform accessibility API and
  its checks for native surfaces.>
- **Keyboard:** <focus order, shortcuts, escape and trap rules.>
- **Perception:** <contrast pairs verified, status never by colour alone, text scaling.>
- **Assistive technology:** <accessible names, live regions, screen-reader pass on core flows.>

## 9. Assets

| Asset | Source or generator | Author | Licence and attribution | Permitted use | Formats and variants | Location |
| ----- | ------------------- | ------ | ----------------------- | ------------- | -------------------- | -------- |
| <font / icon set / image / logo> | <URL or tool + prompt reference> | | <SPDX id; attribution text> | | <SVG, WOFF2, sizes> | <path> |

<Prefer local, optimised assets. A generated asset is not assumed free of third-party rights:
record the tool, its terms and any check done.>

## 10. Acceptance criteria and evidence

- **Criteria:** <the observable checks from `DESIGN-CONTRACT.md` that apply to this support,
  adapted to the priority tasks.>
- **Evidence log:**

  | Date | Change | Checks run (tool, sizes, modes) | Result | Not run, and why |
  | ---- | ------ | ------------------------------- | ------ | ---------------- |

## 11. Open choices, known gaps and maintenance

- **Open choices:** <each with a proposal and its rationale, marked [proposed].>
- **Known gaps:** <documented differences between this contract and the implementation.>
- **Maintenance:** <owner; update this file with every UI change; review trigger.>
