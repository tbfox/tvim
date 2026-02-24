local M = {}

local function create_popup_window()
    -- Create a new buffer
    local buf = vim.api.nvim_create_buf(false, true) -- not listed, scratch buffer

    -- Get editor dimensions
    local width = vim.api.nvim_get_option("columns")
    local height = vim.api.nvim_get_option("lines")

    -- Calculate popup size (80% of screen)
    local win_height = math.ceil(height * 0.8 - 4)
    local win_width = math.ceil(width * 0.8)

    -- Calculate position to center the window
    local row = math.ceil((height - win_height) / 2 - 1)
    local col = math.ceil((width - win_width) / 2)

    -- Window options
    local opts = {
        style = "minimal",
        relative = "editor",
        width = win_width,
        height = win_height,
        row = row,
        col = col,
        border = "rounded",
        title = " Claude Prompt ",
        title_pos = "center",
    }

    -- Open the floating window
    local win = vim.api.nvim_open_win(buf, true, opts)

    -- Set buffer options
    vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
    vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
    vim.api.nvim_buf_set_option(buf, "filetype", "markdown")

    -- Set up keymaps to close the window
    local close_window = function()
        vim.api.nvim_win_close(win, true)
    end

    vim.api.nvim_buf_set_keymap(buf, "n", "<Esc>", "", {
        callback = close_window,
        noremap = true,
        silent = true,
    })
    vim.api.nvim_buf_set_keymap(buf, "n", "q", "", {
        callback = close_window,
        noremap = true,
        silent = true,
    })

    -- Start in insert mode
    vim.cmd("startinsert")

    -- Add a helpful message at the top
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
        "# Enter your Claude prompt below",
        "# Press <Esc> or 'q' in normal mode to close",
        "",
        ""
    })

    -- Move cursor to the end
    vim.api.nvim_win_set_cursor(win, {4, 0})
end

M.setup = function(opts)
    vim.api.nvim_create_user_command("Claude", function()
        create_popup_window()
    end, {})
end

return M
