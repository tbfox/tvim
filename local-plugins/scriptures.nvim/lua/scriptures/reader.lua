local db = require("scriptures.db")
local format = require("scriptures.format")
local history = require("scriptures.history")

local M = {}

-- Current state
M.state = {
	source = nil,
	book = nil,
	chapter = nil,
	bd_entry = nil,  -- slug of current BD entry, or nil if in scripture mode
	bufnr = nil,
}

-- ── Statusline ───────────────────────────────────────────────────────────────

local function update_statusline()
	if M.state.bufnr and vim.api.nvim_buf_is_valid(M.state.bufnr) then
		local statusline
		if M.state.bd_entry then
			statusline = "BD: " .. (M.state.bd_entry or "")
		elseif M.state.chapter == nil then
			statusline = "Scripture: " .. M.state.book
		else
			local abbrev = format.abbreviate_book(M.state.book)
			statusline = string.format("Scripture: %s %d", abbrev, M.state.chapter)
		end
		vim.api.nvim_buf_set_var(M.state.bufnr, "scripture_statusline", statusline)
	end
end

-- ── Scripture loading ────────────────────────────────────────────────────────

local function load_chapter(source, book, chapter, verse_num)
	local lines

	if chapter == nil then
		local blocks = db.get_book_blocks(source, book)
		if #blocks == 0 then
			vim.notify("No content found for " .. book, vim.log.levels.ERROR)
			return false
		end
		lines = format.format_blocks(blocks)
	else
		local verses = db.get_chapter_verses(source, book, chapter)
		if #verses == 0 then
			vim.notify("No verses found for " .. book .. " " .. chapter, vim.log.levels.ERROR)
			return false
		end
		local footnotes = db.get_chapter_footnotes(source, book, chapter)
		lines = format.format_verses(verses, footnotes)
	end

	M.state.source = source
	M.state.book = book
	M.state.chapter = chapter
	M.state.bd_entry = nil

	vim.api.nvim_buf_set_option(M.state.bufnr, "modifiable", true)
	vim.api.nvim_buf_set_lines(M.state.bufnr, 0, -1, false, lines)
	vim.api.nvim_buf_set_option(M.state.bufnr, "modifiable", false)

	local buf_name
	if chapter == nil then
		buf_name = book
	else
		local abbrev = format.abbreviate_book(book)
		buf_name = string.format("%s %d", abbrev, chapter)
	end
	vim.api.nvim_buf_set_name(M.state.bufnr, buf_name)
	update_statusline()

	if verse_num then
		local pattern = "^" .. verse_num .. "\\. "
		vim.fn.search(pattern)
	else
		vim.api.nvim_win_set_cursor(0, { 1, 0 })
	end

	history.push({ type = "chapter", source = source, book = book, chapter = chapter })

	return true
end

-- ── BD loading ───────────────────────────────────────────────────────────────

local function load_bd_entry(slug)
	local entry = db.get_bd_entry(slug)
	if not entry then
		vim.notify("BD entry not found: " .. slug, vim.log.levels.ERROR)
		return false
	end

	local links = db.get_bd_links(slug)
	local lines = format.format_bd_entry(entry, links)

	M.state.source = nil
	M.state.book = nil
	M.state.chapter = nil
	M.state.bd_entry = slug

	vim.api.nvim_buf_set_option(M.state.bufnr, "modifiable", true)
	vim.api.nvim_buf_set_lines(M.state.bufnr, 0, -1, false, lines)
	vim.api.nvim_buf_set_option(M.state.bufnr, "modifiable", false)

	vim.api.nvim_buf_set_name(M.state.bufnr, "BD: " .. entry.title)
	update_statusline()
	vim.api.nvim_win_set_cursor(0, { 1, 0 })

	history.push({ type = "bd", slug = slug })

	return true
end

-- ── Chapter navigation ───────────────────────────────────────────────────────

local function next_chapter()
	if M.state.bd_entry then
		local neighbor = db.get_bd_neighbor(M.state.bd_entry, 1)
		if neighbor then
			load_bd_entry(neighbor.id)
		else
			vim.print("End of Bible Dictionary")
		end
		return
	end

	if not M.state.source or not M.state.book then
		vim.notify("Scripture reader state not initialized", vim.log.levels.ERROR)
		return
	end

	if M.state.chapter == nil then
		local books = db.get_books(M.state.source)
		local idx = nil
		for i, b in ipairs(books) do
			if b == M.state.book then idx = i; break end
		end
		if idx and idx < #books then
			load_chapter(M.state.source, books[idx + 1], nil)
		else
			vim.print("The End of " .. db.get_source_title(M.state.source))
		end
		return
	end

	local next = db.get_next_chapter(M.state.source, M.state.book, M.state.chapter)
	if not next then
		vim.notify("Error getting next chapter", vim.log.levels.ERROR)
		return
	end
	if next.at_boundary == "end" then
		vim.print("The End of " .. db.get_source_title(M.state.source))
		return
	end
	load_chapter(next.source, next.book, next.chapter)
