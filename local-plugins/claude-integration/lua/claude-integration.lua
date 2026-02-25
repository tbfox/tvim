local M = {}

local state = {
    buf = nil,
    win = nil,
}

local function buf_valid()
    return state.buf and vim.api.nvim_buf_is_valid(state.buf)
end

local function win_valid()
    return state.win and vim.api.nvim_win_is_valid(state.win)
end

local function win_opts()
    local width = vim.o.columns
    local height = vim.o.lines
    local win_height = math.ceil(height * 0.8 - 4)
    local win_width = math.ceil(width * 0.8)

    return {
        style = "minimal",
        relative = "editor",
        width = win_width,
        height = win_height,
        row = math.ceil((height - win_height) / 2 - 1),
        col = math.ceil((width - win_width) / 2),
        border = "rounded",
        title = " Claude ",
        title_pos = "center",
    }
end

local function hide()
    if win_valid() then
        vim.api.nvim_win_close(state.win, true)
    end
    state.win = nil
end

local function destroy()
    if win_valid() then
        vim.api.nvim_win_close(state.win, true)
    end
    if buf_valid() then
        vim.api.nvim_buf_delete(state.buf, { force = true })
    end
    state.win = nil
    state.buf = nil
end

local function show()
    state.win = vim.api.nvim_open_win(state.buf, true, win_opts())
    vim.cmd("startinsert")
end

local function create(prompt)
    state.buf = vim.api.nvim_create_buf(false, true)
    vim.bo[state.buf].bufhidden = "hide"

    show()

    local cmd = "claude"
    if prompt then
        cmd = cmd .. " -p " .. vim.fn.shellescape(prompt)
    end

    vim.fn.termopen({ "zsh", "-c", cmd }, {
        on_exit = function()
            state.buf = nil
            state.win = nil
        end,
    })

    vim.keymap.set("t", "<F9>", hide, { buffer = state.buf })
    vim.keymap.set("n", "<F9>", hide, { buffer = state.buf })

    vim.cmd("startinsert")
end

local function toggle()
    if buf_valid() then
        if win_valid() then
            hide()
        else
            show()
        end
    else
        create()
    end
end

local function fetch_issue_body(number)
    local result = vim.fn.system({ "gh", "issue", "view", tostring(number), "--json", "title,body" })
    if vim.v.shell_error ~= 0 then
        return nil, "Failed to fetch issue #" .. number .. ": " .. result
    end
    local data = vim.json.decode(result)
    return "GitHub Issue #" .. number .. ": " .. data.title .. "\n\n" .. data.body
end

local function open_issue(number)
    local prompt, err = fetch_issue_body(number)
    if not prompt then
        vim.notify(err, vim.log.levels.ERROR)
        return
    end
    destroy()
    create(prompt)
end

M.setup = function()
    vim.keymap.set("n", "<F9>", toggle, { desc = "Toggle Claude terminal" })
    vim.api.nvim_create_user_command("Claude", function(opts)
        local args = opts.fargs
        if #args == 0 then
            toggle()
        elseif args[1] == "issue" then
            local number = tonumber(args[2])
            if not number then
                vim.notify("Usage: :Claude issue <number>", vim.log.levels.ERROR)
                return
            end
            open_issue(number)
        else
            vim.notify("Unknown subcommand: " .. args[1] .. "\nUsage: :Claude [issue <number>]", vim.log.levels.ERROR)
        end
    end, {
        nargs = "*",
        desc = "Toggle Claude terminal or run subcommands",
        complete = function(arg_lead, cmd_line)
            local parts = vim.split(cmd_line, "%s+", { trimempty = true })
            if #parts <= 2 and not cmd_line:match("%s$") or (#parts == 1 and cmd_line:match("%s$")) then
                return vim.tbl_filter(function(s)
                    return s:find(arg_lead, 1, true) == 1
                end, { "issue" })
            end
            return {}
        end,
    })
end

return M
