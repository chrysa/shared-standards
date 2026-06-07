# UX / UI / Ergonomics Guidelines — chrysa ecosystem

> Source of truth for **every project with a human-facing surface** — not only web. That includes
> web apps, CLI/TUI tools, VS Code extensions, Discord bots, desktop/tray apps, 2D game UI, and
> conversational/agent interfaces. Sections 1–11 define the web baseline (React 19 + TS + Vite 6,
> shadcn/ui + Tailwind, TanStack Query + Zustand, react-i18next). **Section 12 extends the same
> ergonomics contract to non-web surfaces.**
> Non-negotiable everywhere: **clear feedback**, **error recovery**, **i18n FR+EN for user-facing copy**,
> and an **accessibility-equivalent** baseline (WCAG 2.1 AA on web; the closest equivalent per surface).
>
> Companion skill module: `.claude/skills/ui-ux/SKILL.md` (auto-invoked when building any UI/UX).
> Audit of adoption per project: `docs/UX-UI-SKILLS-AUDIT.md`.
> **Visual layer (the *look*): `docs/DESIGN-SYSTEM.md`** — the "Neon Brutalist" token
> contract + aesthetic DNA all web frontends adopt. This file owns ergonomics; that one owns visuals.

---

## 0. How to use this document

This is a **contract**, not a suggestion. Every project that ships a human-facing surface references
it from its `CLAUDE.md` under `## Skills` and is bound by the **Definition of Done** in section 11
(web) and the per-surface DoD in section 12.

- Preference vs. rule: items marked **RULE** must be satisfied; items marked **PREFER** are defaults you may override with a documented reason (`<repo>/DECISIONS.md`).
- When a surface cannot meet a RULE, that is a blocker — surface it, do not ship around it.
- **Pick your surface:** web → §1–§11. CLI, VS Code, Discord, desktop, game, agent → §12, which builds on the seven core principles in §1 (those are surface-agnostic).

---

## 1. Core principles

1. **Clarity over cleverness.** The user should never wonder what a control does or what state the system is in.
2. **One primary action per view.** Everything else is secondary or tertiary. If two actions compete, the design is wrong.
3. **Feedback for every action.** No action is silent: loading, success, and error states are part of the feature, not an afterthought.
4. **Forgiveness.** Destructive actions are confirmable and/or reversible (undo > confirm dialog where feasible).
5. **Consistency beats novelty.** Reuse existing patterns and components before inventing new ones.
6. **Accessibility is a baseline, not a feature.** A screen that fails WCAG 2.1 AA is not done.
7. **Performance is UX.** Perceived speed (skeletons, optimistic updates) matters as much as raw speed.

---

## 2. Design tokens

All visual values come from tokens. **RULE: no hard-coded hex colors, px spacing, or font sizes in components** — only token-backed Tailwind utilities or CSS variables.

### 2.1 Color — semantic, theme-aware

Use shadcn/ui's semantic CSS-variable convention. Components reference roles, never raw colors. This is what makes dark mode free.

```css
/* globals.css — HSL channels, light + dark */
:root {
  --background: 0 0% 100%;
  --foreground: 222 47% 11%;
  --primary: 222 47% 11%;
  --primary-foreground: 210 40% 98%;
  --muted: 210 40% 96%;
  --muted-foreground: 215 16% 47%;
  --destructive: 0 72% 51%;
  --destructive-foreground: 210 40% 98%;
  --border: 214 32% 91%;
  --ring: 222 47% 11%;
  --radius: 0.5rem;
}
.dark {
  --background: 222 47% 11%;
  --foreground: 210 40% 98%;
  --primary: 210 40% 98%;
  --primary-foreground: 222 47% 11%;
  --muted: 217 33% 17%;
  --muted-foreground: 215 20% 65%;
  --destructive: 0 63% 31%;
  --destructive-foreground: 210 40% 98%;
  --border: 217 33% 17%;
  --ring: 213 27% 84%;
}
```

