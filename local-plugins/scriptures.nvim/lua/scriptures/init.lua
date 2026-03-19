local M = {}

local reader = require("scriptures.reader")
local nav = require("scriptures.nav")
local search = require("scriptures.search")

-- Short name aliases for :Sc go <book> <chapter>
-- Maps abbreviation -> { source_id, book_name }
local BOOK_ALIASES = {
	-- Book of Mormon
	["1ne"] = { "bofm", "1 Nephi" },
	["2ne"] = { "bofm", "2 Nephi" },
	["jacob"] = { "bofm", "Jacob" },
	["enos"] = { "bofm", "Enos" },
	["jarom"] = { "bofm", "Jarom" },
	["omni"] = { "bofm", "Omni" },
	["wom"] = { "bofm", "Words of Mormon" },
	["mosiah"] = { "bofm", "Mosiah" },
	["alma"] = { "bofm", "Alma" },
	["hel"] = { "bofm", "Helaman" },
	["3ne"] = { "bofm", "3 Nephi" },
	["4ne"] = { "bofm", "4 Nephi" },
	["morm"] = { "bofm", "Mormon" },
	["ether"] = { "bofm", "Ether" },
	["moro"] = { "bofm", "Moroni" },
	-- Doctrine and Covenants
	["dc"] = { "dc", "D&C" },
	-- New Testament
	["matt"] = { "nt", "Matthew" },
	["mark"] = { "nt", "Mark" },
	["luke"] = { "nt", "Luke" },
	["john"] = { "nt", "John" },
	["acts"] = { "nt", "Acts" },
	["rom"] = { "nt", "Romans" },
	["1cor"] = { "nt", "1 Corinthians" },
	["2cor"] = { "nt", "2 Corinthians" },
	["gal"] = { "nt", "Galatians" },
	["eph"] = { "nt", "Ephesians" },
	["phil"] = { "nt", "Philippians" },
	["col"] = { "nt", "Colossians" },
	["1thes"] = { "nt", "1 Thessalonians" },
	["2thes"] = { "nt", "2 Thessalonians" },
	["1tim"] = { "nt", "1 Timothy" },
	["2tim"] = { "nt", "2 Timothy" },
	["titus"] = { "nt", "Titus" },
	["phlm"] = { "nt", "Philemon" },
	["heb"] = { "nt", "Hebrews" },
	["james"] = { "nt", "James" },
	["1pet"] = { "nt", "1 Peter" },
	["2pet"] = { "nt", "2 Peter" },
	["1jn"] = { "nt", "1 John" },
	["2jn"] = { "nt", "2 John" },
	["3jn"] = { "nt", "3 John" },
	["jude"] = { "nt", "Jude" },
	["rev"] = { "nt", "Revelation" },
	-- Old Testament
	["gen"] = { "ot", "Genesis" },
	["ex"] = { "ot", "Exodus" },
	["lev"] = { "ot", "Leviticus" },
	["num"] = { "ot", "Numbers" },
	["deut"] = { "ot", "Deuteronomy" },
	["josh"] = { "ot", "Joshua" },
	["judg"] = { "ot", "Judges" },
	["ruth"] = { "ot", "Ruth" },
	["1sam"] = { "ot", "1 Samuel" },
	["2sam"] = { "ot", "2 Samuel" },
	["1kgs"] = { "ot", "1 Kings" },
	["2kgs"] = { "ot", "2 Kings" },
	["1chr"] = { "ot", "1 Chronicles" },
	["2chr"] = { "ot", "2 Chronicles" },
	["ezra"] = { "ot", "Ezra" },
	["neh"] = { "ot", "Nehemiah" },
	["esth"] = { "ot", "Esther" },
	["job"] = { "ot", "Job" },
	["ps"] = { "ot", "Psalms" },
	["prov"] = { "ot", "Proverbs" },
	["eccl"] = { "ot", "Ecclesiastes" },
	["song"] = { "ot", "Solomon's Song" },
	["isa"] = { "ot", "Isaiah" },
	["jer"] = { "ot", "Jeremiah" },
	["lam"] = { "ot", "Lamentations" },
	["ezek"] = { "ot", "Ezekiel" },
	["dan"] = { "ot", "Daniel" },
	["hos"] = { "ot", "Hosea" },
	["joel"] = { "ot", "Joel" },
	["amos"] = { "ot", "Amos" },
	["obad"] = { "ot", "Obadiah" },
	["jonah"] = { "ot", "Jonah" },
	["mic"] = { "ot", "Micah" },
	["nah"] = { "ot", "Nahum" },
	["hab"] = { "ot", "Habakkuk" },
	["zeph"] = { "ot", "Zephaniah" },
	["hag"] = { "ot", "Haggai" },
	["zech"] = { "ot", "Zechariah" },
	["mal"] = { "ot", "Malachi" },
	-- Pearl of Great Price
	["moses"] = { "pgp", "Moses" },
	["abr"] = { "pgp", "Abraham" },
	["jsm"] = { "pgp", "Joseph Smith—Matthew" },
	["jsh"] = { "pgp", "Joseph Smith—History" },
	["aof"] = { "pgp", "Articles of Faith" },
}

-- Setup function called by the plugin manager
function M.setup(opts)
	opts = opts or {}

	-- Main command: :Sc [search [ref]]
	-- No args: Opens the scripture tree navigation
	-- search: Full-text search across verses
	-- search ref: Search scripture references
	vim.api.nvim_create_user_command("Sc", function(cmd_opts)
		local args = cmd_opts.fargs

		if #args == 0 then
			nav.open()
		elseif #args == 1 and args[1] == "search" then
			search.search_content()
		elseif #args == 2 and args[1] == "search" and args[2] == "ref" then
			search.search_references()
		elseif #args == 3 and args[1] == "go" then
			local book_arg = args[2]:lower()
			local chapter = tonumber(args[3])
			if not chapter then
				vim.notify("Usage: :Sc go <book> <chapter>", vim.log.levels.WARN)
				return
			end
			local alias = BOOK_ALIASES[book_arg]
			if not alias then
				vim.notify("Unknown book: " .. args[2], vim.log.levels.WARN)
				return
			end
			nav.state.origin_bufnr = vim.api.nvim_get_current_buf()
			reader.open(alias[1], alias[2], chapter)
		else
			vim.notify("Usage: :Sc | :Sc search | :Sc search ref | :Sc go <book> <chapter>", vim.log.levels.WARN)
		end
	end, { nargs = "*" })

	-- Keep test command for debugging
	vim.api.nvim_create_user_command("St", function(args)
		-- Default to 1 Nephi 1 for testing
		reader.open("bofm", "1 Nephi", 1)
	end, {})
end

-- Export modules for testing/debugging
M.reader = reader
M.nav = nav
M.search = search

return M
