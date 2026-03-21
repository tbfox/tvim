local M = {}

function M.confirm(message, callback)
    local width = #message + 10
    local height = 3
    local row = math.floor((vim.o.lines - height) / 2)
    local col = math.floor((vim.o.columns - width) / 2)

    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { message .. " (y/n): " })

    local win = vim.api.nvim_open_win(buf, true, {
        relative = "editor",
        width = width,
        height = height,
        row = row,
        col = col,
        style = "minimal",
        border = "rounded",
    })

    vim.bo[buf].buftype = "nofile"
    vim.bo[buf].modifiable = false

    local function close()
        if vim.api.nvim_win_is_valid(win) then
            vim.api.nvim_win_close(win, true)
        end
    end

    local opts = { buffer = buf, silent = true, nowait = true }
    vim.keymap.set("n", "y", function() close(); callback(true) end, opts)
    vim.keymap.set("n", "n", function() close(); callback(false) end, opts)
    vim.keymap.set("n", "<Esc>", function() close(); callback(false) end, opts)
    vim.keymap.set("n", "q", function() close(); callback(false) end, opts)
end

return M
