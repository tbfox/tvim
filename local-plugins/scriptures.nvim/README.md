# scriptures.nvim

A Neovim plugin for reading and searching the LDS Standard Works within buffers.

## Database Structure

Located at `res/standard-works.sqlite`:

**Sources:**
- `bofm` - Book of Mormon
- `nt` - New Testament
- `ot` - Old Testament
- `pgp` - Pearl of Great Price
- `dc` - Doctrine and Covenants

**Schema:**
```sql
verses (id, source, book, chapter, verse, content, path)
sources (id, title)
```

Example path: `bofm/1-ne/1/1` (Book of Mormon, 1 Nephi, Chapter 1, Verse 1)

## Feature Specifications

### Commands

**`:Sc` or `:Scriptures`**
- Opens scripture dashboard (tree navigation view)
- Creates new buffer, full screen (not split)
- Buffer is read-only

**`:Sc search`** (Future)
- Full-text search across all verse content
- Uses telescope picker
- Selecting result navigates to that verse in reading view

**`:Sc search-ref`** (Future)
- Search scripture references (e.g., "1 Nephi 3", "Alma 32")
- Uses telescope picker showing all book/chapter combinations
- Selecting navigates to that chapter in reading view

### Tree Navigation (Dashboard)

**Level 1: Source Selection**
- Display list of all 5 sources (Book of Mormon, Old Testament, etc.)
- Show full titles from `sources` table
- `<CR>` on a source → navigate to book list for that source
- Buffer name: `scriptures://sources`

**Level 2: Book Selection**
- Display list of all books in selected source
- `<CR>` on a book → navigate to chapter list for that book
- `-` → go back to source selection
- Buffer name: `scriptures://<source>` (e.g., `scriptures://bofm`)

**Level 3: Chapter Selection**
- Display list of chapters in selected book
- Format: "Chapter 1", "Chapter 2", etc.
- `<CR>` on a chapter → open reading view for that chapter
- `-` → go back to book selection
- Buffer name: `scriptures://<source>/<book>` (e.g., `scriptures://bofm/1-ne`)

### Reading View

**Display Format**
- One chapter displayed at a time
- Verses formatted as numbered list: `1. [verse text]`, `2. [verse text]`, etc.
- Each verse wrapped at 80 columns (like `gq` formatting)
- One empty line between verses
- No line numbers (`:set nonumber`)
- Read-only buffer
- Buffer name: `scriptures://<path>` (e.g., `scriptures://bofm/1-ne/1`)

**Statusline**
- Show current location: `<book abbreviation> <chapter>` (e.g., "1 Ne 3", "Alma 32")
- Use abbreviations for book names

**Navigation**
- `<leader>n` → next chapter
  - Goes from current chapter to next (1 Ne 1 → 1 Ne 2)
  - Wraps to next book when at end of book (1 Ne 22 → 2 Ne 1)
  - At end of source: `vim.print("The End of <source name>")`
- `<leader>p` → previous chapter
  - Goes from current chapter to previous
  - Wraps to previous book when at start of book (2 Ne 1 → 1 Ne 22)
  - At start of source: `vim.print("The Start of <source name>")`
- `-` → exit reading view, return to chapter selection

**Buffer Behavior**
- Read-only (`:set readonly`, `:set nomodifiable`)
- No line numbers
- Regular vim search (`/`, `?`, `n`, `N`) works for in-buffer searching

## Implementation Plan

### Phase 1: Core Reading View (MVP Foundation)
**Files to create:**
- `lua/scriptures/init.lua` - Main module with setup()
- `lua/scriptures/db.lua` - SQLite query functions
- `lua/scriptures/reader.lua` - Reading buffer logic
- `lua/scriptures/format.lua` - Verse formatting (wrap at 80, numbering)

**Tasks:**
1. Set up SQLite query functions in `db.lua`:
   - `get_sources()` - get all sources
   - `get_books(source)` - get books in a source
   - `get_chapters(source, book)` - get chapter numbers for a book
   - `get_chapter_verses(source, book, chapter)` - get all verses in a chapter
   - `get_next_chapter(source, book, chapter)` - returns next chapter info (handling book/source wrapping)
   - `get_prev_chapter(source, book, chapter)` - returns previous chapter info

