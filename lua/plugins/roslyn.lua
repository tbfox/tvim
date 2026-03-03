local home = vim.fn.expand("~")
local roslyn_path = home .. "/.local/share/nvim/roslyn/content/LanguageServer/osx-arm64"
local dotnet_path = home .. "/.dotnet/dotnet"

-- Configure the LSP server before the plugin loads
vim.lsp.config("roslyn", {
    cmd = {
        dotnet_path,
        roslyn_path .. "/Microsoft.CodeAnalysis.LanguageServer.dll",
        "--logLevel=Information",
        "--extensionLogDirectory=" .. vim.fs.dirname(vim.lsp.log.get_filename()),
        "--stdio",
    },
    settings = {
        ["csharp|inlay_hints"] = {
            csharp_enable_inlay_hints_for_implicit_object_creation = true,
            csharp_enable_inlay_hints_for_implicit_variable_types = true,
            csharp_enable_inlay_hints_for_lambda_parameter_types = true,
            csharp_enable_inlay_hints_for_types = true,
            dotnet_enable_inlay_hints_for_indexer_parameters = true,
            dotnet_enable_inlay_hints_for_literal_parameters = true,
            dotnet_enable_inlay_hints_for_object_creation_parameters = true,
            dotnet_enable_inlay_hints_for_other_parameters = true,
            dotnet_enable_inlay_hints_for_parameters = true,
            dotnet_suppress_inlay_hints_for_parameters_that_differ_only_by_suffix = true,
            dotnet_suppress_inlay_hints_for_parameters_that_match_argument_name = true,
            dotnet_suppress_inlay_hints_for_parameters_that_match_method_intent = true,
        },
    },
})

return {
    "seblyng/roslyn.nvim",
    ft = { "cs" },
    opts = {},
}
