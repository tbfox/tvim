local function set_color_scheme()
    require("mini.hues").setup({
        background = "#0d0f0e",
        foreground = "#53ada6",
        saturation = 'medium',
    })
end


local function configure()
    set_color_scheme()
end

return {
    "echasnovski/mini.hues",
    config = configure
}
