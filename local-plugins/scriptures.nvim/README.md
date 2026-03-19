# scriptures.nvim

A Neovim plugin for reading and searching the LDS Standard Works within buffers.

## Database Structure

Located at `res/scriptures.db`:

**Sources:**
- `bofm` - Book of Mormon
- `nt` - New Testament
- `ot` - Old Testament
- `pgp` - Pearl of Great Price
- `dc` - Doctrine and Covenants

**Schema:**
```sql
sources (id, title)
books (id, source_id, name, short_name, sort_order)
verses (id, book_id, chapter_number, verse_number, content)
footnotes (id, book_id, chapter_number, verse_number, note_letter, highlighted_text)
footnote_references (id, footnote_id, reference_type, ref_source_id, ref_book_short, ref_chapter, ref_verse_start, ref_verse_end, sort_order)
content_blocks (id, book_id, block_type, content, sort_order)
```

## Feature Specifications

### Commands

**`:Sc`**
- Opens scripture dashboard (tree navigation view)
- Creates new buffer, full screen (not split)
- Buffer is read-only

**`:Sc search`**
- Full-text search across all verse content
- Requires Telescope plugin
- Uses dynamic telescope picker (searches as you type)
- Limited to 100 results for performance
- Selecting result navigates to that verse in reading view

**`:Sc search ref`**
- Search scripture references (e.g., "1 Nephi 3", "Alma 32")
- Requires Telescope plugin
- Uses telescope picker showing all book/chapter combinations
- Displays "Section" for D&C, "Chapter" for all others
- Selecting navigates to that chapter in reading view

