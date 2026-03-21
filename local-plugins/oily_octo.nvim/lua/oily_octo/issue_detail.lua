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

local function save_changes(issue_id, buf)
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
            end)
        end
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
    vim.notify("Fetching issue #" .. id .. "...", vim.log.levels.INFO)

    gh.view_issue(id, function(data)
        local lines = { "Title: " .. (data.title or ""), "---" }

        if data.body and data.body ~= "" then
            local body_lines = vim.split(data.body, "\n", { plain = true })
            vim.list_extend(lines, body_lines)
        end

        local buf = make_buf(lines)
        local opts = { buffer = buf, silent = true }

        vim.api.nvim_buf_create_user_command(buf, "Gh", function(cmd_opts)
            if cmd_opts.args == "save" then
                save_changes(id, buf)
            elseif cmd_opts.args == "close" then
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
            else
                vim.notify("Usage: :Gh save | :Gh close", vim.log.levels.WARN)
            end
        end, { nargs = 1 })

        vim.keymap.set("n", "-", function()
            vim.cmd("bd")
            M.open_list()
        end, opts)
        vim.keymap.set("n", "q", "<cmd>bd!<CR>", opts)

        vim.api.nvim_set_current_buf(buf)
    end)
end

-- Set by issue_list.lua to avoid circular require
M.open_list = nil

return M
