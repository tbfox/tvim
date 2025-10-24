vim.api.nvim_set_keymap('', '<Space>', '<Nop>', { noremap = true, silent = true, })

vim.g.mapleader = ' '

vim.keymap.set("n", "-", "<CMD>Oil<CR>", { desc = "Explore w/ Minus" })

-- Window Creation
vim.keymap.set('n', "<Leader>wh", "<CMD>vsplit<CR>",            { desc = "[W]indow - [h] (vim direction left)" })
vim.keymap.set('n', "<Leader>wj", "<CMD>rightbelow split<CR>",  { desc = "[W]indow - [j] (vim direction down)" })
vim.keymap.set('n', "<Leader>wk", "<CMD>split<CR>",             { desc = "[W]indow - [k] (vim direction up)" })
vim.keymap.set('n', "<Leader>wl", "<CMD>rightbelow vsplit<CR>", { desc = "[W]indow - [l] (vim direction right)" })

-- Buffer Navigation

vim.keymap.set('n', "<Leader>p", ":bprevious<CR>", { desc = "[B]uffer [P]rev" })
vim.keymap.set('n', "<Leader>n", ":bnext<CR>",     { desc = "[B]uffer [N]ext" })

-- vim.

vim.keymap.set('i', "<c-n>", vim.lsp.completion.get, { desc = "[C]ode [C]ompletion" })
-- vim.keymap.set('i', '<c-space>', function() vim.lsp.completion.get() end, { desc = "[B]uffer [N]ext" })
