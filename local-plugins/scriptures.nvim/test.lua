-- Test script for scriptures.nvim
-- Run this with :luafile local-plugins/scriptures.nvim/test.lua

-- Add the plugin to the runtime path
vim.opt.runtimepath:append(vim.fn.stdpath("config") .. "/local-plugins/scriptures.nvim")

-- Reload the modules to pick up changes
package.loaded["scriptures"] = nil
package.loaded["scriptures.db"] = nil
package.loaded["scriptures.format"] = nil
package.loaded["scriptures.reader"] = nil

-- Require and setup
local scriptures = require("scriptures")
scriptures.setup()

-- Test: Open 1 Nephi 1
vim.print("Opening 1 Nephi 1...")
scriptures.reader.open("bofm", "1 Nephi", 1)

vim.print("\nTest complete!")
vim.print("Try these commands:")
vim.print("  <leader>n - Next chapter")
vim.print("  <leader>p - Previous chapter")
vim.print("\nNavigate to end of 1 Nephi to test book wrapping")
