vim.api.nvim_set_keymap('', '<Space>', '<Nop>', { noremap = true, silent = true, })
vim.g.mapleader = ' '
require("config.lazy")
require("lib.require_all").require_all("config")
