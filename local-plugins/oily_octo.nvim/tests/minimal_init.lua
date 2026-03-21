-- Minimal init for running oily_octo.nvim tests with plenary
-- Usage: nvim --headless -u tests/minimal_init.lua -c "PlenaryBustedDirectory tests/ {minimal_init = 'tests/minimal_init.lua'}"

local plugin_root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h:h")

-- Add the plugin's lua dir to runtimepath
vim.opt.runtimepath:prepend(plugin_root)

-- Add plenary (installed as telescope dependency)
local data = vim.fn.stdpath("data")
vim.opt.runtimepath:append(data .. "/lazy/plenary.nvim")

-- Optional luacov coverage (set LUACOV=1 to enable)
if os.getenv("LUACOV") == "1" then
    package.path = package.path .. ";/opt/homebrew/share/lua/5.4/?.lua;/opt/homebrew/share/lua/5.4/?/init.lua"
    local runner = require("luacov.runner")
    runner.init()
    -- Plenary calls vim.cmd("0cq"/"1cq") to exit, bypassing VimLeavePre. Intercept to flush stats.
    local orig_cmd = vim.cmd
    vim.cmd = function(...)
        local arg = select(1, ...)
        if type(arg) == "string" and arg:match("^%s*%d*cq") then
            runner.shutdown()
        end
        return orig_cmd(...)
    end
end
