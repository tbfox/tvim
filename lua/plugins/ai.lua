return {
    {
        dir = require("lib.local-plugin")("ai.nvim"),
        config = function()
            local ai = require("ai")
            ai.setup()
        end
    }
}
