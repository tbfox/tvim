return {
    {
        dir = require("lib.local-plugin")("twmd.nvim"),
        enabled = false,
        dependencies = { { "nvim-tree/nvim-web-devicons" } },
        config = function()
            require("twmd").setup()
        end
    }
}
