local issue_list = require("oily_octo.issue_list")

local M = {}

function M.setup()
    vim.keymap.set("n", "<F10>", issue_list.open)
end

return M
