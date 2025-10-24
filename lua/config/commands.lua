
vim.api.nvim_create_user_command("Tab2", function()
    require('lib.tabs').set(2)
end, {})

vim.api.nvim_create_user_command("Tab4", function()
    require('lib.tabs').set(4)
end, {})

