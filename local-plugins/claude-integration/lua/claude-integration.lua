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

local function show()
    state.win = vim.api.nvim_open_win(state.buf, true, win_opts())
    vim.cmd("startinsert")
end

local function create()
    state.buf = vim.api.nvim_create_buf(false, true)
    vim.bo[state.buf].bufhidden = "hide"

    show()

    vim.fn.termopen({ "zsh", "-c", "claude" }, {
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

M.setup = function()
    vim.keymap.set("n", "<F9>", toggle, { desc = "Toggle Claude terminal" })
end

return M
