-- Issue listing module for linear.nvim
-- Handles fetching, rendering, and interacting with issue lists

local api = require("linear.api")
local cache = require("linear.cache")
local ui = require("linear.ui")
local utils = require("linear.utils")

local M = {}

-- State
M.show_archived = false
M.current_buffer = nil
M.team_filter = nil -- Team key filter (e.g., "WFM1")
M.assignee_filter = nil -- Assignee user ID
M.assignee_name = nil -- Assignee display name (for UI)

-- GraphQL query for listing issues
local ISSUES_QUERY = [[
  query ListIssues($first: Int, $includeArchived: Boolean, $teamFilter: IssueFilter) {
    issues(
      first: $first
      includeArchived: $includeArchived
      orderBy: updatedAt
      filter: $teamFilter
    ) {
      nodes {
        id
        identifier
        title
        description
        state {
          id
          name
          type
        }
        assignee {
          id
          name
          email
        }
        team {
          id
          key
          name
        }
        project {
          id
          name
        }
        labels {
          nodes {
            id
            name
          }
        }
        dueDate
        updatedAt
        createdAt
        archivedAt
      }
    }
  }
]]

-- GraphQL query for getting a single issue
local GET_ISSUE_QUERY = [[
  query GetIssue($id: String!) {
    issue(id: $id) {
      id
      identifier
      title
      description
      url
      state {
        id
        name
        type
      }
      assignee {
        id
        name
        email
      }
      team {
        id
        key
        name
      }
      project {
        id
        name
      }
      labels {
        nodes {
          id
          name
        }
      }
      dueDate
      updatedAt
      createdAt
    }
  }
]]

-- GraphQL mutation for updating an issue
local UPDATE_ISSUE_MUTATION = [[
  mutation UpdateIssue($id: String!, $title: String, $description: String) {
    issueUpdate(id: $id, input: { title: $title, description: $description }) {
      success
      issue {
        id
        identifier
        title
        description
      }
    }
  }
]]

-- Fetch a single issue by identifier
-- @param identifier string: Issue identifier (e.g., "ENG-123")
-- @return issue table|nil: Issue data
-- @return error string|nil: Error message if failed
function M.fetch_issue(identifier)
  vim.notify("Fetching issue " .. identifier .. "...", vim.log.levels.INFO)

  local result, err = api.query(GET_ISSUE_QUERY, { id = identifier })

  if err then
    return nil, err
  end

  if not result.data or not result.data.issue then
    return nil, "Issue not found"
  end

  return result.data.issue, nil
end

-- Update an issue
-- @param issue_id string: Issue ID
-- @param title string: New title
-- @param description string: New description
-- @return result table|nil: Update result
-- @return error string|nil: Error message if failed
function M.update_issue(issue_id, title, description)
  local variables = {
    id = issue_id,
    title = title,
    description = description
  }

  local result, err = api.query(UPDATE_ISSUE_MUTATION, variables)

  if err then
    return nil, err
  end

  if not result.data or not result.data.issueUpdate then
    return nil, "Unexpected response format"
  end

  if not result.data.issueUpdate.success then
    return nil, "Update failed"
  end

  return result.data.issueUpdate.issue, nil
end

-- Fetch issues from API
-- @param include_archived boolean: Whether to include archived issues
-- @return issues table|nil: Array of issues
-- @return error string|nil: Error message if failed
function M.fetch_issues(include_archived)
  local variables = {
    first = 100, -- TODO: Add pagination later
    includeArchived = include_archived or false
  }

  -- Build filter object
  local filter = {}

  -- Add team filter if specified
  if M.team_filter then
    filter.team = {
      key = {
        eq = M.team_filter
      }
    }
  end

  -- Add assignee filter if specified
  if M.assignee_filter then
    filter.assignee = {
      id = {
        eq = M.assignee_filter
      }
    }
  end

  -- Only add filter if we have any filters
  if next(filter) then
    variables.teamFilter = filter
  end

  local filter_parts = {}
  if M.team_filter then
    table.insert(filter_parts, "team: " .. M.team_filter)
  end
  if M.assignee_name then
    table.insert(filter_parts, "assignee: " .. M.assignee_name)
  end
  local filter_msg = #filter_parts > 0 and (" (" .. table.concat(filter_parts, ", ") .. ")") or ""
  vim.notify("Fetching issues from Linear" .. filter_msg .. "...", vim.log.levels.INFO)

  local result, err = api.query(ISSUES_QUERY, variables)

  if err then
    return nil, err
  end

  if not result.data or not result.data.issues then
    return nil, "Unexpected response format"
  end

  return result.data.issues.nodes, nil
