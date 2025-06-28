local function set_tab(size)
    vim.opt.tabstop = size
    vim.opt.softtabstop = size
    vim.opt.shiftwidth = size
    vim.opt.expandtab = true
end

set_tab(4)
