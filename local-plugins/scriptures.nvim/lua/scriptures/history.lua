local M = {}

-- Stack of visited entries, each entry is a table:
--   { type = "chapter", source, book, chapter }  -- chapter may be nil for block-based
--   { type = "bd", slug }
M.stack = {}
M.cursor = 0  -- 1-based index into stack; 0 means empty

-- When true, the next push from reader is suppressed (history-driven navigation)
M._navigating = false

-- Push a new entry. Truncates any forward history first.
function M.push(entry)
	if M._navigating then return end

	-- Truncate forward history
	while #M.stack > M.cursor do
		table.remove(M.stack)
	end

	table.insert(M.stack, entry)
	M.cursor = #M.stack
end

-- Move back one step. Returns the entry to load, or nil if already at start.
function M.back()
	if M.cursor <= 1 then return nil end
	M.cursor = M.cursor - 1
	return M.stack[M.cursor]
end

-- Move forward one step. Returns the entry to load, or nil if already at end.
function M.forward()
	if M.cursor >= #M.stack then return nil end
	M.cursor = M.cursor + 1
	return M.stack[M.cursor]
end

-- Return the last entry in the stack (for :Sc history).
function M.last()
	if #M.stack == 0 then return nil end
	M.cursor = #M.stack
	return M.stack[M.cursor]
end

-- Reset (called on VimEnter, already empty by default but useful for testing).
function M.reset()
	M.stack = {}
	M.cursor = 0
end

return M
