# linear-integration.nvim

A Neovim plugin for integrating with Linear, inspired by oily_octo.nvim's GitHub issues browser.

## Planning Questions

This document outlines key decisions needed before implementation. Answer these questions to define the plugin's scope and behavior.

---

## 1. Core Scope & Entity Focus

**Q1.1:** Which Linear entities do you want to browse/manage? (Check all that apply)
- [x] Issues (the primary work items)
- [x] Projects (organizational containers)
- [x] Teams (workspace organization)
- [x] Cycles/Sprints
- [ ] Roadmaps
- [x] Labels/Tags
- [x] Comments on issues
- [ ] Other: ___________

**Q1.2:** Should the plugin support a hierarchical view (e.g., Teams → Projects → Issues)?
- [x] Yes, multi-level navigation
- [ ] No, flat list view only (like oily_octo)
- [x] Configurable per-entity

**Q1.3:** What's your primary use case?
- [ ] Quick issue browsing and status updates
- [x] Full issue CRUD (Create, Read, Update, Delete)
- [ ] Project/sprint planning
- [ ] Mixed - I want it all
- [ ] Other: ___________

---

## 2. API Integration Strategy

**Q2.1:** How should the plugin interact with Linear's API?
- [x] **Direct GraphQL API calls** (more control, requires auth handling)

**Q2.2:** Authentication method preference?
- [x] **Personal API key** (simpler, stored in config/env)

**Q2.3:** Where should API credentials be stored?
- [x] Environment variable (`LINEAR_API_KEY`)

