return {
    {
        dir = require("lib.local-plugin")("claude-integration.nvim"),
        config = function()
            require("claude-integration").setup()
        end
    }
}
