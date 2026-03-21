return {
    {
        'lewis6991/gitsigns.nvim',
        config = function()
            require("gitsigns").setup({
                on_attach = function(bufnr)
                    local gs = package.loaded.gitsigns
                    local map = function(mode, l, r, desc)
                        vim.keymap.set(mode, l, r, { buffer = bufnr, desc = desc })
                    end

                    -- Navigation
                    map('n', ']h', gs.next_hunk, 'Next hunk')
                    map('n', '[h', gs.prev_hunk, 'Prev hunk')

                    -- Stage / reset hunks
                    map('n', '<Leader>hs', gs.stage_hunk, 'Stage hunk')
                    map('n', '<Leader>hr', gs.reset_hunk, 'Reset hunk')
                    map('v', '<Leader>hs', function() gs.stage_hunk({ vim.fn.line('.'), vim.fn.line('v') }) end, 'Stage hunk (range)')
                    map('v', '<Leader>hr', function() gs.reset_hunk({ vim.fn.line('.'), vim.fn.line('v') }) end, 'Reset hunk (range)')

                    -- Stage / reset buffer
                    map('n', '<Leader>hS', gs.stage_buffer, 'Stage buffer')
                    map('n', '<Leader>hR', gs.reset_buffer, 'Reset buffer')

                    -- Undo stage
                    map('n', '<Leader>hu', gs.undo_stage_hunk, 'Undo stage hunk')

                    -- Preview
                    map('n', '<Leader>hp', gs.preview_hunk, 'Preview hunk')

                    -- Blame
                    map('n', '<Leader>hb', gs.blame_line, 'Blame line')

                    -- Diff
                    map('n', '<Leader>hd', gs.diffthis, 'Diff this')
                end
            })
        end
    }
}
