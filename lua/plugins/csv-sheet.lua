return {
    {
        dir = require("lib.local-plugin")("csv-sheet.nvim"),
        enabled = true,
        config = function()
            require("csv-sheet").setup()
        end
    }
}
