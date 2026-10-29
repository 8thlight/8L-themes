local M = {}

local palette = {
  black = "#000000",
  charcoal = "#141414",
  dark_gray = "#3C3C3C",
  mid_gray = "#808080",
  gray_350 = "#A6A6A6",
  light_gray = "#DEDEDE",
  lighter_gray = "#EBEBEB",
  lightest_gray = "#F4F4F4",
  white = "#FFFFFF",
  red = "#F32735",
  orange = "#FF8300",
  yellow = "#FFD100",
  green = "#93D500",
  cyan = "#0071CE",
  blue = "#004987",
  indigo = "#A81B8D",
  violet = "#5938FF",
  blue_255 = "#0000FF",
}

local variants = {
  black = {
    name = "Black",
    background = palette.black,
    foreground = palette.lighter_gray,
    surface = palette.charcoal,
    surface_alt = palette.dark_gray,
    muted = palette.gray_350,
    border = palette.dark_gray,
    selection = palette.dark_gray,
  },
  charcoal = {
    name = "Charcoal",
    background = palette.charcoal,
    foreground = palette.lighter_gray,
    surface = palette.black,
    surface_alt = palette.dark_gray,
    muted = palette.gray_350,
    border = palette.dark_gray,
    selection = palette.dark_gray,
  },
  ["dark-gray"] = {
    name = "Dark-Gray",
    background = palette.dark_gray,
    foreground = palette.lightest_gray,
    surface = palette.charcoal,
    surface_alt = palette.black,
    muted = palette.gray_350,
    border = palette.mid_gray,
    selection = palette.mid_gray,
  },
  ["mid-gray"] = {
    name = "Mid-Gray",
    background = palette.mid_gray,
    foreground = palette.black,
    surface = palette.gray_350,
    surface_alt = palette.light_gray,
    muted = palette.dark_gray,
    border = palette.gray_350,
    selection = palette.light_gray,
    light = true,
    restrained = true,
  },
  ["light-gray"] = {
    name = "Light-Gray",
    background = palette.light_gray,
    foreground = palette.charcoal,
    surface = palette.lighter_gray,
    surface_alt = palette.lightest_gray,
    muted = palette.mid_gray,
    border = palette.gray_350,
    selection = palette.gray_350,
    light = true,
  },
  ["lighter-gray"] = {
    name = "Lighter-Gray",
    background = palette.lighter_gray,
    foreground = palette.charcoal,
    surface = palette.light_gray,
    surface_alt = palette.lightest_gray,
    muted = palette.mid_gray,
    border = palette.gray_350,
    selection = palette.light_gray,
    light = true,
  },
  ["lightest-gray"] = {
    name = "Lightest-Gray",
    background = palette.lightest_gray,
    foreground = palette.charcoal,
    surface = palette.lighter_gray,
    surface_alt = palette.light_gray,
    muted = palette.mid_gray,
    border = palette.gray_350,
    selection = palette.light_gray,
    light = true,
  },
  white = {
    name = "White",
    background = palette.white,
    foreground = palette.charcoal,
    surface = palette.lightest_gray,
    surface_alt = palette.lighter_gray,
    muted = palette.mid_gray,
    border = palette.light_gray,
    selection = palette.light_gray,
    light = true,
  },
}

local function set_terminal_colors()
  local colors = {
    palette.black,
    palette.red,
    palette.green,
    palette.yellow,
    palette.blue,
    palette.indigo,
    palette.cyan,
    palette.light_gray,
    palette.mid_gray,
    palette.orange,
    palette.green,
    palette.yellow,
    palette.blue_255,
    palette.violet,
    palette.cyan,
    palette.white,
  }

  for index, color in ipairs(colors) do
    vim.g["terminal_color_" .. index - 1] = color
  end
end

