local db = require("scriptures.db")
local reader = require("scriptures.reader")

local M = {}

-- Navigation state - cache data to avoid re-querying
M.state = {
	bufnr = nil,
	mode = nil, -- "sources", "books", "chapters"
	source = nil,
	book = nil,
	cached_sources = {},
	cached_books = {},
	cached_chapters = {},
	origin_bufnr = nil, -- buffer that was active before opening scripture nav
}

-- Forward declarations
local show_sources
local show_books
local show_chapters

-- Create or get the navigation buffer
local function get_nav_buffer()
	if not M.state.bufnr or not vim.api.nvim_buf_is_valid(M.state.bufnr) then
		M.state.bufnr = vim.api.nvim_create_buf(false, true)

		-- Set buffer options
		vim.bo[M.state.bufnr].filetype = "scripture-nav"
		vim.bo[M.state.bufnr].buftype = "nofile"
		vim.bo[M.state.bufnr].swapfile = false
		vim.bo[M.state.bufnr].bufhidden = "hide"
	end

	return M.state.bufnr
end

-- Set buffer content and make it read-only
local function set_buffer_content(lines)
	local bufnr = get_nav_buffer()
	vim.bo[bufnr].modifiable = true
	vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
	vim.bo[bufnr].modifiable = false
end

-- Display BD entry list (flat, no chapters)
local show_bd_entries
show_bd_entries = function(restore_entry_id)
	local bufnr = get_nav_buffer()
	M.state.mode = "bd_entries"
	M.state.source = "bd"
	M.state.book = nil

	M.state.cached_bd_entries = db.get_bd_entries()
	local lines = {}
	for _, e in ipairs(M.state.cached_bd_entries) do
		table.insert(lines, e.title)
	end

	set_buffer_content(lines)
	vim.api.nvim_buf_set_name(bufnr, "scriptures://bd")

	local opts = { buffer = bufnr, silent = true }

	vim.keymap.set("n", "<CR>", function()
		local line = vim.api.nvim_win_get_cursor(0)[1]
		if line > 0 and line <= #M.state.cached_bd_entries then
			local entry = M.state.cached_bd_entries[line]
			reader.open_bd(entry.id)
		end
	end, opts)

	vim.keymap.set("n", "-", function()
		show_sources("bd")
	end, opts)

	vim.keymap.set("n", "q", function()
		local origin = M.state.origin_bufnr
		if origin and vim.api.nvim_buf_is_valid(origin) then
			vim.api.nvim_set_current_buf(origin)
		else
			vim.cmd("enew")
		end
	end, opts)

	vim.api.nvim_set_current_buf(bufnr)

	-- Restore cursor to the entry we came from, or first line
	local cursor_line = 1
	if restore_entry_id then
		for i, e in ipairs(M.state.cached_bd_entries) do
			if e.id == restore_entry_id then
				cursor_line = i
				break
			end
		end
	end
	vim.api.nvim_win_set_cursor(0, { cursor_line, 0 })
end

-- Display source selection
show_sources = function(restore_source_id)
	local bufnr = get_nav_buffer()
	M.state.mode = "sources"
	M.state.source = nil
	M.state.book = nil

	-- Get sources from database and cache them
	M.state.cached_sources = db.get_sources()
	-- Add BD as a virtual source entry
	local lines = {}
	for _, source in ipairs(M.state.cached_sources) do
		table.insert(lines, source.title)
	end
	table.insert(lines, "Bible Dictionary")

	-- Set buffer content
	set_buffer_content(lines)

	-- Set buffer name
	vim.api.nvim_buf_set_name(bufnr, "scriptures://sources")

	-- Set up keymaps
	local opts = { buffer = bufnr, silent = true }

	vim.keymap.set("n", "<CR>", function()
		local line = vim.api.nvim_win_get_cursor(0)[1]
		-- Last entry is Bible Dictionary
		if line == #M.state.cached_sources + 1 then
			show_bd_entries()
			return
		end
		if line > 0 and line <= #M.state.cached_sources then
			local selected_source = M.state.cached_sources[line]
			-- D&C has only one book, so skip directly to chapters
			if selected_source.id == "dc" then
				show_chapters(selected_source.id, "D&C")
			else
				show_books(selected_source.id)
			end
		end
	end, opts)

	vim.keymap.set("n", "q", function()
		local origin = M.state.origin_bufnr
		if origin and vim.api.nvim_buf_is_valid(origin) then
			vim.api.nvim_set_current_buf(origin)
		else
			vim.cmd("enew")
		end
	end, opts)

	-- Switch to buffer
	vim.api.nvim_set_current_buf(bufnr)

	-- Restore cursor to the source we came from, or first line
	local cursor_line = 1
	if restore_source_id == "bd" then
		cursor_line = #M.state.cached_sources + 1
	elseif restore_source_id then
		for i, source in ipairs(M.state.cached_sources) do
			if source.id == restore_source_id then
				cursor_line = i
				break
			end
		end
	end
	vim.api.nvim_win_set_cursor(0, { cursor_line, 0 })
