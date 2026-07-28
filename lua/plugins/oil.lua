local function config()
    require("nvim-web-devicons").set_icon({
        [".env.local"] = { icon = "", color = "#FAF743", cterm_color = "227", name = "Env" },
        [".env.development"] = { icon = "", color = "#FAF743", cterm_color = "227", name = "Env" },
        [".env.production"] = { icon = "", color = "#FAF743", cterm_color = "227", name = "Env" },
        [".env.test"] = { icon = "", color = "#FAF743", cterm_color = "227", name = "Env" },
        [".env.example"] = { icon = "", color = "#FAF743", cterm_color = "227", name = "Env" },
        [".env.sample"] = { icon = "", color = "#FAF743", cterm_color = "227", name = "Env" },
        [".env.development.local"] = { icon = "", color = "#FAF743", cterm_color = "227", name = "Env" },
        [".env.production.local"] = { icon = "", color = "#FAF743", cterm_color = "227", name = "Env" },
        [".env.test.local"] = { icon = "", color = "#FAF743", cterm_color = "227", name = "Env" },
    })

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

    vim.api.nvim_create_user_command("ConfigEdit", function()
        require("oil").open(vim.fn.stdpath("config"))
    end, {})
end

return {
    'stevearc/oil.nvim',
    dependencies = { { "nvim-tree/nvim-web-devicons" } },
    config = config,
}
