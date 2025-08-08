local function on_attach(client, bufnr)
    local opts = {
        buffer = bufnr,
        noremap = true,
        silent = true,
    }
    require("lib.common-lsp-keymaps").set_keymaps(opts)
end

function configure()
    vim.lsp.config('ts_ls', {
        on_attach = on_attach
    })
    vim.lsp.enable("ts_ls")
end

return {
    'local/ts_ls',
    ft = {
        "javascript",
        "javascriptreact",
        "javascript.jsx",
        "typescript",
        "typescriptreact",
        "typescript.tsx",
    },
    config = configure,
    virtual = true,
}
