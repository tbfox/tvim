local M = {}

-- State management
M.show_closed = true
M.cached_issues = {}

local open_gh_issues -- Forward declare

-- Helper to render the buffer lines based on current state
local function render_issue_list(buf, issues)
    local lines = {}
    table.insert(lines, string.format("%-6s   %-8s   %s", "ID", "STATUS", "TITLE"))
    table.insert(lines, string.rep("-", 40))

    for _, issue in ipairs(issues) do
        local is_open = issue.state:upper() == "OPEN"
        
        -- Logic for g.: If show_closed is false, skip closed issues
        if M.show_closed or is_open then
            local status = is_open and "[!]" or "[x]"
            local row = string.format("%-6d   %-8s   %s", issue.number, status, issue.title)
            table.insert(lines, row)
        end
    end

    vim.bo[buf].modifiable = true
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.bo[buf].modifiable = false
end

-- Parse title and body from buffer content
local function parse_issue_content(lines)
    local title = ""
    local body_lines = {}
    local in_body = false

    for i, line in ipairs(lines) do
        if i == 1 and line:match("^Title:%s*") then
            title = line:match("^Title:%s*(.*)") or ""
        elseif line:match("^%-%-%-+$") and not in_body then
            -- Found separator, body starts after this
            in_body = true
        elseif in_body then
            table.insert(body_lines, line)
        end
    end

    -- Trim trailing empty lines from body
    while #body_lines > 0 and body_lines[#body_lines]:match("^%s*$") do
        table.remove(body_lines)
    end

    local body = table.concat(body_lines, "\n")

    return title, body
end

-- Show oil-style confirmation popup
local function show_confirmation_popup(message, callback)
    local width = #message + 10
    local height = 3
    local row = math.floor((vim.o.lines - height) / 2)
    local col = math.floor((vim.o.columns - width) / 2)

    local buf = vim.api.nvim_create_buf(false, true)
    local prompt = message .. " (y/n): "
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { prompt })

    local win = vim.api.nvim_open_win(buf, true, {
        relative = 'editor',
        width = width,
        height = height,
        row = row,
        col = col,
        style = 'minimal',
        border = 'rounded',
    })

    vim.bo[buf].buftype = 'nofile'
    vim.bo[buf].modifiable = false

    local function close_popup()
        if vim.api.nvim_win_is_valid(win) then
            vim.api.nvim_win_close(win, true)
        end
    end

    local opts = { buffer = buf, silent = true, nowait = true }
    vim.keymap.set('n', 'y', function()
        close_popup()
        callback(true)
    end, opts)

    vim.keymap.set('n', 'n', function()
        close_popup()
        callback(false)
    end, opts)

    vim.keymap.set('n', '<Esc>', function()
        close_popup()
        callback(false)
    end, opts)

    vim.keymap.set('n', 'q', function()
        close_popup()
        callback(false)
    end, opts)
end

