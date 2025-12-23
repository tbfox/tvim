-- Window Creation
vim.keymap.set('n', "<Leader>wh", "<CMD>vsplit<CR>",            { desc = "[W]indow - [h] (vim direction left)" })
vim.keymap.set('n', "<Leader>wj", "<CMD>rightbelow split<CR>",  { desc = "[W]indow - [j] (vim direction down)" })
vim.keymap.set('n', "<Leader>wk", "<CMD>split<CR>",             { desc = "[W]indow - [k] (vim direction up)" })
vim.keymap.set('n', "<Leader>wl", "<CMD>rightbelow vsplit<CR>", { desc = "[W]indow - [l] (vim direction right)" })

-- Buffer Navigation

vim.keymap.set('n', "<Leader>p", "<CMD>bprevious<CR>", { desc = "Buffer [P]rev" })
vim.keymap.set('n', "<Leader>n", "<CMD>bnext<CR>",     { desc = "Buffer [N]ext" })
vim.keymap.set('n', "<Leader>c", "<CMD>close<CR>",     { desc = "[C]lose current window" })

-- Code Execution

vim.keymap.set('n', "<F1>", ":.lua<CR>",            { desc = "Run run lua page" })
vim.keymap.set('v', "<F1>", ":lua<CR>",             { desc = "Run lua snippet" })
vim.keymap.set('n', "<F2>", "<CMD>source %<CR>",    { desc = "Run file" })

vim.keymap.set("v", "<Leader>=", '"+y', { desc = "Yank to clipboard" })

