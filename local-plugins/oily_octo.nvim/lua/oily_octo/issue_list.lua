local gh = require("oily_octo.gh")
local render = require("oily_octo.render")
local state = require("oily_octo.state")
local detail = require("oily_octo.issue_detail")

local M = {}

function M.open()
    vim.notify("Fetching GitHub issues...", vim.log.levels.INFO)

    gh.list_issues(function(issues)
        state.cached_issues = issues

        local buf = vim.api.nvim_create_buf(false, true)
        render.issue_list(buf, state.cached_issues)

        vim.bo[buf].buftype = "nofile"
        vim.bo[buf].swapfile = false
        vim.bo[buf].bufhidden = "wipe"
        vim.bo[buf].filetype = "gitcommit"

        local opts = { buffer = buf, silent = true }

        vim.api.nvim_buf_create_user_command(buf, "Gh", function(cmd_opts)
            if cmd_opts.args == "new" then
                detail.open_new()
            elseif cmd_opts.args == "help" then
                vim.cmd("help oily_octo")
            else
                vim.notify("Usage: :Gh new | :Gh help", vim.log.levels.WARN)
            end
        end, { nargs = 1 })

        vim.keymap.set("n", "<CR>", function()
            local line = vim.api.nvim_get_current_line()
            local id = line:match("^(%d+)")
            if id then detail.open(id) end
        end, opts)

        vim.keymap.set("n", "g.", function()
            state.show_closed = not state.show_closed
            render.issue_list(buf, state.cached_issues)
            vim.notify("Show Closed: " .. tostring(state.show_closed))
        end, opts)

        vim.keymap.set("n", "r", function()
            vim.cmd("bd")
            M.open()
        end, opts)

        vim.keymap.set("n", "q", "<cmd>bd!<CR>", opts)

        vim.api.nvim_set_current_buf(buf)
    end)
end

-- Wire back-navigation in detail views
detail.open_list = M.open

return M