end

local function prev_chapter()
	if M.state.bd_entry then
		local neighbor = db.get_bd_neighbor(M.state.bd_entry, -1)
		if neighbor then
			load_bd_entry(neighbor.id)
		else
			vim.print("Start of Bible Dictionary")
		end
		return
	end

	if not M.state.source or not M.state.book then
		vim.notify("Scripture reader state not initialized", vim.log.levels.ERROR)
		return
	end

	if M.state.chapter == nil then
		local books = db.get_books(M.state.source)
		local idx = nil
		for i, b in ipairs(books) do
			if b == M.state.book then idx = i; break end
		end
		if idx and idx > 1 then
			load_chapter(M.state.source, books[idx - 1], nil)
		else
			vim.print("The Start of " .. db.get_source_title(M.state.source))
		end
		return
	end

	local prev = db.get_prev_chapter(M.state.source, M.state.book, M.state.chapter)
	if not prev then
		vim.notify("Error getting previous chapter", vim.log.levels.ERROR)
		return
	end
	if prev.at_boundary == "start" then
		vim.print("The Start of " .. db.get_source_title(M.state.source))
		return
	end
	load_chapter(prev.source, prev.book, prev.chapter)
end

local function go_back()
	local nav = require("scriptures.nav")
	nav.back_from_reader()
end

local function history_navigate(entry)
	history._navigating = true
	if entry.type == "chapter" then
		load_chapter(entry.source, entry.book, entry.chapter)
	elseif entry.type == "bd" then
		load_bd_entry(entry.slug)
	end
	history._navigating = false
end

local function history_back()
	local entry = history.back()
	if not entry then
		vim.notify("No earlier history", vim.log.levels.INFO)
		return
	end
	history_navigate(entry)
end

local function history_forward()
	local entry = history.forward()
	if not entry then
		vim.notify("No later history", vim.log.levels.INFO)
		return
	end
	history_navigate(entry)
end

-- ── Reference navigation ─────────────────────────────────────────────────────

-- Returns the marker token under the cursor (letter or number), or nil
local function marker_at_cursor()
	local cursor = vim.api.nvim_win_get_cursor(0)
	local line_num = cursor[1]
	local col = cursor[2]
	local line = vim.api.nvim_buf_get_lines(M.state.bufnr, line_num - 1, line_num, false)[1]
	if not line then return nil end

	local pos = 1
	while pos <= #line do
		local s, e, token = line:find("%((%w+)%)|([^|]+)|", pos)
		if not s then break end
		if col >= s - 1 and col < e then return token end
		pos = e + 1
	end
	return nil
end

local function go_to_bd_reference()
	local n = marker_at_cursor()
	if not n then
		vim.notify("Cursor is not on a link", vim.log.levels.WARN)
		return
	end

	local links = db.get_bd_links(M.state.bd_entry)
	local link = nil
	for _, l in ipairs(links) do
		if tostring(l.sort_order) == tostring(n) then
			link = l
			break
		end
	end

	if not link then
		vim.notify("Link not found", vim.log.levels.WARN)
		return
	end

	if link.link_type == "bd" then
		M.open_bd(link.target_entry_id)
	else
		-- Resolve book_short -> full name via db
		local db_path = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h:h:h") .. "/res/scriptures.db"
		local sql = string.format(
			"SELECT name FROM books WHERE source_id='%s' AND short_name='%s';",
			link.ref_source_id, link.ref_book_short
		)
		local book_name = vim.trim(vim.fn.system(string.format("sqlite3 '%s' \"%s\"", db_path, sql)))
		if book_name == "" then
			vim.notify("Could not resolve book: " .. (link.ref_book_short or "?"), vim.log.levels.WARN)
			return
		end
		M.open(link.ref_source_id, book_name, tonumber(link.ref_chapter),
			link.ref_verse_start and tonumber(link.ref_verse_start) or nil)
	end
end

local function go_to_scripture_reference()
	if not M.state.source or not M.state.book or not M.state.chapter then
		vim.notify("Scripture reader state not initialized", vim.log.levels.ERROR)
		return
	end

	local cursor = vim.api.nvim_win_get_cursor(0)
	local line_num = cursor[1]
	local line = vim.api.nvim_buf_get_lines(M.state.bufnr, line_num - 1, line_num, false)[1]
	if not line then return end

	local verse_num = line:match("^(%d+)%. ")
	if not verse_num then
		for i = line_num - 1, 1, -1 do
			local prev_line = vim.api.nvim_buf_get_lines(M.state.bufnr, i - 1, i, false)[1]
			if prev_line then
				verse_num = prev_line:match("^(%d+)%. ")
				if verse_num then break end
			end
		end
	end

	if not verse_num then
		vim.notify("Could not determine verse number", vim.log.levels.WARN)
		return
	end
	verse_num = tonumber(verse_num)

	local note_letter = marker_at_cursor()
	if not note_letter then
		vim.notify("Cursor is not on a footnote reference", vim.log.levels.WARN)
		return
	end

	local references = db.get_footnote_references(M.state.source, M.state.book, M.state.chapter, verse_num, note_letter)

	if #references == 0 then
		if db.has_topical_guide_references(M.state.source, M.state.book, M.state.chapter, verse_num, note_letter) then
			vim.notify("Topical Guide is not implemented yet", vim.log.levels.INFO)
		else
			vim.notify("No scripture references found for this footnote", vim.log.levels.INFO)
		end
		return
	end

	if #references == 1 then
		local ref = references[1]
		M.open(ref.ref_source_id, ref.ref_book_name, ref.ref_chapter, ref.ref_verse_start)
		return
	end

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

	vim.ui.select(items, {
		prompt = "Select reference:",
		format_item = function(item) return item.text end,
	}, function(choice)
		if choice then
			M.open(choice.source, choice.book, choice.chapter, choice.verse)
		end
	end)
