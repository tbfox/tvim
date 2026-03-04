-- Authentication module for linear.nvim
-- Handles Linear API key management

local M = {}

-- Get API key from environment variable
function M.get_api_key()
  local key = vim.fn.getenv("LINEAR_API_KEY")

  if key == vim.NIL or key == "" then
    return nil
  end

  return key
end

-- Ensure user is authenticated, show error if not
-- Returns: boolean (true if authenticated)
function M.ensure_authenticated()
  local key = M.get_api_key()

  if not key then
    vim.notify(
      "LINEAR_API_KEY environment variable not set.\n" ..
      "Get your API key from: https://linear.app/settings/api\n" ..
      "Then add to your shell: export LINEAR_API_KEY='lin_api_xxxxx'",
      vim.log.levels.ERROR
    )
    return false
  end

  return true
end

return M