**Q2.4:** Should the plugin cache API responses?
- [x] Yes, with manual refresh (like oily_octo's 'r' key)

---

## 3. User Interface & Navigation

**Q3.1:** What should the main entry point look like?
- Single main command with sub-commands (`:Lin` or `:Linear` as main command)
- Use sub commands to access different things
    - issues
    - projects
    - teams
    - cycles
    - labels
    - comments
    

**Q3.2:** What keybinding(s) should open the Linear browser?
- [x] `<F5>` (next to oily_octo's `<F10>`) 

**Q3.3:** For the issue list view, what columns should display?
```
Example from oily_octo:
ID       STATUS     TITLE
123456   [!]        Fix bug in authentication
```
Desired columns for Linear issues:
- [x] Identifier (e.g., `ENG-123`)
- [x] Status (e.g., `Todo`, `In Progress`, `Done`)
- [ ] Priority (e.g., `🔴 Urgent`, `🟡 High`, `🟢 Low`)
- [x] Assignee
- [x] Title
- [x] Project name
- [x] Labels/tags
- [x] Due date
- [ ] Estimate (points/hours)
- [ ] Other: ___________

**Q3.4:** Should the list be sorted/filterable?
- [x] Sort by: Priority, Status, Updated, Created, Due Date
- [x] Filter by: Team, Project, Assignee, Status, Label

**Q3.5:** How should states/statuses be displayed?
- [x] Text only (e.g., `[Todo]`, `[Done]`)
- [x] Color-coded text (using Neovim highlights)

---

## 4. Issue Detail View

**Q4.0:** When editing attributes on an issue (pressing `<Leader>e`), what should be editable? (These should be editable with a selector instead of by text when "attribute editing" is triggered)
- [x] Status
- [x] Priority
- [x] Assignee
- [x] Labels
- [x] Due date
- [x] Estimate

Note: We will need to flesh out how these selectors work.

**Q4.1:** When viewing an issue (pressing `<CR>`), what should be editable?
- [x] Title
- [x] Description/body

**Q4.2:** What format should the issue detail buffer use?

```
Fix authentication bug (Title without "Title: " prefix)
---

Description goes here...
```

Preferred format is above. 

**Q4.3:** Should comments be included in the detail view?
- [x] Separate view for comments

**Q4.4:** How should saving changes work?
- [x] Auto-save on buffer write (`:w`) (If we struggle to make this work, we can go with a sub-command)

---

## 5. Issue Creation

**Q5.1:** Should the plugin support creating new issues?
- [x] Yes, minimal (just title + description)

**Q5.3:** Should there be shortcuts for common issue types?
- [x] `:Linear new bug` - Create bug report
- [x] `:Linear new feature` - Create feature request
- [x] `:Linear new task` - Create task

We can come up with these templates as we slowly implement them.

---

## 6. Workflow & Actions

**Q6.1:** What quick actions should be available on issues?
- [x] Change status (e.g., `Todo → In Progress → Done`)
- [x] Assign to me
- [x] Change priority
- [x] Archive/delete
- [x] Add to project/cycle
- [x] Copy Linear URL to clipboard
- [x] Open in browser

**Q6.2:** Should there be keyboard shortcuts for state transitions?
- [x] No, use commands only for now

**Q6.3:** Should the plugin support bulk operations?
- [x] No, one-at-a-time is fine for now

---

## 7. Team & Project Context

**Q7.1:** How should team/project context be determined?
- [ ] Auto-detect from git repository (if linked to Linear)
- [ ] Configurable default in setup
- [x] Prompt on first use and put into settings file `~/.local/share/nvim/linear.nvim/`
- [ ] Show all teams/projects (no filtering)

Note: this is mostly stretch goals

---

## 8. Advanced Features

Note: this is mostly stretch goals don't worry about these for now.

**Q8.1:** Integration with other Neovim features:
- [ ] Telescope picker for issues
- [ ] Which-key menu integration
- [ ] Status line component (show current issue)
- [ ] Git branch ↔ Linear issue linking
- [ ] None needed initially

**Q8.2:** Should the plugin support Linear's sub-issues/parent-child relationships?
- [ ] Yes, show hierarchy
- [ ] Yes, but collapsed by default
- [ ] No, too complex

**Q8.3:** Notifications/webhooks:
- [ ] Show when issues assigned to me are updated
- [ ] No real-time features needed

**Q8.4:** Offline mode:
- [ ] Cache issues for offline viewing
- [ ] No, always require connection

---

## 9. Technical Architecture

**Q9.1:** Should this follow the ai.nvim pattern (Lua + Bun/TypeScript)?
- [ ] Yes - Lua frontend, TypeScript backend for API calls
- [ ] No - Pure Lua (use vim.system for API calls)
- [x] Undecided - recommend based on complexity

**Q9.2:** If using TypeScript SDK, what should the build process be?
- [ ] Manual: `cd runner && bun install && bun run build`
- [x] Auto-build on setup if binary missing
- [ ] Pre-built binary checked into repo

**Q9.3:** Error handling preferences:
- [x] Verbose notifications (like current oily_octo)

---

## 10. Migration & Compatibility

**Q10.1:** Should this replace oily_octo or coexist?
- [x] Coexist - I use both GitHub and Linear
- [ ] Replace - moving fully to Linear
- [ ] Extract common code into shared library

**Q10.2:** Should keybindings match oily_octo for consistency?
```
oily_octo mappings:
- <CR> = view details
- g. = toggle closed
- r = refresh
- q = quit
- - = back
```
- [x] Yes, keep same mappings

**Q10.3:** Should there be import/export between GitHub and Linear?
- [x] No, separate systems

---

## 11. Nice-to-Haves (Post-MVP)

All of these are nice to haves!

Rank these features (1 = highest priority):
- Fuzzy search issues by title/description
- Create issue from visual selection (grab code snippet)
- Vim motions in issue list (e.g., `dap` to delete a project)
- Linear cycles/sprints planning view
- Time tracking integration
- Custom views/saved filters
- Export to markdown/PDF
- Other: ___________

---

## 12. Initial MVP Scope

**Q12.1:** For the first working version, which features are MUST-HAVE?
(This helps define what to build first vs. what can wait)

Critical for MVP:
- [x] Authentication
- [x] View Issues
- [x] Edit Issues
- [x] Close Issues

Can wait for v2:
- [x] Change status (e.g., `Todo → In Progress → Done`)
- [x] Assign to me
- [x] Change priority
- [x] Archive/delete
- [x] Add to project/cycle
- [x] Copy Linear URL to clipboard
- [x] Open in browser

---

## Next Steps

Once these questions are answered:

1. **Review API capabilities** - Verify Linear's GraphQL API supports desired features
2. **Create requirements doc** - Transform answers into technical requirements
3. **Design data structures** - Define Lua tables for issues, projects, etc.
4. **Plan architecture** - Decide on Lua-only vs. Lua+TypeScript
5. **Implement MVP** - Build core functionality first
6. **Iterate** - Add features based on usage

---

## References

- Linear API Docs: https://linear.app/developers
- Linear GraphQL Schema: https://studio.apollographql.com/public/Linear-API/variant/current/home
- oily_octo.nvim: `~/.config/nvim/local-plugins/oily_octo.nvim/`
- Existing architecture patterns: See `CLAUDE.md`
