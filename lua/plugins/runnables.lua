return {
    {
        dir = require("lib.local-plugin")("runnables.nvim"),
        config = function()
            local runnables = require("runnables")
            runnables.setup({
                langs = {
                    runnables.langs.lua,
                    runnables.langs.bun,
                    runnables.langs.nu,
                }
            })

            local function set_case_to(case)
                local selection = require('lib.selection').get_selection()
                local output = require('runner').execute('nu', "'" .. selection .. "' | str " .. case).stdout
                require('lib.selection').set_selection(output:gsub("\n$", ""), false)
            end

            local function set_case(opts)
                local case = opts.args
                if case == "kab" then
                    set_case_to('kebab-case')
                elseif case == "down" then
                    set_case_to('downcase')
                elseif case == "up" then
                    set_case_to('upcase')
                elseif case == "camel" then
                    set_case_to('camel-case')
                elseif case == "snake" then
                    set_case_to('snake-case')
                elseif case == "ssnake" then
                    set_case_to('screaming-snake-case')
                elseif case == "title" then
                    set_case_to('title-case')
                else
                    print("Sorry, " .. case .. " is not a valid case. (kab, down, up, camel, snake, ssnake, title)")
                end
            end

            vim.api.nvim_create_user_command("Case", set_case,      { range = true, nargs = "*" })
            vim.keymap.set('v', "<leader>tk", ":Case kab<CR>",      { desc = "[t]o [k]abab case" })
            vim.keymap.set('v', "<leader>td", ":Case down<CR>",     { desc = "[t]o [d]owncase" })
            vim.keymap.set('v', "<leader>tu", ":Case up<CR>",       { desc = "[t]o [u]pcase" })
            vim.keymap.set('v', "<leader>tc", ":Case camel<CR>",    { desc = "[t]o [c]amel case" })
            vim.keymap.set('v', "<leader>ts", ":Case snake<CR>",    { desc = "[t]o [s]nake case" })
            vim.keymap.set('v', "<leader>tS", ":Case ssnake<CR>",   { desc = "[t]o [S]creaming snake case" })
            vim.keymap.set('v', "<leader>tt", ":Case title<CR>",    { desc = "[t]o [t]itle case" })
        end
    }
}
