# DESIGN.md — the product design contract

> How a chrysa product designs, documents and verifies its interface. The **rule** is in the canon
> (`standards/STANDARDS.chrysa.md`, *Design system*, generated into `standards/rules/design.md`);
> this guide is the **method**, the **acceptance criteria** and the **adoption** notes. The
> per-repo template is [templates/DESIGN.template.md](../templates/DESIGN.template.md); the shared
> token contract and the brand-brief method are in [DESIGN-SYSTEM.md](DESIGN-SYSTEM.md); detailed
> UI rules are in [UX-UI-GUIDELINES.md](UX-UI-GUIDELINES.md) and annexe `FRONTEND.md`.

## 1. What the contract is — and is not

A `DESIGN.md` states, for one product: who uses it and for what, how they move through it, what
it looks like and why, where its tokens and components are defined, how it behaves in every
state, which assets it ships under which licence, and what was verified. It is versioned with the
code and updated in the same change as the UI.

It is **not** a token store (values live once, in code), a mood board, a brand book copied from
another company, or proof of quality. Every statement carries its status:

| Marker | Meaning | Required evidence |
| ------ | ------- | ----------------- |
| **[implemented]** | the code does this today | a link to the file, component or asset |
| **[decided]** | agreed, not built yet | who decided, when (ADR, issue, PR) |
| **[proposed]** | a recommendation awaiting a decision | the rationale and the alternatives |

A plan or mock-up is never described as shipped. When the contract and the code disagree, the
gap is written down in *Known gaps* — the contract is not edited to hide it.

## 2. Which repositories need one

A repository needs a contract when it ships, prototypes or actively builds a human-facing
surface. Classify by what the repository **actually contains**, not by its name:

| Surface | Contract focus | Do not impose |
| ------- | -------------- | ------------- |
| Web app / SPA / site | journeys, IA, tokens, states, responsive, WCAG 2.1 AA | a dashboard shell on a content site |
| Django Admin customisation | admin conventions, list/detail density, actions, permissions feedback | a custom SPA look inside the admin |
| Native or overlay app (Qt/PySide, Tauri, Electron) | window sizes, focus stealing, always-on-top and click-through, OS accessibility API | browser layouts, web-only criteria |
| Browser or editor extension | host theme and conventions, popup size, keyboard | a brand that fights the host |
| Interactive TUI / CLI review | 80-column readability, colour never alone, `NO_COLOR`, exit codes, machine output | motion, web contrast numbers |
| Game menu / HUD | controller and keyboard navigation, readability at distance, safe areas, photosensitivity, skippable motion | web layout grids |
| UI library | the component contract: variants, states, props, a11y behaviour, token names | an identity on its consumers |
| Configured dashboard (Home Assistant, Homepage) | information architecture of cards and views, naming, states of devices or services | rewriting the upstream product's UI |

A library without a UI, a backend service, an automation or a pure CLI with plain output needs
**no** `DESIGN.md` — no placeholder. A surface that is being retired or migrated records that
status and points at its successor; it does not receive new requirements (for example, a product
migrating to another engine documents the migration, not a redesign of the retired part).

## 3. Method

Run these steps in order for a new surface, and for any change that alters a journey or the
identity. Small changes inside an agreed contract start at step 7.

1. **Users, devices and tasks** — name the users, where and on what they work, and their three
   priority tasks. Output: §2 of the contract.
2. **Existing surface and constraints** — read the code, current specs, host conventions,
   performance budgets and the assets already present. Output: facts marked [implemented], gaps.
3. **Journeys and information architecture** — two to four representative journeys with their
   failure and recovery paths; the primary objects; the navigation model. Output: §3.
4. **Compare directions when the choice is open** — two or three visual directions, each tied to
   the brand brief (job, audience, mood words, metaphor). Show each on the same representative
   screen. References are inspiration, never copied. Output: [proposed] directions.
5. **Choose an identity for this product** — record the decision, who took it and why it fits
   the product better than a generic shell. Output: §4 [decided].
6. **Formalise tokens, components, behaviours and assets** — token names and their single source
   in code, component variants and states, motion, asset provenance. Output: §5–§9.
7. **Implement one representative journey end to end** — real data shapes, every state.
8. **Verify the rendered result** — in the browser, app or engine: §4 below, with evidence.
9. **Correct before generalising** — fix what the verification found, update the contract, then
   extend to the other screens.

An agent that finds a missing choice **proposes** it with its reasoning and marks it [proposed];
it does not present its own preference as a decision.

## 4. Observable acceptance criteria

"Modern and ergonomic" means these checks pass on the product's support. Each one is observable
by a person or a test; adapt the method to the surface (§2).

