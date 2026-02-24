local M = {}

-- 1. Forward declare the function so we can call it from the details view
local open_gh_issues

local function view_issue_details(id)
    vim.notify("Fetching issue #" .. id .. "...", vim.log.levels.INFO)
    
    -- Fetch the specific issue's body
    local cmd = { "gh", "issue", "view", id }
    local obj = vim.system(cmd, { text = true }):wait()

    if obj.code ~= 0 then
        vim.notify("GH CLI Error: " .. (obj.stderr or ""), vim.log.levels.ERROR)
        return
    end

    -- Split the raw string output into a table of lines
    local lines = vim.split(obj.stdout, '\n', { plain = true })

    -- Create the new buffer
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

    -- Buffer Settings
    vim.bo[buf].buftype = "nofile"
    vim.bo[buf].swapfile = false
    vim.bo[buf].bufhidden = "wipe"
    vim.bo[buf].modifiable = false
    vim.bo[buf].filetype = "markdown" -- 'gh issue view' outputs markdown natively

    -- Keybindings for the details view
    local opts = { buffer = buf, silent = true }
    
    -- Press '-' to go back to the issue list (Oil-style)
    vim.keymap.set('n', '-', function()
        vim.cmd("bd")
        open_gh_issues()
    end, opts)

    -- Press 'q' to quit entirely
    vim.keymap.set('n', 'q', "<cmd>bd!<CR>", opts)

    -- Display the buffer
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
        vim.notify("Failed to parse JSON from GitHub CLI", vim.log.levels.ERROR)
        return
    end

    local lines = {}
    table.insert(lines, string.format("%-6s  %-8s  %s", "ID", "STATUS", "TITLE"))
    table.insert(lines, string.rep("-", 40))

    for _, issue in ipairs(issues) do
        local status = issue.state == "OPEN" and "[!]" or "[x]"
        local row = string.format("%-6d  %-8s  %s", issue.number, status, issue.title)
        table.insert(lines, row)
    end

    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

    vim.bo[buf].buftype = "nofile"
    vim.bo[buf].swapfile = false
    vim.bo[buf].bufhidden = "wipe"
    vim.bo[buf].modifiable = false 
    vim.bo[buf].filetype = "gitcommit" 

    local opts = { buffer = buf, silent = true }
    
    -- 2. Modify <CR> to open the new buffer instead of the browser
    vim.keymap.set('n', '<CR>', function()
        local line = vim.api.nvim_get_current_line()
        local id = line:match("^(%d+)")
        if id then
            view_issue_details(id)
        else
            print("No issue ID found on this line.")
        end
    end, opts)

    -- Press 'r' to refresh the list
    vim.keymap.set('n', 'r', function()
        vim.cmd("bd")
        open_gh_issues()
    end, opts)

    -- Press 'q' to quit
    vim.keymap.set('n', 'q', "<cmd>bd!<CR>", opts)

    vim.api.nvim_set_current_buf(buf)
end

M.setup = function()
    vim.keymap.set('n', '<F10>', open_gh_issues)
end

M.setup()

return M
