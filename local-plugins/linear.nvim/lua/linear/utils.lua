-- Shared utility functions for linear.nvim

local M = {}

-- Format date string to readable format
-- @param date_str string: ISO 8601 date string (e.g., "2026-03-10")
-- @return string: Formatted date or "-" if nil
function M.format_date(date_str)
  if not date_str or date_str == "" or date_str == vim.NIL then
    return "-"
  end

  -- Simple formatting: just return YYYY-MM-DD
  -- Could be enhanced with relative dates ("2 days ago") later
  return date_str:match("^%d%d%d%d%-%d%d%-%d%d") or date_str
end

-- Get first name from full name
-- @param full_name string: Full name (e.g., "Alice Smith")
-- @return string: First name or full name if no space
function M.get_first_name(full_name)
  if not full_name then return "" end
  return full_name:match("^(%S+)") or full_name
end

-- Format assignee name with @ prefix
-- @param assignee table|nil: Assignee object with name field
-- @return string: Formatted name or "-"
function M.format_assignee(assignee)
  -- Handle vim.NIL (JSON null becomes vim.NIL)
  if not assignee or assignee == vim.NIL then
    return "-"
  end
  if not assignee.name or assignee.name == vim.NIL then
    return "-"
  end
  return "@" .. M.get_first_name(assignee.name)
end

-- Join array of items by extracting field
-- @param items table: Array of objects
-- @param field string: Field name to extract
-- @param separator string: Join separator (default ", ")
-- @return string: Joined string or "-" if empty
function M.join_field(items, field, separator)
  -- Handle vim.NIL (JSON null becomes vim.NIL)
  if not items or items == vim.NIL or #items == 0 then
    return "-"
  end

  separator = separator or ", "
  local values = {}
  for _, item in ipairs(items) do
    local value = item[field]
    if value and value ~= vim.NIL then
      table.insert(values, value)
    end
  end

  return #values > 0 and table.concat(values, separator) or "-"
end

return M
