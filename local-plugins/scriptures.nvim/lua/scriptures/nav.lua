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
	vim.bo[bufnr].readonly = true
end

-- Display source selection
show_sources = function()
	local bufnr = get_nav_buffer()
	M.state.mode = "sources"
	M.state.source = nil
	M.state.book = nil

	-- Get sources from database and cache them
	M.state.cached_sources = db.get_sources()
	local lines = {}

	for _, source in ipairs(M.state.cached_sources) do
		table.insert(lines, source.title)
	end

	-- Set buffer content
	set_buffer_content(lines)

	-- Set buffer name
	vim.api.nvim_buf_set_name(bufnr, "scriptures://sources")

	-- Set up keymaps
	local opts = { buffer = bufnr, silent = true }

	vim.keymap.set("n", "<CR>", function()
		local line = vim.api.nvim_win_get_cursor(0)[1]
		if line > 0 and line <= #M.state.cached_sources then
			local selected_source = M.state.cached_sources[line]
			show_books(selected_source.id)
		end
	end, opts)

	vim.keymap.set("n", "q", "<cmd>bd!<CR>", opts)

	-- Switch to buffer and set window options
	vim.api.nvim_set_current_buf(bufnr)
	vim.wo.number = false
	vim.wo.relativenumber = false

	-- Move cursor to first line
	vim.api.nvim_win_set_cursor(0, { 1, 0 })
end

-- Display book selection for a source
show_books = function(source_id)
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
			show_chapters(M.state.source, selected_book)
		end
	end, opts)

	vim.keymap.set("n", "-", function()
		show_sources()
	end, opts)

	vim.keymap.set("n", "q", "<cmd>bd!<CR>", opts)

	-- Switch to buffer and set window options
	vim.api.nvim_set_current_buf(bufnr)
	vim.wo.number = false
	vim.wo.relativenumber = false

	-- Move cursor to first line
	vim.api.nvim_win_set_cursor(0, { 1, 0 })
end

-- Display chapter selection for a book
show_chapters = function(source_id, book)
	local bufnr = get_nav_buffer()
	M.state.mode = "chapters"
	M.state.source = source_id
	M.state.book = book

	-- Get chapters from database and cache them
	M.state.cached_chapters = db.get_chapters(source_id, book)
	local lines = {}

	for _, chapter in ipairs(M.state.cached_chapters) do
		table.insert(lines, "Chapter " .. chapter)
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
		show_books(M.state.source)
	end, opts)

	vim.keymap.set("n", "q", "<cmd>bd!<CR>", opts)

	-- Switch to buffer and set window options
	vim.api.nvim_set_current_buf(bufnr)
	vim.wo.number = false
	vim.wo.relativenumber = false

	-- Move cursor to first line
	vim.api.nvim_win_set_cursor(0, { 1, 0 })
end

-- Navigate back from reading view to chapter selection
function M.back_from_reader()
	if reader.state.source and reader.state.book then
		show_chapters(reader.state.source, reader.state.book)
	else
		-- Fallback to sources if we don't have the state
		show_sources()
	end
end

-- Main entry point - open scripture navigation
function M.open()
	show_sources()
end

-- Export show functions for testing/debugging
M.show_sources = show_sources
M.show_books = show_books
M.show_chapters = show_chapters

return M
