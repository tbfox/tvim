return {
    'salkin-mada/openscad.nvim',
    config = function()
        vim.g.openscad_cheatsheet_toggle_key = '<F4>'
        vim.keymap.set('n', '<F5>', '<Cmd>OpenscadExecFile<CR>')
        require('openscad')
    end,
    dependencies = {
        'ibhagwan/fzf-lua',
    },
}
