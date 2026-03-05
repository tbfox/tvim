local db = require("scriptures.db")
local format = require("scriptures.format")

local M = {}

-- Current state
M.state = {
	source = nil,
	book = nil,
	chapter = nil,
	bufnr = nil,
}

-- Create or update the statusline for scripture buffer
local function update_statusline()
	if M.state.bufnr and vim.api.nvim_buf_is_valid(M.state.bufnr) then
		local abbrev = format.abbreviate_book(M.state.book)
		local statusline = string.format("Scripture: %s %d", abbrev, M.state.chapter)
		vim.api.nvim_buf_set_var(M.state.bufnr, "scripture_statusline", statusline)
	end
end

-- Load a chapter into the current buffer
local function load_chapter(source, book, chapter, verse_num)
	-- Get verses for this chapter
	local verses = db.get_chapter_verses(source, book, chapter)

	if #verses == 0 then
		vim.notify("No verses found for " .. book .. " " .. chapter, vim.log.levels.ERROR)
		return false
	end

	-- Get footnotes for this chapter
	local footnotes = db.get_chapter_footnotes(source, book, chapter)

	-- Format the verses with footnotes
	local lines = format.format_verses(verses, footnotes)

	-- Update state
	M.state.source = source
	M.state.book = book
	M.state.chapter = chapter

	-- Set buffer content
	vim.api.nvim_buf_set_option(M.state.bufnr, "modifiable", true)
	vim.api.nvim_buf_set_lines(M.state.bufnr, 0, -1, false, lines)
	vim.api.nvim_buf_set_option(M.state.bufnr, "modifiable", false)

	-- Update buffer name
	local buf_name = string.format("scriptures://%s/%s/%d", source, book, chapter)
	vim.api.nvim_buf_set_name(M.state.bufnr, buf_name)

	-- Update statusline
	update_statusline()

	-- Move cursor to specific verse or top
	if verse_num then
		-- Search for the verse number pattern: "N. " at the start of a line
		local pattern = "^" .. verse_num .. "\\. "
		vim.fn.search(pattern)
	else
		-- Move cursor to top
		vim.api.nvim_win_set_cursor(0, { 1, 0 })
	end

	return true
end

-- Navigate to next chapter
local function next_chapter()
	-- Check if state is initialized
	if not M.state.source or not M.state.book or not M.state.chapter then
		vim.notify("Scripture reader state not initialized", vim.log.levels.ERROR)
		return
	end

	local next = db.get_next_chapter(M.state.source, M.state.book, M.state.chapter)

	if not next then
		vim.notify("Error getting next chapter", vim.log.levels.ERROR)
		return
	end

	if next.at_boundary == "end" then
		local source_title = db.get_source_title(M.state.source)
		vim.print("The End of " .. source_title)
		return
	end

	load_chapter(next.source, next.book, next.chapter)
end

-- Navigate to previous chapter
local function prev_chapter()
	-- Check if state is initialized
	if not M.state.source or not M.state.book or not M.state.chapter then
		vim.notify("Scripture reader state not initialized", vim.log.levels.ERROR)
		return
	end

	local prev = db.get_prev_chapter(M.state.source, M.state.book, M.state.chapter)

	if not prev then
		vim.notify("Error getting previous chapter", vim.log.levels.ERROR)
		return
	end

	if prev.at_boundary == "start" then
		local source_title = db.get_source_title(M.state.source)
		vim.print("The Start of " .. source_title)
		return
	end

	load_chapter(prev.source, prev.book, prev.chapter)
end

-- Navigate back to chapter selection
local function go_back()
	-- Lazy require to avoid circular dependency
	local nav = require("scriptures.nav")
	nav.back_from_reader()
end

