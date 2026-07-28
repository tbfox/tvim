local db = require("scriptures.db")
local format = require("scriptures.format")

local M = {}

M.state = {
	bufnr = nil,
	mode = nil, -- "lists" or "list_items"
	current_list_id = nil,
	current_list_name = nil,
	cached_lists = {},
	cached_items = {},
	origin_bufnr = nil,
}

-- Forward declarations
local show_lists
local show_list_items

local function get_lists_buffer()
	if not M.state.bufnr or not vim.api.nvim_buf_is_valid(M.state.bufnr) then
		M.state.bufnr = vim.api.nvim_create_buf(false, true)
		vim.bo[M.state.bufnr].filetype = "scripture-nav"
		vim.bo[M.state.bufnr].buftype = "nofile"
		vim.bo[M.state.bufnr].swapfile = false
		vim.bo[M.state.bufnr].bufhidden = "hide"
	end
	return M.state.bufnr
end

local function set_buffer_content(lines)
	local bufnr = get_lists_buffer()
	vim.bo[bufnr].modifiable = true
	vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
	vim.bo[bufnr].modifiable = false
end

show_lists = function(restore_list_id)
	local bufnr = get_lists_buffer()
	M.state.mode = "lists"
	M.state.current_list_id = nil
	M.state.current_list_name = nil

	M.state.cached_lists = db.get_lists()

	local lines = {}
	if #M.state.cached_lists == 0 then
		table.insert(lines, "(no lists yet — press 'a' to create one)")
	else
		for _, lst in ipairs(M.state.cached_lists) do
			local count = tonumber(lst.item_count) or 0
			local suffix = count == 1 and "1 verse" or (count .. " verses")
			table.insert(lines, string.format("%-40s (%s)", lst.name, suffix))
		end
	end

	set_buffer_content(lines)
	vim.api.nvim_buf_set_name(bufnr, "scriptures://lists")

	local opts = { buffer = bufnr, silent = true }

	vim.keymap.set("n", "<CR>", function()
		if #M.state.cached_lists == 0 then return end
		local line = vim.api.nvim_win_get_cursor(0)[1]
		if line > 0 and line <= #M.state.cached_lists then
			local lst = M.state.cached_lists[line]
			show_list_items(lst.id, lst.name)
		end
	end, opts)

	vim.keymap.set("n", "a", function()
		vim.ui.input({ prompt = "New list name: " }, function(name)
			if name and name ~= "" then
				local ok, err = pcall(db.create_list, name)
				if ok then
					vim.notify("Created list: " .. name, vim.log.levels.INFO)
					show_lists(nil)
				else
					vim.notify("Error: " .. tostring(err), vim.log.levels.ERROR)
				end
			end
		end)
	end, opts)

	vim.keymap.set("n", "d", function()
		if #M.state.cached_lists == 0 then return end
		local line = vim.api.nvim_win_get_cursor(0)[1]
		if line > 0 and line <= #M.state.cached_lists then
			local lst = M.state.cached_lists[line]
			vim.ui.select({ "Yes", "No" }, {
				prompt = "Delete list '" .. lst.name .. "'?",
			}, function(choice)
				if choice == "Yes" then
					db.delete_list(lst.id)
					vim.notify("Deleted list: " .. lst.name, vim.log.levels.INFO)
					show_lists(nil)
				end
			end)
		end
	end, opts)

	vim.keymap.set("n", "r", function()
		if #M.state.cached_lists == 0 then return end
		local line = vim.api.nvim_win_get_cursor(0)[1]
		if line > 0 and line <= #M.state.cached_lists then
			local lst = M.state.cached_lists[line]
			vim.ui.input({ prompt = "Rename '" .. lst.name .. "' to: ", default = lst.name }, function(new_name)
				if new_name and new_name ~= "" and new_name ~= lst.name then
					local ok, err = pcall(db.rename_list, lst.id, new_name)
					if ok then
						vim.notify("Renamed to: " .. new_name, vim.log.levels.INFO)
						show_lists(nil)
					else
						vim.notify("Error: " .. tostring(err), vim.log.levels.ERROR)
					end
				end
			end)
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

	vim.api.nvim_set_current_buf(bufnr)

	local cursor_line = 1
	if restore_list_id then
		for i, lst in ipairs(M.state.cached_lists) do
			if lst.id == restore_list_id then
				cursor_line = i
				break
			end
		end
	end
	vim.api.nvim_win_set_cursor(0, { cursor_line, 0 })
end

show_list_items = function(list_id, list_name)
	local bufnr = get_lists_buffer()
	M.state.mode = "list_items"
	M.state.current_list_id = list_id
	M.state.current_list_name = list_name

	M.state.cached_items = db.get_list_items(list_id)

	local HEADER_LINES = 3

	local lines = {}
	table.insert(lines, list_name .. " — Lists")
	table.insert(lines, string.rep("─", 54))
	table.insert(lines, "")

	if #M.state.cached_items == 0 then
		table.insert(lines, "(empty — add verses with 'gl' from the reader)")
	else
		for i, item in ipairs(M.state.cached_items) do
			local ref
			local abbrev = format.abbreviate_book(item.book_name)
			local verse = tonumber(item.verse)
			if verse then
				ref = string.format("%s %s:%s", abbrev, item.chapter, item.verse)
			else
				ref = string.format("%s %s", abbrev, item.chapter)
			end
			table.insert(lines, string.format("%-3d %s", i, ref))
		end
	end

	set_buffer_content(lines)
	vim.api.nvim_buf_set_name(bufnr, "scriptures://lists/" .. list_name)

	local opts = { buffer = bufnr, silent = true }

	vim.keymap.set("n", "<CR>", function()
		if #M.state.cached_items == 0 then return end
		local line = vim.api.nvim_win_get_cursor(0)[1]
		local idx = line - HEADER_LINES
		if idx > 0 and idx <= #M.state.cached_items then
			local item = M.state.cached_items[idx]
			local reader = require("scriptures.reader")
			reader.open(item.source_id, item.book_name, tonumber(item.chapter), tonumber(item.verse))
		end
	end, opts)

	vim.keymap.set("n", "d", function()
		if #M.state.cached_items == 0 then return end
		local line = vim.api.nvim_win_get_cursor(0)[1]
		local idx = line - HEADER_LINES
		if idx > 0 and idx <= #M.state.cached_items then
			local item = M.state.cached_items[idx]
			local abbrev = format.abbreviate_book(item.book_name)
			local ref = tonumber(item.verse)
				and string.format("%s %s:%s", abbrev, item.chapter, item.verse)
				or string.format("%s %s", abbrev, item.chapter)
			db.remove_list_item(item.id)
			vim.notify("Removed " .. ref .. " from list", vim.log.levels.INFO)
			local cursor_line = math.max(HEADER_LINES + 1, line - 1)
			show_list_items(list_id, list_name)
			local new_item_count = #M.state.cached_items
			if new_item_count > 0 then
				cursor_line = math.min(cursor_line, HEADER_LINES + new_item_count)
				vim.api.nvim_win_set_cursor(0, { cursor_line, 0 })
			end
		end
	end, opts)

	vim.keymap.set("n", "-", function()
		show_lists(list_id)
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
	vim.api.nvim_win_set_cursor(0, { HEADER_LINES + 1, 0 })
end

function M.open()
	M.state.origin_bufnr = vim.api.nvim_get_current_buf()
	show_lists()
end

-- Add a specific reference to a list via picker; called from reader or visual mode
function M.add_to_list(source_id, book_name, chapter, verse)
	local all_lists = db.get_lists()
	if #all_lists == 0 then
		vim.notify("No lists yet. Create one with :Sc lists", vim.log.levels.INFO)
		return
	end
	vim.ui.select(all_lists, {
		prompt = "Add to list:",
		format_item = function(lst) return lst.name end,
	}, function(choice)
		if choice then
			db.add_list_item(choice.id, source_id, book_name, chapter, verse)
			local abbrev = format.abbreviate_book(book_name)
			local ref = verse
				and string.format("%s %s:%s", abbrev, chapter, verse)
				or string.format("%s %s", abbrev, chapter)
			vim.notify("Added " .. ref .. " to " .. choice.name, vim.log.levels.INFO)
		end
	end)
end

M.show_lists = show_lists
M.show_list_items = show_list_items

return M
