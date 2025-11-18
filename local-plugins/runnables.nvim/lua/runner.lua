local M = {}

function M.execute(program, code)
    local tempfile = vim.fn.tempname()
    vim.fn.writefile(vim.split(code, '\n'), tempfile)
    local result = vim.system({program, tempfile}, { text = true }):wait()
    vim.fn.delete(tempfile)
    return result
end

return M
