local gh = require("oily_octo.gh")
local render = require("oily_octo.render")
local ui = require("oily_octo.ui")

local M = {}

local function make_buf(lines)
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.bo[buf].buftype = "nofile"
    vim.bo[buf].swapfile = false
    vim.bo[buf].bufhidden = "wipe"
    vim.bo[buf].filetype = "markdown"
    return buf
end

local function save_changes(issue_id, buf, on_success)
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local title, body = render.parse_issue_content(lines)

    if title == "" then
        vim.notify("Error: Could not parse issue title", vim.log.levels.ERROR)
        return
    end

    local is_new = issue_id == nil
    local prompt = is_new and "Create new issue?" or ("Update issue #" .. issue_id .. "?")

    ui.confirm(prompt, function(confirmed)
        if not confirmed then
            vim.notify(is_new and "Create cancelled" or "Update cancelled", vim.log.levels.INFO)
            return
        end

        if is_new then
            vim.notify("Creating new issue...", vim.log.levels.INFO)
            gh.create_issue(title, body, function()
                vim.bo[buf].modified = false
                vim.cmd("bd")
                M.open_list()
            end)
        else
            vim.notify("Updating issue #" .. issue_id .. "...", vim.log.levels.INFO)
            gh.edit_issue(issue_id, title, body, function()
                vim.bo[buf].modified = false
                if on_success then on_success() end
            end)
        end
    end)
end

local function find_comment_at(cursor_line, comment_ranges)
    for _, r in ipairs(comment_ranges) do
        if cursor_line >= r.start_line and cursor_line <= r.end_line then
            return r
        end
    end
    return nil
end

local open_read_mode  -- forward declaration
local open_comment_buf  -- forward declaration

local function open_edit_mode(id, data)
    local lines = { "Title: " .. (data.title or ""), "---" }
    if data.body and data.body ~= "" then
        vim.list_extend(lines, vim.split(data.body, "\n", { plain = true }))
    end

    local prev_buf = vim.api.nvim_get_current_buf()
    local buf = make_buf(lines)
    vim.bo[buf].modifiable = true

    local opts = { buffer = buf, silent = true }

    vim.api.nvim_buf_create_user_command(buf, "Gh", function(cmd_opts)
        local arg = cmd_opts.args
        if arg == "save" then
            save_changes(id, buf, function()
                vim.cmd("bd")
                open_read_mode(id)
            end)
        elseif arg == "cancel" then
            vim.cmd("bd")
            open_read_mode(id)
        elseif arg == "help" then
            vim.cmd("help oily_octo")
        else
            vim.notify("Usage: :Gh save | :Gh cancel | :Gh help", vim.log.levels.WARN)
        end
    end, { nargs = 1 })

    vim.keymap.set("n", "<Esc>", function()
        vim.cmd("bd")
        open_read_mode(id)
    end, opts)
    vim.keymap.set("n", "-", function()
        vim.cmd("bd")
        M.open_list()
    end, opts)
    vim.keymap.set("n", "q", "<cmd>bd!<CR>", opts)

    vim.api.nvim_set_current_buf(buf)
    if vim.api.nvim_buf_is_valid(prev_buf) then
        vim.api.nvim_buf_delete(prev_buf, { force = true })
    end
end

open_comment_buf = function(id, quote_body, parent_buf)
    local lines = {}
    if quote_body then
        local quoted = vim.split(quote_body, "\n", { plain = true })
        while #quoted > 0 and quoted[#quoted]:match("^%s*$") do
            table.remove(quoted)
        end
        for _, ql in ipairs(quoted) do
            table.insert(lines, "> " .. ql)
        end
        table.insert(lines, "")
    end

    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.bo[buf].buftype = "nofile"
    vim.bo[buf].swapfile = false
    vim.bo[buf].bufhidden = "wipe"
    vim.bo[buf].filetype = "markdown"
    vim.bo[buf].modifiable = true

    local opts = { buffer = buf, silent = true }

    vim.api.nvim_buf_create_user_command(buf, "Gh", function(cmd_opts)
        if cmd_opts.args == "save" then
            local comment_lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
            while #comment_lines > 0 and comment_lines[#comment_lines]:match("^%s*$") do
                table.remove(comment_lines)
            end
            local body = table.concat(comment_lines, "\n")
            if body == "" then
                vim.notify("Comment body is empty", vim.log.levels.WARN)
                return
            end
            vim.notify("Submitting comment on #" .. id .. "...", vim.log.levels.INFO)
            gh.add_comment(id, body, function()
                vim.cmd("bd")
                if vim.api.nvim_buf_is_valid(parent_buf) then
                    vim.api.nvim_buf_delete(parent_buf, { force = true })
                end
                open_read_mode(id)
            end)
        elseif cmd_opts.args == "help" then
            vim.cmd("help oily_octo")
        else
            vim.notify("Usage: :Gh save | :Gh help", vim.log.levels.WARN)
        end
    end, { nargs = 1 })

    local function discard()
        vim.cmd("bd")
        if vim.api.nvim_buf_is_valid(parent_buf) then
            vim.api.nvim_set_current_buf(parent_buf)
        end
    end

    vim.keymap.set("n", "q", discard, opts)
    vim.keymap.set("n", "-", discard, opts)

    vim.api.nvim_set_current_buf(buf)
    local cursor_row = (quote_body ~= nil) and #lines or 1
    vim.api.nvim_win_set_cursor(0, { cursor_row, 0 })
    vim.cmd("startinsert!")
