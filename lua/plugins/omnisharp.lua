return {
    "Hoffs/omnisharp-extended-lsp.nvim",
    event = { "BufReadPre *.cs", "BufNewFile *.cs" },
    config = function()
        vim.lsp.config.omnisharp = {
            cmd = { "omnisharp" },
            filetypes = { "cs" },
            
            root_dir = function(fname)
                return vim.fs.root(fname, function(name)
                    return name:match("%.sln$") or name:match("%.csproj$") or name == ".git"
                end)
            end,
            
            settings = {
                FormattingOptions = { EnableEditorConfigSupport = true, OrganizeImports = true },
                MsBuild = { LoadProjectsOnDemand = true },
                RoslynExtensionsOptions = {
                    EnableAnalyzersSupport = true,
                    EnableImportCompletion = true,
                    AnalyzeOpenDocumentsOnly = true,
                },
                Sdk = { IncludePrereleases = true },
            }
        }

        vim.lsp.enable('omnisharp')
        
        vim.api.nvim_create_autocmd("LspAttach", {
            callback = function(args)
                local client = vim.lsp.get_client_by_id(args.data.client_id)
                if client and client.name == "omnisharp" then
                    local opts = { buffer = args.buf }
                    vim.keymap.set('n', 'gd', require('omnisharp_extended').lsp_definition, opts)
                    vim.keymap.set('n', 'gr', require('omnisharp_extended').lsp_references, opts)
                    vim.keymap.set('n', 'gi', require('omnisharp_extended').lsp_implementation, opts)
                end
            end,
        })
    end
}
