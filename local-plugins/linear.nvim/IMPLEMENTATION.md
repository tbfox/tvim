# linear.nvim Implementation Plan

A phased approach to building a Linear integration for Neovim.

## Architecture Decision

**Recommendation: Pure Lua with `vim.system` for GraphQL calls**

**Rationale:**
- GraphQL queries are just HTTP POST requests with JSON payloads
- `vim.system` + `curl` can handle this without TypeScript overhead
- Simpler build process (no Bun runner to maintain)
- Easy to debug and modify
- Pattern: Similar to oily_octo's use of `gh` CLI, but with direct curl calls

**Trade-off:** If GraphQL queries become too complex or we need strong typing, we can migrate to TypeScript SDK later.

---

## Phase 0: Project Setup & Research

**Goal:** Set up project structure and understand Linear's GraphQL API

### Tasks

- [ ] Create basic directory structure
  ```
  local-plugins/linear.nvim/
  ├── lua/
  │   ├── linear.lua           # Main module with setup()
  │   ├── linear/
  │   │   ├── api.lua          # GraphQL API client
  │   │   ├── auth.lua         # Authentication helper
  │   │   ├── cache.lua        # Response caching
  │   │   ├── ui.lua           # Buffer management & rendering
  │   │   └── utils.lua        # Shared utilities
  │   └── linear.nvim.lua      # Optional: namespace wrapper
  └── README.md
  ```

- [ ] Research Linear GraphQL API
  - [ ] Visit https://studio.apollographql.com/public/Linear-API/variant/current/home
  - [ ] Identify queries needed for MVP:
    - `issues` query (list with filters)
    - `issue` query (single issue details)
    - `updateIssue` mutation (edit title/description)
    - `issueCreate` mutation (create new issue)
    - `issueArchive` mutation (close/archive)
  - [ ] Document required fields and return types
  - [ ] Test queries using Linear's GraphQL playground or curl

- [ ] Create plugin spec in `~/.config/nvim/lua/plugins/linear.lua`
  ```lua
  return {
    {
      dir = require("lib.local-plugin")("linear.nvim"),
      config = function()
        require("linear").setup()
      end
    }
  }
  ```

**Deliverable:** Project structure exists, GraphQL queries documented, plugin loads without errors

---

## Phase 1: MVP - Core Infrastructure

**Goal:** Authentication, API client, and basic command structure

### Tasks

- [ ] **Auth module** (`lua/linear/auth.lua`)
  - [ ] Function to get API key from `LINEAR_API_KEY` env variable
  - [ ] Validation that key exists and is non-empty
  - [ ] Helper to show friendly error if not authenticated
  ```lua
  M.get_api_key() -> string | nil
  M.ensure_authenticated() -> boolean (shows error if false)
  ```

- [ ] **API client** (`lua/linear/api.lua`)
  - [ ] Function to make GraphQL requests via curl
  - [ ] Input: query string, variables table
  - [ ] Output: parsed JSON response or error
  - [ ] Handle HTTP errors (401, 429, 500, etc.)
  ```lua
  M.query(query_string, variables) -> result, error
  ```
  - [ ] Example curl command structure:
  ```bash
  curl -X POST https://api.linear.app/graphql \
    -H "Content-Type: application/json" \
    -H "Authorization: ${LINEAR_API_KEY}" \
    -d '{"query": "...", "variables": {...}}'
  ```

- [ ] **Cache module** (`lua/linear/cache.lua`)
  - [ ] Simple in-memory cache (table with keys)
  - [ ] Functions: `get(key)`, `set(key, value)`, `clear(key)`, `clear_all()`
  - [ ] Used for storing fetched issues between renders

- [ ] **Main module** (`lua/linear.lua`)
  - [ ] `M.setup()` function (can be empty initially)
  - [ ] Register `:Linear` command with subcommands
  - [ ] Bind `<F5>` to `:Linear issues`
  ```lua
  vim.api.nvim_create_user_command("Linear", handle_command, {
    nargs = "*",
    complete = function() return {"issues", "new"} end
  })
  vim.keymap.set('n', '<F5>', function() require("linear").open_issues() end)
  ```

- [ ] **Test authentication**
  - [ ] Set `LINEAR_API_KEY` in environment
  - [ ] Run `:Linear test-auth` command that makes a simple query
  - [ ] Verify error handling for missing/invalid key

