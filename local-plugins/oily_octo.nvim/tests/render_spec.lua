local render = require("oily_octo.render")
local state = require("oily_octo.state")

describe("parse_issue_content", function()
    it("parses title from first line", function()
        local title, _ = render.parse_issue_content({ "Title: Fix the bug", "---", "Some body text" })
        assert.are.equal("Fix the bug", title)
    end)

    it("parses body after separator", function()
        local _, body = render.parse_issue_content({ "Title: My issue", "---", "Line one", "Line two" })
        assert.are.equal("Line one\nLine two", body)
    end)

    it("trims trailing blank lines from body", function()
        local _, body = render.parse_issue_content({ "Title: T", "---", "Content", "", "" })
        assert.are.equal("Content", body)
    end)

    it("returns empty title when no Title: line", function()
        local title, _ = render.parse_issue_content({ "---", "body" })
        assert.are.equal("", title)
    end)

    it("returns empty body when nothing after separator", function()
        local _, body = render.parse_issue_content({ "Title: T", "---" })
        assert.are.equal("", body)
    end)

    it("handles multi-line body", function()
        local _, body = render.parse_issue_content({
            "Title: Bug",
            "---",
            "## Steps",
            "1. Do thing",
            "2. Observe crash",
        })
        assert.are.equal("## Steps\n1. Do thing\n2. Observe crash", body)
    end)

    it("Title: with extra whitespace is stripped", function()
        local title, _ = render.parse_issue_content({ "Title:   spaces around  ", "---", "" })
        assert.are.equal("spaces around  ", title)
    end)

    it("separator must match ^---+ pattern", function()
        -- a line with dashes but preceded by text should NOT trigger body mode
        local _, body = render.parse_issue_content({ "Title: T", "not---separator", "should not be body" })
        assert.are.equal("", body)
    end)

    it("only first line is treated as title", function()
        local title, _ = render.parse_issue_content({
            "Title: First",
            "Title: Second",
            "---",
            "body",
        })
        assert.are.equal("First", title)
    end)
end)

describe("render.issue_list", function()
    local buf

    before_each(function()
        buf = vim.api.nvim_create_buf(false, true)
        state.show_closed = false
    end)

    after_each(function()
        vim.api.nvim_buf_delete(buf, { force = true })
    end)

    local function get_lines()
        return vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    end

    it("renders header row", function()
        render.issue_list(buf, {})
        local lines = get_lines()
        assert.is_truthy(lines[1]:match("ID"))
        assert.is_truthy(lines[1]:match("STATUS"))
        assert.is_truthy(lines[1]:match("TITLE"))
    end)

    it("renders a separator line", function()
        render.issue_list(buf, {})
        local lines = get_lines()
        assert.is_truthy(lines[2]:match("^%-+$"))
    end)

    it("renders open issues", function()
        render.issue_list(buf, { { number = 42, title = "Open bug", state = "OPEN" } })
        local lines = get_lines()
        assert.is_truthy(lines[3]:match("%[!%]"))
        assert.is_truthy(lines[3]:match("Open bug"))
        assert.is_truthy(lines[3]:match("42"))
    end)

    it("hides closed issues when show_closed is false", function()
        render.issue_list(buf, { { number = 7, title = "Closed thing", state = "CLOSED" } })
        local lines = get_lines()
        assert.are.equal(2, #lines) -- only header + separator
    end)

    it("shows closed issues when show_closed is true", function()
        state.show_closed = true
        render.issue_list(buf, { { number = 7, title = "Closed thing", state = "CLOSED" } })
        local lines = get_lines()
        assert.is_truthy(lines[3]:match("%[x%]"))
        assert.is_truthy(lines[3]:match("Closed thing"))
    end)

    it("renders multiple issues in order", function()
        render.issue_list(buf, {
            { number = 1, title = "First", state = "OPEN" },
            { number = 2, title = "Second", state = "OPEN" },
        })
        local lines = get_lines()
        assert.are.equal(4, #lines)
        assert.is_truthy(lines[3]:match("First"))
        assert.is_truthy(lines[4]:match("Second"))
    end)

    it("state comparison is case-insensitive", function()
        render.issue_list(buf, { { number = 99, title = "Lowercase open", state = "open" } })
        local lines = get_lines()
        assert.is_truthy(lines[3]:match("%[!%]"))
    end)

    it("buffer is not modifiable after render", function()
        render.issue_list(buf, {})
        assert.is_false(vim.bo[buf].modifiable)
    end)
end)
