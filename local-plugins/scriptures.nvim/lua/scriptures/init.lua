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

-- Build a reverse lookup: lowercase full book name -> { source_id, book_name }
local FULL_NAME_LOOKUP = {}
for _, alias in pairs(BOOK_ALIASES) do
	FULL_NAME_LOOKUP[alias[2]:lower()] = alias
end

-- Parse a visual selection as a scripture reference: "<book> <chapter>[:<verse>[-<verse>]]"
-- Accepts both abbreviations (e.g. "1ne") and full names (e.g. "1 Nephi").
-- Returns { source_id, book_name, chapter } or nil on failure
local function parse_visual_reference(text)
	-- Trim whitespace
	text = text:match("^%s*(.-)%s*$")

	-- Try to match a full book name by checking all known names against the start of text.
	-- Full names may contain spaces, so we can't simply split on whitespace.
	local alias
	local chapter_part
	local verse_part

	local lower_text = text:lower()
	for full_name, entry in pairs(FULL_NAME_LOOKUP) do
		if lower_text:sub(1, #full_name) == full_name then
			local rest = text:sub(#full_name + 1)
			local ch, vs = rest:match("^%s+(%d+):(%d+)")
			if not ch then
				ch = rest:match("^%s+(%d+)")
			else
				verse_part = vs
			end
			if ch then
				alias = entry
				chapter_part = ch
				break
			end
		end
	end

	-- Fall back to abbreviation lookup (single token before the chapter number)
	if not alias then
		local book_part
		book_part, chapter_part, verse_part = text:match("^(%S+)%s+(%d+):(%d+)")
		if not book_part then
			book_part, chapter_part = text:match("^(%S+)%s+(%d+)")
		end
		if book_part then
			alias = BOOK_ALIASES[book_part:lower()]
		end
	end

	if not alias or not chapter_part then
		return nil, string.format("Invalid reference: '%s'\nExpected: <book> <chapter>[:<verse>]", text)
	end

	return {
		source_id = alias[1],
		book = alias[2],
		chapter = tonumber(chapter_part),
		verse = tonumber(verse_part),
	}, nil
end

-- Get the visual selection as a single line of text
local function get_visual_selection()
	-- Re-enter normal mode to update '< and '> marks
	local mode = vim.fn.mode()
	if mode == "v" or mode == "V" or mode == "\22" then
		vim.cmd("normal! \27") -- Escape to update marks
	end

	local start_pos = vim.fn.getpos("'<")
	local end_pos = vim.fn.getpos("'>")
	local lines = vim.api.nvim_buf_get_lines(0, start_pos[2] - 1, end_pos[2], false)

	if #lines == 0 then
		return nil
	end

	-- Trim to column range on single-line selections
	if #lines == 1 then
		lines[1] = lines[1]:sub(start_pos[3], end_pos[3])
	else
		lines[1] = lines[1]:sub(start_pos[3])
		lines[#lines] = lines[#lines]:sub(1, end_pos[3])
	end

	return table.concat(lines, " ")
end

-- Setup function called by the plugin manager
function M.setup(opts)
	opts = opts or {}

	-- Main command: :Sc [search [ref]]
	-- No args: Opens the scripture tree navigation
	-- search: Full-text search across verses
	-- search ref: Search scripture references
	-- Visual mode 'Sc go': navigate to the reference in the selection
	vim.api.nvim_create_user_command("Sc", function(cmd_opts)
		local args = cmd_opts.fargs

		-- Visual mode: 'Sc go' with a selection parses the selection as a reference
		if cmd_opts.range == 2 and #args == 1 and args[1] == "go" then
			local text = get_visual_selection()
			if not text or text:match("^%s*$") then
				vim.notify("No text selected", vim.log.levels.ERROR)
				return
			end
			local ref, err = parse_visual_reference(text)
			if err then
				vim.notify(err, vim.log.levels.ERROR)
				return
			end
			nav.state.origin_bufnr = vim.api.nvim_get_current_buf()
			reader.open(ref.source_id, ref.book, ref.chapter, ref.verse, { new_tab = true })
			return
		end

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
			reader.open(alias[1], alias[2], chapter, nil, { new_tab = true })
		elseif #args == 1 and args[1] == "listen" then
			local state = reader.state
			if not state.source or not state.book or not state.bufnr or not vim.api.nvim_buf_is_valid(state.bufnr) then
				vim.notify("No scripture chapter is currently open", vim.log.levels.WARN)
				return
			end
			-- Build a safe filename: e.g. "bofm_1-nephi_3.mp3"
			local chapter_str = state.chapter and tostring(state.chapter) or "all"
			local book_slug = state.book:lower():gsub("[^%a%d]+", "-"):gsub("^%-+", ""):gsub("%-+$", "")
			local audio_dir = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h:h:h") .. "/res/audio"
			local audio_file = string.format("%s/%s_%s_%s.mp3", audio_dir, state.source, book_slug, chapter_str)
			local speaker = require("speaker")
			if vim.fn.filereadable(audio_file) == 1 then
				vim.notify("Playing cached audio...", vim.log.levels.INFO)
				vim.fn.jobstart({ "afplay", audio_file }, { detach = true })
			else
				local lines = vim.api.nvim_buf_get_lines(state.bufnr, 0, -1, false)
				local text = table.concat(lines, "\n")
				vim.notify("Cleaning text for speech...", vim.log.levels.INFO)
				speaker.ollama_clean(text, function(cleaned)
					vim.schedule(function()
						vim.notify("Fetching audio from ElevenLabs...", vim.log.levels.INFO)
						speaker.elevenlabs_save(cleaned, audio_file, function(ok)
							if ok then
								vim.notify("Playing audio...", vim.log.levels.INFO)
								vim.fn.jobstart({ "afplay", audio_file }, { detach = true })
							end
						end)
					end)
				end)
			end
		elseif #args == 1 and args[1] == "open" then
			local state = reader.state
			if not state.source or not state.book then
				vim.notify("No scripture chapter is currently open", vim.log.levels.WARN)
				return
			end
			-- Verified URL slugs for churchofjesuschrist.org
			local URL_SLUGS = {
				-- Book of Mormon
				["1 Nephi"] = "bofm/1-ne",
				["2 Nephi"] = "bofm/2-ne",
				["Jacob"] = "bofm/jacob",
				["Enos"] = "bofm/enos",
				["Jarom"] = "bofm/jarom",
				["Omni"] = "bofm/omni",
				["Words of Mormon"] = "bofm/w-of-m",
				["Mosiah"] = "bofm/mosiah",
				["Alma"] = "bofm/alma",
				["Helaman"] = "bofm/hel",
				["3 Nephi"] = "bofm/3-ne",
				["4 Nephi"] = "bofm/4-ne",
				["Mormon"] = "bofm/morm",
				["Ether"] = "bofm/ether",
				["Moroni"] = "bofm/moro",
				-- Doctrine and Covenants
				["D&C"] = "dc-testament/dc",
				-- Old Testament
				["Genesis"] = "ot/gen",
				["Exodus"] = "ot/ex",
				["Leviticus"] = "ot/lev",
				["Numbers"] = "ot/num",
				["Deuteronomy"] = "ot/deut",
				["Joshua"] = "ot/josh",
				["Judges"] = "ot/judg",
				["Ruth"] = "ot/ruth",
				["1 Samuel"] = "ot/1-sam",
				["2 Samuel"] = "ot/2-sam",
				["1 Kings"] = "ot/1-kgs",
				["2 Kings"] = "ot/2-kgs",
				["1 Chronicles"] = "ot/1-chr",
				["2 Chronicles"] = "ot/2-chr",
				["Ezra"] = "ot/ezra",
				["Nehemiah"] = "ot/neh",
				["Esther"] = "ot/esth",
				["Job"] = "ot/job",
				["Psalms"] = "ot/ps",
				["Proverbs"] = "ot/prov",
				["Ecclesiastes"] = "ot/eccl",
				["Solomon's Song"] = "ot/song",
				["Isaiah"] = "ot/isa",
				["Jeremiah"] = "ot/jer",
				["Lamentations"] = "ot/lam",
				["Ezekiel"] = "ot/ezek",
				["Daniel"] = "ot/dan",
				["Hosea"] = "ot/hosea",
				["Joel"] = "ot/joel",
				["Amos"] = "ot/amos",
				["Obadiah"] = "ot/obad",
				["Jonah"] = "ot/jonah",
				["Micah"] = "ot/micah",
				["Nahum"] = "ot/nahum",
				["Habakkuk"] = "ot/hab",
				["Zephaniah"] = "ot/zeph",
				["Haggai"] = "ot/hag",
				["Zechariah"] = "ot/zech",
				["Malachi"] = "ot/mal",
				-- New Testament
				["Matthew"] = "nt/matt",
				["Mark"] = "nt/mark",
				["Luke"] = "nt/luke",
				["John"] = "nt/john",
				["Acts"] = "nt/acts",
				["Romans"] = "nt/rom",
				["1 Corinthians"] = "nt/1-cor",
				["2 Corinthians"] = "nt/2-cor",
				["Galatians"] = "nt/gal",
				["Ephesians"] = "nt/eph",
				["Philippians"] = "nt/philip",
				["Colossians"] = "nt/col",
				["1 Thessalonians"] = "nt/1-thes",
				["2 Thessalonians"] = "nt/2-thes",
				["1 Timothy"] = "nt/1-tim",
				["2 Timothy"] = "nt/2-tim",
				["Titus"] = "nt/titus",
				["Philemon"] = "nt/philem",
				["Hebrews"] = "nt/heb",
				["James"] = "nt/james",
				["1 Peter"] = "nt/1-pet",
				["2 Peter"] = "nt/2-pet",
				["1 John"] = "nt/1-jn",
				["2 John"] = "nt/2-jn",
				["3 John"] = "nt/3-jn",
				["Jude"] = "nt/jude",
				["Revelation"] = "nt/rev",
				-- Pearl of Great Price
				["Moses"] = "pgp/moses",
				["Abraham"] = "pgp/abr",
				["Joseph Smith—Matthew"] = "pgp/js-m",
				["Joseph Smith—History"] = "pgp/js-h",
				["Articles of Faith"] = "pgp/a-of-f",
			}
			local book_path = URL_SLUGS[state.book]
			if not book_path then
				vim.notify("No URL mapping for: " .. state.book, vim.log.levels.WARN)
				return
			end
			local url
			if state.chapter then
				url = string.format(
					"https://www.churchofjesuschrist.org/study/scriptures/%s/%d?lang=eng",
					book_path, state.chapter
				)
			else
				url = string.format(
					"https://www.churchofjesuschrist.org/study/scriptures/%s?lang=eng",
					book_path
				)
			end
			vim.fn.jobstart({ "open", url }, { detach = true })
		else
			vim.notify("Usage: :Sc | :Sc search | :Sc search ref | :Sc go <book> <chapter> | :Sc open", vim.log.levels.WARN)
		end
	end, { nargs = "*", range = true })

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