| Criterion | Observable check | How to verify |
| --------- | ---------------- | ------------- |
| Primary action identifiable | each main view has one visually dominant action matching a priority task | screenshot review; first-time user test |
| Predictable navigation | the current location is shown; the same control always does the same thing; back and reload keep the place | keyboard + reload walk-through |
| Density fitted to content | expert data views are compact and scannable; occasional flows are comfortable | review at the real data volume |
| Explicit forms | labels visible, required fields marked, errors next to the field saying what to fix, **input kept after an error** | submit invalid data, read errors, fix one field |
| Keyboard and visible focus | every action reachable by keyboard, logical order, no trap, focus always visible | keyboard-only pass; axe |
| Understandable feedback | every action shows pending, success or failure within 100 ms; failures say what to do | inject a failure |
| Screen and window sizes | no loss of content or function at the tested sizes (web: 320 px to wide, 400 % zoom) | Playwright viewports; manual resize |
| Functional motion | entrance for new content (FE-053), transitions that explain change; nothing blocks input; reduced motion honoured | run with `reducedMotion: "reduce"` |
| Loading | shape-accurate placeholder, no layout shift | throttled network; CLS budget |
| Empty | explains why and offers the next action | empty fixture |
| Error | says what happened and what to do, with retry | API error fixture |
| Offline / unreachable | persistent banner, destructive actions disabled, input kept | offline emulation; 503 |
| Stale data | age shown when data may be old | freeze the clock or the feed |
| Reconnection | bounded backoff, refetch, banner cleared | drop and restore the connection |
| Live updates preserve the interaction | focus, typed input, selection, scroll and control positions do not move during an update | update data while typing and scrolling |
| Contrast and non-colour status | text ≥ 4.5:1 (3:1 large), status also by text or icon | contrast tool; greyscale screenshot |
| Long and numerous data | long labels wrap or truncate with full text available; hundreds of rows stay usable | long-string and large fixtures |

Record what ran, at which sizes and modes, and what could not run, in the contract's evidence
log. Static lint is never evidence for these rows.

## 5. Agents and loading

