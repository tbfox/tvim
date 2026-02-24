return {
    {
        dir = require("lib.local-plugin")("oily_octo.nvim"),
        config = function()
            require("oily_octo").setup()
        end
    }
}