function M.load(variant_name)
  local variant = variants[variant_name]
  if not variant then
    error("Unknown 8th Light variant: " .. variant_name)
  end

  vim.cmd("highlight clear")
  if vim.fn.exists("syntax_on") == 1 then
    vim.cmd("syntax reset")
  end

  vim.o.termguicolors = true
  vim.o.background = variant.light and "light" or "dark"
  vim.g.colors_name = "8th-Light-" .. variant.name
  vim.g.neovide_background_color = variant.background .. "ff"
  vim.g.neovide_cursor_vfx_color = palette.green

  local syntax
  if variant.restrained then
    syntax = {
      keyword = palette.black,
      func = palette.blue,
      string = palette.dark_gray,
      constant = palette.indigo,
      type = palette.black,
      special = palette.blue_255,
    }
  elseif variant.light then
    syntax = {
      keyword = palette.blue_255,
      func = palette.blue,
      string = palette.blue,
      constant = palette.indigo,
      type = palette.blue,
      special = palette.red,
    }
  else
    syntax = {
      keyword = palette.violet,
      func = palette.cyan,
      string = palette.green,
      constant = palette.orange,
      type = palette.yellow,
      special = palette.indigo,
    }
  end

  local highlights = {
    Normal = { fg = variant.foreground, bg = variant.background },
    NormalNC = { fg = variant.foreground, bg = variant.background },
    NormalFloat = { fg = variant.foreground, bg = variant.surface },
    FloatBorder = { fg = palette.cyan, bg = variant.surface },
    FloatTitle = { fg = syntax.type, bg = variant.surface, bold = true },
    Cursor = { fg = variant.background, bg = variant.foreground },
    lCursor = { link = "Cursor" },
    CursorIM = { link = "Cursor" },
    CursorLine = { bg = variant.surface },
    CursorColumn = { link = "CursorLine" },
    ColorColumn = { bg = variant.surface_alt },
    LineNr = { fg = variant.muted },
    CursorLineNr = { fg = syntax.type, bold = true },
    SignColumn = { fg = variant.muted, bg = variant.background },
    FoldColumn = { fg = variant.muted, bg = variant.background },
    Folded = { fg = variant.muted, bg = variant.surface },
    Visual = { bg = variant.selection },
    VisualNOS = { link = "Visual" },
    Search = { fg = palette.black, bg = palette.yellow },
    IncSearch = { fg = palette.black, bg = palette.orange },
    CurSearch = { fg = palette.black, bg = palette.green },
    Substitute = { fg = palette.white, bg = palette.red },
    MatchParen = { fg = palette.black, bg = palette.cyan, bold = true },
    Pmenu = { fg = variant.foreground, bg = variant.surface_alt },
    PmenuSel = { fg = palette.white, bg = palette.blue, bold = true },
    PmenuSbar = { bg = variant.surface },
    PmenuThumb = { bg = variant.muted },
    StatusLine = { fg = palette.white, bg = palette.blue, bold = true },
    StatusLineNC = { fg = variant.muted, bg = variant.surface },
    TabLine = { fg = variant.muted, bg = variant.surface },
    TabLineFill = { bg = variant.surface_alt },
    TabLineSel = { fg = palette.black, bg = palette.yellow, bold = true },
    WinSeparator = { fg = variant.border },
    VertSplit = { link = "WinSeparator" },
    WinBar = { fg = variant.foreground, bg = variant.background, bold = true },
    WinBarNC = { fg = variant.muted, bg = variant.background },
    Directory = { fg = syntax.func, bold = true },
    Title = { fg = syntax.type, bold = true },
    NonText = { fg = variant.border },
    SpecialKey = { fg = variant.muted },
    Whitespace = { fg = variant.border },
    EndOfBuffer = { fg = variant.background },
    ErrorMsg = { fg = palette.red, bold = true },
    WarningMsg = { fg = palette.orange, bold = true },
    MoreMsg = { fg = syntax.string },
    Question = { fg = syntax.func },
    ModeMsg = { fg = syntax.type, bold = true },

    Comment = { fg = variant.muted, italic = true },
    Constant = { fg = syntax.constant },
    String = { fg = syntax.string },
    Character = { link = "String" },
    Number = { fg = syntax.constant },
    Boolean = { fg = syntax.constant, bold = true },
    Float = { link = "Number" },
    Identifier = { fg = variant.foreground },
    Function = { fg = syntax.func, bold = true },
    Statement = { fg = syntax.keyword },
    Conditional = { link = "Statement" },
    Repeat = { link = "Statement" },
    Label = { fg = syntax.special },
    Operator = { fg = variant.foreground },
    Keyword = { fg = syntax.keyword, bold = true },
    Exception = { fg = palette.red },
    PreProc = { fg = syntax.special },
    Include = { fg = syntax.keyword },
    Define = { fg = syntax.keyword },
    Macro = { fg = syntax.special },
    PreCondit = { link = "PreProc" },
    Type = { fg = syntax.type },
    StorageClass = { link = "Type" },
    Structure = { link = "Type" },
    Typedef = { link = "Type" },
    Special = { fg = syntax.special },
    SpecialChar = { fg = syntax.constant },
    Tag = { fg = syntax.func },
    Delimiter = { fg = variant.foreground },
    SpecialComment = { fg = variant.muted, bold = true },
    Debug = { fg = palette.red },
    Underlined = { fg = syntax.func, underline = true },
    Ignore = { fg = variant.muted },
    Error = { fg = palette.white, bg = palette.red },
    Todo = { fg = palette.black, bg = palette.yellow, bold = true },

    DiagnosticError = { fg = palette.red },
    DiagnosticWarn = { fg = palette.orange },
    DiagnosticInfo = { fg = palette.cyan },
    DiagnosticHint = { fg = syntax.string },
    DiagnosticOk = { fg = palette.green },
    DiagnosticVirtualTextError = { fg = palette.red, bg = variant.surface },
    DiagnosticVirtualTextWarn = { fg = palette.orange, bg = variant.surface },
    DiagnosticVirtualTextInfo = { fg = palette.cyan, bg = variant.surface },
    DiagnosticVirtualTextHint = { fg = syntax.string, bg = variant.surface },
    DiagnosticUnderlineError = { undercurl = true, sp = palette.red },
    DiagnosticUnderlineWarn = { undercurl = true, sp = palette.orange },
    DiagnosticUnderlineInfo = { undercurl = true, sp = palette.cyan },
    DiagnosticUnderlineHint = { undercurl = true, sp = syntax.string },

    DiffAdd = { fg = palette.black, bg = palette.green },
    DiffChange = { fg = palette.black, bg = palette.cyan },
    DiffDelete = { fg = palette.white, bg = palette.red },
    DiffText = { fg = palette.black, bg = palette.yellow, bold = true },
    Added = { fg = syntax.string },
    Changed = { fg = syntax.func },
    Removed = { fg = palette.red },
    GitSignsAdd = { fg = syntax.string },
    GitSignsChange = { fg = syntax.func },
    GitSignsDelete = { fg = palette.red },

    ["@comment"] = { link = "Comment" },
    ["@constant"] = { link = "Constant" },
    ["@string"] = { link = "String" },
    ["@number"] = { link = "Number" },
    ["@boolean"] = { link = "Boolean" },
    ["@variable"] = { link = "Identifier" },
    ["@variable.builtin"] = { fg = syntax.special },
    ["@function"] = { link = "Function" },
    ["@function.builtin"] = { fg = syntax.func, italic = true },
    ["@function.macro"] = { link = "Macro" },
    ["@keyword"] = { link = "Keyword" },
    ["@keyword.function"] = { link = "Keyword" },
    ["@keyword.return"] = { link = "Keyword" },
    ["@operator"] = { link = "Operator" },
    ["@type"] = { link = "Type" },
    ["@type.builtin"] = { fg = syntax.type, italic = true },
    ["@property"] = { fg = syntax.func },
    ["@constructor"] = { fg = syntax.type },
    ["@tag"] = { fg = syntax.keyword },
    ["@tag.attribute"] = { fg = syntax.special },
    ["@tag.delimiter"] = { fg = variant.muted },
    ["@markup.heading"] = { link = "Title" },
    ["@markup.link"] = { link = "Underlined" },
    ["@markup.raw"] = { link = "String" },

    LspReferenceText = { bg = variant.surface_alt },
    LspReferenceRead = { bg = variant.surface_alt },
    LspReferenceWrite = { bg = variant.selection, bold = true },
  }

  for group, options in pairs(highlights) do
    vim.api.nvim_set_hl(0, group, options)
  end

  set_terminal_colors()
end

return M
