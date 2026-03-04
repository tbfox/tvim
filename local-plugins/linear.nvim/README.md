# linear.nvim

A Neovim plugin for integrating with Linear, inspired by oily_octo.nvim's GitHub issues browser.

## Overview

Browse and manage Linear issues directly from Neovim with an oil.nvim-style interface.

### Key Features (Planned)

**MVP:**
- 🔐 Authenticate with Linear API
- 📋 View and browse issues
- ✏️  Edit issue title and description
- ➕ Create new issues with templates
- 📦 Archive/close issues

**V2+:**
- 📁 Browse Projects, Teams, Cycles, Labels
- 🏷️  Change issue attributes (status, priority, assignee, labels, due date, estimate)
- 💬 View and add comments
- 🔗 Copy URLs and open in browser
- 🔍 Sort and filter issues

## Quick Reference

### Commands
- `:Linear issues` - Browse issues (bound to `<F5>`)
- `:Linear new [bug|feature|task]` - Create new issue
- `:Linear projects` - Browse projects *(v2)*
- `:Linear teams` - Browse teams *(v2)*
- `:Linear cycles` - Browse cycles *(v2)*

### Keybindings (in issue list)
- `<CR>` - View issue details
- `g.` - Toggle archived issues
- `r` - Refresh
- `q` - Quit
- `-` - Back

### Keybindings (in issue detail)
- `:w` - Save changes (auto-save)
- `<Leader>e` - Edit attributes *(v2)*
- `-` - Back to list
- `q` - Close

## Setup

### Prerequisites

1. **Linear API Key**: Get yours from https://linear.app/settings/api
2. **Environment Variable**: Set `LINEAR_API_KEY` in your shell:
   ```bash
   export LINEAR_API_KEY="lin_api_xxxxx"
   ```

### Installation

Add to your Neovim config (assuming lazy.nvim):

```lua
-- In lua/plugins/linear.lua
return {
  {
    dir = require("lib.local-plugin")("linear.nvim"),
    config = function()
      require("linear").setup()
    end
  }
}
```

## Architecture

**Pure Lua** implementation using:
- `vim.system` + `curl` for GraphQL API calls
- Manual caching with refresh (like oily_octo)
- Buffer-based UI with markdown editing
- Linear's GraphQL API (https://api.linear.app/graphql)

If complexity grows, can migrate to TypeScript SDK later.

## Implementation Status

See [IMPLEMENTATION.md](./IMPLEMENTATION.md) for detailed implementation plan.

### Current Phase
- [ ] Phase 0: Project setup & GraphQL research
- [ ] Phase 1: Core infrastructure (auth, API client)
- [ ] Phase 2: Issue listing
- [ ] Phase 3: Issue viewing & editing
- [ ] Phase 4: Issue creation & archiving
- [ ] Phase 5: Additional entity views
- [ ] Phase 6: Advanced actions & attributes
- [ ] Phase 7: Comments
- [ ] Phase 8: Polish & optimization

## Development

### Testing Queries

Use Linear's GraphQL playground:
https://studio.apollographql.com/public/Linear-API/variant/current/home

Example query:
```graphql
query {
  issues(first: 10) {
    nodes {
      id
      identifier
      title
      state { name }
    }
  }
}
```

### Testing the Plugin

```vim
" Source the plugin
:source ~/.config/nvim/local-plugins/linear.nvim/lua/linear.lua

" Test commands
:Linear issues
```

## Design Decisions

