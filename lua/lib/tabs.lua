local M = {}

function M.set(size)
    vim.opt.tabstop = size
    vim.opt.softtabstop = size
    vim.opt.shiftwidth = size
    vim.opt.expandtab = true
end

return M