```tsx
// ✅ semantic, theme-aware
<div className="bg-background text-foreground border border-border" />
<Button variant="destructive">Delete</Button>

// ❌ never
<div className="bg-[#0f172a] text-white" style={{ borderColor: "#e2e8f0" }} />
```

**Color rules**
- **RULE** Color is never the *only* carrier of meaning (status, errors, required fields use icon + text too). WCAG 1.4.1.
- **RULE** Define every semantic role for both `:root` and `.dark`. A token that exists only in light mode is a bug.
- **PREFER** a single accent/primary hue per app; reserve `destructive` strictly for irreversible/negative actions.

### 2.2 Spacing & sizing

- **RULE** Use the Tailwind 4px scale (`p-2` = 8px, `gap-4` = 16px…). No arbitrary `p-[13px]`.
- **PREFER** a 4/8px rhythm; vertical spacing between sections ≥ `space-y-6`.
- **RULE** Border radius from `--radius` (`rounded-md`/`rounded-lg`), consistent across the app.

### 2.3 Typography

- **PREFER** one display/sans family (e.g. Inter) loaded with `font-display: swap`.
- **RULE** Type scale is fixed: `text-xs` (labels/meta) → `text-sm` (body-dense) → `text-base` (body) → `text-lg`/`text-xl` (section) → `text-2xl`+ (page title). Do not introduce off-scale sizes.
- **RULE** Body line-height ≥ 1.5 (`leading-relaxed`/`leading-6`+), paragraph width ≤ ~75ch.
- **RULE** Respect the user's font-size — use `rem`, never fixed `px` font sizes that break zoom (WCAG 1.4.4: text must scale to 200%).

### 2.4 Elevation & motion

- **PREFER** shadows from a fixed set (`shadow-sm`/`shadow-md`/`shadow-lg`) tied to elevation meaning (card < popover < modal).
- **RULE** Honor `prefers-reduced-motion`: disable non-essential transitions/animations.

```css
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after { animation-duration: .001ms !important; transition-duration: .001ms !important; }
}
```

- **PREFER** transitions 150–250ms, `ease-out` for enter, `ease-in` for exit. Nothing animates longer than 400ms on interaction.

---

## 3. Layout & responsive

- **RULE** Mobile-first. Design the 360px viewport first, enhance upward with `sm md lg xl 2xl`.
- **RULE** No horizontal scroll at any breakpoint ≥ 320px.
- **PREFER** a max content width (`max-w-7xl mx-auto`) on wide screens; don't let text run edge-to-edge.
- **RULE** Tap/click targets ≥ 44×44px on touch (Apple HIG / Material). WCAG 2.2 AA minimum is 24×24px — treat 44px as the team default.
- **PREFER** CSS Grid for page scaffolding, Flexbox for component-internal layout.
- **RULE** Content reflows to a single column on mobile; nothing critical is hidden behind hover (no hover-only actions on touch).

**Breakpoint intent**

| Token  | Min width | Typical use                          |
|--------|-----------|--------------------------------------|
| (base) | 0         | phone portrait, single column        |
| `sm`   | 640px     | phone landscape / small tablet       |
| `md`   | 768px     | tablet, 2-column                     |
| `lg`   | 1024px    | laptop, sidebar + content            |
| `xl`   | 1280px    | desktop, multi-pane                  |
| `2xl`  | 1536px    | large desktop, capped content width  |

---

## 4. Components (shadcn/ui)

- **RULE** Use shadcn/ui primitives before building custom. They ship correct ARIA, focus management, and keyboard handling — do not reimplement.
- **RULE** When extending a primitive, keep its accessibility props (`aria-*`, `role`, focus trap) intact.
- **PREFER** a thin `components/ui/` (shadcn) + `components/` (app composites) split. No business logic in `ui/`.
- **RULE** Every interactive element has a visible, non-color focus indicator (`focus-visible:ring-2 ring-ring`). Never `outline: none` without a replacement. WCAG 2.4.7.

**Buttons & actions**
- One `variant="default"` (primary) per region. Use `secondary`, `outline`, `ghost`, `link`, `destructive` deliberately.
- Disabled buttons explain *why* (tooltip or inline helper) — never a dead-end.
- Async buttons show a spinner and disable to prevent double-submit; label stays readable (`aria-busy`).

