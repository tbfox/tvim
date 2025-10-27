local builtin = require('telescope.builtin')

local function find_config_files()
    builtin.find_files({
        cwd = vim.fn.stdpath("config")
    })
end

local function config()
    require("telescope").setup({
        defaults = {
            file_ignore_patterns = {
                "node_modules/",
                ".git/",
            }
        }
    })
    vim.keymap.set('n', '<leader>F',  find_config_files,        { desc = 'Telescope - [F]iles' })
    vim.keymap.set('n', '<leader>f',  builtin.find_files,       { desc = 'Telescope - [F]iles' })
    vim.keymap.set('n', '<leader>k',  builtin.keymaps,          { desc = 'Telescope - [F]iles' })
    vim.keymap.set('n', '<leader>g',  builtin.live_grep,        { desc = 'Telescope - [G]rep' })
    vim.keymap.set('n', '<leader>b',  builtin.buffers,          { desc = 'Telescope - [B]uffer' })
    vim.keymap.set('n', '<leader>h',  builtin.help_tags,        { desc = 'Telescope - [H]elp' })
    vim.keymap.set('n', '<leader>q',  builtin.quickfix,         { desc = 'Telescope - Quickfi[x]' })
    vim.keymap.set('n', '<leader>et', builtin.diagnostics,      { desc = 'Telescope - [D]iagnostics' })
    vim.keymap.set('n', '<leader>m',  builtin.marks,            { desc = 'Telescope - [M]arks' })
    vim.keymap.set('n', '<leader>s',  builtin.spell_suggest,    { desc = 'Telescope - [S]pell Check' })
end

return {
    'nvim-telescope/telescope.nvim',
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = config
}