**Deliverable:** Can authenticate with Linear API, make basic GraphQL queries, commands registered

---

## Phase 2: MVP - Issue Listing

**Goal:** Display a list of issues in an oil.nvim-style buffer

### Tasks

- [ ] **Define GraphQL query for issue list**
  ```graphql
  query ListIssues($first: Int, $filter: IssueFilter) {
    issues(first: $first, filter: $filter) {
      nodes {
        id
        identifier       # e.g., "ENG-123"
        title
        state {
          name           # e.g., "Todo", "In Progress"
        }
        assignee {
          name
        }
        project {
          name
        }
        labels {
          nodes {
            name
          }
        }
        dueDate
        updatedAt
      }
    }
  }
  ```

- [ ] **Add issue listing to API module**
  ```lua
  M.list_issues(filter_opts) -> issues_table, error
  ```
  - [ ] Default to showing open issues only
  - [ ] Support `includeArchived` filter option

- [ ] **UI module - Issue list rendering** (`lua/linear/ui.lua`)
  - [ ] Function to create buffer for issue list
  - [ ] Format issues into table rows:
  ```
  ID         STATUS        ASSIGNEE    PROJECT      DUE        TITLE
  ENG-123    [In Progress] @alice      Backend      2026-03-10 Fix auth bug
  ENG-124    [Todo]        @bob        Frontend     -          Add dark mode
  ```
  - [ ] Use `string.format` with column widths
  - [ ] Truncate long titles with ellipsis
  - [ ] Handle nil values (no assignee, no project, etc.)

