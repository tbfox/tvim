return {
    {
        dir = require("lib.local-plugin")("time_track.nvim"),
        enabled = false,
        dependencies = { { "nvim-tree/nvim-web-devicons" } },
        config = function()
            require("time_track").setup()
        end
    }
}
