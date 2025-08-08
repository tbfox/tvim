local M = {}

function wrapper()
    vim.api.nvim_set_hl(0, "@markup.raw.block.markdown", { bg = "#000000", })
    vim.lsp.buf.hover()
    -- vim.api.nvim_set_hl(0, "@markup.raw.block.markdown", { bg = "NONE", })
end

function M.set_keymaps(opts)
    vim.keymap.set('n', '<leader>i', wrapper, opts)
end

-- vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
-- vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
-- vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
-- vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
-- vim.keymap.set('n', 'gt', vim.lsp.buf.type_definition, opts)
-- vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, opts)
-- vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts)
-- vim.keymap.set('i', '<C-s>', vim.lsp.buf.signature_help, opts)
return M
