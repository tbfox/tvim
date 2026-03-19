return {
	{
		dir = require("lib.local-plugin")("scriptures.nvim"),
		config = function()
			require("scriptures").setup()
			vim.keymap.set("v", "<Leader>gs", ":'<,'>Sc go<CR>", { desc = "Go to scripture reference" })
		end,
	},
}
