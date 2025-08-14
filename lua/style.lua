vim.cmd.colorscheme("gruvbox")

vim.api.nvim_set_hl(0, "Visual", { bg = "#404040", ctermbg = "darkgrey" })

vim.cmd[[
    highlight Normal guibg=none
    highlight NonText guibg=none
    highlight Normal ctermbg=none
    highlight NonText ctermbg=none
]]
