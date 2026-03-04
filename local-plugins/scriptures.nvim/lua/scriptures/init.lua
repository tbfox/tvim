local M = {}

local reader = require("scriptures.reader")

-- Setup function called by the plugin manager
function M.setup(opts)
	opts = opts or {}

	-- For now, we'll just create a test command to open a chapter
	-- In Phase 2, this will be replaced with the tree navigation
	vim.api.nvim_create_user_command("ScriptureTest", function(args)
		-- Default to 1 Nephi 1 for testing
		reader.open("bofm", "1 Nephi", 1)
	end, {})

	-- TODO: In Phase 2, add :Sc and :Scriptures commands that open tree navigation
end

-- Export reader for testing/debugging
M.reader = reader

return M
