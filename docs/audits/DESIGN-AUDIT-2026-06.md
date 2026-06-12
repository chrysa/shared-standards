# Design Audit — chrysa frontends (2026-06)

> Portfolio-wide review triggered by the report that the apps have problems of
> **identity, display, and ergonomics**. This audit establishes the factual base
> for the pivot recorded in [ADR 0002](../adr/0002-design-personas.md) and the
> rewritten [DESIGN-SYSTEM.md](../DESIGN-SYSTEM.md).
>
> **Method:** remote-first. Every row reflects the repo's **default branch
> (`main`) on GitHub**, verified via `gh pr list --state merged` + reading the
> token/theme file on `main` — *not* the local checkout (local working copies were
> on stale feature branches showing a pre-campaign look, e.g. gaming-os on
> `feat/in-app-bug-report` still rendered the old soft violet theme while `main`
> is brutalist lime).
>
> **Visual capture deferred:** screenshots were not taken. The 13 brutalist apps
> are uniform *by specification* (token spot-checks on `main` matched
> DESIGN-SYSTEM.md §1 exactly), so the diagnosis is structural, not pixel-level.
> Per-app screenshots belong to each app's own redesign session.

## 1. The core finding

The active **"Neon Brutalist" campaign re-skinned 13 of 16 frontends to one
identical aesthetic** (radius 0, 2px foreground-colored borders, hard offset
shadows, Space Grotesk + JetBrains Mono, uppercase labels). **The only thing that
varies per app is the accent hue.** Accent-hue-only is too thin to carry identity:
a résumé, a CI dashboard, a doc generator, and a CDN explorer are visually the
same product in different highlighter colors.

The two apps with the **strongest identity were never touched by the campaign** —
`sport-intelligence-hub` (bespoke F1 surface ramp + per-team palette + live/finished
states) and `discordium` (four themed cosmic skins). They prove the point: identity
came from purpose-built design, and the uniform system would have *erased* it.

So the complaint decomposes as:
- **Identity** → 13 apps share one skin; accent-only differentiation. Plus genre
  clashes (brutalism on a résumé).
- **Display** → loud borders + hard shadows + acid fills = high visual noise;
  acid-accent fills are contrast-fragile (a white-on-yellow bug already shipped and
  was patched reactively in linkendin-resume). Two directions live simultaneously
  (brutalist `main` vs soft stale branches) → inconsistent reality.
- **Ergonomics** → uppercase-mono body copy, radius 0, press-translate as the only
  affordance; optimized for "loud structure" over reading and discoverability.

## 2. Truth table (verified on `main`)

Score 0–3 (higher = better). **Id** = identity, **Di** = display, **Er** = ergonomics.