**`:Sc go <book> <chapter>`**
- Jump directly to a specific chapter using a book abbreviation
- Example: `:Sc go alma 32`, `:Sc go 1ne 3`, `:Sc go dc 76`
- See [Book Abbreviations](#book-abbreviations) below

### Tree Navigation (Dashboard)

**Level 1: Source Selection**
- Display list of all 5 sources (Book of Mormon, Old Testament, etc.)
- Show full titles from `sources` table
- `<CR>` on a source → navigate to book list for that source (or section list for D&C)
- **Special case:** Doctrine and Covenants (D&C) skips the book layer and goes directly to sections
- `q` → return to origin buffer
- Buffer name: `scriptures://sources`

**Level 2: Book Selection**
- Display list of all books in selected source
- `<CR>` on a book → navigate to chapter list (or directly to reading view for block-based sources)
- `-` → go back to source selection
- `q` → return to origin buffer
- Buffer name: `scriptures://<source>` (e.g., `scriptures://bofm`)

**Level 3: Chapter Selection**
- Display list of chapters in selected book
- Format: "Chapter 1", "Chapter 2", etc. (or "Section 1", "Section 2", etc. for D&C)
- `<CR>` on a chapter → open reading view for that chapter
- `-` → go back to book selection (or source selection for D&C)
- `q` → return to origin buffer
- Buffer name: `scriptures://<source>/<book>` (e.g., `scriptures://bofm/1 Nephi`)

### Reading View

**Display Format**
- One chapter displayed at a time
- Verses formatted as numbered list: `1. [verse text]`, `2. [verse text]`, etc.
- Footnote markers displayed inline as `(letter)|highlighted text|` (concealed to just the highlighted text)
- Read-only buffer
- Buffer name: `scriptures://<source>/<book>/<chapter>` (e.g., `scriptures://bofm/1 Nephi/1`)

**Statusline**
- Show current location: `Scripture: <book abbreviation> <chapter>` (e.g., "Scripture: 1 Ne 3", "Scripture: Alma 32")

**Navigation**
- `]c` → next chapter
  - Goes from current chapter to next (1 Ne 1 → 1 Ne 2)
  - Wraps to next book when at end of book (1 Ne 22 → 2 Ne 1)
  - At end of source: `vim.print("The End of <source name>")`
- `[c` → previous chapter
  - Goes from current chapter to previous
  - Wraps to previous book when at start of book (2 Ne 1 → 1 Ne 22)
  - At start of source: `vim.print("The Start of <source name>")`
- `-` → exit reading view, return to chapter selection
- `gd` → follow footnote cross-reference under cursor
  - If single reference: navigates directly to it
  - If multiple references: presents `vim.ui.select` picker

**Buffer Behavior**
- Read-only (`:set nomodifiable`)
- Regular vim search (`/`, `?`, `n`, `N`) works for in-buffer searching
- Line numbers follow user's global configuration
- `conceallevel=2` set automatically when entering the buffer (restored on leave)

### Block-Based Sources

Some sources (e.g., "For the Strength of Youth") use content blocks instead of chapters/verses. For these:
- Book selection opens the reading view directly (no chapter list)
- `]c` / `[c` navigate between books rather than chapters
- Buffer name: `scriptures://<source>/<book>` (no chapter number)

## Book Abbreviations

Used with `:Sc go <book> <chapter>`:

| Abbreviation | Book |
|---|---|
| **Book of Mormon** | |
| `1ne` | 1 Nephi |
| `2ne` | 2 Nephi |
| `jacob` | Jacob |
| `enos` | Enos |
| `jarom` | Jarom |
| `omni` | Omni |
| `wom` | Words of Mormon |
| `mosiah` | Mosiah |
| `alma` | Alma |
| `hel` | Helaman |
| `3ne` | 3 Nephi |
| `4ne` | 4 Nephi |
| `morm` | Mormon |
| `ether` | Ether |
| `moro` | Moroni |
| **Doctrine & Covenants** | |
| `dc` | D&C |
| **New Testament** | |
| `matt` | Matthew |
| `mark` | Mark |
| `luke` | Luke |
| `john` | John |
| `acts` | Acts |
| `rom` | Romans |
| `1cor` | 1 Corinthians |
| `2cor` | 2 Corinthians |
| `gal` | Galatians |
| `eph` | Ephesians |
| `phil` | Philippians |
| `col` | Colossians |
| `1thes` | 1 Thessalonians |
| `2thes` | 2 Thessalonians |
| `1tim` | 1 Timothy |
| `2tim` | 2 Timothy |
| `titus` | Titus |
| `phlm` | Philemon |
| `heb` | Hebrews |
| `james` | James |
| `1pet` | 1 Peter |
| `2pet` | 2 Peter |
| `1jn` | 1 John |
| `2jn` | 2 John |
| `3jn` | 3 John |
| `jude` | Jude |
| `rev` | Revelation |
| **Old Testament** | |
| `gen` | Genesis |
| `ex` | Exodus |
| `lev` | Leviticus |
| `num` | Numbers |
| `deut` | Deuteronomy |
| `josh` | Joshua |
| `judg` | Judges |
| `ruth` | Ruth |
| `1sam` | 1 Samuel |
| `2sam` | 2 Samuel |
| `1kgs` | 1 Kings |
| `2kgs` | 2 Kings |
| `1chr` | 1 Chronicles |
| `2chr` | 2 Chronicles |
| `ezra` | Ezra |
| `neh` | Nehemiah |
| `esth` | Esther |
| `job` | Job |
| `ps` | Psalms |
| `prov` | Proverbs |
| `eccl` | Ecclesiastes |
| `song` | Solomon's Song |
| `isa` | Isaiah |
| `jer` | Jeremiah |
| `lam` | Lamentations |
| `ezek` | Ezekiel |
| `dan` | Daniel |
| `hos` | Hosea |
| `joel` | Joel |
| `amos` | Amos |
| `obad` | Obadiah |
| `jonah` | Jonah |
| `mic` | Micah |
| `nah` | Nahum |
| `hab` | Habakkuk |
| `zeph` | Zephaniah |
| `hag` | Haggai |
| `zech` | Zechariah |
| `mal` | Malachi |
| **Pearl of Great Price** | |
| `moses` | Moses |
| `abr` | Abraham |
| `jsm` | Joseph Smith—Matthew |
| `jsh` | Joseph Smith—History |
| `aof` | Articles of Faith |

## Technical Implementation Details

**SQLite Interaction:**
- Uses `vim.fn.system("sqlite3 -separator '\t' <db_path> \"<query>\"")` for queries
- Database path: `<plugin_dir>/res/scriptures.db`

**Buffer Management:**
- Uses `vim.api.nvim_create_buf(false, true)` for scratch buffers
- Navigation view: filetype `scripture-nav`
- Reading view: filetype `scripture`
- Uses `vim.api.nvim_buf_set_name()` for buffer naming scheme

**Footnotes:**
- Footnote markers stored in `footnotes` table with `highlighted_text`
- Cross-references stored in `footnote_references` with `reference_type` (`scripture` or `topical_guide`)
- Displayed inline using concealment syntax; `gd` navigates to referenced verse(s)

**Plugin Structure:**
- Main plugin code in `local-plugins/scriptures.nvim/lua/scriptures/`
- Setup file in `~/.config/nvim/lua/plugins/scriptures.lua`
- Uses `require("lib.local-plugin")("scriptures.nvim")` for path resolution

## Progress Tracker

- [x] Phase 1: Core Reading View
  - [x] Database query functions (db.lua)
  - [x] Verse formatting (format.lua)
  - [x] Reading buffer creation (reader.lua)
  - [x] Chapter navigation (]c, [c)
  - [x] Statusline integration
- [x] Phase 2: Tree Navigation
  - [x] Source selection buffer
  - [x] Book selection buffer
  - [x] Chapter selection buffer
  - [x] `:Sc` command
  - [x] `-` navigation back through tree
  - [x] `q` to return to origin buffer
- [x] Phase 3: Search
  - [x] `:Sc search` (content)
  - [x] `:Sc search ref` (references)
- [x] Phase 4 (partial):
  - [x] Footnote cross-references (`gd`)
  - [x] `:Sc go <book> <chapter>` direct navigation
  - [x] Block-based source support
- [ ] Phase 4 (future):
  - [ ] Bookmarks/favorites
  - [ ] Study notes
  - [ ] Highlighting/marking verses
  - [ ] Copy verse with automatic citation
  - [ ] Topical Guide references
