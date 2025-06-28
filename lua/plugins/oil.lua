local function config()
    require("oil").setup({
        default_file_explorer = true,
        columns = {
            "icon",
        },
    })
    vim.keymap.set("n", "-", "<CMD>Oil<CR>", {
        desc = "Open parent directory",
    })
end

return {
    'stevearc/oil.nvim',
    dependencies = { { "nvim-tree/nvim-web-devicons" } },
    config = config,
    lazy = false,
}