end

local function go_to_reference()
	if M.state.bd_entry then
		go_to_bd_reference()
	else
		go_to_scripture_reference()
	end
end

-- ── Buffer setup ─────────────────────────────────────────────────────────────

local function setup_keymaps(bufnr)
	local opts = { buffer = bufnr, noremap = true, silent = true }
	vim.keymap.set("n", "]c", next_chapter, opts)
	vim.keymap.set("n", "[c", prev_chapter, opts)
	vim.keymap.set("n", "-", go_back, opts)
	vim.keymap.set("n", "gd", go_to_reference, opts)
	vim.keymap.set("n", "<C-o>", history_back, opts)
	vim.keymap.set("n", "<C-i>", history_forward, opts)
end

local function ensure_buffer()
	if not M.state.bufnr or not vim.api.nvim_buf_is_valid(M.state.bufnr) then
		M.state.bufnr = vim.api.nvim_create_buf(false, true)

		vim.api.nvim_buf_set_option(M.state.bufnr, "filetype", "scripture")
		vim.api.nvim_buf_set_option(M.state.bufnr, "buftype", "nofile")
		vim.api.nvim_buf_set_option(M.state.bufnr, "swapfile", false)
		vim.api.nvim_buf_set_option(M.state.bufnr, "bufhidden", "hide")

		setup_keymaps(M.state.bufnr)

		local augroup = vim.api.nvim_create_augroup("ScriptureConcealment", { clear = true })
		local saved_conceallevel = nil
		local saved_concealcursor = nil
		local active_win = nil

		vim.api.nvim_create_autocmd("BufEnter", {
			group = augroup,
			buffer = M.state.bufnr,
			callback = function()
				active_win = vim.api.nvim_get_current_win()
				saved_conceallevel = vim.wo[active_win].conceallevel
				saved_concealcursor = vim.wo[active_win].concealcursor
				vim.wo[active_win].conceallevel = 2
				vim.wo[active_win].concealcursor = ""
			end,
		})

		vim.api.nvim_create_autocmd("BufLeave", {
			group = augroup,
			buffer = M.state.bufnr,
			callback = function()
				if active_win and vim.api.nvim_win_is_valid(active_win) then
					if saved_conceallevel ~= nil then
						vim.wo[active_win].conceallevel = saved_conceallevel
					end
					if saved_concealcursor ~= nil then
						vim.wo[active_win].concealcursor = saved_concealcursor
					end
				end
				active_win = nil
				saved_conceallevel = nil
				saved_concealcursor = nil
			end,
		})
	end
end

-- ── Public API ───────────────────────────────────────────────────────────────

-- Open a scripture chapter
function M.open(source, book, chapter, verse, opts)
	opts = opts or {}
	if opts.new_tab then vim.cmd("tabnew") end
	ensure_buffer()
	vim.api.nvim_set_current_buf(M.state.bufnr)
	load_chapter(source, book, chapter, verse)
end

-- Open a Bible Dictionary entry by slug
function M.open_bd(slug, opts)
	opts = opts or {}
	if opts.new_tab then vim.cmd("tabnew") end
	ensure_buffer()
	vim.api.nvim_set_current_buf(M.state.bufnr)
	load_bd_entry(slug)
end

-- History back/forward (callable from init.lua for :Sc hist prev/next)
function M.history_back()
	history_back()
end

function M.history_forward()
	history_forward()
end

-- Jump to the most recent history entry (useful after leaving scripture context)
function M.go_history_end()
	local entry = history.last()
	if not entry then
		vim.notify("No scripture history", vim.log.levels.INFO)
		return
	end
	ensure_buffer()
	vim.api.nvim_set_current_buf(M.state.bufnr)
	history_navigate(entry)
end

-- Get current statusline text
function M.get_statusline()
	if M.state.bufnr and vim.api.nvim_buf_is_valid(M.state.bufnr) then
		local ok, statusline = pcall(vim.api.nvim_buf_get_var, M.state.bufnr, "scripture_statusline")
		if ok then return statusline end
	end
	return ""
end

return M
