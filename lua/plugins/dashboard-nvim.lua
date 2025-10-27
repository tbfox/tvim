return {
    'nvimdev/dashboard-nvim',
    event = 'VimEnter',
    config = function()
        vim.keymap.set('n', "<F12>", "<CMD>Dashboard<CR>",     { desc = "[C]lose current window" })

        vim.api.nvim_create_user_command("ConfigFindFile", function()
            require("telescope.builtin").find_files {
                cwd = vim.fn.stdpath("config")
            }
        end, {})

        vim.api.nvim_create_user_command("ConfigGrep", function()
            require("telescope.builtin").live_grep {
                cwd = vim.fn.stdpath("config")
            }
        end, {})

        vim.api.nvim_create_user_command("ConfigEdit", function()
            require("oil").open(vim.fn.stdpath("config"))
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
                        desc = "[F]ind Files",
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
