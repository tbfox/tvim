local M = {}

-- Tokenize text, treating footnote markers as single indivisible tokens
local function tokenize(text)
	local tokens = {}
	local pos = 1

	while pos <= #text do
		-- Skip whitespace
		local ws_start, ws_end = text:find("^%s+", pos)
		if ws_start then
			pos = ws_end + 1
		end

		if pos <= #text then
			-- Check for footnote marker pattern: (letter)|...|
			local marker_start, marker_end = text:find("^%(%w+%)%|[^|]+%|", pos)
			if marker_start then
				-- Extract the entire marker as one token
				table.insert(tokens, text:sub(marker_start, marker_end))
				pos = marker_end + 1
			else
				-- Extract regular word (non-whitespace)
				local word_start, word_end = text:find("^%S+", pos)
				if word_start then
					table.insert(tokens, text:sub(word_start, word_end))
					pos = word_end + 1
				else
					pos = pos + 1
				end
			end
		end
	end

	return tokens
end

-- Wrap a line of text at the specified width
-- Treats footnote markers (letter)|text| as indivisible units
local function wrap_line(text, width)
	local lines = {}
	local current_line = ""
	local tokens = tokenize(text)

	for _, token in ipairs(tokens) do
		if #current_line == 0 then
			current_line = token
		elseif #current_line + 1 + #token <= width then
			current_line = current_line .. " " .. token
		else
			table.insert(lines, current_line)
			current_line = token
		end
	end

	if #current_line > 0 then
		table.insert(lines, current_line)
	end

	return lines
end

