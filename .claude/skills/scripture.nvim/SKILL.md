---
name: scripture.nvim
description: Work on the scriptures.nvim local plugin — adding features, fixing bugs, adding commands, or debugging display issues.
---

# scripture.nvim Skill

scriptures.nvim is a Neovim plugin providing an in-buffer scripture reading and navigation interface for the LDS Standard Works. Users can browse, read, and search across all five scripture sources with footnote support, cross-reference navigation, and Come Follow Me study integration.

**Plugin location**: `local-plugins/scriptures.nvim/`
**Plugin spec**: `lua/plugins/scriptures.lua`

## When invoked, start here

Before making any changes, read the files relevant to the task:

- **Adding or changing a command**: read `lua/scriptures/init.lua` first — all `:Sc` subcommand routing lives here
- **Changing how verses display**: read `lua/scriptures/format.lua` and `after/syntax/scripture.vim`
- **Changing navigation behavior**: read `lua/scriptures/nav.lua`
- **Changing what's loaded into the reading buffer**: read `lua/scriptures/reader.lua`
- **Database queries**: read `lua/scriptures/db.lua`
- **Search pickers**: read `lua/scriptures/search.lua`
- **Come Follow Me study file format**: read `.claude/skills/scripture.nvim/come-follow-me.md`

Do not suggest changes to files you haven't read.

## Architecture

| File | Role |
|------|------|
| `lua/scriptures/init.lua` | Entry point, `:Sc` command routing, book aliases, audio/open |
| `lua/scriptures/reader.lua` | Reading buffer management, state, keymaps, statusline |
| `lua/scriptures/nav.lua` | Three-level tree navigation, caching, origin buffer tracking |
| `lua/scriptures/search.lua` | Telescope pickers for content and reference search |
| `lua/scriptures/db.lua` | SQLite queries via `sqlite3` shell command |
| `lua/scriptures/format.lua` | Verse formatting, footnote marker insertion, word-wrap |
| `after/syntax/scripture.vim` | Syntax highlighting, footnote concealment (`conceallevel=2`) |
| `res/scriptures.db` | ~18MB SQLite database with all verses, footnotes, blocks |

## Common Task Patterns

### Adding a new `:Sc` subcommand
1. Add the subcommand branch in `init.lua` inside the `Sc` command handler
2. Implement the logic (inline or in a new/existing module)
3. Document it in the features list below if user-facing

### Adding a new scripture source
1. Insert a row in the `sources` table in `scriptures.db`
2. Add books and verses/content_blocks to the appropriate tables
3. If the source uses blocks instead of verses, ensure `source_has_blocks()` in `db.lua` returns true for it
4. Add a URL slug mapping in `init.lua` for `:Sc open` support

### Adding a new book alias
All abbreviation lookups live in the `BOOK_ALIASES` table in `init.lua`. Add entries there for any new abbreviations.

### Changing verse display / formatting
Verse text is assembled in `format.lua`. Footnote markers use the `(a)|text|` format — the syntax file conceals the markup. Changes to the marker format must be reflected in both `format.lua` and `after/syntax/scripture.vim`.

## Gotchas — Read Before Suggesting Changes

- **No Lua SQLite bindings** — `db.lua` uses `vim.fn.system("sqlite3 -separator '\t' ...")` with tab-separated parsing. Do not suggest `sqlite.lua` or any Lua SQLite library.
- **Block-based sources have a separate code path** — sources like "For the Strength of Youth" use `content_blocks` instead of `verses`. There is no chapter selection; books open directly to the reading view. `]c`/`[c` navigate between books, not chapters. Check `source_has_blocks()` before assuming verse-based logic applies.
- **Audio is macOS-only** — `:Sc listen` uses `afplay` for playback and `open` for URLs. Do not suggest cross-platform alternatives unless asked.
- **Telescope is optional** — `:Sc search` and `:Sc search ref` require Telescope. Do not make Telescope a hard dependency.
- **`sqlite3` must be in PATH** — the shell command will silently fail if it isn't. If queries return empty, check this first.
- **Footnote concealment is fragile** — the `(a)|text|` format must remain intact through wrapping. `format.lua`'s `wrap_line()` treats footnote markers as indivisible units for this reason.

## Database Tables

- `sources` — 5 LDS sources (bofm, nt, ot, pgp, dc)
- `books` — 66 books with short_name and sort_order
- `verses` — ~33k verse records
- `footnotes` — note metadata with highlighted_text and note_letter
- `footnote_references` — cross-reference links (scripture or topical_guide)
- `content_blocks` — for block-based sources (heading/paragraph/list_item)

## Key Features (for reference)

- Tree navigation: Sources → Books → Chapters
- Full-text verse search via Telescope (`:Sc search`)
- Reference search (`:Sc search ref`) — all book/chapter combos
- Direct navigation: `:Sc go <book> <chapter>` (e.g., `:Sc go alma 32`)
- Visual mode reference parsing: select "Alma 32", press `<Leader>gs`
- Footnote cross-reference navigation (`gd` in reader; `vim.ui.select` if multiple)
- Chapter navigation: `]c` / `[c`
- Audio narration: `:Sc listen` (ElevenLabs + Ollama, cached in `res/audio/`)
- Open on churchofjesuschrist.org: `:Sc open`
- Come Follow Me study notes in `res/study/YYYY/week_N.sc.md`

## Buffer Types

- `scripture-nav` — Read-only navigation tree
- `scripture` — Read-only reading view with `conceallevel=2`

## Testing & Reloading

- `test.lua` — debug helpers and reloading instructions; source it with `<F2>` while it's open
- To reload after edits: re-source the changed file with `<F2>`, then open a scripture buffer to verify
- For syntax changes (`scripture.vim`): close and reopen a scripture buffer to pick up the new syntax

