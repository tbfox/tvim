local function config()
    require("lualine").setup({
        options = {
            theme = 'gruvbox',
        },
        sections = {
            lualine_c = {
                {
                    'filename',
                    path = 3,
                }
            }
        }
    })
end

return {
    'nvim-lualine/lualine.nvim',
    config = config,
    dependencies = { 'nvim-tree/nvim-web-devicons'}
}