| App | Stack | Look on `main` | Accent | Id | Di | Er | Note |
|---|---|---|---|:--:|:--:|:--:|---|
| gaming-os | React+Tailwind v4 | Brutalist (#148) | lime | 2 | 2 | 1 | brutalism partly fits arcade genre |
| studioverse | React+Tailwind | Brutalist (#83) | lime | 2 | 2 | 1 | same skin as gaming-os |
| ai-aggregator | React+SCSS | **Soft slop** (#159) | indigo/violet | 1 | 2 | 2 | Inter + #4f46e5/#7c3aed, soft radii — generic SaaS, not brutalist |
| mirrador | React+Tailwind | Brutalist (#116) | orange | 1 | 2 | 1 | |
| link-reader-bot | React+Tailwind | Brutalist (#79) | magenta | 1 | 2 | 1 | |
| dev-nexus | React+plain CSS | Brutalist (#256) | cyan | 1 | 2 | 2 | density suits a dev dashboard |
| devtool | React+Bootstrap | Brutalist (#93) | cyan | 1 | 2 | 2 | |
| doc-gen | React+Tailwind | Brutalist (#145) | violet | 1 | 2 | 1 | content tool wearing structure-loud skin |
| cdn-explorer | React+plain CSS | Brutalist (#82) | magenta | 1 | 2 | 2 | |
| container-webview | React+SCSS | Brutalist (#161) | cyan | 1 | 2 | 2 | |
| satisfactory-factory-manager | React+SCSS | Brutalist (#147) | orange | 2 | 2 | 1 | industrial orange partly fits the game |
| audit-platform | React+plain CSS | Brutalist (#57) | azure | 1 | 2 | 2 | azure accent not in §3 table |
| linkendin-resume | React+plain CSS | Brutalist (#201) | yellow | **0** | 1 | 1 | **worst genre clash: a résumé in acid-yellow radius-0 brutalism**; white-on-yellow contrast bug history |
| chrysa-portfolio-viz | React | Brutalist (#130) | chrome | 1 | 2 | 2 | |
| sport-intelligence-hub | React+Tailwind | **Bespoke F1** (untouched) | per-team | **3** | **3** | **3** | surface ramp 0–4, ink ramp, team colors, live/finished — best identity in the portfolio |
| discordium | React | **4 themed skins** (deferred) | per-theme | 3 | 2 | 2 | Discorde/Ordre/Vide/Néon; real identity via themes |
| my-resume | — | **no frontend** | — | — | — | — | docs/agent-config repo only; drop from the 17 → 16 real frontends |

## 3. Cross-cutting defect catalog

1. **Identity-by-accent-only** (root cause of "identité"). 13 apps, one skin, one
   variable. Fix: a per-genre **persona layer** (ADR 0002).
2. **Genre mismatch.** Brutalism applied to genres it fights — most acutely a
   résumé (`linkendin-resume`) and content/landing surfaces. Fix: personas map app
   genre → appropriate type/density/depth.
3. **Reflex fonts in the soft holdout.** `ai-aggregator` ships **Inter** as its
   face + indigo/violet — the textbook AI-slop look. Fix: persona-defined pairings,
   Inter allowed for *body* only, never as the brand/display face.
4. **Uppercase-mono body.** Mono + uppercase used beyond labels hurts reading speed.
   Fix: body is always a readable sans/serif in normal case; mono reserved for data.
5. **Contrast-fragile acid fills.** Acid accents as fills need per-app verification;
   the white-on-yellow bug shipped because the rule wasn't enforced mechanically.
   Fix: every accent fill + text/bg pair carries a stated, AA-verified ratio.
6. **Two live directions at once.** `main` is brutalist; stale local branches and
   the session primer still describe the soft look → the "display inconsistency" is
   partly an artifact of nobody trusting a single source of truth. Fix: this audit +
   the rewritten spec are the single truth; verify `main` before judging a repo.
7. **Best identities bypassed the system.** `sport-intelligence-hub` and
   `discordium` earned their identity *outside* the uniform DNA. A system that the
   best work has to route around is mis-specified. Fix: the persona layer makes
   purpose-built identity the default path, not the exception.
8. **Undocumented accent drift.** `audit-platform` introduced an azure accent not in
   DESIGN-SYSTEM.md §3; linkendin yellow likewise. Accents are being added ad hoc.
   Fix: §3 accent table is authoritative; additions are PRs to it.

## 4. What carries over vs. what changes

**Keep (the backbone is sound):** the semantic token vocabulary, the per-app accent
mechanism, the WCAG AA floor and four-states from `UX-UI-GUIDELINES.md`, the
"tokens not hardcoded hex" discipline, the primitive component contracts.

**Change:** replace the single "Neon Brutalist" aesthetic DNA with a **4-persona
layer** (Console / Arcade / Editorial / Signal). Identity becomes **persona +
accent**. See [DESIGN-SYSTEM.md](../DESIGN-SYSTEM.md) and
[ADR 0002](../adr/0002-design-personas.md). Per-app migration is one repo per
session (rule 1+2); `linkendin-resume` → Editorial is the recommended pilot because
it is the worst current clash and proves the persona produces a visibly different,
better result.
