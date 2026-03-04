return {
	{
		dir = require("lib.local-plugin")("scriptures.nvim"),
		config = function()
			require("scriptures").setup()
		end,
	},
}
