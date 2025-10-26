vim.api.nvim_set_keymap('', '<Space>', '<Nop>', { noremap = true, silent = true, })
vim.g.mapleader = ' '

-- Window Creation
vim.keymap.set('n', "<Leader>wh", "<CMD>vsplit<CR>",            { desc = "[W]indow - [h] (vim direction left)" })
vim.keymap.set('n', "<Leader>wj", "<CMD>rightbelow split<CR>",  { desc = "[W]indow - [j] (vim direction down)" })
vim.keymap.set('n', "<Leader>wk", "<CMD>split<CR>",             { desc = "[W]indow - [k] (vim direction up)" })
vim.keymap.set('n', "<Leader>wl", "<CMD>rightbelow vsplit<CR>", { desc = "[W]indow - [l] (vim direction right)" })

-- Buffer Navigation

vim.keymap.set('n', "<Leader>p", ":bprevious<CR>", { desc = "[B]uffer [P]rev" })
vim.keymap.set('n', "<Leader>n", ":bnext<CR>",     { desc = "[B]uffer [N]ext" })

