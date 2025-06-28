local function set_tab_two()
    require('lib.tabs').set(2)
end

local function set_tab_four()
    require('lib.tabs').set(4)
end

vim.api.nvim_create_user_command("SetTabFour", set_tab_four, {})
vim.api.nvim_create_user_command("SetTabTwo", set_tab_two, {})