2. Create reading buffer in `reader.lua`:
   - Function to create/populate reading buffer
   - Format verses with numbering and wrapping
   - Set buffer options (readonly, nomodifiable, nonumber)
   - Set buffer name to `scriptures://<path>`

3. Implement chapter navigation:
   - `<leader>n` mapping → load next chapter
   - `<leader>p` mapping → load previous chapter
   - Print messages at source boundaries

4. Create statusline component showing current location

### Phase 2: Tree Navigation (MVP Completion)
**Files to create:**
- `lua/scriptures/nav.lua` - Tree navigation logic

**Tasks:**
1. Implement source selection buffer:
   - Display sources from database
   - `<CR>` mapping to navigate to book list
   - Set buffer as readonly

2. Implement book selection buffer:
   - Query and display books for selected source
   - `<CR>` mapping to navigate to chapter list
   - `-` mapping to go back to sources

3. Implement chapter selection buffer:
   - Display chapters for selected book
   - `<CR>` mapping to open reading view
   - `-` mapping to go back to books

4. Create `:Sc` / `:Scriptures` command:
   - Opens source selection buffer
   - Handle command registration in setup()

5. Add `-` mapping in reading view to return to chapter selection

### Phase 3: Search Functionality (Nice to Have)
**Files to create:**
- `lua/scriptures/search.lua` - Telescope integration

**Tasks:**
1. Implement `:Sc search`:
   - Full-text verse content search via telescope
   - Performance optimization if needed (consider indexing or limits)
   - Navigate to selected verse

2. Implement `:Sc search-ref`:
   - Build list of all book/chapter references
   - Telescope picker for references
   - Navigate to selected chapter

### Phase 4: Future Enhancements
- Cross-references
- Bookmarks/favorites
- Study notes
- Highlighting/marking verses
- Copy verse with automatic citation

## Technical Implementation Details

**SQLite Interaction:**
- Use `vim.fn.system("sqlite3 <db_path> '<query>'")` for simple queries
- Or consider `kkharji/sqlite.lua` if more complex queries needed
- Database path: `<plugin_dir>/res/standard-works.sqlite`

**Buffer Management:**
- Use `vim.api.nvim_create_buf(false, true)` for scratch buffers
- Set filetype to `scripture` for potential future syntax highlighting
- Use `vim.api.nvim_buf_set_name()` for buffer naming scheme

**Text Formatting:**
- Use `vim.fn.split(text, '\n')` and manual wrapping logic for 80-char wrapping
- Or leverage `vim.api.nvim_buf_set_lines()` with pre-formatted text

**Keymaps:**
- Use buffer-local keymaps: `vim.keymap.set('n', '<leader>n', fn, { buffer = bufnr })`
- Only override `<leader>n`/`<leader>p` in scripture buffers
- Detect buffer type by checking `vim.bo.filetype == 'scripture'` or buffer name pattern

**Plugin Structure:**
Following the pattern of other local plugins:
- Main plugin code in `local-plugins/scriptures.nvim/lua/scriptures/`
- Setup file in `~/.config/nvim/lua/plugins/scriptures.lua`
- Use `require("lib.local-plugin")("scriptures.nvim")` for path resolution

## Progress Tracker

- [ ] Phase 1: Core Reading View
  - [ ] Database query functions (db.lua)
  - [ ] Verse formatting (format.lua)
  - [ ] Reading buffer creation (reader.lua)
  - [ ] Chapter navigation (<leader>n, <leader>p)
  - [ ] Statusline integration
- [ ] Phase 2: Tree Navigation
  - [ ] Source selection buffer
  - [ ] Book selection buffer
  - [ ] Chapter selection buffer
  - [ ] `:Sc` command
  - [ ] `-` navigation back through tree
- [ ] Phase 3: Search
  - [ ] `:Sc search` (content)
  - [ ] `:Sc search-ref` (references)
- [ ] Phase 4: Future enhancements
