local M = {}

local reader = require("scriptures.reader")
local nav = require("scriptures.nav")
local search = require("scriptures.search")

-- Setup function called by the plugin manager
function M.setup(opts)
	opts = opts or {}

	-- Main command: :Sc [search|search-ref]
	-- No args: Opens the scripture tree navigation
	-- search: Full-text search across verses
	-- search-ref: Search scripture references
	vim.api.nvim_create_user_command("Sc", function(cmd_opts)
		local arg = cmd_opts.args

		if arg == "search" then
			search.search_content()
		elseif arg == "search-ref" then
			search.search_references()
		elseif arg == "" then
			nav.open()
		else
			vim.notify("Usage: :Sc [search|search-ref]", vim.log.levels.WARN)
		end
	end, { nargs = "?" })

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
M.search = search

return M
