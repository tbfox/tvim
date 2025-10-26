local function config()
    require("oil").setup({
        default_file_explorer = true,
        columns = {
            "icon",
        },
        keymaps = {
            ["<C-h>"] = { "<CMD>TmuxNavigateLeft<CR>" },
            ["<C-j>"] = { "<CMD>TmuxNavigateDown<CR>" },
            ["<C-k>"] = { "<CMD>TmuxNavigateUp<CR>" },
            ["<C-l>"] = { "<CMD>TmuxNavigateRight<CR>" },
            ["<leader>r"] = "actions.refresh",
            ["~"] = false,
        }
    })
    vim.keymap.set("n", "-", "<CMD>Oil<CR>", { desc = "Open parent directory" })
end

return {
    'stevearc/oil.nvim',
    dependencies = { { "nvim-tree/nvim-web-devicons" } },
    config = config,
}
