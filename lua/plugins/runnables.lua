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
        end
    }
}
