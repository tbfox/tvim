local M = {}

function M.get_selection_with_context()
    local mode = vim.api.nvim_get_mode().mode
    local buf = vim.api.nvim_get_current_buf()
    local vstart, vend

    if mode:find("[vV\22]") then
        vstart = vim.fn.getpos("v")
        vend = vim.fn.getpos(".")
    else
        vstart = vim.fn.getpos("'<")
        vend = vim.fn.getpos("'>")
    end

    -- Basic validation: if marks aren't set, getpos returns {0, 0, 0, 0}
    if vstart[2] == 0 then return nil end

    local start_row, start_col = vstart[2] - 1, vstart[3] - 1
    local end_row, end_col = vend[2] - 1, vend[3]

    -- Clamp end_col to line length to avoid "out of bounds" errors
    local line_text = vim.api.nvim_buf_get_lines(buf, end_row, end_row + 1, true)[1]
    if line_text then
        end_col = math.min(end_col, #line_text)
    end

    -- Standardize order (if user selected backwards)
    if start_row > end_row or (start_row == end_row and start_col > end_col) then
        start_row, end_row = end_row, start_row
        start_col, end_col = end_col, start_col
    end

    local lines = vim.api.nvim_buf_get_text(buf, start_row, start_col, end_row, end_col, {})

    return {
        text = table.concat(lines, '\n'),
        buf = buf,
        range = {
            start_row = start_row,
            start_col = start_col,
            end_row = end_row,
            end_col = end_col
        }
    }
end

function M.set_selection_with_context(selection, new_text)
    if not selection or not selection.range then return end

    local r = selection.range
    -- We use selection.buf instead of 0 to target the original buffer
    vim.api.nvim_buf_set_text(
        selection.buf,
        r.start_row,
        r.start_col,
        r.end_row,
        r.end_col,
        vim.split(new_text, "\n")
    )
end

function M.get_selection()
    local mode = vim.api.nvim_get_mode().mode
    local vstart, vend

    if mode == 'c' or mode == 'n' then
        vstart = vim.fn.getpos("'<")
        vend = vim.fn.getpos("'>")
    elseif mode:find("[vV\22]") then
        vstart = vim.fn.getpos("v")
        vend = vim.fn.getpos(".")
    else
        return nil
    end


    local start_row = vstart[2] - 1
    local start_col = vstart[3] - 1
    local end_row = vend[2] - 1
    local end_col = vend[3]

    local line_text = vim.api.nvim_buf_get_lines(0, end_row, end_row + 1, true)[1]

    if line_text then
        end_col = math.min(end_col, #line_text)
    end

    local lines = vim.api.nvim_buf_get_text(0, start_row, start_col, end_row, end_col, {})
    return table.concat(lines, '\n')
end

function M.set_selection(text)
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
