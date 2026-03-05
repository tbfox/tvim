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

-- extra_args: optional list of extra args appended to {"claude"}, e.g. {"--resume", id}
local function create(initial_text, extra_args)
    state.buf = vim.api.nvim_create_buf(false, true)
    vim.bo[state.buf].bufhidden = "hide"

    show()

    local cmd = { "claude" }
    if extra_args then
        vim.list_extend(cmd, extra_args)
    end

    local job_id = vim.fn.termopen(cmd, {
        on_exit = function()
            state.buf = nil
            state.win = nil
        end,
    })

    if initial_text and job_id > 0 then
        vim.defer_fn(function()
            -- Bracket paste escapes so embedded newlines don't submit early
            vim.fn.chansend(job_id, "\x1b[200~" .. initial_text .. "\x1b[201~\r")
        end, 3000)
    end

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

local function read_sessions()
    local home = vim.fn.expand("~")
    local projects_dir = home .. "/.claude/projects"
    local jsonl_files = vim.fn.glob(projects_dir .. "/*/*.jsonl", false, true)

    local sessions = {}

    for _, filepath in ipairs(jsonl_files) do
        local stat = vim.uv.fs_stat(filepath)
        if not stat then goto continue end

        local session_id = vim.fn.fnamemodify(filepath, ":t:r")
        local slug = nil
        local first_msg = nil
        local cwd = nil

        local f = io.open(filepath, "r")
        if not f then goto continue end

        for line in f:lines() do
            local ok, data = pcall(vim.json.decode, line)
            if ok and data.type == "user" then
                if not cwd and data.cwd then
                    cwd = data.cwd
                end
                if not slug and data.slug then
                    slug = data.slug
                end
                local content = data.message and data.message.content
                -- Only use plain string messages; skip tool_result arrays and internal commands
                if not first_msg and type(content) == "string" and content:match("%S") and not content:match("^<command") then
                    first_msg = content:gsub("\n+", " "):sub(1, 70)
                end
            end
            if cwd and first_msg then break end
        end
        f:close()

        if cwd or first_msg then
            table.insert(sessions, {
                id = session_id,
                slug = slug,
                cwd = cwd,
                first_msg = first_msg,
                mtime = stat.mtime.sec,
            })
        end

        ::continue::
    end

    table.sort(sessions, function(a, b) return a.mtime > b.mtime end)
    return sessions
end

local function pick_session()
    local cwd = vim.fn.getcwd()
    local sessions = vim.tbl_filter(function(s) return s.cwd == cwd end, read_sessions())
    if #sessions == 0 then
        vim.notify("No Claude sessions found for " .. cwd, vim.log.levels.WARN)
        return
    end

    local pickers = require("telescope.pickers")
    local finders = require("telescope.finders")
    local conf = require("telescope.config").values
    local actions = require("telescope.actions")
    local action_state = require("telescope.actions.state")
    local entry_display = require("telescope.pickers.entry_display")

    local home = vim.fn.expand("~")

    local displayer = entry_display.create({
        separator = "  ",
        items = {
            { width = 28 }, -- slug or blank
            { width = 32 }, -- cwd
            { remaining = true }, -- first message preview
        },
    })

    local function make_display(entry)
        local s = entry.value
        local slug = s.slug or ""
        local cwd = s.cwd and s.cwd:gsub("^" .. home, "~") or "?"
        local preview = s.first_msg or "(no preview)"
        return displayer({
            { slug, "TelescopeResultsIdentifier" },
            { cwd, "TelescopeResultsNumber" },
            { preview, "TelescopeResultsComment" },
        })
    end

    pickers.new({}, {
        prompt_title = "Claude Sessions",
        finder = finders.new_table({
            results = sessions,
            entry_maker = function(s)
                local cwd = s.cwd and s.cwd:gsub("^" .. home, "~") or ""
                return {
                    value = s,
                    display = make_display,
                    ordinal = table.concat({ s.slug or "", cwd, s.first_msg or "" }, " "),
                }
            end,
        }),
        sorter = conf.generic_sorter({}),
        attach_mappings = function(prompt_bufnr)
            actions.select_default:replace(function()
                actions.close(prompt_bufnr)
                local selection = action_state.get_selected_entry()
                if not selection then return end
                destroy()
                create(nil, { "--resume", selection.value.id })
            end)
            return true
        end,
    }):find()
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
        elseif args[1] == "resume" then
            pick_session()
        else
            vim.notify(
                "Unknown subcommand: " .. args[1] .. "\nUsage: :Claude [issue <number> | resume]",
                vim.log.levels.ERROR
            )
        end
    end, {
        nargs = "*",
        desc = "Toggle Claude terminal or run subcommands",
        complete = function(arg_lead, cmd_line)
            local parts = vim.split(cmd_line, "%s+", { trimempty = true })
            if #parts <= 2 and not cmd_line:match("%s$") or (#parts == 1 and cmd_line:match("%s$")) then
                return vim.tbl_filter(function(s)
                    return s:find(arg_lead, 1, true) == 1
                end, { "issue", "resume" })
            end
            return {}
        end,
    })
end

return M
