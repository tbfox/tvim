local s = require('lib.selection')
local finders = require("telescope.finders")
local pickers = require("telescope.pickers")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

vim.api.nvim_create_user_command("Tab2", function()
    require('lib.tabs').set(2)
end, {})

vim.api.nvim_create_user_command("Tab4", function()
    require('lib.tabs').set(4)
end, {})

vim.api.nvim_create_user_command("H", function()
    local selection = s.get_selection()
    vim.cmd("help " .. selection)
end, { range = true })

vim.api.nvim_create_user_command("Projects", function()
    local dir = vim.env.HOME .. "/Projects";
    local contents = vim.fn.readdir(dir)
    if contents and #contents > 0 then
        pickers.new({}, {
            prompt_title = "Projects",
            finder = finders.new_table {
                results = contents
            },
            sorter = conf.generic_sorter({}),
            attach_mappings = function(prompt_bufnr)
                actions.select_default:replace(function()
                    actions.close(prompt_bufnr)
                    local selection = action_state.get_selected_entry()
                    vim.cmd('cd ' .. dir .. "/" .. selection[1])
                    vim.cmd('Oil')
                end)
                return true
            end
        }):find()
    else
        print("No projects found in ~/Projects")
    end
end, {})
