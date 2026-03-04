-- Main module for linear.nvim
-- Entry point and plugin setup

local M = {}

-- Module state
M.config = {
  -- Future configuration options will go here
}

function M.setup(opts)
  opts = opts or {}
  M.config = vim.tbl_deep_extend("force", M.config, opts)

  -- Register commands
  vim.api.nvim_create_user_command("Linear", function(cmd_opts)
    M.handle_command(cmd_opts.fargs)
  end, {
    nargs = "*",
    complete = function(arg_lead, cmd_line, cursor_pos)
      local commands = { "issues", "new", "test-auth" }
      return vim.tbl_filter(function(cmd)
        return vim.startswith(cmd, arg_lead)
      end, commands)
    end,
  })

  -- Register keybinding
  vim.keymap.set('n', '<F5>', function()
    M.open_issues()
  end, { desc = "Open Linear issues" })

  vim.notify("linear.nvim loaded", vim.log.levels.INFO)
end

function M.handle_command(args)
  if #args == 0 or args[1] == "issues" then
    M.open_issues()
  elseif args[1] == "new" then
    local issue_type = args[2] -- bug, feature, task
    M.create_issue(issue_type)
  elseif args[1] == "test-auth" then
    M.test_auth()
  else
    vim.notify("Unknown command: " .. args[1], vim.log.levels.ERROR)
  end
end

function M.open_issues()
  local issues = require("linear.issues")
  issues.open()
end

function M.create_issue(issue_type)
  vim.notify("Creating new issue: " .. (issue_type or "default"), vim.log.levels.INFO)
  -- TODO: Implement in Phase 4
end

function M.test_auth()
  local auth = require("linear.auth")
  local api = require("linear.api")

  if not auth.ensure_authenticated() then
    return
  end

  vim.notify("Testing Linear authentication...", vim.log.levels.INFO)

  -- Simple query to test auth
  local query = [[
    query {
      viewer {
        id
        name
        email
      }
    }
  ]]

  local result, err = api.query(query, {})

  if err then
    vim.notify("Authentication failed: " .. err, vim.log.levels.ERROR)
  else
    local viewer = result.data.viewer
    vim.notify(
      string.format("✓ Authenticated as: %s (%s)", viewer.name, viewer.email),
      vim.log.levels.INFO
    )
  end
end

return M
