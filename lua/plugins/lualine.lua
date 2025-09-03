local function config()
    require("lualine").setup({
        options = {
            theme = 'gruvbox'
        }
    })
end

return {
    'nvim-lualine/lualine.nvim',
    config = config,
    dependencies = { 'nvim-tree/nvim-web-devicons'}
}
