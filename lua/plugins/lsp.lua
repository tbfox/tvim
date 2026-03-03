local function configure()
    vim.lsp.enable('lua_ls')
    vim.lsp.enable('nushell')
    vim.lsp.enable('ts_ls')
    vim.api.nvim_create_autocmd("LspAttach", {
        callback = function()
            require("lib.common-lsp-keymaps").set_keymaps({ buffer = 0 })
        end
    })
end


return {
    {
        "neovim/nvim-lspconfig",
        config = configure,
        dependencies = {
            "folke/lazydev.nvim",
            ft = "lua",
            opts = {
                library = {
                    { path = "${3rd}/luv/library", words = { "vim%.uv" } },
                },
            },
        }
    }
}