-- Insert footnote markers into verse content
-- Replaces highlighted text with (letter)|text| format
local function insert_footnote_markers(content, verse_footnotes)
	if not verse_footnotes or #verse_footnotes == 0 then
		return content
	end

	for _, footnote in ipairs(verse_footnotes) do
		local highlighted_text = footnote.highlighted_text
		local note_letter = footnote.note_letter

		-- Find the first occurrence that's not already inside a marker (case-insensitive)
		local lower_content = content:lower()
		local lower_text = highlighted_text:lower()
		local search_pos = 1
		local start_pos = nil

		-- Search for the text, skipping any occurrences inside existing markers
		while true do
			local pos = lower_content:find(lower_text, search_pos, true)
			if not pos then
				break
			end

			-- Check if this occurrence is inside a marker
			-- Look backwards to see if we're right after a ")|" pattern
			local inside_marker = false
			if pos >= 3 then
				local before = content:sub(pos - 2, pos - 1)
				-- Check if the 2 characters before us are ")|"
				if before == ")|" then
					inside_marker = true
				end
			end

			if not inside_marker then
				start_pos = pos
				break
			end

			search_pos = pos + 1
		end

		if start_pos then
			-- Extract the actual text with its original casing
			local actual_text = content:sub(start_pos, start_pos + #highlighted_text - 1)
			-- Create the replacement with the marker
			local replacement = string.format("(%s)|%s|", note_letter, actual_text)
			-- Replace in the content
			content = content:sub(1, start_pos - 1) .. replacement .. content:sub(start_pos + #highlighted_text)
		end
	end

	return content
end

-- Format verses with numbering and wrapping
-- Returns a list of strings ready to be set in a buffer
function M.format_verses(verses, footnotes)
	local lines = {}
	footnotes = footnotes or {}

	-- Group footnotes by verse number for easier lookup
	local footnotes_by_verse = {}
	for _, footnote in ipairs(footnotes) do
		local verse_num = footnote.verse_number
		if not footnotes_by_verse[verse_num] then
			footnotes_by_verse[verse_num] = {}
		end
		table.insert(footnotes_by_verse[verse_num], footnote)
	end

	for i, verse_data in ipairs(verses) do
		local verse_num = verse_data.verse
		local content = verse_data.content

		-- Insert footnote markers into the content
		local verse_footnotes = footnotes_by_verse[verse_num]
		if verse_footnotes then
			content = insert_footnote_markers(content, verse_footnotes)
		end

		-- Wrap the verse content at 80 columns, accounting for the verse number
		-- Format: "1. verse text here"
		local verse_prefix = verse_num .. ". "

		-- Wrap the text
		local wrapped = wrap_line(content, 80)

		-- Add the verse number to the first line
		if #wrapped > 0 then
			table.insert(lines, verse_prefix .. wrapped[1])

			-- Add subsequent lines without indentation (flows like a paragraph)
			for j = 2, #wrapped do
				table.insert(lines, wrapped[j])
			end
		else
			table.insert(lines, verse_prefix)
		end

		-- Add footnotes for this verse if they exist
		local verse_footnotes = footnotes_by_verse[verse_num]
		if verse_footnotes and #verse_footnotes > 0 then
			for _, footnote in ipairs(verse_footnotes) do
				local footnote_line = string.format("  %s. %s", footnote.note_letter, footnote.highlighted_text)
				table.insert(lines, footnote_line)
			end
		end

		-- Add empty line between verses (except after the last verse)
		if i < #verses then
			table.insert(lines, "")
		end
	end

	return lines
end

-- Create a book abbreviation from the full book name
function M.abbreviate_book(book)
	-- Common abbreviations for LDS scriptures
	local abbrevs = {
		["1 Nephi"] = "1 Ne",
		["2 Nephi"] = "2 Ne",
		["3 Nephi"] = "3 Ne",
		["4 Nephi"] = "4 Ne",
		["Words of Mormon"] = "W of M",
		["Moroni"] = "Moro",
		["Mosiah"] = "Mosiah",
		["Alma"] = "Alma",
		["Helaman"] = "Hel",
		["Mormon"] = "Morm",
		["Ether"] = "Ether",
		["Jacob"] = "Jacob",
		["Enos"] = "Enos",
		["Jarom"] = "Jarom",
		["Omni"] = "Omni",
		-- Old Testament
		["Genesis"] = "Gen",
		["Exodus"] = "Ex",
		["Leviticus"] = "Lev",
		["Numbers"] = "Num",
		["Deuteronomy"] = "Deut",
		["Joshua"] = "Josh",
		["Judges"] = "Judg",
		["Ruth"] = "Ruth",
		["1 Samuel"] = "1 Sam",
		["2 Samuel"] = "2 Sam",
		["1 Kings"] = "1 Kgs",
		["2 Kings"] = "2 Kgs",
		["1 Chronicles"] = "1 Chr",
		["2 Chronicles"] = "2 Chr",
		["Ezra"] = "Ezra",
		["Nehemiah"] = "Neh",
		["Esther"] = "Esth",
		["Job"] = "Job",
		["Psalms"] = "Ps",
		["Proverbs"] = "Prov",
		["Ecclesiastes"] = "Eccl",
		["Song of Solomon"] = "Song",
		["Isaiah"] = "Isa",
		["Jeremiah"] = "Jer",
		["Lamentations"] = "Lam",
		["Ezekiel"] = "Ezek",
		["Daniel"] = "Dan",
		["Hosea"] = "Hosea",
		["Joel"] = "Joel",
		["Amos"] = "Amos",
		["Obadiah"] = "Obad",
		["Jonah"] = "Jonah",
		["Micah"] = "Micah",
		["Nahum"] = "Nahum",
		["Habakkuk"] = "Hab",
		["Zephaniah"] = "Zeph",
		["Haggai"] = "Hag",
		["Zechariah"] = "Zech",
		["Malachi"] = "Mal",
		-- New Testament
		["Matthew"] = "Matt",
		["Mark"] = "Mark",
		["Luke"] = "Luke",
		["John"] = "John",
		["Acts"] = "Acts",
		["Romans"] = "Rom",
		["1 Corinthians"] = "1 Cor",
		["2 Corinthians"] = "2 Cor",
		["Galatians"] = "Gal",
		["Ephesians"] = "Eph",
		["Philippians"] = "Philip",
		["Colossians"] = "Col",
		["1 Thessalonians"] = "1 Thes",
		["2 Thessalonians"] = "2 Thes",
		["1 Timothy"] = "1 Tim",
		["2 Timothy"] = "2 Tim",
		["Titus"] = "Titus",
		["Philemon"] = "Philem",
		["Hebrews"] = "Heb",
		["James"] = "James",
		["1 Peter"] = "1 Pet",
		["2 Peter"] = "2 Pet",
		["1 John"] = "1 Jn",
		["2 John"] = "2 Jn",
		["3 John"] = "3 Jn",
		["Jude"] = "Jude",
		["Revelation"] = "Rev",
	}

	return abbrevs[book] or book
end

return M