- [ ] **State management**
  - [ ] Track `show_archived` boolean (like oily_octo's `show_closed`)
  - [ ] Cache fetched issues in cache module
  - [ ] Re-render on state changes without re-fetching

- [ ] **Keybindings for issue list buffer**
  - [ ] `g.` - Toggle archived issues (re-render from cache)
  - [ ] `r` - Refresh (clear cache, re-fetch, re-render)
  - [ ] `q` - Quit (close buffer)
  - [ ] `<CR>` - View issue details (stub for Phase 3)
  - [ ] `-` - Back/close (same as `q` for now)

- [ ] **Syntax highlighting**
  - [ ] Define highlight groups for status (Todo, InProgress, Done, etc.)
  - [ ] Apply highlights to status column
  - [ ] Set buffer filetype to something custom (e.g., `linear-issues`)

- [ ] **Command implementation**
  - [ ] `:Linear issues` - Opens issue list
  - [ ] `<F5>` keybinding calls this

**Deliverable:** Can view a formatted list of issues, toggle archived, refresh

---

## Phase 3: MVP - Issue Viewing & Editing

**Goal:** View and edit issue title/description, auto-save on `:w`

### Tasks

- [ ] **Define GraphQL query for single issue**
  ```graphql
  query GetIssue($id: String!) {
    issue(id: $id) {
      id
      identifier
      title
      description
      state { name }
      # ... other fields for display
    }
  }
  ```

- [ ] **Add single issue fetch to API**
  ```lua
  M.get_issue(issue_id) -> issue_table, error
  ```

- [ ] **Issue detail buffer creation**
  - [ ] Parse issue ID from list buffer line
  - [ ] Fetch issue details via API
  - [ ] Create new buffer with format:
  ```
  Fix authentication bug
  ---

  ## Description
  Users are getting 401 errors when...

  ## Steps to Reproduce
  1. ...
  ```
  - [ ] Set buffer options:
    - `buftype = "nofile"`
    - `filetype = "markdown"`
    - `modifiable = true`
  - [ ] Store issue ID in buffer variable: `vim.b[buf].linear_issue_id = id`

- [ ] **Parse edited buffer back to issue**
  - [ ] Function to extract title (first line before `---`)
  - [ ] Function to extract description (everything after `---`)
  - [ ] Handle empty descriptions gracefully

- [ ] **Define GraphQL mutation for updating issue**
  ```graphql
  mutation UpdateIssue($id: String!, $input: IssueUpdateInput!) {
    issueUpdate(id: $id, input: $input) {
      success
      issue {
        id
        title
        description
      }
    }
  }
  ```

- [ ] **Auto-save on `:w` implementation**
  - [ ] Set buffer option: `vim.bo[buf].buftype = "acwrite"`
  - [ ] Register `BufWriteCmd` autocmd for buffer
  - [ ] On write:
    - Parse title and description from buffer
    - Call `issueUpdate` mutation
    - Show success/error notification
    - Mark buffer as unmodified
    - Refresh issue list cache (invalidate)

- [ ] **Keybindings for issue detail buffer**
  - [ ] `-` - Go back to issue list
  - [ ] `q` - Close buffer (warn if modified)
  - [ ] `<CR>` - No-op (or show metadata popup?)

- [ ] **Error handling**
  - [ ] Validate title is non-empty before saving
  - [ ] Handle API errors gracefully
  - [ ] Show helpful error messages via `vim.notify`

**Deliverable:** Can view issue, edit title/description, save with `:w`, return to list

---

## Phase 4: MVP - Issue Creation & Archiving

**Goal:** Create new issues and close/archive existing ones

### Tasks

- [ ] **Define GraphQL mutation for creating issue**
  ```graphql
  mutation CreateIssue($input: IssueCreateInput!) {
    issueCreate(input: $input) {
      success
      issue {
        id
        identifier
        title
      }
    }
  }
  ```
  - [ ] Required fields: `title`, `teamId` (will need to handle team selection)
  - [ ] Optional: `description`, `stateId`, `priority`, etc.

- [ ] **Team selection for new issues**
  - [ ] Query to get user's teams:
  ```graphql
  query GetTeams {
    teams {
      nodes {
        id
        name
        key  # e.g., "ENG"
      }
    }
  }
  ```
  - [ ] If only one team, use it automatically
  - [ ] If multiple teams, show selection prompt (`vim.ui.select`)
  - [ ] Cache selected team for session (optional: persist to `~/.local/share/nvim/linear.nvim/settings.json`)

- [ ] **Issue creation command: `:Linear new`**
  - [ ] Create buffer with template:
  ```
  New Issue Title
  ---

  Description goes here...
  ```
  - [ ] Set `vim.b[buf].linear_new_issue = true` (marker for new vs edit)
  - [ ] On save (`:w`):
    - Select team if needed
    - Parse title/description
    - Call `issueCreate` mutation
    - Close buffer and refresh issue list
    - Notify with new issue identifier (e.g., "Created ENG-125")

- [ ] **Issue templates for types**
  - [ ] `:Linear new bug` template:
  ```
  Bug:
  ---

  ## Steps to Reproduce
  1.

  ## Expected Behavior


  ## Actual Behavior

  ```
  - [ ] `:Linear new feature` template:
  ```
  Feature:
  ---

  ## User Story
  As a [user type], I want [goal] so that [benefit].

  ## Acceptance Criteria
  - [ ]
  ```
  - [ ] `:Linear new task` template:
  ```
  Task:
  ---

  ## Details


  ## Checklist
  - [ ]
  ```

- [ ] **Define GraphQL mutation for archiving**
  ```graphql
  mutation ArchiveIssue($id: String!) {
    issueArchive(id: $id) {
      success
    }
  }
  ```

- [ ] **Archive/close command**
  - [ ] `:Linear close` command (buffer-local when viewing issue)
  - [ ] Show confirmation popup (reuse oily_octo's pattern)
  - [ ] Call `issueArchive` mutation
  - [ ] Close buffer and refresh issue list
  - [ ] Notify success

**Deliverable:** Can create new issues with templates, archive/close issues

---

## Phase 5: V2 - Additional Entity Views

**Goal:** Browse Projects, Teams, Cycles, Labels

### Tasks

- [ ] **Projects view** (`:Linear projects`)
  - [ ] GraphQL query for projects list
  - [ ] Render as list with columns: Name, Status, Progress, Lead
  - [ ] `<CR>` to view project issues (filtered issue list)
  - [ ] Same keybindings: `r`, `q`, `-`

- [ ] **Teams view** (`:Linear teams`)
  - [ ] GraphQL query for teams list
  - [ ] Render as list with columns: Key, Name, Members
  - [ ] `<CR>` to view team issues

- [ ] **Cycles view** (`:Linear cycles`)
  - [ ] GraphQL query for cycles
  - [ ] Render with columns: Name, Start, End, Progress
  - [ ] `<CR>` to view cycle issues

- [ ] **Labels view** (`:Linear labels`)
  - [ ] GraphQL query for labels
  - [ ] Render with columns: Name, Color, Issues
  - [ ] `<CR>` to view labeled issues

- [ ] **Navigation state management**
  - [ ] Track navigation stack (e.g., Teams → Team XYZ → Issues)
  - [ ] `-` key pops from stack (goes back)
  - [ ] Preserve filters when navigating

**Deliverable:** Can browse and navigate Projects, Teams, Cycles, Labels

---

## Phase 6: V2 - Advanced Actions & Attribute Editing

**Goal:** Change status, priority, assignee, etc. with selectors

### Tasks

- [ ] **Fetch workflow states for status selection**
  ```graphql
  query GetWorkflowStates($teamId: String!) {
    workflowStates(filter: {team: {id: {eq: $teamId}}}) {
      nodes {
        id
        name
        type  # e.g., "started", "completed"
      }
    }
  }
  ```

- [ ] **Status change selector**
  - [ ] Command: `:Linear status` (when viewing issue)
  - [ ] Fetch available states for issue's team
  - [ ] Show `vim.ui.select` with state names
  - [ ] Update issue with `issueUpdate` mutation
  - [ ] Re-render issue view

- [ ] **Priority change selector**
  - [ ] Command: `:Linear priority`
  - [ ] Options: No priority, Urgent, High, Normal, Low
  - [ ] Update via `issueUpdate` mutation

- [ ] **Assignee selector**
  - [ ] Command: `:Linear assign`
  - [ ] Fetch team members
  - [ ] Show `vim.ui.select` with member names
  - [ ] Update via `issueUpdate` mutation
  - [ ] Special option: "Assign to me"

- [ ] **Labels selector**
  - [ ] Command: `:Linear labels`
  - [ ] Fetch available labels
  - [ ] Multi-select UI (custom or sequential `vim.ui.select`)
  - [ ] Update via `issueUpdate` mutation

- [ ] **Due date picker**
  - [ ] Command: `:Linear due`
  - [ ] Simple input: YYYY-MM-DD or relative (e.g., "3 days", "next friday")
  - [ ] Parse and validate
  - [ ] Update via `issueUpdate` mutation

- [ ] **Estimate input**
  - [ ] Command: `:Linear estimate`
  - [ ] Input: number (points or hours, depending on team config)
  - [ ] Update via `issueUpdate` mutation

- [ ] **`<Leader>e` keybinding for attribute editor**
  - [ ] When viewing issue, show menu:
  ```
  Edit Attributes:
  1. Status
  2. Priority
  3. Assignee
  4. Labels
  5. Due Date
  6. Estimate
  ```
  - [ ] Use `vim.ui.select` to choose, then run appropriate command

- [ ] **Utility commands**
  - [ ] `:Linear url` - Copy Linear URL to clipboard
  - [ ] `:Linear open` - Open issue in browser (use `open` or `xdg-open`)
  - [ ] `:Linear project` - Add issue to project (selector)
  - [ ] `:Linear cycle` - Add issue to cycle (selector)

**Deliverable:** Can change all issue attributes via selectors, utility commands work

---

## Phase 7: V2 - Comments View

**Goal:** View and add comments to issues

### Tasks

- [ ] **GraphQL query for comments**
  ```graphql
  query GetIssueComments($issueId: String!) {
    issue(id: $issueId) {
      comments {
        nodes {
          id
          body
          user {
            name
          }
          createdAt
        }
      }
    }
  }
  ```

- [ ] **Comments view buffer**
  - [ ] Command: `:Linear comments` (when viewing issue)
  - [ ] Format:
  ```
  Comments for ENG-123: Fix authentication bug
  ────────────────────────────────────────────

  @alice (2026-03-01 10:23)
  I think the issue is in the JWT validation...

  @bob (2026-03-01 14:45)
  Confirmed, I'll push a fix shortly.

  ────────────────────────────────────────────
  [Type your comment below, then :w to submit]


  ```

- [ ] **Comment creation**
  - [ ] GraphQL mutation:
  ```graphql
  mutation CreateComment($issueId: String!, $body: String!) {
    commentCreate(input: {issueId: $issueId, body: $body}) {
      success
      comment {
        id
      }
    }
  }
  ```
  - [ ] On `:w`, parse new comment text (after separator)
  - [ ] Submit via mutation
  - [ ] Refresh comments view
  - [ ] Clear input area

- [ ] **Keybindings**
  - [ ] `-` to go back to issue detail
  - [ ] `r` to refresh comments

**Deliverable:** Can view and add comments to issues

---

## Phase 8: Polish & Optimization

**Goal:** Improve UX, add sorting/filtering, optimize performance

### Tasks

- [ ] **Sorting in issue list**
  - [ ] Command: `:Linear sort [field]`
  - [ ] Fields: `updated`, `created`, `priority`, `due`
  - [ ] Store sort preference in state
  - [ ] Re-render list with sorted data

- [ ] **Filtering in issue list**
  - [ ] Command: `:Linear filter [type] [value]`
  - [ ] Types: `assignee`, `project`, `status`, `label`
  - [ ] Build GraphQL filter from active filters
  - [ ] Show active filters in buffer header
  - [ ] Command to clear filters: `:Linear filter clear`

- [ ] **Loading indicators**
  - [ ] Show "Loading..." in buffer while fetching
  - [ ] Progress notifications for long operations

- [ ] **Better error messages**
  - [ ] Parse GraphQL error responses
  - [ ] Show field-specific errors (e.g., "Title cannot be empty")
  - [ ] Link to docs for authentication errors

- [ ] **Persistent settings**
  - [ ] Save to `~/.local/share/nvim/linear.nvim/settings.json`:
    - Last selected team
    - Default filters
    - Sort preferences
  - [ ] Load on startup

- [ ] **Optimization**
  - [ ] Debounce cache invalidation
  - [ ] Pagination support for large issue lists (GraphQL cursors)
  - [ ] Lazy-load comments only when viewed

- [ ] **Help documentation**
  - [ ] `:Linear help` command shows keybindings and commands
  - [ ] Add to README.md

**Deliverable:** Polished, performant plugin with sorting/filtering

---

## Testing Checklist

Throughout implementation, test these scenarios:

- [ ] Missing `LINEAR_API_KEY` environment variable
- [ ] Invalid API key (401 error)
- [ ] Rate limiting (429 error)
- [ ] Network errors (offline, timeout)
- [ ] Empty issue lists
- [ ] Issues with missing fields (no assignee, no project, etc.)
- [ ] Very long issue titles (truncation)
- [ ] Concurrent buffer edits (don't lose work)
- [ ] Buffer auto-save race conditions

---

## Migration Path

If pure Lua becomes too complex:

1. Extract GraphQL queries to separate file
2. Create TypeScript runner (similar to ai.nvim):
   ```
   local-plugins/linear.nvim/runner/
   ├── src/
   │   ├── index.ts
   │   ├── linear-client.ts
   │   └── queries.ts
   ├── package.json
   └── tsconfig.json
   ```
3. Use Linear's TypeScript SDK: `@linear/sdk`
4. Lua calls TypeScript binary via `vim.system`
5. Binary reads input from stdin, writes JSON to stdout

**Trigger for migration:** If GraphQL query building or error handling becomes unwieldy in Lua.

---

## Success Criteria

### MVP Complete When:
- [x] Can authenticate with Linear
- [x] Can view list of issues
- [x] Can view individual issue
- [x] Can edit issue title/description
- [x] Can create new issue
- [x] Can archive/close issue
- [x] All keybindings work (`<CR>`, `g.`, `r`, `q`, `-`)

### V2 Complete When:
- [x] Can browse Projects, Teams, Cycles, Labels
- [x] Can change issue attributes (status, priority, assignee, labels, due date, estimate)
- [x] Can view and add comments
- [x] Can copy URL and open in browser
- [x] Sorting and filtering work

### Ready for Daily Use When:
- [x] Error handling is robust
- [x] Performance is acceptable (< 1s for most operations)
- [x] No data loss (changes save reliably)
- [x] Documentation exists (README with setup and usage)

---

## Next Steps

1. Start with **Phase 0**: Set up project structure
2. Use Linear's GraphQL playground to test queries
3. Build **Phase 1** (auth + API client) - this is the foundation
4. Iterate through phases, testing each before moving on
5. Get MVP working end-to-end before adding V2 features

Good luck! 🚀
