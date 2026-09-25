vim.cmd("highlight clear")
vim.o.termguicolors = true
vim.o.background = "dark"
vim.g.colors_name = "monochrome-pastel"

local c = {
  bg = "#0f0f0f",
  panel = "#161616",
  border = "#2a2a2a",
  fg = "#e8e8e8",
  accent = "#d0d0d0",
  dim = "#6a6a6a",
  red = "#e88888",
  green = "#a8c8a8",
  yellow = "#e8c088",
  blue = "#88b0c8",
  purple = "#c8b088",
  gray = "#b0b0b0",
  selection = "#1c1c1c",
}

local groups = {
  Normal = { fg = c.fg, bg = c.bg },
  NormalFloat = { fg = c.fg, bg = c.panel },
  SignColumn = { bg = c.bg },
  LineNr = { fg = c.dim, bg = c.bg },
  CursorLineNr = { fg = c.accent, bold = true },
  CursorLine = { bg = c.panel },
  ColorColumn = { bg = c.panel },
  VertSplit = { fg = c.border, bg = c.bg },
  WinSeparator = { fg = c.border, bg = c.bg },
  StatusLine = { fg = c.fg, bg = c.panel },
  StatusLineNC = { fg = c.dim, bg = c.panel },
  TabLine = { fg = c.dim, bg = c.panel },
  TabLineSel = { fg = c.bg, bg = c.fg, bold = true },
  TabLineFill = { bg = c.panel },
  Pmenu = { fg = c.fg, bg = c.panel },
  PmenuSel = { fg = c.bg, bg = c.fg },
  Visual = { bg = c.selection },
  Search = { fg = c.bg, bg = c.yellow },
  IncSearch = { fg = c.bg, bg = c.red },
  CurSearch = { fg = c.bg, bg = c.red },
  MatchParen = { fg = c.yellow, bold = true, underline = true },
  ErrorMsg = { fg = c.red, bold = true },
  WarningMsg = { fg = c.yellow },
  MoreMsg = { fg = c.green },
  Question = { fg = c.green },
  Comment = { fg = c.dim, italic = true },
  Constant = { fg = c.purple },
  String = { fg = c.green },
  Character = { fg = c.green },
  Number = { fg = c.yellow },
  Boolean = { fg = c.yellow },
  Float = { fg = c.yellow },
  Identifier = { fg = c.fg },
  Function = { fg = c.blue },
  Statement = { fg = c.red },
  Conditional = { fg = c.red },
  Repeat = { fg = c.red },
  Label = { fg = c.red },
  Operator = { fg = c.fg },
  Keyword = { fg = c.red },
  Exception = { fg = c.red },
  PreProc = { fg = c.purple },
  Include = { fg = c.purple },
  Define = { fg = c.purple },
  Macro = { fg = c.purple },
  Type = { fg = c.blue },
  StorageClass = { fg = c.red },
  Structure = { fg = c.blue },
  Special = { fg = c.yellow },
  Todo = { fg = c.bg, bg = c.yellow, bold = true },
  DiagnosticError = { fg = c.red },
  DiagnosticWarn = { fg = c.yellow },
  DiagnosticInfo = { fg = c.blue },
  DiagnosticHint = { fg = c.green },
  DiffAdd = { fg = c.green, bg = c.panel },
  DiffChange = { fg = c.yellow, bg = c.panel },
  DiffDelete = { fg = c.red, bg = c.panel },
  DiffText = { fg = c.bg, bg = c.yellow },
}

for group, opts in pairs(groups) do
  vim.api.nvim_set_hl(0, group, opts)
end

vim.g.terminal_color_0 = c.bg
vim.g.terminal_color_1 = c.red
vim.g.terminal_color_2 = c.green
vim.g.terminal_color_3 = c.yellow
vim.g.terminal_color_4 = c.blue
vim.g.terminal_color_5 = c.purple
vim.g.terminal_color_6 = c.gray
vim.g.terminal_color_7 = c.fg
vim.g.terminal_color_8 = c.dim
vim.g.terminal_color_9 = c.red
vim.g.terminal_color_10 = c.green
vim.g.terminal_color_11 = c.yellow
vim.g.terminal_color_12 = c.blue
vim.g.terminal_color_13 = c.purple
vim.g.terminal_color_14 = c.gray
vim.g.terminal_color_15 = c.fg
