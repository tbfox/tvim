local M = {}

function M.set_keymaps(opts)
    vim.keymap.set('n', '<leader>i', vim.lsp.buf.hover, opts)
    vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
    vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
    vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, opts)
    vim.keymap.set('n', '<leader>ci', vim.lsp.buf.implementation, opts)
    vim.keymap.set('n', '<leader>cr', vim.lsp.buf.references, opts)
    vim.keymap.set('n', '<leader>ct', vim.lsp.buf.type_definition, opts)
    vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts)
    vim.keymap.set('n', '<leader>fm', vim.lsp.buf.format, opts)
    vim.keymap.set('n', '<leader>h', vim.lsp.buf.signature_help, opts)
    vim.keymap.set('n', '<leader>en', vim.diagnostic.goto_next, opts)
    vim.keymap.set('n', '<leader>ep', vim.diagnostic.goto_prev, opts)
    vim.keymap.set('n', '<leader>ee', vim.diagnostic.open_float, opts)
end

return M
