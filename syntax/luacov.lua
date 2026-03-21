if vim.b.current_syntax then return end

vim.cmd([[
  syn match luacovMissed        /^\*\+0\s.*/
  syn match luacovHitCount      /^\s*\d\+\ze\s/ contained
  syn match luacovHitLine       /^\s*\d\+\s.*/ contains=luacovHitCount
  syn match luacovUncounted     /^\s\{6\}\S.*/
  syn match luacovSeparator     /^=\{10,\}/
  syn match luacovFilePath      /^\/.\+\.lua$/
  syn match luacovSummaryHeader /^Summary$/
  syn match luacovSummaryDivider /^-\{10,\}/
  syn match luacovSummaryTotal  /^Total\s.*/
  syn match luacovPct100        /\s1\{0,2\}00\.00%/
  syn match luacovPctHigh       /\s[89][0-9]\.\d\+%/
  syn match luacovPctMid        /\s[5-7][0-9]\.\d\+%/
  syn match luacovPctLow        /\s[0-4][0-9]\.\d\+%/
]])

local highlights = {
    luacovMissed        = { fg = "#f38ba8", bold = true },
    luacovHitCount      = { fg = "#a6e3a1" },
    luacovUncounted     = { fg = "#585b70" },
    luacovSeparator     = { fg = "#45475a" },
    luacovFilePath      = { fg = "#89b4fa", bold = true },
    luacovSummaryHeader = { fg = "#cba6f7", bold = true },
    luacovSummaryDivider = { fg = "#45475a" },
    luacovSummaryTotal  = { fg = "#cdd6f4", bold = true },
    luacovPct100        = { fg = "#a6e3a1", bold = true },
    luacovPctHigh       = { fg = "#a6e3a1" },
    luacovPctMid        = { fg = "#f9e2af" },
    luacovPctLow        = { fg = "#f38ba8" },
}

for group, opts in pairs(highlights) do
    vim.api.nvim_set_hl(0, group, { fg = opts.fg, bold = opts.bold, default = true })
end

vim.b.current_syntax = "luacov"
