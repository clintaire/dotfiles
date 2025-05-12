--
-- ███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗
-- ████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║
-- ██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║
-- ██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║
-- ██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║
-- ╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝
--

require("colorizer").setup()

require('gitsigns').setup()

vim.g.vimtex_view_method = 'zathura'
vim.g.vimtex_compiler_method = 'latexmk'
vim.g.vimtex_quickfix_mode = 0

require("lualine").setup({
  options = {
    theme = "auto",
    component_separators = " ",
    section_separators = { left = "", right = "" },
  },
})

require("nvim-autopairs").setup()

require("noice").setup({
  lsp = {
    override = {
      ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
      ["vim.lsp.util.stylize_markdown"] = true,
      ["cmp.entry.get_documentation"] = true,
    },
  },
  presets = {
    bottom_search = true,
    command_palette = false,
    long_message_to_split = true,
    lsp_doc_border = true,
  },
})

require("plugins.configs.dap_setup")()

local mocha = require("catppuccin.palettes").get_palette "mocha"
print(vim.inspect(mocha))

require("catppuccin").setup({
  flavour = "mocha",
  transparent_background = false,
  integrations = {
    cmp = true,
    gitsigns = true,
    nvimtree = true,
    treesitter = true,
    notify = true,
    mini = true,
    lsp_trouble = true,
    telescope = true,
    which_key = true,
    dap = true,
    dap_ui = true,
    native_lsp = {
      enabled = true,
      underlines = {
        errors = { "undercurl" },
        warnings = { "undercurl" },
        information = { "undercurl" },
      },
    },
  },
  color_overrides = {},
  custom_highlights = {
    -- Example: Make Normal text use Mocha's base color and comments italic and teal
    Normal = { fg = mocha.text, bg = mocha.base },
    Comment = { fg = mocha.teal, style = { "italic" } },
    LineNr = { fg = mocha.overlay1 },
    CursorLineNr = { fg = mocha.yellow, style = { "bold" } },
    Visual = { bg = mocha.surface2 },
    Pmenu = { bg = mocha.mantle },
    PmenuSel = { bg = mocha.surface1, fg = mocha.text },
    Search = { bg = mocha.yellow, fg = mocha.base, style = { "bold" } },
    IncSearch = { bg = mocha.red, fg = mocha.base, style = { "bold" } },
    -- Add more highlight customizations as you like
  },
})

vim.cmd.colorscheme "catppuccin-mocha"
