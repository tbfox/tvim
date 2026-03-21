return {
    {
        dir = require("lib.local-plugin")("oily_octo.nvim"),
        build = ":helptags ALL",
        config = function()
            require("oily_octo").setup()
        end
    }
}
