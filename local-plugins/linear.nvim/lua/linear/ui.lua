-- UI module for linear.nvim
-- Handles buffer creation, rendering, and keybindings

local M = {}

-- Create a new buffer with common settings
-- @param buftype string: Buffer type (nofile, acwrite, etc.)
-- @param filetype string: Filetype for syntax highlighting
-- @return buf number: Buffer handle
function M.create_buffer(buftype, filetype)
  local buf = vim.api.nvim_create_buf(false, true)

  vim.bo[buf].buftype = buftype or "nofile"
  vim.bo[buf].swapfile = false
  vim.bo[buf].bufhidden = "wipe"

  if filetype then
    vim.bo[buf].filetype = filetype
  end

  return buf
end

-- Set buffer lines (respecting modifiable state)
-- @param buf number: Buffer handle
-- @param lines table: Array of strings
function M.set_lines(buf, lines)
  local was_modifiable = vim.bo[buf].modifiable
  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = was_modifiable
end

-- Register common keybindings for list views
-- @param buf number: Buffer handle
-- @param callbacks table: Map of key -> callback function
function M.set_list_keymaps(buf, callbacks)
  local opts = { buffer = buf, silent = true }

  -- Default keybindings (oil.nvim style)
  if callbacks.view_detail then
    vim.keymap.set('n', '<CR>', callbacks.view_detail, opts)
  end

  if callbacks.toggle then
    vim.keymap.set('n', 'g.', callbacks.toggle, opts)
  end

  if callbacks.refresh then
    vim.keymap.set('n', 'r', callbacks.refresh, opts)
  end

  if callbacks.back then
    vim.keymap.set('n', '-', callbacks.back, opts)
  end

  -- Always provide quit
  vim.keymap.set('n', 'q', '<cmd>bd!<CR>', opts)
end

-- Parse issue ID from current line (format: "ID-123  ...")
-- @return string|nil: Issue identifier or nil if not found
function M.parse_issue_id_from_line()
  local line = vim.api.nvim_get_current_line()
  local id = line:match("^(%w+%-%d+)")
  return id
end

-- Truncate string to max length with ellipsis
-- @param str string: String to truncate
-- @param max_len number: Maximum length
-- @return string: Truncated string
function M.truncate(str, max_len)
  if not str then return "" end
  if #str <= max_len then return str end
  return str:sub(1, max_len - 3) .. "..."
end

-- Format table row with fixed column widths
-- @param columns table: Array of {text, width} tables
-- @return string: Formatted row
function M.format_row(columns)
  local parts = {}
  for _, col in ipairs(columns) do
    local text = col.text or ""
    local width = col.width
    local truncated = M.truncate(text, width)
    table.insert(parts, string.format("%-" .. width .. "s", truncated))
  end
  return table.concat(parts, "  ")
end

return M