-- Go to footnote reference
local function go_to_reference()
	-- Check if state is initialized
	if not M.state.source or not M.state.book or not M.state.chapter then
		vim.notify("Scripture reader state not initialized", vim.log.levels.ERROR)
		return
	end

	-- Get current cursor position
	local cursor = vim.api.nvim_win_get_cursor(0)
	local line_num = cursor[1]
	local col = cursor[2]

	-- Get the line text
	local line = vim.api.nvim_buf_get_lines(M.state.bufnr, line_num - 1, line_num, false)[1]
	if not line then
		return
	end

	-- Find which footnote marker the cursor is on
	-- Pattern: (letter)|text|
	local note_letter = nil
	local verse_num = nil

	-- First, get the verse number from the beginning of the line or search backwards
	local verse_pattern = "^(%d+)%. "
	verse_num = line:match(verse_pattern)

	-- If not found on this line, search backwards for verse number
	if not verse_num then
		for i = line_num - 1, 1, -1 do
			local prev_line = vim.api.nvim_buf_get_lines(M.state.bufnr, i - 1, i, false)[1]
			if prev_line then
				verse_num = prev_line:match(verse_pattern)
				if verse_num then
					break
				end
			end
		end
	end

	if not verse_num then
		vim.notify("Could not determine verse number", vim.log.levels.WARN)
		return
	end
	verse_num = tonumber(verse_num)

	-- Find all footnote markers in the line and check if cursor is within one
	local pos = 1
	while pos <= #line do
		local marker_start, marker_end, letter = line:find("%((%w+)%)|([^|]+)|", pos)
		if not marker_start then
			break
		end

		-- Check if cursor is within this marker (adjust for 0-indexed col)
		if col >= marker_start - 1 and col < marker_end then
			note_letter = letter
			break
		end

		pos = marker_end + 1
	end

	if not note_letter then
		vim.notify("Cursor is not on a footnote reference", vim.log.levels.WARN)
		return
	end

	-- Get the references from the database
	local references = db.get_footnote_references(M.state.source, M.state.book, M.state.chapter, verse_num, note_letter)

	if #references == 0 then
		-- Check if there are topical guide references
		if db.has_topical_guide_references(M.state.source, M.state.book, M.state.chapter, verse_num, note_letter) then
			vim.notify("Topical Guide is not implemented yet", vim.log.levels.INFO)
		else
			vim.notify("No scripture references found for this footnote", vim.log.levels.INFO)
		end
		return
	end

	-- If only one reference, go directly to it
	if #references == 1 then
		local ref = references[1]
		local verse_target = ref.ref_verse_start
		M.open(ref.ref_source_id, ref.ref_book_name, ref.ref_chapter, verse_target)
		return
	end

	-- Multiple references: show in location list
	local items = {}
	for _, ref in ipairs(references) do
		local verse_range = tostring(ref.ref_verse_start)
		if ref.ref_verse_end and ref.ref_verse_end ~= ref.ref_verse_start then
			verse_range = verse_range .. "-" .. ref.ref_verse_end
		end

		local abbrev = format.abbreviate_book(ref.ref_book_name)
		local text = string.format("%s %d:%s", abbrev, ref.ref_chapter, verse_range)

		table.insert(items, {
			text = text,
			source = ref.ref_source_id,
			book = ref.ref_book_name,
			chapter = ref.ref_chapter,
			verse = ref.ref_verse_start
		})
	end

	-- Use vim.ui.select to present choices
	vim.ui.select(items, {
		prompt = "Select reference:",
		format_item = function(item)
			return item.text
		end
	}, function(choice)
		if choice then
			M.open(choice.source, choice.book, choice.chapter, choice.verse)
		end
	end)
end

-- Set up buffer-local keymaps
local function setup_keymaps(bufnr)
	local opts = { buffer = bufnr, noremap = true, silent = true }

	vim.keymap.set("n", "<leader>n", next_chapter, opts)
	vim.keymap.set("n", "<leader>p", prev_chapter, opts)
	vim.keymap.set("n", "-", go_back, opts)
	vim.keymap.set("n", "gd", go_to_reference, opts)
end

-- Open a reading buffer for a specific chapter
-- If verse is provided, scroll to that verse
function M.open(source, book, chapter, verse)
	-- Create a new buffer if needed
	if not M.state.bufnr or not vim.api.nvim_buf_is_valid(M.state.bufnr) then
		M.state.bufnr = vim.api.nvim_create_buf(false, true)

		-- Set buffer options
		vim.api.nvim_buf_set_option(M.state.bufnr, "filetype", "scripture")
		vim.api.nvim_buf_set_option(M.state.bufnr, "buftype", "nofile")
		vim.api.nvim_buf_set_option(M.state.bufnr, "swapfile", false)
		vim.api.nvim_buf_set_option(M.state.bufnr, "bufhidden", "hide")

		-- Set up keymaps
		setup_keymaps(M.state.bufnr)

		-- Set up autocommands to manage conceallevel
		local augroup = vim.api.nvim_create_augroup("ScriptureConcealment", { clear = false })

		vim.api.nvim_create_autocmd("BufEnter", {
			group = augroup,
			buffer = M.state.bufnr,
			callback = function()
				-- Save the current conceallevel before changing it
				vim.b.saved_conceallevel = vim.wo.conceallevel
				vim.b.saved_concealcursor = vim.wo.concealcursor
				-- Set conceallevel for scripture reading (2 = hide completely)
				vim.wo.conceallevel = 2
				-- Empty concealcursor means reveal when cursor is on the line
				vim.wo.concealcursor = ""
			end,
		})

		vim.api.nvim_create_autocmd("BufLeave", {
			group = augroup,
			buffer = M.state.bufnr,
			callback = function()
				-- Restore the previous conceallevel
				if vim.b.saved_conceallevel then
					vim.wo.conceallevel = vim.b.saved_conceallevel
				end
				if vim.b.saved_concealcursor then
					vim.wo.concealcursor = vim.b.saved_concealcursor
				end
			end,
		})
	end

	-- Switch to the buffer
	vim.api.nvim_set_current_buf(M.state.bufnr)

	-- Load the chapter
	load_chapter(source, book, chapter, verse)
end

-- Get current statusline text
function M.get_statusline()
	if M.state.bufnr and vim.api.nvim_buf_is_valid(M.state.bufnr) then
		local ok, statusline = pcall(vim.api.nvim_buf_get_var, M.state.bufnr, "scripture_statusline")
		if ok then
			return statusline
		end
	end
	return ""
end

return M
