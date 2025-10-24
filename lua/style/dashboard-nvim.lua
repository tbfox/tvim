return {
  'nvimdev/dashboard-nvim',
  event = 'VimEnter',
  config = function()
    require('dashboard').setup {
        -- http://patorjk.com/software/taag/
        theme = 'doom',
        config = {
            header = {
                "████████╗██████╗ ███████╗ ██████╗ ██╗  ██╗",
                "╚══██╔══╝██╔══██╗██╔════╝██╔═══██╗╚██╗██╔╝",
                "   ██║   ██████╔╝█████╗  ██║   ██║ ╚███╔╝ ",
                "   ██║   ██╔══██╗██╔══╝  ██║   ██║ ██╔██╗ ",
                "   ██║   ██████╔╝██║     ╚██████╔╝██╔╝ ██╗",
                "   ╚═╝   ╚═════╝ ╚═╝      ╚═════╝ ╚═╝  ╚═╝",
            },
            center = {
                {
                    icon = " ",
                    desc = "Find Files",
                    key = "f",
                    key_hl = "group",
                    action = "Telescope find_files",
                },
                {
                    icon = "󱎸 ",
                    desc = "Live Grep",
                    key = "g",
                    key_hl = "group",
                    action = "Telescope live_grep",
                }
            },
            footer = {}
        }
    }
  end,
  dependencies = { {'nvim-tree/nvim-web-devicons'}}
}
