local function config()
    local builtin = require('telescope.builtin')
    local finders = require("telescope.finders")
    local pickers = require("telescope.pickers")
    local conf = require("telescope.config").values
    local actions = require("telescope.actions")
    local action_state = require("telescope.actions.state")

    require("telescope").setup({
        defaults = {
            file_ignore_patterns = {
                "node_modules/",
                ".git/",
            }
        }
    })

    local function find_config_files()
        builtin.find_files({ cwd = vim.fn.stdpath("config") })
    end

    vim.keymap.set('n', '<leader>F',  find_config_files,        { desc = 'Telescope - [F]iles' })
    vim.keymap.set('n', '<leader>f',  builtin.find_files,       { desc = 'Telescope - [F]iles' })
    vim.keymap.set('n', '<leader>k',  builtin.keymaps,          { desc = 'Telescope - [K]eymaps' })
    vim.keymap.set('n', '<leader>g',  builtin.live_grep,        { desc = 'Telescope - [G]rep' })
    vim.keymap.set('n', '<leader>q',  builtin.quickfix,         { desc = 'Telescope - Quickfi[x]' })
    vim.keymap.set('n', '<leader>et', builtin.diagnostics,      { desc = 'Telescope - [D]iagnostics' })
    vim.keymap.set('n', '<leader>m',  builtin.marks,            { desc = 'Telescope - [M]arks' })
    vim.keymap.set('n', '<leader>s',  builtin.spell_suggest,    { desc = 'Telescope - [S]pell Check' })

    vim.api.nvim_create_user_command("ConfigFindFile", function()
        builtin.find_files({ cwd = vim.fn.stdpath("config") })
    end, {})

    vim.api.nvim_create_user_command("ConfigGrep", function()
        builtin.live_grep({ cwd = vim.fn.stdpath("config") })
    end, {})

    vim.api.nvim_create_user_command("Projects", function()
        local dir = vim.env.HOME .. "/Projects"
        local contents = vim.fn.readdir(dir)
        if contents and #contents > 0 then
            pickers.new({}, {
                prompt_title = "Projects",
                finder = finders.new_table { results = contents },
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
end

return {
    'nvim-telescope/telescope.nvim',
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = config
}
