-- tbfox.lua - Custom colorscheme based on colors.md

vim.g.colors_name = "tbfox"

-- Clear existing highlights
vim.cmd("highlight clear")
if vim.fn.exists("syntax_on") then
  vim.cmd("syntax reset")
end

-- Define color palettes
local colors_light = {
  primary = "#14b8a6",
  primary_hover = "#0f9488",
  primary_active = "#0d7c66",
  
  secondary = "#fb923c",
  secondary_hover = "#f97316",
  secondary_active = "#ea580c",
  
  danger = "#ef4444",
  danger_hover = "#dc2626",
  danger_active = "#b91c1c",
  
  success = "#10b981",
  success_hover = "#059669",
  success_active = "#047857",
  
  warning = "#d97706",
  warning_hover = "#b45309",
  warning_active = "#92400e",
  
  info = "#3b82f6",
  info_hover = "#2563eb",
  info_active = "#1d4ed8",
  
  neutral_50 = "#f8fafc",
  neutral_100 = "#f1f5f9",
  neutral_200 = "#e2e8f0",
  neutral_300 = "#cbd5e1",
  neutral_400 = "#94a3b8",
  neutral_500 = "#64748b",
  neutral_600 = "#475569",
  neutral_700 = "#334155",
  neutral_800 = "#1e293b",
  neutral_900 = "#0f172a",
  
  bg_main = "#ffffff",
  bg_secondary = "#f8fafc",
  bg_tertiary = "#f1f5f9",
  text_main = "#0f172a",
  text_secondary = "#475569",
  text_inverse = "#ffffff",
  
  input_bg = "#ffffff",
  input_bg_focus = "#f0fdfa",
  input_border = "#cbd5e1",
  input_border_focus = "#14b8a6",
  input_border_error = "#ef4444",
  
  link = "#0f766e",
  link_hover = "#0d7c66",
  link_active = "#065f46",
}

local colors_dark = {
  primary = "#2dd4bf",
  primary_hover = "#5eead4",
  primary_active = "#7dd3fc",
  
  secondary = "#ffa726",
  secondary_hover = "#ffb74d",
  secondary_active = "#ffc947",
  
  danger = "#f87171",
  danger_hover = "#fca5a5",
  danger_active = "#fecaca",
  
  success = "#34d399",
  success_hover = "#6ee7b7",
  success_active = "#a7f3d0",
  
  warning = "#fbbf24",
  warning_hover = "#fcd34d",
  warning_active = "#fde68a",
  
  info = "#60a5fa",
  info_hover = "#93c5fd",
  info_active = "#bfdbfe",
  
  neutral_50 = "#0f172a",
  neutral_100 = "#1e293b",
  neutral_200 = "#334155",
  neutral_300 = "#475569",
  neutral_400 = "#64748b",
  neutral_500 = "#94a3b8",
  neutral_600 = "#cbd5e1",
  neutral_700 = "#e2e8f0",
  neutral_800 = "#f1f5f9",
  neutral_900 = "#f8fafc",
  
  bg_main = "#0f172a",
  bg_secondary = "#1e293b",
  bg_tertiary = "#334155",
  text_main = "#f8fafc",
  text_secondary = "#cbd5e1",
  text_inverse = "#0f172a",
  
  input_bg = "#1e293b",
  input_bg_focus = "#134e4a",
  input_border = "#475569",
  input_border_focus = "#2dd4bf",
  input_border_error = "#f87171",
  
  link = "#2dd4bf",
  link_hover = "#5eead4",
  link_active = "#7dd3fc",
}

-- Select colors based on background
local colors = vim.o.background == "dark" and colors_dark or colors_light

-- Helper function to set highlights
local function hl(group, opts)
  vim.api.nvim_set_hl(0, group, opts)
end

