vim.api.nvim_set_keymap('', '<Space>', '<Nop>', {
    noremap = true,
    silent = true,
})

vim.g.mapleader = ' '

vim.keymap.set("n", "-", "<CMD>Oil<CR>", {
    desc = "Explore w/ Minus"
})

vim.keymap.set('n', "<Leader>wnl", "<CMD>vsplit<CR>", {
    desc = "[W]indow - [N]ew - [L]eft"
})

vim.keymap.set('n', "<Leader>wnr", "<CMD>rightbelow vsplit<CR>", {
    desc = "[W]indow - [N]ew - [R]ight"
})

vim.keymap.set('n', "<Leader>wnu", "<CMD>split<CR>", {
    desc = "[W]indow - [N]ew - [U]p"
})

vim.keymap.set('n', "<Leader>wnd", "<CMD>rightbelow split<CR>", {
    desc = "[W]indow - [N]ew - [D]own"
})
