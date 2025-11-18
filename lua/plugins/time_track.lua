return {
    {
        dir = require("lib.local-plugin")("time_track.nvim"),
        enabled = true,
        dependencies = { { "nvim-tree/nvim-web-devicons" } },
        config = function()
            require("time_track").setup()
        end
    }
}
