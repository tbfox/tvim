vim.api.nvim_set_keymap('', '<Space>', '<Nop>', {
    noremap = true,
    silent = true,
})

vim.g.mapleader = ' '

vim.keymap.set("n", "-", "<CMD>Oil<CR>", {
    desc = "Explore w/ Minus"
})

-- Window Creation
vim.keymap.set('n', "<Leader>wnh", "<CMD>vsplit<CR>", {
    desc = "[W]indow - [N]ew - (vim direction left)"
})

vim.keymap.set('n', "<Leader>wnj", "<CMD>rightbelow split<CR>", {
    desc = "[W]indow - [N]ew - (vim direction down)"
})

vim.keymap.set('n', "<Leader>wnk", "<CMD>split<CR>", {
    desc = "[W]indow - [N]ew - (vim direction up)"
})

vim.keymap.set('n', "<Leader>wnl", "<CMD>rightbelow vsplit<CR>", {
    desc = "[W]indow - [N]ew - (vim direction right)"
})

-- Window Navigation
vim.keymap.set('n', "<Leader>wh", "<C-w>h", {
    desc = "Navigage [W]indow - (vim direction left)"
})

vim.keymap.set('n', "<Leader>wj", "<C-w>j", {
    desc = "Navigage [W]indow - (vim direction down)"
})

vim.keymap.set('n', "<Leader>wk", "<C-w>k", {
    desc = "Navigage [W]indow - (vim direction up)"
})

vim.keymap.set('n', "<Leader>wl", "<C-w>l", {
    desc = "Navigage [W]indow - (vim direction right)"
})
