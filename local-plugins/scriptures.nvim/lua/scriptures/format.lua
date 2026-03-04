local M = {}

-- Wrap a line of text at the specified width
local function wrap_line(text, width)
	local lines = {}
	local current_line = ""

	for word in text:gmatch("%S+") do
		if #current_line == 0 then
			current_line = word
		elseif #current_line + 1 + #word <= width then
			current_line = current_line .. " " .. word
		else
			table.insert(lines, current_line)
			current_line = word
		end
	end

	if #current_line > 0 then
		table.insert(lines, current_line)
	end

	return lines
end

-- Format verses with numbering and wrapping
-- Returns a list of strings ready to be set in a buffer
function M.format_verses(verses)
	local lines = {}

	for i, verse_data in ipairs(verses) do
		local verse_num = verse_data.verse
		local content = verse_data.content

		-- Wrap the verse content at 80 columns, accounting for the verse number
		-- Format: "1. verse text here"
		local verse_prefix = verse_num .. ". "
		local first_line_width = 80 - #verse_prefix
		local subsequent_width = 80 - 3  -- Indent by 3 spaces for continuation

		-- Wrap the text
		local wrapped = wrap_line(content, 80)

		-- Add the verse number to the first line
		if #wrapped > 0 then
			table.insert(lines, verse_prefix .. wrapped[1])

			-- Add subsequent lines with indentation
			for j = 2, #wrapped do
				table.insert(lines, "   " .. wrapped[j])
			end
		else
			table.insert(lines, verse_prefix)
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
