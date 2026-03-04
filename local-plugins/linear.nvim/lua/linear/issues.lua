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

-- GraphQL query for listing issues
local ISSUES_QUERY = [[
  query ListIssues($first: Int, $includeArchived: Boolean) {
    issues(
      first: $first
      includeArchived: $includeArchived
      orderBy: updatedAt
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

-- Fetch issues from API
-- @param include_archived boolean: Whether to include archived issues
-- @return issues table|nil: Array of issues
-- @return error string|nil: Error message if failed
function M.fetch_issues(include_archived)
  local variables = {
    first = 100, -- TODO: Add pagination later
    includeArchived = include_archived or false
  }

  vim.notify("Fetching issues from Linear...", vim.log.levels.INFO)

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
  local cache_key = "issues_" .. tostring(M.show_archived)

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
  table.insert(lines, string.format("Showing %d issue(s) | Archived: %s (toggle with g.)",
    visible_count, M.show_archived and "shown" or "hidden"))

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

-- View issue details (stub for Phase 3)
function M.view_issue_details()
  local issue_id = ui.parse_issue_id_from_line()
  if not issue_id then
    vim.notify("No issue found on current line", vim.log.levels.WARN)
    return
  end

  vim.notify("Viewing issue " .. issue_id .. " (Phase 3 - not yet implemented)", vim.log.levels.INFO)
  -- TODO: Implement in Phase 3
end

-- Close issue list and clean up
function M.close()
  if M.current_buffer and vim.api.nvim_buf_is_valid(M.current_buffer) then
    vim.api.nvim_buf_delete(M.current_buffer, { force = true })
  end
  M.current_buffer = nil
end

-- Open issue list buffer
function M.open()
  local auth = require("linear.auth")

  -- Check authentication first
  if not auth.ensure_authenticated() then
    return
  end

  -- Fetch issues
  local issues, err = M.get_issues(false)
  if err then
    vim.notify("Failed to fetch issues: " .. err, vim.log.levels.ERROR)
    return
  end

  vim.notify("Loaded " .. #issues .. " issue(s)", vim.log.levels.INFO)

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

  -- Switch to buffer
  vim.api.nvim_set_current_buf(buf)

  -- Move cursor to first issue (line 3, after header)
  vim.api.nvim_win_set_cursor(0, {3, 0})
end

return M
