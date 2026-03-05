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

-- Set up buffer-local keymaps
local function setup_keymaps(bufnr)
	local opts = { buffer = bufnr, noremap = true, silent = true }

	vim.keymap.set("n", "<leader>n", next_chapter, opts)
	vim.keymap.set("n", "<leader>p", prev_chapter, opts)
	vim.keymap.set("n", "-", go_back, opts)
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
