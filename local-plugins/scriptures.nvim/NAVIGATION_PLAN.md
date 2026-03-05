# Scripture Reader Navigation Plan

## Current Keymaps
- `<leader>n` - Next chapter
- `<leader>p` - Previous chapter
- `-` - Go back to chapter selection
- `gd` - Go to reference (footnote navigation)

## Proposed Changes

### Core Navigation (Single Key Press)

#### Chapter Navigation
- `]c` - Next chapter (follows vim convention: `]` = forward, `c` = chapter)
- `[c` - Previous chapter (follows vim convention: `[` = backward, `c` = chapter)

**Alternative options:**
- `Ctrl-j` / `Ctrl-k` - Next/Previous chapter (follows up/down convention)
- `Tab` / `Shift-Tab` - Next/Previous chapter (simple and easy)
- `n` / `N` - Next/Previous chapter (mirrors search navigation, but may conflict with future search)

### History Navigation
- `<leader>n` - History forward (newer in history)
- `<leader>p` - History backward (older in history)
- Or: `Ctrl-o` / `Ctrl-i` - Jump backward/forward in history (matches vim's native jump list)

### Verse Navigation

#### Quick Jump
- `gg` - Jump to verse 1 (first verse of chapter) - *already vim default for top of buffer*
- `G` - Jump to last verse of chapter - *already vim default for end of buffer*
- `{number}G` - Jump to specific verse number (e.g., `15G` jumps to verse 15)

#### Verse Movement
- `}` - Next verse (jump to next verse number)
- `{` - Previous verse (jump to previous verse number)

**Alternative for verse movement:**
- `]v` / `[v` - Next/Previous verse
- `Ctrl-n` / `Ctrl-p` - Next/Previous verse

### Book Navigation
- `]b` - Next book
- `[b` - Previous book

### Reference Navigation
- `gd` - Go to reference (already implemented)
- `Ctrl-]` - Go to reference (alternative, follows vim tag navigation)
- `Ctrl-t` - Go back from reference (pairs with `Ctrl-]`, like tag stack)

### Quick Access
- `<leader>h` - Go to home/navigation menu
- `-` - Go back to chapter selection (current behavior, keep this)
- `<leader>s` - Search verses (for future implementation)
- `<leader>f` - Find/filter within current chapter

### Context/Information
- `K` - Show verse cross-references in floating window (mirrors LSP hover behavior)
- `<leader>i` - Show chapter info/summary
- `gf` - Show footnote details for word under cursor

## Recommended Implementation

### Phase 1 - Essential Navigation
1. **Chapter navigation:** `]c` / `[c` (next/prev chapter)
2. **History:** `<leader>n` / `<leader>p` (forward/back in history)
   - Implement a simple history stack that tracks: `{source, book, chapter, verse_position}`
   - Max history size: 50 entries
3. **Keep existing:**
   - `-` for back to navigation
   - `gd` for go to reference

### Phase 2 - Enhanced Navigation
1. **Verse jumping:** `}` / `{` (next/prev verse)
   - Search for next `^\d+\.` pattern
2. **Quick jump:** `{number}G` to jump to verse
   - Override default `G` behavior to jump to verse number instead of line number
3. **Book navigation:** `]b` / `[b` (next/prev book)

### Phase 3 - Advanced Features
1. **Floating windows:** `K` to show cross-references
2. **Search integration:** `<leader>s` for verse search
3. **Bookmark system:** `m{letter}` to set bookmark, `'{letter}` to jump to bookmark

## History Implementation Details

### Data Structure
```lua
M.history = {
  entries = {},  -- Array of {source, book, chapter, verse, cursor_pos}
  current = 0,   -- Current position in history (1-indexed)
  max_size = 50  -- Maximum history entries
}
```

### Behavior
- When navigating to a new location via:
  - Next/prev chapter
  - Go to reference (`gd`)
  - Chapter selection menu
  - Book navigation

  → Add to history (truncate forward history if not at end)

- When navigating via history (`<leader>n` / `<leader>p`):
  → Move pointer, don't add to history

- When at beginning/end of history, show message:
  - "Already at oldest position"
  - "Already at newest position"

### Edge Cases
- Don't add duplicate consecutive entries
- Persist history across buffer close/reopen? (Optional)
- Show history list with `<leader>H`? (Like `:jumps` in vim)

## Summary of Recommended Keymaps

| Key | Action | Notes |
|-----|--------|-------|
| `]c` | Next chapter | Vim-style bracket navigation |
| `[c` | Previous chapter | Vim-style bracket navigation |
| `<leader>n` | History forward | Navigate to newer position |
| `<leader>p` | History backward | Navigate to older position |
| `gd` | Go to reference | Already implemented |
| `-` | Back to menu | Already implemented |
| `}` | Next verse | Phase 2 |
| `{` | Previous verse | Phase 2 |
| `{num}G` | Jump to verse | Phase 2 |
| `]b` | Next book | Phase 2 |
| `[b` | Previous book | Phase 2 |
| `K` | Show references | Phase 3 |

This approach:
- ✅ Follows vim conventions (`]`/`[` for navigation)
- ✅ Single key press for common operations
- ✅ Familiar to vim users
- ✅ Leaves room for future features
- ✅ Consistent with LSP keybindings where applicable