end

-- Display book selection for a source
show_books = function(source_id, restore_book)
	local bufnr = get_nav_buffer()
	M.state.mode = "books"
	M.state.source = source_id
	M.state.book = nil

	-- Get books from database and cache them
	M.state.cached_books = db.get_books(source_id)
	local lines = vim.deepcopy(M.state.cached_books)

	-- Set buffer content
	set_buffer_content(lines)

	-- Set buffer name
	vim.api.nvim_buf_set_name(bufnr, "scriptures://" .. source_id)

	-- Set up keymaps
	local opts = { buffer = bufnr, silent = true }

	vim.keymap.set("n", "<CR>", function()
		local line = vim.api.nvim_win_get_cursor(0)[1]
		if line > 0 and line <= #M.state.cached_books then
			local selected_book = M.state.cached_books[line]
			if db.source_has_blocks(M.state.source) then
				reader.open(M.state.source, selected_book, nil)
			else
				show_chapters(M.state.source, selected_book)
			end
		end
	end, opts)

	vim.keymap.set("n", "-", function()
		show_sources(M.state.source)
	end, opts)

	vim.keymap.set("n", "q", function()
		local origin = M.state.origin_bufnr
		if origin and vim.api.nvim_buf_is_valid(origin) then
			vim.api.nvim_set_current_buf(origin)
		else
			vim.cmd("enew")
		end
	end, opts)

	-- Switch to buffer
	vim.api.nvim_set_current_buf(bufnr)

	-- Restore cursor to the book we came from, or first line
	local cursor_line = 1
	if restore_book then
		for i, book in ipairs(M.state.cached_books) do
			if book == restore_book then
				cursor_line = i
				break
			end
		end
	end
	vim.api.nvim_win_set_cursor(0, { cursor_line, 0 })
end

-- Display chapter selection for a book
show_chapters = function(source_id, book, restore_chapter)
	local bufnr = get_nav_buffer()
	M.state.mode = "chapters"
	M.state.source = source_id
	M.state.book = book

	-- Get chapters from database and cache them
	M.state.cached_chapters = db.get_chapters(source_id, book)
	local lines = {}

	-- D&C uses "Section" instead of "Chapter"
	local label = source_id == "dc" and "Section" or "Chapter"
	for _, chapter in ipairs(M.state.cached_chapters) do
		table.insert(lines, label .. " " .. chapter)
	end

	-- Set buffer content
	set_buffer_content(lines)

	-- Set buffer name
	local buf_name = string.format("scriptures://%s/%s", source_id, book)
	vim.api.nvim_buf_set_name(bufnr, buf_name)

	-- Set up keymaps
	local opts = { buffer = bufnr, silent = true }

	vim.keymap.set("n", "<CR>", function()
		local line = vim.api.nvim_win_get_cursor(0)[1]
		if line > 0 and line <= #M.state.cached_chapters then
			local selected_chapter = M.state.cached_chapters[line]
			-- Open the reading view
			reader.open(M.state.source, M.state.book, selected_chapter)
		end
	end, opts)

	vim.keymap.set("n", "-", function()
		-- D&C has no book layer, go directly back to sources
		if M.state.source == "dc" then
			show_sources(M.state.source)
		else
			show_books(M.state.source, M.state.book)
		end
	end, opts)

	vim.keymap.set("n", "q", function()
		local origin = M.state.origin_bufnr
		if origin and vim.api.nvim_buf_is_valid(origin) then
			vim.api.nvim_set_current_buf(origin)
		else
			vim.cmd("enew")
		end
	end, opts)

	-- Switch to buffer
	vim.api.nvim_set_current_buf(bufnr)

	-- Restore cursor to the chapter we came from, or first line
	local cursor_line = 1
	if restore_chapter then
		for i, ch in ipairs(M.state.cached_chapters) do
			if ch == restore_chapter then
				cursor_line = i
				break
			end
		end
	end
	vim.api.nvim_win_set_cursor(0, { cursor_line, 0 })
end

-- Navigate back from reading view to chapter/entry selection
function M.back_from_reader()
	if reader.state.bd_entry then
		show_bd_entries(reader.state.bd_entry)
	elseif reader.state.source and reader.state.book then
		if db.source_has_blocks(reader.state.source) then
			show_books(reader.state.source, reader.state.book)
		else
			show_chapters(reader.state.source, reader.state.book, reader.state.chapter)
		end
	else
		show_sources()
	end
end

-- Main entry point - open scripture navigation
function M.open()
	M.state.origin_bufnr = vim.api.nvim_get_current_buf()
	show_sources()
end

-- Export show functions for testing/debugging
M.show_sources = show_sources
M.show_books = show_books
M.show_chapters = show_chapters
M.show_bd_entries = show_bd_entries

return M