**Forms**
- **RULE** Every input has an associated `<Label htmlFor>`. Placeholder is never a substitute for a label (WCAG 3.3.2).
- **RULE** Validate on blur or submit, not on every keystroke; show errors next to the field with `aria-describedby` + `aria-invalid`.
- **PREFER** `react-hook-form` + `zod`; mark required fields with text, not just `*`.
- Group related fields with `<fieldset>`/`<legend>`; preserve user input on error.

**Tables & lists**
- Provide empty, loading (skeleton), and error states for every data view (see §5).
- **PREFER** server-side pagination/virtualization beyond ~100 rows (TanStack Query keeps cache).
- Sortable/filterable columns expose state via `aria-sort` and are keyboard-operable.

**Overlays (dialog/sheet/popover)**
- **RULE** Trap focus, close on `Esc`, return focus to the trigger, and render an accessible name (`aria-labelledby`).
- Confirmation dialogs name the consequence ("Delete 3 projects? This cannot be undone.") and put the destructive action on the right with `variant="destructive"`.

---

## 5. State patterns (the four states)

**RULE: every data-driven view designs all four states explicitly.** A view that only handles "success with data" is incomplete.

| State    | What the user sees                                                            |
|----------|-------------------------------------------------------------------------------|
| Loading  | Skeleton matching final layout (not a bare spinner) for content; spinner only for short actions. |
| Empty    | Explains *why* it's empty + the primary next action ("No projects yet — Create one"). Never a blank box. |
| Error    | Plain-language cause + a recovery action (Retry). Never a raw stack trace or error code alone. |
| Success  | The data, with optimistic updates where safe.                                 |

```tsx
const { data, isPending, isError, refetch } = useQuery(...);
if (isPending) return <ListSkeleton rows={6} />;
if (isError)   return <ErrorState onRetry={refetch} message={t("errors.loadProjects")} />;
if (!data.length) return <EmptyState action={<CreateProjectButton />} />;
return <ProjectList items={data} />;
```

- **PREFER** optimistic mutations (TanStack `onMutate` + rollback) for instant feedback on low-risk writes.
- **RULE** Toasts confirm background outcomes (saved/failed); they never carry the *only* copy of critical info.

---

## 6. Accessibility — WCAG 2.1 AA (mandatory baseline)

This is the floor for every project. Items below map to specific success criteria.

**Perceivable**
- **RULE** Text contrast ≥ **4.5:1** (normal), ≥ **3:1** (large: ≥24px, or ≥18.66px bold). UI components & meaningful graphics ≥ 3:1. (1.4.3, 1.4.11)
- **RULE** Every meaningful image has `alt`; decorative images use `alt=""`. (1.1.1)
- **RULE** No information by color alone. (1.4.1)
- **RULE** Layout works at 200% zoom and 320px width without loss of content/function. (1.4.4, 1.4.10)

**Operable**
- **RULE** Full keyboard operability; logical tab order; no keyboard traps. (2.1.1, 2.1.2)
- **RULE** Visible focus on all interactive elements. (2.4.7)
- **RULE** Skip-to-content link; landmarks (`header/nav/main/footer`); one `<h1>` per page, ordered headings. (2.4.1, 1.3.1)
- **PREFER** target size ≥ 44px (24px is the WCAG 2.2 AA floor). (2.5.8)

**Understandable**
- **RULE** `<html lang>` set and updated on locale switch. (3.1.1)
- **RULE** Inputs have programmatic labels; errors are identified in text and described. (3.3.1, 3.3.2)
- **PREFER** consistent navigation and component naming across pages. (3.2.3)

**Robust**
- **RULE** Prefer native semantic HTML over ARIA. Use ARIA only to fill gaps, and keep `aria-*` state in sync. (4.1.2)
- **RULE** Dynamic updates announced via `aria-live` (e.g. toast region `aria-live="polite"`, errors `assertive`).

