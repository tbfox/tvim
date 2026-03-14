local db = require("scriptures.db")
local reader = require("scriptures.reader")

local M = {}

-- Check if telescope is available
local function has_telescope()
	local ok, _ = pcall(require, "telescope")
	return ok
end

-- Search verse content using telescope
function M.search_content()
	if not has_telescope() then
		vim.notify("Telescope is required for search functionality", vim.log.levels.ERROR)
		return
	end

	local pickers = require("telescope.pickers")
	local finders = require("telescope.finders")
	local conf = require("telescope.config").values
	local actions = require("telescope.actions")
	local action_state = require("telescope.actions.state")

	-- Get all verses from database
	local function get_all_verses()
		local db_path = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h:h:h") .. "/res/scriptures.db"
		local sql = "SELECT s.id, b.name, v.chapter_number, v.verse_number, v.content FROM verses v JOIN books b ON v.book_id = b.id JOIN sources s ON b.source_id = s.id ORDER BY v.id;"
		local cmd = string.format("sqlite3 -separator '\t' '%s' \"%s\"", db_path, sql)
		local result = vim.fn.system(cmd)

		if vim.v.shell_error ~= 0 then
			vim.notify("Failed to query database: " .. result, vim.log.levels.ERROR)
			return {}
		end

		local verses = {}
		local lines = vim.split(result, "\n", { trimempty = true })

		for _, line in ipairs(lines) do
			local parts = vim.split(line, "\t")
			if #parts >= 5 then
				table.insert(verses, {
					source = parts[1],
					book = parts[2],
					chapter = tonumber(parts[3]),
					verse = tonumber(parts[4]),
					content = parts[5],
				})
			end
		end

		return verses
	end

	-- Create telescope picker
	pickers.new({}, {
		prompt_title = "Search Scriptures",
		finder = finders.new_dynamic({
			fn = function(prompt)
				if not prompt or prompt == "" then
					return {}
				end

				-- Filter verses by prompt
				local all_verses = get_all_verses()
				local results = {}
				local pattern = prompt:lower()

				for _, verse in ipairs(all_verses) do
					if verse.content:lower():find(pattern, 1, true) then
						table.insert(results, verse)
						-- Limit results for performance
						if #results >= 100 then
							break
						end
					end
				end

				return results
			end,
			entry_maker = function(verse)
				return {
					value = verse,
					display = string.format("%s %s:%d - %s",
						verse.book,
						verse.chapter,
						verse.verse,
						verse.content:sub(1, 80)
					),
					ordinal = verse.book .. " " .. verse.chapter .. ":" .. verse.verse .. " " .. verse.content,
				}
			end,
		}),
		sorter = conf.generic_sorter({}),
		attach_mappings = function(prompt_bufnr, map)
			actions.select_default:replace(function()
				actions.close(prompt_bufnr)
				local selection = action_state.get_selected_entry()
				if selection then
					local verse = selection.value
					reader.open(verse.source, verse.book, verse.chapter, verse.verse)
				end
			end)
			return true
		end,
	}):find()
end

-- Search scripture references using telescope
function M.search_references()
	if not has_telescope() then
		vim.notify("Telescope is required for search functionality", vim.log.levels.ERROR)
		return
	end

	local pickers = require("telescope.pickers")
	local finders = require("telescope.finders")
	local conf = require("telescope.config").values
	local actions = require("telescope.actions")
	local action_state = require("telescope.actions.state")

	-- Get all book/chapter combinations
	local function get_all_references()
		local sources = db.get_sources()
		local references = {}

		for _, source in ipairs(sources) do
			local books = db.get_books(source.id)
			for _, book in ipairs(books) do
				local chapters = db.get_chapters(source.id, book)
				for _, chapter in ipairs(chapters) do
					table.insert(references, {
						source = source.id,
						source_title = source.title,
						book = book,
						chapter = chapter,
					})
				end
			end
		end

		return references
	end

	local all_refs = get_all_references()

	-- Create telescope picker
	pickers.new({}, {
		prompt_title = "Scripture References",
		finder = finders.new_table({
			results = all_refs,
			entry_maker = function(ref)
				-- Use "Section" for D&C
				local chapter_label = ref.source == "dc" and "Section" or "Chapter"
				return {
					value = ref,
					display = string.format("%s - %s %s %d",
						ref.source_title,
						ref.book,
						chapter_label,
						ref.chapter
					),
					ordinal = ref.source_title .. " " .. ref.book .. " " .. ref.chapter,
				}
			end,
		}),
		sorter = conf.generic_sorter({}),
		attach_mappings = function(prompt_bufnr, map)
			actions.select_default:replace(function()
				actions.close(prompt_bufnr)
				local selection = action_state.get_selected_entry()
				if selection then
					local ref = selection.value
					reader.open(ref.source, ref.book, ref.chapter)
				end
			end)
			return true
		end,
	}):find()
end

return M
