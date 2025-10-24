local s = require('lib.selection')

local function mk_cmd(from, to)
    local init = "vi" .. from .. "xhi"
    local cleanup = "Pllxx"

    if to == '{' then
        return init .. '{}' .. cleanup
    end
    if to == '[' then
        return init .. '[]' .. cleanup
    end
    if to == '(' then
        return init .. '()' .. cleanup
    end

    return init .. to .. to .. cleanup
end

vim.api.nvim_create_user_command("Sur", function(opts)
    local content = s.get_selection()
    s.set_selection(opts.fargs[1] .. content .. opts.fargs[2])
end, { nargs = "+", range = true })

vim.api.nvim_create_user_command("Rep", function(opts)
    vim.cmd("normal! " .. mk_cmd(opts.fargs[1], opts.fargs[2]))
end, { nargs = "+" })

-- currently broken
-- vim.keymap.set('v', "<Leader>{", "<CMD>'<,'>Sur { }<CR>", { desc = "Surround selected text with { }" })
-- vim.keymap.set('v', "<Leader>[", "<CMD>'<,'>Sur [ ]<CR>", { desc = "Surround selected text with [ ]" })
-- vim.keymap.set('v', "<Leader>(", "<CMD>'<,'>Sur ( )<CR>", { desc = "Surround selected text with ( )" })
-- local function leader(from, to)
--     return "<Leader>" .. from .. to
-- end

-- local quote_types = { "'", '"', '`', "{", "(", "[" }
-- for _, from in ipairs(quote_types) do
--     for _, to in ipairs(quote_types) do
--         if from ~= to then
--             -- vim.keymap.set('n', leader(from, to), cmd2(from, to), { desc = 'Replace string ' .. from .. ' with ' .. to .. ' string' })
--         end
--     end
-- end
