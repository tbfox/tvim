return {
    {
        "mrcjkb/rustaceanvim",
        version = "^6",
        lazy = false,
        ft = { "rust" },
        init = function()
            vim.g.rustaceanvim = {
                tools = {
                    hover_actions = { auto_focus = true },
                },
                server = {
                    default_settings = {
                        ["rust-analyzer"] = {
                            check = { command = "clippy" },
                            inlayHints = { lifetimeElisionHints = { enable = "skip_trivial" } },
                        },
                    },
                    on_attach = function(_, bufnr)
                        vim.keymap.set("n", "<Leader>rr", function() vim.cmd.RustLsp("runnables") end,
                            { buffer = bufnr, desc = "[R]ust [R]unnables" })
                        vim.keymap.set("n", "<Leader>rt", function() vim.cmd.RustLsp("testables") end,
                            { buffer = bufnr, desc = "[R]ust [T]estables" })
                        vim.keymap.set("n", "<Leader>rd", function() vim.cmd.RustLsp("debuggables") end,
                            { buffer = bufnr, desc = "[R]ust [D]ebuggables" })
                        vim.keymap.set("n", "<Leader>rm", function() vim.cmd.RustLsp("expandMacro") end,
                            { buffer = bufnr, desc = "[R]ust expand [M]acro" })
                        vim.keymap.set("n", "<Leader>rk", function() vim.cmd.RustLsp({ "hover", "actions" }) end,
                            { buffer = bufnr, desc = "[R]ust hover actions" })

                        vim.api.nvim_create_autocmd("BufWritePre", {
                            buffer = bufnr,
                            callback = function()
                                vim.lsp.buf.format({ bufnr = bufnr, async = false })
                            end,
                        })
                    end,
                },
            }
        end,
    },
    {
        "saecki/crates.nvim",
        event = { "BufRead Cargo.toml" },
        opts = {
            completion = {
                cmp = { enabled = true },
            },
        },
    },
}
