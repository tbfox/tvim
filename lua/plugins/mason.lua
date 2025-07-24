local function on_attach(client, bufnr)
    print("LSP on_attach called for:", client.name, "on buffer:", bufnr)

    local opts = {
        buffer = bufnr,
        noremap = true,
        silent = true,
    }
    vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
    vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
    vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
    vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
    vim.keymap.set('n', 'gt', vim.lsp.buf.type_definition, opts)
    vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
    vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, opts)
    vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts)
    vim.keymap.set('i', '<C-s>', vim.lsp.buf.signature_help, opts)
    
    print("LSP keymaps set for buffer:", bufnr)
end

local function config()
    require("mason").setup()
    require("mason-lspconfig").setup({
        ensure_installed = {
            "lua_ls",
            "ts_ls",
        },
        handlers = {
            function(server_name)
                require("lspconfig")[server_name].setup({
                    on_attach = on_attach,
                })
            end,
            lua_ls = function()
                require("lspconfig").lua_ls.setup({
                    on_attach = on_attach,
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
            end,
            ts_ls = function()
                print("Setting up ts_ls with special config")
                require("lspconfig").ts_ls.setup({
                    on_attach = on_attach,
                    filetypes = {
                        "javascript",
                        "javascriptreact", 
                        "javascript.jsx",
                        "typescript",
                        "typescriptreact",
                        "typescript.tsx"
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
