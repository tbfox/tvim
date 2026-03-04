-- Test script for scriptures.nvim
-- Run this with :luafile local-plugins/scriptures.nvim/test.lua

-- Add the plugin to the runtime path
vim.opt.runtimepath:append(vim.fn.stdpath("config") .. "/local-plugins/scriptures.nvim")

-- Reload the modules to pick up changes
package.loaded["scriptures"] = nil
package.loaded["scriptures.db"] = nil
package.loaded["scriptures.format"] = nil
package.loaded["scriptures.reader"] = nil
package.loaded["scriptures.nav"] = nil

-- Require and setup
local scriptures = require("scriptures")
scriptures.setup()

-- Test: Open scripture navigation
vim.print("Opening scripture navigation...")
scriptures.nav.open()

vim.print("\n=== Scripture Navigation Test ===")
vim.print("\nNavigation commands:")
vim.print("  <CR> - Select item / go deeper")
vim.print("  -    - Go back up the tree")
vim.print("\nReading view commands (once you open a chapter):")
vim.print("  <leader>n - Next chapter")
vim.print("  <leader>p - Previous chapter")
vim.print("  -         - Back to chapter selection")
vim.print("\nAlternatively, use :Sc or :Scriptures to open navigation")