end

-- Get issues (from cache or fetch)
-- @param force_refresh boolean: Force re-fetch even if cached
-- @return issues table|nil: Array of issues
-- @return error string|nil: Error message if failed
function M.get_issues(force_refresh)
  local cache_key = "issues_"
    .. tostring(M.show_archived)
    .. "_" .. (M.team_filter or "all")
    .. "_" .. (M.assignee_filter or "all")

  if not force_refresh then
    local cached = cache.get(cache_key)
    if cached then
      return cached, nil
    end
  end

  local issues, err = M.fetch_issues(M.show_archived)
  if err then
    return nil, err
  end

  -- Cache the results
  cache.set(cache_key, issues)

  return issues, nil
end

-- Format issue state with color coding
-- @param state table: State object with name and type
-- @return string: Formatted state
function M.format_state(state)
  if not state then return "[Unknown]" end

  local type_map = {
    backlog = "○",
    unstarted = "○",
    started = "◐",
    completed = "●",
    canceled = "✕"
  }

  local icon = type_map[state.type] or "•"
  return string.format("[%s %s]", icon, state.name)
end

-- Render issue list to buffer
-- @param buf number: Buffer handle
-- @param issues table: Array of issues
function M.render_issue_list(buf, issues)
  local lines = {}

  -- Header
  local header = ui.format_row({
    { text = "ID", width = 12 },
    { text = "STATUS", width = 20 },
    { text = "ASSIGNEE", width = 12 },
    { text = "PROJECT", width = 15 },
    { text = "DUE", width = 12 },
    { text = "TITLE", width = 60 }
  })
  table.insert(lines, header)
  table.insert(lines, string.rep("─", 131))

  -- Filter and render issues
  for _, issue in ipairs(issues) do
    -- Handle vim.NIL (JSON null becomes vim.NIL, not nil)
    local is_archived = issue.archivedAt ~= nil and issue.archivedAt ~= vim.NIL

    -- Show based on archived state
    if M.show_archived or not is_archived then
      local row = ui.format_row({
        { text = issue.identifier, width = 12 },
        { text = M.format_state(issue.state), width = 20 },
        { text = utils.format_assignee(issue.assignee), width = 12 },
        { text = (issue.project and issue.project ~= vim.NIL and issue.project.name) or "-", width = 15 },
        { text = utils.format_date(issue.dueDate), width = 12 },
        { text = issue.title, width = 60 }
      })
      table.insert(lines, row)
    end
  end

  -- Show count
  local visible_count = 0
  for _, issue in ipairs(issues) do
    local is_archived = issue.archivedAt ~= nil and issue.archivedAt ~= vim.NIL
    if M.show_archived or not is_archived then
      visible_count = visible_count + 1
    end
  end

  table.insert(lines, "")
  local filter_parts = {}
  if M.team_filter then
    table.insert(filter_parts, "Team: " .. M.team_filter)
  end
  if M.assignee_name then
    table.insert(filter_parts, "Assignee: " .. M.assignee_name)
  end
  local filter_info = #filter_parts > 0 and (" | " .. table.concat(filter_parts, " | ") .. " (clear with gc)") or ""
  table.insert(lines, string.format("Showing %d issue(s) | Archived: %s (toggle with g.)%s",
    visible_count, M.show_archived and "shown" or "hidden", filter_info))

  ui.set_lines(buf, lines)