end

open_read_mode = function(id)
    vim.notify("Fetching issue #" .. id .. "...", vim.log.levels.INFO)

    gh.view_issue(id, function(data)
        gh.list_comments(id, function(comments)
            local lines = { "Title: " .. (data.title or ""), "---" }
            if data.body and data.body ~= "" then
                vim.list_extend(lines, vim.split(data.body, "\n", { plain = true }))
            end

            local comment_lines, comment_ranges = render.render_comments(comments)
            local offset = #lines
            vim.list_extend(lines, comment_lines)
            for _, r in ipairs(comment_ranges) do
                r.start_line = r.start_line + offset
                r.end_line = r.end_line + offset
            end

            local buf = make_buf(lines)
            vim.bo[buf].modifiable = false

            local opts = { buffer = buf, silent = true }

            vim.api.nvim_buf_create_user_command(buf, "Gh", function(cmd_opts)
                local arg = cmd_opts.args
                if arg == "edit" then
                    open_edit_mode(id, data)
                elseif arg == "comment" then
                    open_comment_buf(id, nil, buf)
                elseif arg == "reply" then
                    local cursor_line = vim.api.nvim_win_get_cursor(0)[1]
                    local target = find_comment_at(cursor_line, comment_ranges)
                    if target then
                        open_comment_buf(id, target.body, buf)
                    else
                        vim.notify("Cursor is not on a comment", vim.log.levels.WARN)
                    end
                elseif arg == "close" then
                    ui.confirm("Close issue #" .. id .. "?", function(confirmed)
                        if not confirmed then
                            vim.notify("Close cancelled", vim.log.levels.INFO)
                            return
                        end
                        vim.notify("Closing issue #" .. id .. "...", vim.log.levels.INFO)
                        gh.close_issue(id, function()
                            vim.cmd("bd")
                            M.open_list()
                        end)
                    end)
                elseif arg == "help" then
                    vim.cmd("help oily_octo")
                else
                    vim.notify("Usage: :Gh edit | :Gh comment | :Gh reply | :Gh close | :Gh help", vim.log.levels.WARN)
                end
            end, { nargs = 1 })

            vim.keymap.set("n", "-", function()
                vim.cmd("bd")
                M.open_list()
            end, opts)
            vim.keymap.set("n", "q", "<cmd>bd!<CR>", opts)

            vim.api.nvim_set_current_buf(buf)
        end)
    end)
end

function M.open_new()
    local template = {
        "Title: ",
        "---",
        "",
        "## Description",
        "",
        "",
        "",
        "## Steps to Reproduce",
        "",
        "1. ",
        "",
        "",
        "## Expected Behavior",
        "",
        "",
        "",
        "## Actual Behavior",
        "",
    }

    local buf = make_buf(template)
    local opts = { buffer = buf, silent = true }

    vim.api.nvim_buf_create_user_command(buf, "Gh", function(cmd_opts)
        if cmd_opts.args == "save" then
            save_changes(nil, buf)
        else
            vim.notify("Usage: :Gh save", vim.log.levels.WARN)
        end
    end, { nargs = 1 })

    vim.keymap.set("n", "-", function()
        vim.cmd("bd")
        M.open_list()
    end, opts)
    vim.keymap.set("n", "q", "<cmd>bd!<CR>", opts)

    vim.api.nvim_set_current_buf(buf)
    vim.api.nvim_win_set_cursor(0, { 1, 7 })
    vim.cmd("startinsert!")
end

function M.open(id)
    open_read_mode(id)
end

-- Set by issue_list.lua to avoid circular require
M.open_list = nil

return M
