local printers = require("printers")

local M = {}

M.lua = {
    filetypes = { "lua" },
    program = "lua",
    printer = printers.lua
}

M.bun = {
    filetypes = { "typescriptreact", "typescript", "javascript", "javascriptreact" },
    program = "bun",
    printer = printers.js
}

M.nu = {
    filetypes = { "nu" },
    program = "nu",
    printer = printers.nu
}

return M
