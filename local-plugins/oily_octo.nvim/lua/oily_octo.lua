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

local function view_issue_details(id)
    vim.notify("Fetching issue #" .. id .. "...", vim.log.levels.INFO)
    
    local cmd = { "gh", "issue", "view", id }
    local obj = vim.system(cmd, { text = true }):wait()

    if obj.code ~= 0 then
        vim.notify("GH CLI Error: " .. (obj.stderr or ""), vim.log.levels.ERROR)
        return
    end

    local lines = vim.split(obj.stdout, '\n', { plain = true })
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

    vim.bo[buf].buftype = "nofile"
    vim.bo[buf].swapfile = false
    vim.bo[buf].bufhidden = "wipe"
    vim.bo[buf].modifiable = false
    vim.bo[buf].filetype = "markdown"

    local opts = { buffer = buf, silent = true }
    
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
