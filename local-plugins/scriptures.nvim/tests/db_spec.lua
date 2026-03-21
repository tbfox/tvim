-- Integration tests for scriptures.db
-- These hit the actual SQLite database and require sqlite3 in PATH.
-- Run with: nvim --headless -u tests/minimal_init.lua -c "PlenaryBustedDirectory tests/ {minimal_init = 'tests/minimal_init.lua'}"

local assert = require("luassert")
local db = require("scriptures.db")

describe("db", function()

	describe("get_sources", function()
		it("returns at least 5 LDS sources", function()
			local sources = db.get_sources()
			assert.is_true(#sources >= 5)
		end)

		it("returns records with id and title fields", function()
			local sources = db.get_sources()
			for _, s in ipairs(sources) do
				assert.is_not_nil(s.id)
				assert.is_not_nil(s.title)
			end
		end)

		it("includes bofm source", function()
			local sources = db.get_sources()
			local ids = {}
			for _, s in ipairs(sources) do ids[s.id] = true end
			assert.is_true(ids["bofm"])
		end)
	end)

	describe("get_books", function()
		it("returns books for bofm", function()
			local books = db.get_books("bofm")
			assert.is_true(#books > 0)
		end)

		it("first book of bofm is 1 Nephi", function()
			local books = db.get_books("bofm")
			assert.are.equal("1 Nephi", books[1])
		end)

		it("last book of bofm is Moroni", function()
			local books = db.get_books("bofm")
			assert.are.equal("Moroni", books[#books])
		end)

		it("returns books for ot", function()
			local books = db.get_books("ot")
			assert.is_true(#books > 0)
		end)

		it("first book of ot is Genesis", function()
			local books = db.get_books("ot")
			assert.are.equal("Genesis", books[1])
		end)
	end)

	describe("get_chapters", function()
		it("returns chapters for Alma", function()
			local chapters = db.get_chapters("bofm", "Alma")
			assert.is_true(#chapters > 0)
		end)

		it("Alma has 63 chapters", function()
			local chapters = db.get_chapters("bofm", "Alma")
			assert.are.equal(63, #chapters)
		end)

		it("chapters are numbers", function()
			local chapters = db.get_chapters("bofm", "Alma")
			for _, ch in ipairs(chapters) do
				assert.are.equal("number", type(ch))
			end
		end)

		it("chapters are sequential starting from 1", function()
			local chapters = db.get_chapters("bofm", "Alma")
			assert.are.equal(1, chapters[1])
			assert.are.equal(2, chapters[2])
		end)
	end)

	describe("get_chapter_verses", function()
		it("returns verses for Alma 32", function()
			local verses = db.get_chapter_verses("bofm", "Alma", 32)
			assert.is_true(#verses > 0)
		end)

		it("verses have verse number and content", function()
			local verses = db.get_chapter_verses("bofm", "Alma", 32)
			for _, v in ipairs(verses) do
				assert.is_not_nil(v.verse)
				assert.is_not_nil(v.content)
				assert.is_true(#v.content > 0)
			end
		end)

		it("verse numbers are sequential", function()
			local verses = db.get_chapter_verses("bofm", "Alma", 32)
			assert.are.equal("1", verses[1].verse)
			assert.are.equal("2", verses[2].verse)
		end)

		it("1 Nephi 3:7 contains the faith verse text", function()
			local verses = db.get_chapter_verses("bofm", "1 Nephi", 3)
			local verse7 = verses[7]
			assert.is_not_nil(verse7)
			-- This verse is well-known: "I will go and do..."
			assert.is_not_nil(verse7.content:find("I will go and do"))
		end)
	end)

	describe("get_next_chapter", function()
		it("returns next chapter within same book", function()
			local next = db.get_next_chapter("bofm", "Alma", 1)
			assert.are.equal("Alma", next.book)
			assert.are.equal(2, next.chapter)
			assert.is_false(next.at_boundary)
		end)

		it("crosses book boundary at end of book", function()
			-- Enos has only 1 chapter; next should be Jarom
			local next = db.get_next_chapter("bofm", "Enos", 1)
			assert.are.equal("Jarom", next.book)
			assert.are.equal(1, next.chapter)
		end)

		it("returns at_boundary=end at end of source", function()
			-- Moroni 10 is the last chapter of bofm
			local next = db.get_next_chapter("bofm", "Moroni", 10)
			assert.are.equal("end", next.at_boundary)
		end)
	end)

	describe("get_prev_chapter", function()
		it("returns previous chapter within same book", function()
			local prev = db.get_prev_chapter("bofm", "Alma", 5)
			assert.are.equal("Alma", prev.book)
			assert.are.equal(4, prev.chapter)
			assert.is_false(prev.at_boundary)
		end)

		it("crosses book boundary at start of book", function()
			-- Jarom ch 1 -> previous should be last chapter of Enos (ch 1)
			local prev = db.get_prev_chapter("bofm", "Jarom", 1)
			assert.are.equal("Enos", prev.book)
			assert.are.equal(1, prev.chapter)
		end)

		it("returns at_boundary=start at start of source", function()
			local prev = db.get_prev_chapter("bofm", "1 Nephi", 1)
			assert.are.equal("start", prev.at_boundary)
		end)
	end)

	describe("source_has_blocks", function()
		it("returns false for bofm (verse-based)", function()
			assert.is_false(db.source_has_blocks("bofm"))
		end)

		it("returns false for nt (verse-based)", function()
			assert.is_false(db.source_has_blocks("nt"))
		end)
	end)

end)
