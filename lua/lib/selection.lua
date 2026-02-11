local M = {}

function M.get_selection()
    local vstart = vim.fn.getpos("'<")
    local vend = vim.fn.getpos("'>")

    local start_row = vstart[2] - 1
    local start_col = vstart[3] - 1
    local end_row = vend[2] - 1
    local end_col = vend[3] -- This is 1-based, inclusive

    -- FIX: Get the content of the last line to calculate the valid end column
    local line_text = vim.api.nvim_buf_get_lines(0, end_row, end_row + 1, true)[1]
    if line_text then
        -- Clamp the end column to the line length
        -- math.min fixes the 'out of range' error in Visual Line mode
        end_col = math.min(end_col, #line_text)
    end

    local lines = vim.api.nvim_buf_get_text(0, start_row, start_col, end_row, end_col, {})
    return table.concat(lines, '\n')
end

function M.set_selection(text, newline)
    local vstart = vim.fn.getpos("'<")
    local vend = vim.fn.getpos("'>")

    local start_row = vstart[2] - 1
    local start_col = vstart[3] - 1
    local end_row = vend[2] - 1
    local end_col = vend[3]

    -- FIX: Same clamp logic for setting text
    local line_text = vim.api.nvim_buf_get_lines(0, end_row, end_row + 1, true)[1]
    if line_text then
        end_col = math.min(end_col, #line_text)
    end

    vim.api.nvim_buf_set_text(0, start_row, start_col, end_row, end_col, vim.split(text, "\n"))
end

return M
