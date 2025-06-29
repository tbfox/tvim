local function on_attach(_, bufrn)
    local opts = {
        buffer = bufrn,
        noremap = true,
        silent = true,
    }
    vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
end

local function config()
    require("mason").setup()
    require("mason-lspconfig").setup({
        ensure_installed = {
            "lua_ls",
            "typescript_language_server",
        },
        on_attach = on_attach,
        handlers = {
            function(server_name)
                require("lspconfig")[server_name].setup({})
            end,
            lua_ls = function()
                require("lspconfig").lua_ls.setup({
                    settings = {
                        workspace = {
                            library = vim.api.nvim_get_runtime_file("", true),
                            checkThirdParty = false,
                        },
                        runtime = {
                            version = 'LuaJIT',
                        },
                        Lua = {
                            diagnostics = {
                                globals = { "vim" }
                            }
                        }
                    },
                })
            end
        },
    })
end


return {
    "mason-org/mason-lspconfig.nvim",
    opts = {},
    dependencies = {
        { "mason-org/mason.nvim", opts = {} },
        "neovim/nvim-lspconfig",
    },
    config = config
}