Based on planning questionnaire ([original questions preserved below](#planning-questions)):

- **API**: Direct GraphQL calls (pure Lua)
- **Auth**: Personal API key via `LINEAR_API_KEY` env var
- **Cache**: Manual refresh with `r` key
- **UI**: Single command with subcommands
- **Keybindings**: Match oily_octo for consistency
- **Save**: Auto-save on `:w`
- **Scope**: Coexist with oily_octo (GitHub + Linear)

---

## Planning Questions

<details>
<summary>Click to expand original planning questions and answers</summary>

### 1. Core Scope & Entity Focus

**Q1.1:** Which Linear entities do you want to browse/manage?
- [x] Issues (the primary work items)
- [x] Projects (organizational containers)
- [x] Teams (workspace organization)
- [x] Cycles/Sprints
- [ ] Roadmaps
- [x] Labels/Tags
- [x] Comments on issues

**Q1.2:** Should the plugin support a hierarchical view?
- [x] Yes, multi-level navigation
- [x] Configurable per-entity

**Q1.3:** What's your primary use case?
- [x] Full issue CRUD (Create, Read, Update, Delete)

### 2. API Integration Strategy

**Q2.1:** How should the plugin interact with Linear's API?
- [x] Direct GraphQL API calls

**Q2.2:** Authentication method preference?
- [x] Personal API key (simpler, stored in config/env)

**Q2.3:** Where should API credentials be stored?
- [x] Environment variable (`LINEAR_API_KEY`)

**Q2.4:** Should the plugin cache API responses?
- [x] Yes, with manual refresh (like oily_octo's 'r' key)

### 3. User Interface & Navigation

**Q3.1:** What should the main entry point look like?
- Single main command (`:Lin` or `:Linear`) with subcommands:
  - `issues`, `projects`, `teams`, `cycles`, `labels`, `comments`

**Q3.2:** What keybinding(s) should open the Linear browser?
- [x] `<F5>`

**Q3.3:** For the issue list view, what columns should display?
- [x] Identifier (e.g., `ENG-123`)
- [x] Status (e.g., `Todo`, `In Progress`, `Done`)
- [x] Assignee
- [x] Title
- [x] Project name
- [x] Labels/tags
- [x] Due date

**Q3.4:** Should the list be sorted/filterable?
- [x] Sort by: Priority, Status, Updated, Created, Due Date
- [x] Filter by: Team, Project, Assignee, Status, Label

**Q3.5:** How should states/statuses be displayed?
- [x] Text only (e.g., `[Todo]`, `[Done]`)
- [x] Color-coded text (using Neovim highlights)

### 4. Issue Detail View

**Q4.0:** When editing attributes (pressing `<Leader>e`), what should be editable?
- [x] Status, Priority, Assignee, Labels, Due date, Estimate
- Note: These use selectors, not text editing

**Q4.1:** When viewing an issue (pressing `<CR>`), what should be editable?
- [x] Title
- [x] Description/body

**Q4.2:** What format should the issue detail buffer use?
```
Fix authentication bug
---

Description goes here...
```

**Q4.3:** Should comments be included in the detail view?
- [x] Separate view for comments

**Q4.4:** How should saving changes work?
- [x] Auto-save on buffer write (`:w`)

### 5. Issue Creation

**Q5.1:** Should the plugin support creating new issues?
- [x] Yes, minimal (just title + description)

**Q5.3:** Should there be shortcuts for common issue types?
- [x] `:Linear new bug` - Create bug report
- [x] `:Linear new feature` - Create feature request
- [x] `:Linear new task` - Create task

### 6. Workflow & Actions

**Q6.1:** What quick actions should be available on issues?
- [x] Change status, Assign to me, Change priority, Archive/delete
- [x] Add to project/cycle, Copy Linear URL, Open in browser

**Q6.2:** Should there be keyboard shortcuts for state transitions?
- [x] No, use commands only for now

**Q6.3:** Should the plugin support bulk operations?
- [x] No, one-at-a-time is fine for now

### 7. Team & Project Context

**Q7.1:** How should team/project context be determined?
- [x] Prompt on first use and save to `~/.local/share/nvim/linear.nvim/`

### 10. Migration & Compatibility

**Q10.1:** Should this replace oily_octo or coexist?
- [x] Coexist - I use both GitHub and Linear

**Q10.2:** Should keybindings match oily_octo?
- [x] Yes, keep same mappings

### 12. Initial MVP Scope

**Critical for MVP:**
- [x] Authentication
- [x] View Issues
- [x] Edit Issues
- [x] Close Issues

**Can wait for v2:**
- All advanced actions and other entity types

</details>

---

## References

- [Linear API Docs](https://linear.app/developers)
- [Linear GraphQL Schema](https://studio.apollographql.com/public/Linear-API/variant/current/home)
- [oily_octo.nvim](../oily_octo.nvim/) - GitHub integration (sister plugin)
- [CLAUDE.md](../../CLAUDE.md) - Project architecture patterns

---

## License

MIT (or whatever your dotfiles use)
