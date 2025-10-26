return {
    'nvimdev/dashboard-nvim',
    event = 'VimEnter',
    config = function()
        vim.api.nvim_create_user_command("EditConfig", function()
            vim.cmd('cd ' .. vim.fn.stdpath("config"))
            vim.cmd('Oil')
        end, {})

        require('dashboard').setup {
            -- http://patorjk.com/software/taag/
            hide = {
                statusline = true
            },
            theme = 'doom',
            config = {
                header = {
                    "",
                    "",
                    "",
                    "",
                    "",
                    "████████╗██████╗ ███████╗ ██████╗ ██╗  ██╗",
                    "╚══██╔══╝██╔══██╗██╔════╝██╔═══██╗╚██╗██╔╝",
                    "   ██║   ██████╔╝█████╗  ██║   ██║ ╚███╔╝ ",
                    "   ██║   ██╔══██╗██╔══╝  ██║   ██║ ██╔██╗ ",
                    "   ██║   ██████╔╝██║     ╚██████╔╝██╔╝ ██╗",
                    "   ╚═╝   ╚═════╝ ╚═╝      ╚═════╝ ╚═╝  ╚═╝",
                    "",
                    "",
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
                    },
                    {
                        icon = " ",
                        desc = "Edit Config",
                        key = "c",
                        key_hl = "group",
                        action = "EditConfig",
                    }
                },
                footer = {}
            }
        }
    end,
    dependencies = { {'nvim-tree/nvim-web-devicons'}}
}
