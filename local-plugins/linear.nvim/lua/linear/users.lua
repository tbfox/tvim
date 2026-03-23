-- User listing module for linear.nvim
-- Handles fetching and displaying users for filtering

local api = require("linear.api")
local cache = require("linear.cache")
local ui = require("linear.ui")

local M = {}

-- State
M.current_buffer = nil

-- GraphQL query for listing users
local USERS_QUERY = [[
  query ListUsers {
    users {
      nodes {
        id
        name
        email
        displayName
        active
        isMe
      }
    }
  }
]]

-- Fetch users from API
-- @return users table|nil: Array of users
-- @return error string|nil: Error message if failed
function M.fetch_users()
  vim.notify("Fetching users from Linear...", vim.log.levels.INFO)

  local result, err = api.query(USERS_QUERY, {})

  if err then
    return nil, err
  end

  if not result.data or not result.data.users then
    return nil, "Unexpected response format"
  end

  return result.data.users.nodes, nil
end

-- Get users (from cache or fetch)
-- @param force_refresh boolean: Force re-fetch even if cached
-- @return users table|nil: Array of users
-- @return error string|nil: Error message if failed
function M.get_users(force_refresh)
  local cache_key = "users"

  if not force_refresh then
    local cached = cache.get(cache_key)
    if cached then
      return cached, nil
    end
  end

  local users, err = M.fetch_users()
  if err then
    return nil, err
  end

  -- Cache the results
  cache.set(cache_key, users)

  return users, nil
end

-- Render user list to buffer
-- @param buf number: Buffer handle
-- @param users table: Array of users
function M.render_user_list(buf, users)
  local lines = {}

  -- Header
  table.insert(lines, "LINEAR USERS")
  table.insert(lines, string.rep("─", 40))
  table.insert(lines, "")

  -- Filter to active users and sort by name
  local active_users = vim.tbl_filter(function(user)
    return user.active
  end, users)

  table.sort(active_users, function(a, b)
    local name_a = a.displayName or a.name
    local name_b = b.displayName or b.name
    return name_a < name_b
  end)

  -- Render users
  for _, user in ipairs(active_users) do
    local display_name = user.displayName or user.name
    local me_marker = user.isMe and " (me)" or ""
    local line = string.format("  %s%s", display_name, me_marker)
    table.insert(lines, line)
  end

  table.insert(lines, "")
  table.insert(lines, string.rep("─", 40))
  table.insert(lines, string.format("%d active user(s)", #active_users))
  table.insert(lines, "")
  table.insert(lines, "Press <CR> to filter issues by user")
  table.insert(lines, "Press q to close")

  ui.set_lines(buf, lines)
end

-- Set up syntax highlighting for users
-- @param buf number: Buffer handle
function M.setup_highlights(buf)
  vim.cmd([[
    highlight default link LinearUserName Identifier
    highlight default link LinearUserMe Special
  ]])

  vim.api.nvim_buf_call(buf, function()
    vim.fn.matchadd("LinearUserName", "\\v^  \\w+.*")
    vim.fn.matchadd("LinearUserMe", "(me)")
  end)
end

-- Get user info from current line
-- @return user table|nil: User info or nil if not found
function M.get_user_from_line()
  local line = vim.api.nvim_get_current_line()

  -- Extract display name from line (format: "  Name (me)")
  local display_name = line:match("^%s+(.-)%s*%(me%)") or line:match("^%s+(.-)%s*$")

  if not display_name or display_name == "" then
    return nil
  end

  -- Find user by display name
  local users, err = M.get_users(false)
  if err or not users then
    return nil
  end

  for _, user in ipairs(users) do
    local user_display = user.displayName or user.name
    if user_display == display_name then
      return user
    end
  end

  return nil
end

-- Filter issues by selected user
function M.filter_by_user()
  local user = M.get_user_from_line()

  if not user then
    vim.notify("No user found on current line", vim.log.levels.WARN)
    return
  end

  -- Close users buffer
  M.close()

  -- Apply assignee filter to issues
  local issues = require("linear.issues")
  issues.set_assignee_filter(user.id, user.displayName or user.name)
end

-- Refresh user list
function M.refresh()
  if not M.current_buffer or not vim.api.nvim_buf_is_valid(M.current_buffer) then
    return
  end

  cache.clear_all()

  local users, err = M.get_users(true)
  if err then
    vim.notify("Failed to fetch users: " .. err, vim.log.levels.ERROR)
    return
  end

  M.render_user_list(M.current_buffer, users)
  vim.notify("Refreshed " .. #users .. " user(s)", vim.log.levels.INFO)
end

-- Close users list
function M.close()
  if M.current_buffer and vim.api.nvim_buf_is_valid(M.current_buffer) then
    vim.api.nvim_buf_delete(M.current_buffer, { force = true })
  end
  M.current_buffer = nil
end

-- Open users list in a vertical split
function M.open()
  local auth = require("linear.auth")

  -- Check authentication first
  if not auth.ensure_authenticated() then
    return
  end

  -- Fetch users
  local users, err = M.get_users(false)
  if err then
    vim.notify("Failed to fetch users: " .. err, vim.log.levels.ERROR)
    return
  end

  vim.notify("Loaded " .. #users .. " user(s)", vim.log.levels.INFO)

  -- Create buffer
  local buf = ui.create_buffer("nofile", "linear-users")
  M.current_buffer = buf

  -- Render users
  M.render_user_list(buf, users)

  -- Set up highlighting
  M.setup_highlights(buf)

  -- Make buffer read-only
  vim.bo[buf].modifiable = false

  -- Set up keybindings
  local opts = { buffer = buf, silent = true }
  vim.keymap.set('n', '<CR>', M.filter_by_user, opts)
  vim.keymap.set('n', 'r', M.refresh, opts)
  vim.keymap.set('n', 'q', M.close, opts)

  -- Open in vertical split on the right
  vim.cmd('rightbelow vsplit')
  vim.api.nvim_win_set_buf(0, buf)

  -- Set reasonable width (40 columns)
  vim.api.nvim_win_set_width(0, 40)

  -- Move cursor to first user (line 4, after header)
  vim.api.nvim_win_set_cursor(0, {4, 0})
end

return M
