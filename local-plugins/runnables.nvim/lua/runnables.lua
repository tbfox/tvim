local M = {}

local function list_contains(list, value)
  for _, v in ipairs(list) do
    if v == value then
      return true
    end
  end
  return false
end

local function execute(program, code)
    local tempfile = vim.fn.tempname()
    vim.fn.writefile(vim.split(code, '\n'), tempfile)
    local result = vim.system({program, tempfile}, { text = true }):wait()
    vim.fn.delete(tempfile)
    return result
end

local function execute_print(program, code)
    local output = execute(program, code)
    print(output.stdout)
end

local function execute_program(opts)
    local selection = require('lib.selection').get_selection()
    local is_expression = opts.is_expression
    for _, lang in ipairs(opts.langs) do
        if list_contains(lang.filetypes, vim.bo.filetype) then
            if is_expression then
                execute_print(lang.program, lang.printer(selection))
            else
                execute_print(lang.program, selection)
            end
            return
        end
    end
    print("The filetype \"" .. vim.bo.filetype .. "\" is not currently supported.")
end

M.setup = function(opts)
    vim.api.nvim_create_user_command("Exp", function() execute_program({ langs = opts.langs, is_expression = true  }) end, { range = true })
    vim.api.nvim_create_user_command("Ex",  function() execute_program({ langs = opts.langs, is_expression = false }) end, { range = true })
end

M.printers = require("printers")
M.langs = require("langs")

return M
