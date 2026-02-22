local M = {}
-- /Users/tristanbarrow/.config/nvim/local-plugins/time_track.nvim/parser/tree-sitter

M.setup = function()
    local parser_path = vim.fn.stdpath("config") .. "/local-plugins/time_track.nvim/tree-sitter/parser.so"
    if vim.fn.filereadable(parser_path) == 1 then
        vim.treesitter.language.register('time_track', { 'time_track' })
        vim.treesitter.language.add('time_track', { path = parser_path })
        vim.filetype.add({
            extension = {
                time_track = 'time_track'
            }
        })
        require("nvim-web-devicons").setup {
            override_by_extension = {
                time_track = {
                    icon = "",
                    color = "#d47911",
                    name = "time_track"
                }
            }
        }
    end
end

return M
