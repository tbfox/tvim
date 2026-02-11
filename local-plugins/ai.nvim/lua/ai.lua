local M = {}

function run_command()
    local selection = require('lib.selection').get_selection()
    local api_file = vim.fn.stdpath("config") .. "/local-plugins/ai.nvim/runner/ai_request"
    local result = vim.system({ api_file, selection }, { text = true }):wait()
    vim.print(result.stdout)
end

M.setup = function()
    vim.api.nvim_create_user_command("Ai", run_command, { desc = "", range = true })
end

M.setup()

return M
