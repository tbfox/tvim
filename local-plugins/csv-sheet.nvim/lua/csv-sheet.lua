local M = {}

local function new_sheet()
    return "| A | B | C |\n| ~ | ~ | ~ |\n| ~ | ~ | ~ |\n| ~ | ~ | ~ |"
end

local DIR = vim.env.HOME .. "/.local/share/nvim/sheets"
local TMP_FILE = DIR .. "/tmp.sheet"

local function cursor_right()
    vim.g.CSV_SHEET_CURSOR_COL = vim.g.CSV_SHEET_CURSOR_COL + 1
    
end

local function cursor_left()
    
end

local function set_commands()
    vim.keymap.set("n", "l", cursor_right, { desc = "Right a cell." })
    vim.keymap.set("n", "h", cursor_left, { desc = "Left a cell." })
    vim.keymap.set("n", "<Leader>z", function() vim.print(vim.fn.cursor(1, 1)) end, { desc = "Left a cell." })
end

local function unset_commands()
    vim.keymap.set("n", "l", '<Right>')
    vim.keymap.set("n", "h", '<Left>')
end

local function open()
    vim.fn.system("mkdir -p " .. DIR .. " && echo '" .. new_sheet() .. "' > " .. TMP_FILE)
    vim.cmd.edit(vim.env.HOME .. "/.local/share/nvim/sheets/tmp.sheet")
    set_commands()
    vim.g.CSV_SHEET_CURSOR_COL = 1
    vim.g.CSV_SHEET_CURSOR_ROW = 1
end

local function close()
    local buffs = vim.api.nvim_list_bufs()
    for i, buffer_number in ipairs(buffs) do
        local file = vim.api.nvim_buf_get_name(buffer_number)
        if file == TMP_FILE then
            vim.cmd("bd! " .. buffer_number)
        end
    end
    vim.fn.system("rm " .. vim.env.HOME .. "/.local/share/nvim/sheets/tmp.sheet")
    unset_commands()
end

local function thing(opts)
    local cmd = opts.fargs[1]
    if (cmd == 'open') then
        open()
    elseif (cmd == 'close') then
        close()
    end
end

M.setup = function()
    vim.filetype.add({
        extension = {
            sheet = 'sheet'
        }
    })
    vim.api.nvim_create_user_command("Sheet", thing, { nargs = 1 })
end

M.setup()

return M
