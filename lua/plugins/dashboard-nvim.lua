return {
    'nvimdev/dashboard-nvim',
    event = 'VimEnter',
    config = function()

        vim.api.nvim_create_user_command("ConfigFindFile", function()
            vim.cmd('cd ' .. vim.fn.stdpath("config"))
            vim.cmd('Telescope find_files')
        end, {})

        vim.api.nvim_create_user_command("ConfigGrep", function()
            vim.cmd('cd ' .. vim.fn.stdpath("config"))
            vim.cmd('Telescope live_grep')
        end, {})

        vim.api.nvim_create_user_command("ConfigEdit", function()
            vim.cmd('cd ' .. vim.fn.stdpath("config"))
            vim.cmd('Oil')
        end, {})

        require('dashboard').setup {
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
                        icon = "  ",
                        desc = "[P]rojects",
                        key = "p",
                        key_hl = "group",
                        action = "Projects",
                    },
                    {
                        icon = "  ",
                        desc = "Find Files",
                        key = "f",
                        key_hl = "group",
                        action = "Telescope find_files",
                    },
                    {
                        icon = "󱎸  ",
                        desc = "[G]rep",
                        key = "g",
                        key_hl = "group",
                        action = "Telescope live_grep",
                    },
                    {
                        icon = "  ",
                        desc = "[C]onfig Edit",
                        key = "c",
                        key_hl = "group",
                        action = "ConfigEdit",
                    },
                    {
                        icon = "󱎸 ",
                        desc = "[G]rep config" ,
                        key = "G",
                        key_hl = "group",
                        action = "ConfigGrep",
                    },
                    {
                        icon = " ",
                        desc = "[F]ind file config" ,
                        key = "F",
                        key_hl = "group",
                        action = "ConfigFindFile",
                    },
                    {
                        icon = "󰩈  ",
                        desc = "[Q]uit" ,
                        key = "q",
                        key_hl = "group",
                        action = "q",
                    },
                },
                footer = {}
            }
        }
    end,
    dependencies = { {'nvim-tree/nvim-web-devicons'}}
}