-- Apply highlights
local highlights = {
  -- Basic highlights
  Normal = { fg = colors.text_main, bg = colors.bg_main },
  NormalFloat = { fg = colors.text_main, bg = colors.bg_secondary },
  NormalNC = { fg = colors.text_secondary, bg = colors.bg_main },
  
  -- Cursor and selection
  Cursor = { fg = colors.bg_main, bg = colors.text_main },
  CursorLine = { bg = colors.bg_secondary },
  CursorColumn = { bg = colors.bg_secondary },
  Visual = { bg = colors.neutral_200 },
  VisualNOS = { bg = colors.neutral_200 },
  
  -- Line numbers
  LineNr = { fg = colors.neutral_400 },
  CursorLineNr = { fg = colors.primary, bold = true },
  
  -- Status line
  StatusLine = { fg = colors.text_main, bg = colors.bg_tertiary },
  StatusLineNC = { fg = colors.text_secondary, bg = colors.bg_tertiary },
  
  -- Search
  Search = { fg = colors.bg_main, bg = colors.warning },
  IncSearch = { fg = colors.bg_main, bg = colors.secondary },
  
  -- Messages
  ErrorMsg = { fg = colors.danger },
  WarningMsg = { fg = colors.warning },
  ModeMsg = { fg = colors.info },
  MoreMsg = { fg = colors.success },
  
  -- Popup menu
  Pmenu = { fg = colors.text_main, bg = colors.bg_tertiary },
  PmenuSel = { fg = colors.text_inverse, bg = colors.primary },
  PmenuSbar = { bg = colors.neutral_300 },
  PmenuThumb = { bg = colors.neutral_500 },
  
  -- Tabs
  TabLine = { fg = colors.text_secondary, bg = colors.bg_tertiary },
  TabLineFill = { bg = colors.bg_tertiary },
  TabLineSel = { fg = colors.text_main, bg = colors.bg_main },
  
  -- Window splits
  WinSeparator = { fg = colors.neutral_300 },
  VertSplit = { fg = colors.neutral_300 },
  
  -- Syntax highlighting
  Comment = { fg = colors.neutral_400, italic = true },
  Constant = { fg = colors.secondary },
  String = { fg = colors.success },
  Character = { fg = colors.success },
  Number = { fg = colors.warning },
  Boolean = { fg = colors.danger },
  Float = { fg = colors.warning },
  
  Identifier = { fg = colors.text_main },
  Function = { fg = colors.primary },
  
  Statement = { fg = colors.info },
  Conditional = { fg = colors.info },
  Repeat = { fg = colors.info },
  Label = { fg = colors.info },
  Operator = { fg = colors.text_main },
  Keyword = { fg = colors.info },
  Exception = { fg = colors.danger },
  
  PreProc = { fg = colors.secondary },
  Include = { fg = colors.secondary },
  Define = { fg = colors.secondary },
  Macro = { fg = colors.secondary },
  PreCondit = { fg = colors.secondary },
  
  Type = { fg = colors.primary },
  StorageClass = { fg = colors.primary },
  Structure = { fg = colors.primary },
  Typedef = { fg = colors.primary },
  
  Special = { fg = colors.warning },
  SpecialChar = { fg = colors.warning },
  Tag = { fg = colors.primary },
  Delimiter = { fg = colors.text_main },
  SpecialComment = { fg = colors.neutral_400 },
  Debug = { fg = colors.danger },
  
  -- Underlined and errors
  Underlined = { underline = true },
  Error = { fg = colors.danger },
  Todo = { fg = colors.warning, bold = true },
  
  -- Diff
  DiffAdd = { fg = colors.success },
  DiffChange = { fg = colors.warning },
  DiffDelete = { fg = colors.danger },
  DiffText = { fg = colors.info },
  
  -- Git signs
  GitSignsAdd = { fg = colors.success },
  GitSignsChange = { fg = colors.warning },
  GitSignsDelete = { fg = colors.danger },
  
  -- Tree-sitter
  ["@variable"] = { fg = colors.text_main },
  ["@variable.builtin"] = { fg = colors.secondary },
  ["@function"] = { fg = colors.primary },
  ["@function.builtin"] = { fg = colors.primary },
  ["@keyword"] = { fg = colors.info },
  ["@string"] = { fg = colors.success },
  ["@number"] = { fg = colors.warning },
  ["@boolean"] = { fg = colors.danger },
  ["@comment"] = { fg = colors.neutral_400, italic = true },
  ["@type"] = { fg = colors.primary },
  ["@constant"] = { fg = colors.secondary },
  ["@parameter"] = { fg = colors.text_secondary },
}

for group, opts in pairs(highlights) do
  hl(group, opts)
end 