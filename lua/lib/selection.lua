local M = {}

function M.get_selection()
    local vstart = vim.fn.getpos("'<")
    local vend = vim.fn.getpos("'>")
    vim.api.nvim_buf_get_text(0, vstart[2] - 1, vstart[3] - 1, vend[2] - 1, vend[3], {})
end

function M.set_selection(text)
    local vstart = vim.fn.getpos("'<")
    local vend = vim.fn.getpos("'>")
    vim.api.nvim_buf_set_text(0, vstart[2] - 1, vstart[3] - 1, vend[2] - 1, vend[3], { text })
end

return M
