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

