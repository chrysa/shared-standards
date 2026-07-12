# Glossaire chrysa — Docker-Desktop-style search ("omnibar")

- **Date:** 2026-06-28
- **Status:** Design approved (approach 1) — awaiting spec review
- **Author:** Anthony Gréau (with assistant)
- **Scope:** Notion organizational convention. No custom UI code (Notion's search bar is not stylable).
- **Surface:** `📖 Glossaire chrysa-V2 — vocabulaire commun` (currently page `37f59293-e35e-81ca-ab23-cdba0162c668`, under DB `📚 Reference chrysa-V2`, page tree `🏠 HOME chrysa-V2`).

## 1. Problem

The user wants the glossary's search to feel "like Docker Desktop's omnibar": a single
prominent field, opened by keyboard, that returns **fuzzy** matches **grouped by category**
and is fully keyboard-navigable.

Notion does **not** allow styling or replacing its search bar. Its native quick-find
(`Cmd/Ctrl + K`) is already command-palette-shaped, but on a **prose page** it only matches
page title + raw body text: no category grouping, no synonym/alias matching, weak fuzziness.

Therefore the Docker-Desktop *feel* cannot come from UI — it must come from **data structure**.
The lever is to make the native search behave like Docker Desktop by structuring the glossary
so that grouping and alias-matching fall out naturally.

## 2. What "Docker Desktop omnibar" means here

Mapping each Docker Desktop trait to a Notion-native equivalent we *can* deliver:

| Docker Desktop trait | Notion-native equivalent (this spec) |
|---|---|
| `Cmd/Ctrl + K` opens search | Notion native quick-find (`Cmd/Ctrl + K`) — already exists |
| Results **grouped by category** | Database view **grouped by `Catégorie`**; the 7 existing rubrics become the groups |
| **Fuzzy** matching | Term `Terme` (title) + `Alias/Synonymes` text property both indexed by Notion search |
| Icon + name + secondary metadata per row | Term + `Statut` badge + `Catégorie` + short definition preview in the view |
| Keyboard nav (↑↓ / Enter / Esc) | Native Notion quick-find keyboard navigation |
| Prominent, centered entry point | A **linked view** of the glossary DB pinned at the top of `🏠 HOME chrysa-V2` with its search box visible |

Out of scope (impossible in Notion, do not promise): custom CSS, a centered floating modal of
our own, custom fuzzy ranking, custom keybindings.

## 3. Approach (approved: #1)

Convert the single prose glossary page into a **Notion database** — one row per term — and
surface it via a grouped, searchable linked view.

Rejected alternatives:
- **#2 Prose + convention only** — keep the page, add a ToC and a "search convention" callout.
  Cheapest, but no grouping and no alias matching → weak Docker-Desktop feel. Rejected.
- **#3 DB without HOME embed** — same DB but rely only on the in-DB quick-find. Less integrated
  with the HOME entry point. Rejected in favor of the pinned linked view.

## 4. Target data model — DB `📖 Glossaire chrysa-V2`

One row = one term.

| Property | Type | Notes |
|---|---|---|
| `Terme` | Title | The canonical term, e.g. "Fiche", "Jalon", "Cascade". |
| `Définition` | Text | The definition. Keep concise; long nuance can stay in the row's page body. |
| `Catégorie` | Select | One of the 7 rubrics (see §5). Drives the grouped view (the "groups"). |
| `Alias/Synonymes` | Text | Comma-separated alternates so search matches non-canonical phrasings (the "fuzzy" lever). |
| `Statut` | Select | `Actif` · `Banni` · `Déprécié`. Lets banned terms (e.g. "Lot", "sprint", "MVP", "Gelée") stay searchable but flagged. |
| `Source / Décision` | Text | Provenance, e.g. "Anthony 2026-06-14", or the ADR it comes from. |

Notes:
- `Statut = Banni` replaces the strikethrough convention in the current prose (`~~Lot~~`,
  `~~❄️ Gelée~~`). A banned term still appears in search with a clear badge + the term to use
  instead (kept in `Définition`).
- Rich nuance / multi-paragraph rulings (e.g. the "Résolution cascade × câbler" entry) live in
  the row's **page body**, not the `Définition` property.

## 5. Categories (Select options for `Catégorie`)

Reuse the existing rubrics verbatim so nothing is reclassified during migration:

1. 🗂️ Organisation du travail
2. 🔗 Dépendances & relations
3. 🏷️ Qualification projet
4. 🎮 Jeux
5. 🏗️ Infrastructure
6. 🗄️ Bases & lieux
7. 📐 Standards de fiche

## 6. Views

- **Default view — "Par catégorie" (grouped):** Table or Gallery grouped by `Catégorie`,
  sorted `Terme` ascending within each group. This *is* the Docker-Desktop grouped-results look.
  Show `Terme`, `Statut`, and a `Définition` preview.
- **HOME entry point:** a **linked view** of this DB pinned near the top of `🏠 HOME chrysa-V2`,
  with the view's search box visible — the prominent "omnibar" entry. `Cmd/Ctrl + K` remains the
  global keyboard path.
- Optional **"Actifs seulement"** filtered view (`Statut != Banni`) for day-to-day reading.

## 7. Migration

1. Create DB `📖 Glossaire chrysa-V2` with the schema in §4 under `📚 Reference chrysa-V2`.
2. Port each bold-term entry from the prose page into a row, assigning `Catégorie` from the
   heading it currently sits under and `Statut` from its strikethrough state.
3. Move long nuance text into row page bodies.
4. Replace the old prose page content with a redirect callout pointing to the new DB (keep the
   page id so existing links survive), or convert the page in place.
5. Add the grouped default view + the HOME linked view.

Migration is **content work in Notion** (via MCP), not code. No repo code changes.

## 8. Success criteria

- Typing a term (or a known alias) in the glossary search returns it.
- Results are visibly grouped by the 7 categories.
- Banned terms are findable and clearly marked, with the preferred term shown.
- A single pinned entry point exists on `🏠 HOME chrysa-V2`.
- `Cmd/Ctrl + K` reaches a glossary term in ≤ 2 keystrokes-worth of typing for any canonical term.

## 9. Non-goals

- No custom front-end, no CSS, no external glossary site.
- No custom fuzzy-ranking engine — we rely on Notion's matching + the `Alias` field.
- No change to guideline-checker code.