**Tooling** (wire into CI where the project has a UI)
- `eslint-plugin-jsx-a11y` (lint), `@axe-core/playwright` or `jest-axe` (automated checks), manual keyboard + screen-reader pass before merge. Automated tools catch ~30–40% — manual pass is **RULE**, not optional.

---

## 7. Dark mode (V1 requirement)

- **RULE** Implemented via the `.dark` class on `<html>` + the semantic tokens in §2.1. No per-component dark overrides scattered in markup.
- **RULE** Default to `prefers-color-scheme`, let the user override, persist the choice (Zustand + `localStorage`), and avoid flash-of-wrong-theme (set the class before first paint).
- **RULE** Both themes meet the §6 contrast ratios — verify dark separately; it is not automatic.
- **PREFER** `next-themes`-style provider or a small Zustand store; expose a toggle in a consistent location (top-right).

---

## 8. Internationalization (FR + EN from V1)

- **RULE** No hard-coded user-facing strings. All copy goes through `react-i18next` (`t("namespace.key")`). Backend messages via `fastapi-babel`.
- **RULE** Never concatenate translated fragments; use interpolation and ICU plurals (`t("items", { count })`).
- **RULE** Layouts tolerate +30–40% text expansion (FR is longer than EN) — no fixed-width labels that truncate.
- **RULE** Format dates, numbers, and currencies with `Intl.*` / locale-aware formatters, never manual string building.
- **PREFER** keys by feature namespace (`projects.list.empty`), not by English sentence. Keep FR and EN catalogs in lockstep — a missing key is a CI failure.
- **RULE** `lang` attribute follows the active locale; mirror layout only if/when an RTL locale is added (not required now, but don't hard-block it with `left/right` where `start/end` works).

---

## 9. UX copy (microcopy)

- **PREFER** plain language, active voice, sentence case for buttons and labels ("Save changes", not "SAVE CHANGES" or "Saving Of Changes").
- **RULE** Errors say what happened and what to do next, in the user's terms — never "Error 500" alone.
- **PREFER** buttons name the action ("Create project"), not generic "OK/Submit". Cancel/secondary on the left, confirm on the right.
- **RULE** Empty states and first-run screens guide toward the primary action.
- Keep terminology consistent across the app (one word per concept, in both FR and EN).
- For deeper copy work, invoke the `design:ux-copy` skill (error messages, empty states, CTAs).

---

## 10. Performance & perceived speed

- **PREFER** route-level code splitting (`React.lazy` + `Suspense`) and skeletons for above-the-fold data.
- **RULE** Images sized and lazy-loaded (`loading="lazy"`, explicit `width/height` to avoid layout shift). Target CLS < 0.1.
- **PREFER** TanStack Query caching + `staleTime` tuned per resource; optimistic updates for snappy writes.
- **PREFER** budget: LCP < 2.5s, INP < 200ms on a mid-tier device. Measure, don't guess.

---

## 11. Definition of Done (UI checklist)

A UI change is **not done** until all RULE items hold:

- [ ] All four states handled (loading skeleton / empty / error+retry / success) — §5
- [ ] Dark mode verified, contrast OK in both themes — §7, §6
- [ ] Keyboard-only pass: reach + operate everything, visible focus, `Esc` closes overlays — §6
- [ ] Screen-reader smoke test: labels, headings, live regions announce — §6
- [ ] Contrast ≥ 4.5:1 (text) / 3:1 (large + UI) — §6
- [ ] No hard-coded colors/sizes; tokens only — §2
- [ ] No hard-coded strings; FR + EN keys present and aligned — §8
- [ ] Responsive 320px → 2xl, no horizontal scroll, targets ≥ 44px — §3
- [ ] `prefers-reduced-motion` respected — §2.4
- [ ] `eslint-plugin-jsx-a11y` clean + automated axe check passes — §6
- [ ] One primary action per view; destructive actions confirmable/reversible — §1, §4

---

## 12. Ergonomics across surfaces (not just web)

The seven core principles in §1 are **surface-agnostic** — clarity, one primary action, feedback for
every action, forgiveness, consistency, accessibility baseline, performance-as-UX apply to a CLI, a
bot, or a game just as much as to a web page. This section translates them into concrete rules per
surface. Every non-web project picks its subsection and treats it as its Definition of Done.

### 12.0 Surface-agnostic ergonomics (every project)

- **RULE** Discoverability: the user can find what's available without reading source (help, command list, menu, onboarding).
- **RULE** Feedback: every action produces visible confirmation of success/failure within ~1s, or a progress indicator if longer.
- **RULE** Error recovery: errors state cause + next step in plain language; never a bare code or stack trace as the only message.
- **RULE** Reversibility: destructive/irreversible actions are confirmed and/or undoable; provide a dry-run where feasible.
- **RULE** Sane defaults: the common path works with zero configuration; advanced options are opt-in.
- **RULE** Consistency: same concept = same word, same shortcut, same place, across the app and across the ecosystem.
- **RULE** Respect attention: no noise. Notify only what's actionable; let the user silence/tune frequency.
- **RULE** i18n FR+EN for all user-facing copy (labels, errors, help). Logs/internal stay English.

### 12.1 CLI / TUI tools
_e.g. project-init, guideline-checker, pre-commit-tools, epub-sorter, genealogy-validator, automations_

- **RULE** `--help`/`-h` on every command and subcommand, with usage, examples, and exit codes.
- **RULE** Consistent flag grammar (`--dry-run`, `--json`, `--verbose`, `--quiet`, `--yes`); long + short forms; `--version`.
- **RULE** Standard exit codes: `0` success, non-zero on error; errors to **stderr**, results to **stdout**.
- **RULE** Destructive operations require confirmation or `--yes`/`--force`; offer `--dry-run`.
- **RULE** Long operations show progress (bar/spinner/step counter) and are interruptible (`Ctrl-C` leaves a clean state).
- **RULE** Respect `NO_COLOR` and non-TTY (no ANSI codes when piped); offer `--json` for machine consumption.
- **PREFER** actionable errors ("config not found at X — run `init` or pass `--config`"), idempotent commands, and `--quiet` for CI.

### 12.2 VS Code extensions
_e.g. django-query-optimizer-vscode; webviews in container-webview, devtool_

- **RULE** Commands are namespaced and human-readable in the Command Palette ("Chrysa: Optimize query", not "doOpt").
- **RULE** Honor the user's theme — use VS Code theme color tokens / `ThemeColor`, never hard-coded colors. Test in light, dark, and high-contrast themes.
- **RULE** Use the right surface: status bar for ambient state, notifications **sparingly** (only actionable), Progress API for long tasks, Output channel for logs.
- **RULE** No keybindings that clash with VS Code defaults; contributions documented in `package.json` and settings have descriptions.
- **RULE** Webviews inherit the full web baseline (§2–§11): tokens, keyboard, focus, contrast, the four states.
- **PREFER** activation events scoped narrowly (lazy activation), graceful behavior with no workspace open, and respect `window.dialogStyle`.

### 12.3 Discord bots
_e.g. discord-bot-back, discordium bot layer, link-reader-bot_

- **RULE** Slash commands with clear `description` per command and option; avoid prefix-command-only UX.
- **RULE** Errors and validation replies are **ephemeral** (only the invoker sees them); success that others need is public.
- **RULE** Acknowledge within 3s (defer if needed) to avoid "interaction failed"; show typing/defer for slow work.
- **RULE** Destructive/admin commands check permissions and confirm via buttons before acting.
- **RULE** Embeds: legible structure (title/fields), status conveyed by label+icon not color alone; respect Discord's 6000-char/embed limits gracefully.
- **RULE** Interactive components (buttons/selects) have clear labels and disable/expire cleanly; i18n FR+EN.
- **PREFER** a `/help` command, rate-limit-aware batching, and pagination for long results.

### 12.4 Desktop / tray / native apps
_e.g. windows-autonome, windows-docker-state-notification, diy-stream-deck, floating-agent_

- **RULE** Follow OS conventions (menu placement, shortcuts, window controls); persist window/position/state between launches.
- **RULE** Honor OS dark/light mode and accent where the platform exposes it.
- **RULE** Tray/background apps: clear icon states, a right-click menu with Quit always present, and never trap the user with no visible exit.
- **RULE** Notifications are actionable and rate-limited; provide a setting to mute/tune. No notification storms.
- **RULE** Keyboard operability and screen-reader labels via the platform a11y API (UIA on Windows, AX on macOS).
- **PREFER** graceful offline/degraded states, single-instance behavior, and explicit feedback on long startups.

### 12.5 Game UI (2D)
_e.g. Discordium V3, PO-GO-DEX, satisfactory-* tools, game-solver-platform_

- **RULE** HUD readable at target resolution/distance; critical info never relies on color alone (colorblind-safe palette).
- **RULE** Pause and Settings reachable from anywhere; Settings expose audio, controls, and accessibility toggles.
- **RULE** Input remapping for keyboard and controller; never hard-bind without a rebind path.
- **RULE** Clear feedback ("juice"): every meaningful action has visual/audio response; state changes are legible.
- **RULE** Onboarding/tutorial for first run; non-blocking for returning players.
- **PREFER** text-size/scaling option, subtitle support, FR+EN, and a reduced-motion/flash setting (photosensitivity).

### 12.6 Conversational / agent interfaces
_e.g. lifeos agents, my-assistant, coach, orchestrator, ai-aggregator, paperclip_

- **RULE** Set expectations up front: state capabilities and limits; don't imply abilities the agent lacks.
- **RULE** Confirm before irreversible or external-effect actions (sending, deleting, spending, posting).
- **RULE** Be transparent about uncertainty and failures; never fabricate a result — say what failed and offer a next step.
- **RULE** Respect the user's output constraints and language (FR/EN); honor stored preferences.
- **RULE** Concise by default; structure long answers; surface the most important thing first.
- **PREFER** showing sources/reasoning when it aids trust, graceful handling of ambiguous requests (ask one focused question), and resumable/stateless-safe interactions.

### 12.7 Notification & alert systems
_e.g. briefing-agent, health-agent, windows-docker-state-notification, frost/heat alerts_

- **RULE** Signal over noise: only fire when actionable; deduplicate and batch related events.
- **RULE** Severity is explicit (label + icon, not color alone) and consistent across the ecosystem.
- **RULE** Each alert is self-contained: what happened, why it matters, what to do, where to look.
- **RULE** Dismissible/snoozable; respect quiet hours and frequency settings.
- **PREFER** digest formats over per-event spam, and a clear "all clear"/resolution message.

### 12.8 Per-surface Definition of Done

A non-web surface is **done** when its §12 subsection RULEs hold, plus §12.0 (surface-agnostic) and:
- [ ] Discoverability path exists (help/menu/command list/onboarding)
- [ ] Feedback + error-recovery on every action
- [ ] Destructive actions confirmed/reversible (+ dry-run where feasible)
- [ ] FR+EN for user-facing copy
- [ ] Accessibility-equivalent for the surface (keyboard/SR/contrast/colorblind as applicable)
- [ ] Notifications/output tunable, no noise

---

## 13. Quick reference

```
Tokens     semantic CSS vars · no hex · 4/8px scale · --radius
States      loading / empty / error+retry / success — always all four
A11y        WCAG 2.1 AA floor · 4.5:1 · keyboard · focus-visible · semantic HTML
Dark        .dark class + tokens · default to system · persist · verify contrast
i18n        react-i18next · no concat · ICU plurals · +40% expansion · Intl.*
Components  shadcn first · keep ARIA · one primary action · 44px targets
Surfaces    web §1-11 · CLI/TUI · VS Code · Discord · desktop/tray · game 2D · agent · alerts (§12)
Always      discoverable · feedback · error-recovery · reversible · sane defaults · FR+EN · no noise
Skills      ui-ux (this) · design:design-system · design:accessibility-review · design:ux-copy
```

Related skills for deeper work: `design:design-system`, `design:accessibility-review`,
`design:ux-copy`, `design:design-critique`, `design:design-handoff`.
