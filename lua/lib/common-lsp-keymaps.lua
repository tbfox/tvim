local M = {}

local function wrapper()
    vim.api.nvim_set_hl(0, "@markup.raw.block.markdown", { bg = "#000000", })
    vim.lsp.buf.hover()
    -- vim.api.nvim_set_hl(0, "@markup.raw.block.markdown", { bg = "NONE", })
end

function M.set_keymaps(opts)
    vim.keymap.set('n', '<leader>i', wrapper, opts)
    vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
    vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
    vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, opts)
    vim.keymap.set('n', '<leader>ci', vim.lsp.buf.implementation, opts)
    vim.keymap.set('n', '<leader>cr', vim.lsp.buf.references, opts)
    vim.keymap.set('n', '<leader>ct', vim.lsp.buf.type_definition, opts)
    vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts)
    vim.keymap.set('n', '<leader>fm', vim.lsp.buf.format, opts)
    vim.keymap.set('n', '<leader>h', vim.lsp.buf.signature_help, opts)
end

return M