-- Save issue changes using gh CLI (edit existing or create new)
local function save_issue_changes(issue_id, buf)
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local title, body = parse_issue_content(lines)

    if title == "" then
        vim.notify("Error: Could not parse issue title", vim.log.levels.ERROR)
        return
    end

    -- Check if this is a new issue or editing existing
    local is_new = issue_id == nil
    local prompt_msg = is_new and "Create new issue?" or ("Update issue #" .. issue_id .. "?")

    show_confirmation_popup(prompt_msg, function(confirmed)
        if not confirmed then
            vim.notify(is_new and "Create cancelled" or "Update cancelled", vim.log.levels.INFO)
            return
        end

        local cmd, action_msg, success_msg
        if is_new then
            vim.notify("Creating new issue...", vim.log.levels.INFO)
            cmd = { "gh", "issue", "create", "--title", title, "--body", body }
            success_msg = "Issue created successfully!"
        else
            vim.notify("Updating issue #" .. issue_id .. "...", vim.log.levels.INFO)
            cmd = { "gh", "issue", "edit", tostring(issue_id), "--title", title, "--body", body }
            success_msg = "Issue #" .. issue_id .. " updated successfully!"
        end

        -- Debug: print what we're sending
        vim.notify("Title: " .. title, vim.log.levels.DEBUG)
        vim.notify("Body length: " .. #body .. " chars", vim.log.levels.DEBUG)

        local obj = vim.system(cmd, { text = true }):wait()

        if obj.code ~= 0 then
            vim.notify("Failed to " .. (is_new and "create" or "update") .. " issue: " .. (obj.stderr or ""), vim.log.levels.ERROR)
        else
            vim.notify(success_msg, vim.log.levels.INFO)
            vim.bo[buf].modified = false
            -- If created new issue, close buffer and refresh issue list
            if is_new then
                vim.cmd("bd")
                open_gh_issues()
            end
        end
    end)
end

-- Create a new issue buffer with template
local function create_new_issue()
    local template_lines = {
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

    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, template_lines)

    vim.bo[buf].buftype = "nofile"
    vim.bo[buf].swapfile = false
    vim.bo[buf].bufhidden = "wipe"
    vim.bo[buf].filetype = "markdown"

    local opts = { buffer = buf, silent = true }

    -- Create buffer-local command (no issue_id = new issue)
    vim.api.nvim_buf_create_user_command(buf, "Gh", function(cmd_opts)
        if cmd_opts.args == "save" then
            save_issue_changes(nil, buf) -- nil means new issue
        else
            vim.notify("Usage: :Gh save", vim.log.levels.WARN)
        end
    end, { nargs = 1 })

    vim.keymap.set('n', '-', function()
        vim.cmd("bd")
        open_gh_issues()
    end, opts)

    vim.keymap.set('n', 'q', "<cmd>bd!<CR>", opts)

    vim.api.nvim_set_current_buf(buf)

    -- Move cursor to end of first line (after "Title: ")
    vim.api.nvim_win_set_cursor(0, {1, 7})
    vim.cmd("startinsert!")
end

local function view_issue_details(id)
    vim.notify("Fetching issue #" .. id .. "...", vim.log.levels.INFO)

    -- Fetch issue data as JSON for reliable parsing
    local cmd = { "gh", "issue", "view", id, "--json", "title,body" }
    local obj = vim.system(cmd, { text = true }):wait()

    if obj.code ~= 0 then
        vim.notify("GH CLI Error: " .. (obj.stderr or ""), vim.log.levels.ERROR)
        return
    end

    local success, issue_data = pcall(vim.json.decode, obj.stdout)
    if not success or not issue_data then
        vim.notify("Failed to parse issue JSON", vim.log.levels.ERROR)
        return
    end

    -- Format for editing: Title on first line, separator, then body
    local lines = {
        "Title: " .. (issue_data.title or ""),
        "---",
    }

    -- Add body lines
    if issue_data.body and issue_data.body ~= "" then
        local body_lines = vim.split(issue_data.body, '\n', { plain = true })
        for _, line in ipairs(body_lines) do
            table.insert(lines, line)
        end
    end

    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

    vim.bo[buf].buftype = "nofile"
    vim.bo[buf].swapfile = false
    vim.bo[buf].bufhidden = "wipe"
    vim.bo[buf].filetype = "markdown"

    -- Store issue ID in buffer variable for save handler
    vim.b[buf].oily_octo_issue_id = id

    local opts = { buffer = buf, silent = true }

    -- Create buffer-local command to save changes or close issue
    vim.api.nvim_buf_create_user_command(buf, "Gh", function(cmd_opts)
        if cmd_opts.args == "save" then
            save_issue_changes(id, buf)
        elseif cmd_opts.args == "close" then
            show_confirmation_popup("Close issue #" .. id .. "?", function(confirmed)
                if not confirmed then
                    vim.notify("Close cancelled", vim.log.levels.INFO)
                    return
                end

                vim.notify("Closing issue #" .. id .. "...", vim.log.levels.INFO)
                local cmd = { "gh", "issue", "close", tostring(id) }
                local obj = vim.system(cmd, { text = true }):wait()

                if obj.code ~= 0 then
                    vim.notify("Failed to close issue: " .. (obj.stderr or ""), vim.log.levels.ERROR)
                else
                    vim.notify("Issue #" .. id .. " closed successfully!", vim.log.levels.INFO)
                    vim.cmd("bd")
                    open_gh_issues()
                end
            end)
        else
            vim.notify("Usage: :Gh save | :Gh close", vim.log.levels.WARN)
        end
    end, { nargs = 1 })

    vim.keymap.set('n', '-', function()
        vim.cmd("bd")
        open_gh_issues()
    end, opts)

    vim.keymap.set('n', 'q', "<cmd>bd!<CR>", opts)
    vim.api.nvim_set_current_buf(buf)
end

open_gh_issues = function()
    vim.notify("Fetching GitHub issues...", vim.log.levels.INFO)
    local cmd = { 
        "gh", "issue", "list", 
        "--state", "all", 
        "--limit", "100", 
        "--json", "number,title,state" 
    }

    local obj = vim.system(cmd, { text = true }):wait()

    if obj.code ~= 0 then
        vim.notify("GH CLI Error: " .. (obj.stderr or "Check 'gh auth status'"), vim.log.levels.ERROR)
        return
    end

    local success, issues = pcall(vim.json.decode, obj.stdout)
    if not success or not issues then
        vim.notify("Failed to parse JSON", vim.log.levels.ERROR)
        return
    end

    -- Cache the issues so we can toggle 'g.' without re-fetching from API
    M.cached_issues = issues

    local buf = vim.api.nvim_create_buf(false, true)
    render_issue_list(buf, M.cached_issues)

    vim.bo[buf].buftype = "nofile"
    vim.bo[buf].swapfile = false
    vim.bo[buf].bufhidden = "wipe"
    vim.bo[buf].filetype = "gitcommit" 

    local opts = { buffer = buf, silent = true }

    -- Create buffer-local command for creating new issues
    vim.api.nvim_buf_create_user_command(buf, "Gh", function(cmd_opts)
        if cmd_opts.args == "new" then
            create_new_issue()
        else
            vim.notify("Usage: :Gh new", vim.log.levels.WARN)
        end
    end, { nargs = 1 })

    -- Open Issue
    vim.keymap.set('n', '<CR>', function()
        local line = vim.api.nvim_get_current_line()
        local id = line:match("^(%d+)")
        if id then view_issue_details(id) end
    end, opts)

    -- Toggle Closed Issues (Oil style)
    vim.keymap.set('n', 'g.', function()
        M.show_closed = not M.show_closed
        render_issue_list(buf, M.cached_issues)
        vim.notify("Show Closed: " .. tostring(M.show_closed))
    end, opts)

    -- Refresh
    vim.keymap.set('n', 'r', function()
        vim.cmd("bd")
        open_gh_issues()
    end, opts)

    -- Quit
    vim.keymap.set('n', 'q', "<cmd>bd!<CR>", opts)

    vim.api.nvim_set_current_buf(buf)
end

M.setup = function()
    vim.keymap.set('n', '<F10>', open_gh_issues)
end

return M