No agent loads a file because it is named `DESIGN.md`. What Claude Code actually loads
([memory docs](https://code.claude.com/docs/en/memory)):

- `CLAUDE.md` / `.claude/CLAUDE.md` (and `AGENTS.md` when there is no `CLAUDE.md`) in the working
  directory and above, at launch; `CLAUDE.md` or `AGENTS.md` in a subdirectory when Claude reads a
  file there.
- `@path` imports are expanded **at launch with the file that imports them** (relative to the
  importing file, four hops at most): an import does not save context.
- `.claude/rules/*.md` without `paths` load at launch; with `paths`, when Claude reads or edits a
  matching file.

The chrysa wiring follows from this:

1. **The pointer is generated, not copied.** The canon rule *Before UI work, read the product's
   `DESIGN.md` and the specs it links* is in the generated core of every view (`CLAUDE.md`,
   `AGENTS.md`, Copilot) — one line, one source. Repositories do not paste their own copy.
2. **The contract loads on demand.** An agent reads `DESIGN.md` when it starts UI work. Do not
   `@DESIGN.md`-import it: that loads the whole contract in every session, UI or not. An import is
   justified only for a very small contract in a repository whose work is almost all UI.
3. **Repositories outside the distribution keep one local pointer.** The standards distribution
   serves `status: dev` repositories of `repos.yml`; forks, `non-dev` repositories, repositories
   absent from `repos.yml` and Forge-Stack-Workshop tools do not receive the generated line. They
   carry the pointer once, in the file Claude Code loads (`CLAUDE.md` if it exists, else
   `AGENTS.md`) — never in both.
4. **Nested specs are linked from the root contract.** A repository instruction adds a location
   only when a spec is not reachable from the root `DESIGN.md`.
5. **Optional path-scoped trigger.** A repository may add a `.claude/rules/` file with `paths`
   matching its UI files (`src/**/*.{tsx,css}`) whose only content is the pointer: it loads when
   Claude touches those files, at no cost otherwise.

**Claude Design** (claude.ai/design, Anthropic Labs research preview) is a separate product: it
builds a design system from a codebase, design files or an uploaded `DESIGN.md`, produces
prototypes and hands a bundle to Claude Code. **Claude Code** works in the repository and follows
its instruction files. Use Claude Design to explore directions (method step 4); bring the chosen
tokens back into the code's single source, and keep the repository contract as the reference.

## 6. Assets: provenance and licences

Every font, icon set, illustration, photo, logo and generated image is listed in §9 of the
contract with: source or generator, author, licence (SPDX id) and attribution text, permitted
uses, formats and variants, location in the repository, and the optimisation applied.

- Prefer local, optimised files: SVG for icons and logos, WOFF2 (subset) for fonts, AVIF/WebP for
  images; no runtime hotlinking to third-party CDNs where a local copy is allowed.
- Reuse what the fleet already ships (`@chrysa/ui`, an existing icon set) before adding a source.
- Fonts: open licences (SIL OFL) or the system stack; never a proprietary brand typeface.
- A **generated** asset records the tool, model, date and prompt reference, and the tool's terms.
  Generation is not a guarantee of rights: check for resemblance to existing marks or characters
  before use.
- No third-party logo, mascot, trade dress or screenshot is used as a product's own identity.

## 7. External `DESIGN.md` catalogues

Reviewed 2026-11-08: [VoltAgent/awesome-claude-design](https://github.com/VoltAgent/awesome-claude-design)
and its sources.

- **What it is:** a README and an MIT licence — no design file is stored in the repository. Its
  68 entries link to pages on `getdesign.md`, each described as "inspired by" a named company
  (Sentry, BMW, Ferrari, Tesla, …), with a disclaimer that they are not official or endorsed and
  that users must respect each company's trademarks and brand policies. Seven commits by one
  author, created 2026-04-18, last pushed 2026-06-20. The linked files' own licence is not stated
  in the repository; the sister repository `VoltAgent/awesome-design-md` (MIT, 84 folders, active
  in October 2026) holds copies.
- **Format:** nine visual sections (visual theme, colour roles, typography, components, layout,
  depth, do's and don'ts, responsive, agent prompt guide), written for Claude Design to scaffold a
  UI kit. The concept comes from Google Stitch; the open specification
  [google-labs-code/design.md](https://github.com/google-labs-code/design.md) (Apache-2.0, version
  *alpha*) puts **normative token values in YAML front matter** with prose rationale and ships a
  linter (`npx @google/design.md lint`).
- **What it brings:** a shared vocabulary of sections, and the useful idea of keeping the rule and
  its rationale next to each other so an agent can decide unseen cases.
- **Limits:** visual-only (no users, tasks, journeys, states, accessibility, assets or evidence);
  brand imitation by construction; unclear licence of the linked files; thin maintenance; aimed at
  Claude Design, not at a repository's agents; embedded token values conflict with a single source
  of truth in code.
- **How chrysa uses it:** as inspiration during method step 4 only. A catalogue file is never a
  product's contract, and no catalogue brand's logo, typeface or layout is reproduced. Token front
  matter is allowed only when `DESIGN.md` is the declared source and code tokens are generated from
  it (canon).

## 8. Tooling

- **`prism-ai-lint`** (generic, organisation-neutral) reports four distinct facts about any
  `DESIGN.md`: *present* (bounded discovery that skips dependency, build, cache, hidden and
  git-ignored trees and never follows a symlink out of the project), *analysed* (`@` imports,
  local links resolved from the contract's folder, commands against the nearest
  `Makefile`/`package.json`, an on-demand size budget), *referenced* (`DESIGN_UNREFERENCED` when no
  instruction file points to it) and *loaded at launch* (`DESIGN_ALWAYS_LOADED` for an import from
  an always-loaded file). It never requires, edits or style-lints a contract and judges neither
  the design nor its accessibility.
- **`scripts/audit-design-conformance.sh <app-dir>`** checks brand-theme conformance (token names,
  `contract.css` import, `DESIGN.md` and `BRAND-BRIEF.md` present).
- **Browser verification** — Playwright (viewports, keyboard, `reducedMotion`), axe, Lighthouse,
  then a manual pass: the only evidence for §4.

## 9. Generators and new products

- **Template:** copy `templates/DESIGN.template.md` to the repository root as `DESIGN.md` when the
  first human-facing surface is started; fill §1–§3 before choosing an identity.
- **`project-init`:** its `frontend` profile is the natural place to require the contract for new
  UI repositories. [proposed]
- **Forge-Stack-Workshop generators** are independent tools: they may scaffold a neutral
  `DESIGN.md` entry point for generated apps, without any chrysa-specific policy.

## 10. Adoption checklist

- [ ] The repository has a human-facing surface (§2); otherwise stop — no file.
- [ ] Existing specs were read and kept; nested specs are linked, not copied.
- [ ] §1–§3 filled from users, tasks and the current code; statuses marked.
- [ ] Token and component sources linked; no value duplicated.
- [ ] States, motion (FE-053), live-update behaviour (FE-080), responsive and accessibility filled
      for this support.
- [ ] Assets listed with provenance and licence.
- [ ] Evidence log states what was verified and what was not.
- [ ] `prism-ai-lint` reports no `DESIGN_UNREFERENCED` / `DESIGN_DEAD_LINK` for the contract.
