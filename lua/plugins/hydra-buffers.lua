return {
    {
        'hydra/buffers',
        dependencies = { { 'anuvyklack/hydra.nvim' } }, 
        virtual = true,
        config = function()
            local hydra = require('hydra')
            local builtin = require('telescope.builtin')
            hydra({
                name = 'buffers',
                mode = 'n',
                body = '<Leader>b',
                heads = {
                    { 'l', "<CMD>bnext<CR>", { desc = "next" } },
                    { 'h', "<CMD>bprevious<CR>", { desc = "prev" } },
                    { 'b', "<CMD>buffers<CR>", { desc = "list" } },
                    { 'x', "<CMD>bdelete<CR>", { desc = "delete" } },
                    { 't', builtin.buffers, { desc = "telescope", exit_before = true } },
                }
            })
        end
    }
}
