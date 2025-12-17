return {
    {
        dir = require("lib.local-plugin")("twmd.nvim"),
        enabled = true,
        dependencies = { { "nvim-tree/nvim-web-devicons" } },
        config = function()
            require("twmd").setup()
        end
    }
}
