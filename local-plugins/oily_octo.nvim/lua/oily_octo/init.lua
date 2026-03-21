local issue_list = require("oily_octo.issue_list")

local M = {}

function M.help()
    vim.cmd("help oily_octo")
end

function M.setup()
    local plugin_root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h:h:h")
    vim.opt.runtimepath:append(plugin_root)
    vim.cmd("helptags " .. plugin_root .. "/doc")
    vim.keymap.set("n", "<F10>", issue_list.open)

    vim.api.nvim_create_user_command("Gh", function(cmd_opts)
        local arg = cmd_opts.args
        if arg == "issues" then
            issue_list.open()
        elseif arg == "help" then
            vim.cmd("help oily_octo")
        else
            vim.notify("Usage: :Gh issues | :Gh help", vim.log.levels.WARN)
        end
    end, { nargs = 1 })
end

return M
