local M = {}

local reader = require("scriptures.reader")
local nav = require("scriptures.nav")

-- Setup function called by the plugin manager
function M.setup(opts)
	opts = opts or {}

	-- Main command: :Sc or :Scriptures
	-- Opens the scripture tree navigation
	vim.api.nvim_create_user_command("Sc", function(args)
		nav.open()
	end, {})

	vim.api.nvim_create_user_command("Scriptures", function(args)
		nav.open()
	end, {})

	-- Keep test command for debugging
	vim.api.nvim_create_user_command("ScriptureTest", function(args)
		-- Default to 1 Nephi 1 for testing
		reader.open("bofm", "1 Nephi", 1)
	end, {})
end

-- Export modules for testing/debugging
M.reader = reader
M.nav = nav

return M
