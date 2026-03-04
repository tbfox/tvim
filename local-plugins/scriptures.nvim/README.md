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

## Questions & Design Decisions

### 1. Navigation Model
- **Chapter Navigation**: Override `<leader>n` and `<leader>p` to move between chapters
    - Should this work within a single book, or across all scriptures? 
        - This should go from chapter to chapter. (1ne:1 -> 1ne:2)
    - When reaching the end of a book, should it wrap to the next book or stop?
        - It should wrap to the next book (1ne:22 -> 2ne:1)
    - Should we show which chapter we're on in the statusline or as a header?
        - Lets put it in the statusline
    - other
        - When at the start of source it should `vim.print` a message saying "The Start of <source>"
        - ditto with the end

### 2. Buffer Display Format
- How should verses be displayed in the buffer?
    - Display the current Chapter and book in the status line.
    - Display the current chapter in the buffer, verse by verse broken at 80 just how paragraphs get broken with `<visual-mode>gq`
    - Have one empty line between each verse
    - Display the number of the verse at the start of the verse with a `.` just like a numbered list.
    - Should we show the full book name or abbreviations? Show abbreviations
    - Should verses be numbered inline or in a sign column? inline

### 3. Opening/Starting Point
- How do you want to open scriptures?
    - Use `:Sc` or `:Scriptures` to open
    - It should open to a scripture dashboard. (more about the dashboard later)
    - Should it open in a split, new tab, or current buffer? new buffer full screen.

### 4. Search Functionality
- What kind of search do you want?
    - when `:Sc search` is run, it should search the content of the verses with telescope (this may need to be changed for perfromance reasons)
    - when `:Sc search-ref` is run, it should open all the scripture references ("1 Nephi 3", "Alma 32") in a telescope menu
    - Search within current book/chapter? default buffer search with vim is fine

### 5. Buffer Behavior
- Should the scripture buffer be:
    - Read-only? yes!
    - Allow annotations/notes? not yet
    - Highlighted with custom syntax? not yet
    - Line numbers or not? no line numbers

### 6. Tree-nav
- It should open in a little dashboard or buffer that resembles an oil or netrw buffer. 
- It starts out showing each source in the buffer, when enter is pressed it changes the buffer to a list of books in the selected source. When enter is pressed again, it shows the chapter view which is the standard reading view.
- when `-` is pressed it goes back up the tree or out of the reading buffer back into the selection buffer (think netrw and oil)

## Initial Requirements

### Must Have (MVP)
- [ ] Reading buffer with <leader>n & <leader>p cycling through chapters
- [ ] netrw / oil like tree-nav to bring you where you want to go

### Nice to Have
- [ ] Search Functionality

### Future Enhancements
- Cross-references
- Bookmarks/favorites
- Study notes
- Highlighting/marking verses
- Copy verse with automatic citation

## Implementation Notes

Following the pattern of other local plugins:
- Main plugin code in `lua/scriptures.lua`
- Try to keep the code organized into several different files as things grow
- Setup file in `~/.config/nvim/lua/plugins/scriptures.lua`
- Use `require("lib.local-plugin")("scriptures.nvim")` for path resolution
- SQLite interaction via `vim.fn.system()` or Lua sqlite library