end

-- Set up syntax highlighting
-- @param buf number: Buffer handle
function M.setup_highlights(buf)
  -- Define highlight groups if they don't exist
  vim.cmd([[
    highlight default link LinearIssueId Identifier
    highlight default link LinearStateBacklog Comment
    highlight default link LinearStateStarted Special
    highlight default link LinearStateCompleted String
    highlight default link LinearStateCanceled Error
    highlight default LinearAssignee guifg=#7c3aed ctermfg=98
  ]])

  -- Apply highlights (simple pattern matching for now)
  -- TODO: Use tree-sitter or better matching
  vim.api.nvim_buf_call(buf, function()
    vim.fn.matchadd("LinearIssueId", "\\v^\\w+-\\d+")
    vim.fn.matchadd("LinearStateBacklog", "\\[○ [^\\]]*\\]")
    vim.fn.matchadd("LinearStateStarted", "\\[◐ [^\\]]*\\]")
    vim.fn.matchadd("LinearStateCompleted", "\\[● [^\\]]*\\]")
    vim.fn.matchadd("LinearStateCanceled", "\\[✕ [^\\]]*\\]")
    vim.fn.matchadd("LinearAssignee", "@\\w\\+")
  end)
end

-- Refresh issue list
function M.refresh()
  if not M.current_buffer or not vim.api.nvim_buf_is_valid(M.current_buffer) then
    return
  end

  -- Clear cache and re-fetch
  cache.clear_all()

  local issues, err = M.get_issues(true)
  if err then
    vim.notify("Failed to fetch issues: " .. err, vim.log.levels.ERROR)
    return
  end

  M.render_issue_list(M.current_buffer, issues)
  vim.notify("Refreshed " .. #issues .. " issue(s)", vim.log.levels.INFO)
end

-- Toggle showing archived issues
function M.toggle_archived()
  M.show_archived = not M.show_archived

  if not M.current_buffer or not vim.api.nvim_buf_is_valid(M.current_buffer) then
    return
  end

  local issues, err = M.get_issues(false) -- Use cache
  if err then
    vim.notify("Failed to get issues: " .. err, vim.log.levels.ERROR)
    return
  end

  M.render_issue_list(M.current_buffer, issues)
  vim.notify("Archived issues: " .. (M.show_archived and "shown" or "hidden"), vim.log.levels.INFO)
end

-- Clear all filters and show all issues
function M.clear_filter()
  if not M.team_filter and not M.assignee_filter then
    vim.notify("No filter active", vim.log.levels.INFO)
    return
  end

  M.team_filter = nil
  M.assignee_filter = nil
  M.assignee_name = nil
  cache.clear_all()

  if not M.current_buffer or not vim.api.nvim_buf_is_valid(M.current_buffer) then
    return
  end

  local issues, err = M.get_issues(true)
  if err then
    vim.notify("Failed to fetch issues: " .. err, vim.log.levels.ERROR)
    return
  end

  M.render_issue_list(M.current_buffer, issues)
  vim.notify("Filters cleared - showing all issues", vim.log.levels.INFO)
end

-- Set assignee filter and refresh issues
-- @param user_id string: User ID to filter by
-- @param user_name string: User display name (for UI)
function M.set_assignee_filter(user_id, user_name)
  M.assignee_filter = user_id
  M.assignee_name = user_name
  cache.clear_all()

  -- If issues buffer is open, refresh it
  if M.current_buffer and vim.api.nvim_buf_is_valid(M.current_buffer) then
    local issues, err = M.get_issues(true)
    if err then
      vim.notify("Failed to fetch issues: " .. err, vim.log.levels.ERROR)
      return
    end

    M.render_issue_list(M.current_buffer, issues)
    vim.notify("Filtered by assignee: " .. user_name, vim.log.levels.INFO)
  else
    -- Open issues view with filter
    M.open()
  end
end

-- Format issue for display in detail buffer
-- @param issue table: Issue data
-- @return lines table: Array of lines for buffer
function M.format_issue_detail(issue)
  local lines = {}

  -- Title (first line)
  table.insert(lines, issue.title)

  -- Separator
  table.insert(lines, "---")
  table.insert(lines, "")

  -- Description (or placeholder if empty)
  local description = issue.description
  if description and description ~= vim.NIL and description ~= "" then
    -- Split description into lines
    for line in description:gmatch("[^\r\n]+") do
      table.insert(lines, line)
    end
  else
    table.insert(lines, "## Description")
    table.insert(lines, "")
    table.insert(lines, "Add your description here...")
  end

  return lines
end

-- Parse issue detail buffer back to title and description
-- @param buf number: Buffer handle
-- @return title string: Issue title (first line before ---)
-- @return description string: Issue description (everything after ---)
function M.parse_issue_detail(buf)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

  -- Find separator
  local separator_idx = nil
  for i, line in ipairs(lines) do
    if line:match("^%-%-%-+$") then
      separator_idx = i
      break
    end
  end

  if not separator_idx or separator_idx < 2 then
    return nil, nil, "Invalid format: missing '---' separator"
  end

  -- Title is first line
  local title = lines[1]
  if not title or title:match("^%s*$") then
    return nil, nil, "Title cannot be empty"
  end

  -- Description is everything after separator (and empty line)
  local desc_lines = {}
  for i = separator_idx + 2, #lines do
    table.insert(desc_lines, lines[i])
  end
  local description = table.concat(desc_lines, "\n")

  -- Trim trailing whitespace
  description = description:gsub("%s+$", "")

  return title, description, nil
end

-- Save issue from detail buffer
-- @param buf number: Buffer handle
function M.save_issue_detail(buf)
  local issue_id = vim.b[buf].linear_issue_id
  if not issue_id then
    vim.notify("No issue associated with this buffer", vim.log.levels.ERROR)
    return
  end

  -- Parse title and description
  local title, description, err = M.parse_issue_detail(buf)
  if err then
    vim.notify("Failed to parse issue: " .. err, vim.log.levels.ERROR)
    return
  end

  vim.notify("Saving issue " .. issue_id .. "...", vim.log.levels.INFO)

  -- Update issue via API
  local result, update_err = M.update_issue(issue_id, title, description)
  if update_err then
    vim.notify("Failed to update issue: " .. update_err, vim.log.levels.ERROR)
    return
  end

  -- Mark buffer as unmodified
  vim.bo[buf].modified = false

  -- Clear issues cache to force refresh
  cache.clear_all()

  vim.notify("✓ Issue " .. issue_id .. " updated successfully", vim.log.levels.INFO)
end

-- Open issue in browser
-- @param buf number: Buffer handle
function M.open_issue_in_browser(buf)
  local issue_url = vim.b[buf].linear_issue_url
  if not issue_url then
    vim.notify("No issue URL associated with this buffer", vim.log.levels.ERROR)
    return
  end

  -- Determine the open command based on OS
  local open_cmd
  if vim.fn.has("mac") == 1 then
    open_cmd = "open"
  elseif vim.fn.has("unix") == 1 then
    open_cmd = "xdg-open"
  elseif vim.fn.has("win32") == 1 then
    open_cmd = "start"
  else
    vim.notify("Unsupported operating system", vim.log.levels.ERROR)
    return
  end

  -- Open URL in browser
  vim.fn.jobstart({ open_cmd, issue_url }, { detach = true })
  vim.notify("Opening issue in browser...", vim.log.levels.INFO)
end

-- View issue details
function M.view_issue_details()
  local issue_id = ui.parse_issue_id_from_line()
  if not issue_id then
    vim.notify("No issue found on current line", vim.log.levels.WARN)
    return
  end

  -- Fetch issue details
  local issue, err = M.fetch_issue(issue_id)
  if err then
    vim.notify("Failed to fetch issue: " .. err, vim.log.levels.ERROR)
    return
  end

  -- Create detail buffer
  local buf = ui.create_buffer("nofile", "markdown")

  -- Store issue ID and URL in buffer variables
  vim.b[buf].linear_issue_id = issue_id
  vim.b[buf].linear_issue_url = issue.url

  -- Format and set buffer content
  local lines = M.format_issue_detail(issue)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  -- Make buffer modifiable
  vim.bo[buf].modifiable = true

  -- Set buffer name
  vim.api.nvim_buf_set_name(buf, "linear://" .. issue_id)

  -- Set up keybindings for detail buffer
  local opts = { buffer = buf, silent = true }
  vim.keymap.set('n', '-', function()
    -- Go back to issues list
    vim.api.nvim_buf_delete(buf, { force = false })
    -- Reopen issues list if it was closed
    if not M.current_buffer or not vim.api.nvim_buf_is_valid(M.current_buffer) then
      M.open(M.team_filter)
    else
      vim.api.nvim_set_current_buf(M.current_buffer)
    end
  end, opts)

  vim.keymap.set('n', 'q', function()
    if vim.bo[buf].modified then
      local choice = vim.fn.confirm("Buffer has unsaved changes. Save before closing?", "&Yes\n&No\n&Cancel", 3)
      if choice == 1 then
        M.save_issue_detail(buf)
        vim.api.nvim_buf_delete(buf, { force = false })
      elseif choice == 2 then
        vim.api.nvim_buf_delete(buf, { force = true })
      end
      -- choice == 3 or 0 (cancel/escape): do nothing
    else
      vim.api.nvim_buf_delete(buf, { force = false })
    end
  end, opts)

  vim.keymap.set('n', 'gx', function()
    M.open_issue_in_browser(buf)
  end, vim.tbl_extend("force", opts, { desc = "Open issue in browser" }))

  -- Switch to buffer
  vim.api.nvim_set_current_buf(buf)

  -- Move cursor to title
  vim.api.nvim_win_set_cursor(0, {1, 0})
end

-- Close issue list and clean up
function M.close()
  if M.current_buffer and vim.api.nvim_buf_is_valid(M.current_buffer) then
    vim.api.nvim_buf_delete(M.current_buffer, { force = true })
  end
  M.current_buffer = nil
end

-- Open issue list buffer
-- @param team_filter string|nil: Team key to filter by (e.g., "WFM1")
function M.open(team_filter)
  local auth = require("linear.auth")

  -- Check authentication first
  if not auth.ensure_authenticated() then
    return
  end

  -- Set team filter and clear cache if changed
  if team_filter ~= M.team_filter then
    M.team_filter = team_filter
    -- Clear assignee filter when changing team filter
    M.assignee_filter = nil
    M.assignee_name = nil
    cache.clear_all()
  end

  -- Fetch issues
  local issues, err = M.get_issues(false)
  if err then
    vim.notify("Failed to fetch issues: " .. err, vim.log.levels.ERROR)
    return
  end

  local filter_msg = M.team_filter and (" for team " .. M.team_filter) or ""
  vim.notify("Loaded " .. #issues .. " issue(s)" .. filter_msg, vim.log.levels.INFO)

  -- Create buffer
  local buf = ui.create_buffer("nofile", "linear-issues")
  M.current_buffer = buf

  -- Render issues
  M.render_issue_list(buf, issues)

  -- Set up highlighting
  M.setup_highlights(buf)

  -- Make buffer read-only
  vim.bo[buf].modifiable = false

  -- Set up keybindings
  ui.set_list_keymaps(buf, {
    view_detail = M.view_issue_details,
    toggle = M.toggle_archived,
    refresh = M.refresh,
    back = M.close
  })

  -- Add additional keybinding for clearing filter
  vim.keymap.set('n', 'gc', M.clear_filter, { buffer = buf, silent = true, desc = "Clear team filter" })

  -- Switch to buffer
  vim.api.nvim_set_current_buf(buf)

  -- Move cursor to first issue (line 3, after header)
  vim.api.nvim_win_set_cursor(0, {3, 0})
end

return M
