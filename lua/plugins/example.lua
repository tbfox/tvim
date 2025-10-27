return {
    {
        dir = require("lib.local-plugin")("example.nvim"),
        enabled = false,
        config = function()
            require("runnables").setup()
        end
    }
}
