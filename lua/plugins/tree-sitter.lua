local function config()
    require("nvim-treesitter.configs").setup({
        ensure_installed = { "lua" },
        auto_install = true,
    })
end

return {
    'nvim-treesitter/nvim-treesitter',
    config = config,
    lazy = false,
}
