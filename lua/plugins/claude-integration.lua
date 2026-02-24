return {
    {
        dir = require("lib.local-plugin")("claude-integration"),
        config = function()
            require("claude-integration").setup()
        end
    }
}
