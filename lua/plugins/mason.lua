local function on_attach(client, bufnr)
	local opts = {
		buffer = bufnr,
		noremap = true,
		silent = true,
	}
	require("lib.common-lsp-keymaps").set_keymaps(opts)
end

local function config()
	require("mason").setup()
	require("mason-lspconfig").setup({
		ensure_installed = {
			"lua_ls",
		},
		handlers = {},
	})
	vim.lsp.config("*", {
		on_attach = on_attach,
	})
end

return {
	"mason-org/mason-lspconfig.nvim",
	opts = {},
	dependencies = {
		{ "mason-org/mason.nvim", opts = {} },
		"neovim/nvim-lspconfig",
	},
	config = config,
}
