return {
    {
        "kevinhwang91/nvim-ufo",
        dependencies = { "kevinhwang91/promise-async" },
        event = "BufReadPost",
        opts = {
            provider_selector = function(_, filetype, _)
                local map = {
                    lua = { "treesitter", "indent" },
                    typescript = { "treesitter", "indent" },
                    javascript = { "treesitter", "indent" },
                    python = { "treesitter", "indent" },
                    rust = { "treesitter", "indent" },
                    go = { "treesitter", "indent" },
                }
                return map[filetype] or { "lsp", "indent" }
            end,
        },
        init = function()
            vim.opt.foldlevel = 99
            vim.opt.foldlevelstart = 99
            vim.opt.foldenable = true
        end,
        keys = {
            { "zR", function() require("ufo").openAllFolds() end,  desc = "Open all folds" },
            { "zM", function() require("ufo").closeAllFolds() end, desc = "Close all folds" },
            { "zr", function() require("ufo").openFoldsExceptKinds() end, desc = "Open folds except kinds" },
            { "zm", function() require("ufo").closeFoldsWith() end, desc = "Close folds with" },
            { "K",  function()
                local ufo = require("ufo")
                local winid = ufo.peekFoldedLinesUnderCursor()
                if not winid then
                    vim.lsp.buf.hover()
                end
            end, desc = "Peek fold / hover" },
        },
    }
}
