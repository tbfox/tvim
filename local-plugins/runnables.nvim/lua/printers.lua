local M = {}

function M.lua(code)
    return "print(" .. code .. ")"
end

function M.js(code)
    return "console.log(" .. code .. ")"
end

function M.nu(code)
    return "print " .. code
end

return M
