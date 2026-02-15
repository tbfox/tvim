local M = {}

function M.open_prompt(callback)
    local buf = vim.api.nvim_create_buf(false, true)

    local width = 80
    local height = 10
    local opts = {
        relative = 'editor',
        width = width,
        height = height,
        col = (vim.o.columns - width) / 2,
        row = (vim.o.lines - height) / 2,
        style = 'minimal',
        border = 'rounded',
        title = ' Prompt ',
        title_pos = 'center',
    }

    local win = vim.api.nvim_open_win(buf, true, opts)

    vim.api.nvim_create_autocmd("BufLeave", {
        buffer = buf,
        once = true,
        callback = function()
            local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

            if vim.api.nvim_win_is_valid(win) then
                vim.api.nvim_win_close(win, true)
            end

            callback(table.concat(lines, " "))

            vim.api.nvim_buf_delete(buf, { force = true })
        end,
    })
end

return M
