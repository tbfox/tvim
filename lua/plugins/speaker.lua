return {
    {
        dir = require("lib.local-plugin")("speaker.nvim"),
        config = function()
            require("speaker").setup()
            vim.keymap.set('v', "<leader>sy", ":Say<CR>", { desc = "[s]a[y] selection" })
        end
    }
}
