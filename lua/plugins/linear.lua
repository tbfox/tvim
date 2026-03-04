-- Plugin specification for linear.nvim (lazy.nvim)

return {
  {
    dir = require("lib.local-plugin")("linear.nvim"),
    config = function()
      require("linear").setup()
    end
  }
}
