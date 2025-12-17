local M = {}
-- /Users/tristanbarrow/.config/nvim/local-plugins/time_track.nvim/parser/tree-sitter

M.setup = function()
    local parser_path = '/Users/tristanbarrow/Projects/talks-and-workshops/tree-sitter-twmd/parser.so'
    vim.treesitter.language.register('twmd', { 'twmd' })
    vim.treesitter.language.add('twmd', { path = parser_path })
    vim.filetype.add({
        extension = {
            twmd = 'twmd'
        }
    })
    require("nvim-web-devicons").setup {
        override_by_extension = {
            twmd = {
                icon = "󰐩",
                color = "#ffffff",
                name = "twmd"
            }
        }
    }
end

return M
