return {
    {
        dir = require("lib.local-plugin")("csv-sheet.nvim"),
        enabled = false,
        config = function()
            require("csv-sheet").setup()
        end
    }
}
