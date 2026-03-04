local M = {}

-- Get the path to the database
local function get_db_path()
	local plugin_dir = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h:h:h")
	return plugin_dir .. "/res/standard-works.sqlite"
end

-- Escape single quotes for SQL
local function escape_sql(str)
	if not str then return str end
	return str:gsub("'", "''")
end

-- Execute a SQLite query and return the result
local function query(sql)
	local db_path = get_db_path()
	local cmd = string.format("sqlite3 -separator '\t' '%s' \"%s\"", db_path, sql)
	local result = vim.fn.system(cmd)
	if vim.v.shell_error ~= 0 then
		error("SQLite query failed: " .. result)
	end
	return result
end

-- Parse tab-separated output into a list of records
local function parse_result(result, fields)
	local lines = vim.split(result, "\n", { trimempty = true })
	local records = {}
	for _, line in ipairs(lines) do
		local values = vim.split(line, "\t")
		local record = {}
		for i, field in ipairs(fields) do
			record[field] = values[i]
		end
		table.insert(records, record)
	end
	return records
end

-- Get all sources
function M.get_sources()
	local result = query("SELECT id, title FROM sources ORDER BY id;")
	return parse_result(result, { "id", "title" })
end

-- Get all books in a source (in order of appearance)
function M.get_books(source)
	local sql = string.format(
		[[SELECT book FROM verses WHERE source='%s' GROUP BY book ORDER BY MIN(id);]],
		escape_sql(source)
	)
	local result = query(sql)
	local lines = vim.split(result, "\n", { trimempty = true })
	return lines
end

-- Get all chapter numbers for a book
function M.get_chapters(source, book)
	local sql = string.format(
		[[SELECT DISTINCT chapter FROM verses WHERE source='%s' AND book='%s' ORDER BY chapter;]],
		escape_sql(source),
		escape_sql(book)
	)
	local result = query(sql)
	local lines = vim.split(result, "\n", { trimempty = true })
	local chapters = {}
	for _, line in ipairs(lines) do
		table.insert(chapters, tonumber(line))
	end
	return chapters
end

-- Get all verses in a chapter
function M.get_chapter_verses(source, book, chapter)
	local sql = string.format(
		[[SELECT verse, content FROM verses WHERE source='%s' AND book='%s' AND chapter=%d ORDER BY verse;]],
		escape_sql(source),
		escape_sql(book),
		chapter
	)
	local result = query(sql)
	return parse_result(result, { "verse", "content" })
end

-- Get the next chapter, handling book and source wrapping
function M.get_next_chapter(source, book, chapter)
	local chapters = M.get_chapters(source, book)

	-- Find current chapter index
	local current_idx = nil
	for i, ch in ipairs(chapters) do
		if ch == chapter then
			current_idx = i
			break
		end
	end

	if not current_idx then
		return nil
	end

	-- If not at the end of the book, return next chapter
	if current_idx < #chapters then
		return {
			source = source,
			book = book,
			chapter = chapters[current_idx + 1],
			at_boundary = false
		}
	end

	-- At end of book, try to get next book
	local books = M.get_books(source)
	local book_idx = nil
	for i, b in ipairs(books) do
		if b == book then
			book_idx = i
			break
		end
	end

	if not book_idx then
		return nil
	end

	-- If not at the end of the source, return first chapter of next book
	if book_idx < #books then
		local next_book = books[book_idx + 1]
		local next_book_chapters = M.get_chapters(source, next_book)
		return {
			source = source,
			book = next_book,
			chapter = next_book_chapters[1],
			at_boundary = false
		}
	end

	-- At end of source
	return {
		source = source,
		book = book,
		chapter = chapter,
		at_boundary = "end"
	}
end

-- Get the previous chapter, handling book and source wrapping
function M.get_prev_chapter(source, book, chapter)
	local chapters = M.get_chapters(source, book)

	-- Find current chapter index
	local current_idx = nil
	for i, ch in ipairs(chapters) do
		if ch == chapter then
			current_idx = i
			break
		end
	end

	if not current_idx then
		return nil
	end

	-- If not at the start of the book, return previous chapter
	if current_idx > 1 then
		return {
			source = source,
			book = book,
			chapter = chapters[current_idx - 1],
			at_boundary = false
		}
	end

	-- At start of book, try to get previous book
	local books = M.get_books(source)
	local book_idx = nil
	for i, b in ipairs(books) do
		if b == book then
			book_idx = i
			break
		end
	end

	if not book_idx then
		return nil
	end

	-- If not at the start of the source, return last chapter of previous book
	if book_idx > 1 then
		local prev_book = books[book_idx - 1]
		local prev_book_chapters = M.get_chapters(source, prev_book)
		return {
			source = source,
			book = prev_book,
			chapter = prev_book_chapters[#prev_book_chapters],
			at_boundary = false
		}
	end

	-- At start of source
	return {
		source = source,
		book = book,
		chapter = chapter,
		at_boundary = "start"
	}
end

-- Get source title by ID
function M.get_source_title(source_id)
	local sources = M.get_sources()
	for _, s in ipairs(sources) do
		if s.id == source_id then
			return s.title
		end
	end
	return source_id
end

return M
