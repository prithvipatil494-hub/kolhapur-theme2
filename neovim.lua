-- Kolhapur Theme for Neovim

local colors = {
  bg        = "#1C1210",
  bg_alt    = "#241813",
  fg        = "#F1E7D0",
  fg_dim    = "#B8A98F",
  maroon    = "#7B2323",
  maroon_b  = "#A83232",
  gold      = "#C98A2C",
  gold_b    = "#E0A83F",
  teal      = "#2F6E5E",
  teal_b    = "#3E8E77",
  stone     = "#8A7863",
  red       = "#B33A3A",
  green     = "#6E8F4F",
  yellow    = "#D4A017",
}

vim.cmd("highlight clear")
if vim.fn.exists("syntax_on") then
  vim.cmd("syntax reset")
end
vim.o.background = "dark"
vim.g.colors_name = "kolhapur"

local hl = vim.api.nvim_set_hl

hl(0, "Normal", { fg = colors.fg, bg = colors.bg })
hl(0, "CursorLine", { bg = colors.bg_alt })
hl(0, "LineNr", { fg = colors.fg_dim })
hl(0, "CursorLineNr", { fg = colors.gold_b, bold = true })
hl(0, "Visual", { bg = colors.maroon })
hl(0, "Search", { bg = colors.gold, fg = colors.bg })

hl(0, "Comment", { fg = colors.fg_dim, italic = true })
hl(0, "String", { fg = colors.green })
hl(0, "Number", { fg = colors.gold_b })
hl(0, "Function", { fg = colors.teal_b })
hl(0, "Keyword", { fg = colors.maroon_b, bold = true })
hl(0, "Type", { fg = colors.gold })
hl(0, "Identifier", { fg = colors.fg })
hl(0, "Statement", { fg = colors.maroon_b })
hl(0, "PreProc", { fg = colors.teal })
hl(0, "Constant", { fg = colors.gold_b })
hl(0, "Special", { fg = colors.stone })
hl(0, "Error", { fg = colors.red, bold = true })
hl(0, "Warning", { fg = colors.yellow })

hl(0, "Pmenu", { bg = colors.bg_alt, fg = colors.fg })
hl(0, "PmenuSel", { bg = colors.maroon, fg = colors.fg })
hl(0, "StatusLine", { bg = colors.bg_alt, fg = colors.gold_b })
hl(0, "VertSplit", { fg = colors.stone })
