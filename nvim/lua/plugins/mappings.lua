return {
  {
    "AstroNvim/astrocore",
    ---@type AstroCoreOpts
    opts = {
      mappings = {
        n = {
          -- File & Editing (Sublime-style)
          ["<C-p>"]     = { "<cmd>Telescope find_files<cr>", desc = "Find File" },
          ["<C-S-p>"]   = { "<cmd>Telescope commands<cr>", desc = "Command Palette" },
          ["<C-f>"]     = { "<cmd>Telescope live_grep<cr>", desc = "Find in Files" },
          ["<C-h>"]     = { ":%s//g<Left><Left>", desc = "Replace in File" },
          ["<C-S-d>"]   = { "yyp", desc = "Duplicate Line" },

          -- Comment toggling (requires Comment.nvim, already included in AstroNvim)
          ["<C-/>"]     = { "gcc", desc = "Toggle Line Comment", noremap = false },

          -- Easy command entry
          ["<Leader>c"] = { ":", desc = "Enter Command Mode" },

          -- Goto
          ["<F12>"]     = { "<cmd>lua vim.lsp.buf.definition()<cr>", desc = "Go to Definition" },

          -- Tabs & Buffers
          ["<C-Tab>"]   = { "<cmd>bnext<cr>", desc = "Next Buffer" },
          ["<C-S-Tab>"] = { "<cmd>bprevious<cr>", desc = "Previous Buffer" },
          ["<C-w>"]     = { "<cmd>bdelete<cr>", desc = "Close Buffer" },

          -- Save
          ["<C-s>"]     = { "<cmd>w<cr>", desc = "Save File" },

          -- Comment group label (for which-key)
          ["gc"]        = { desc = "Toggle Comment", noremap = false },

          -- Sublime-style editing
          ["<C-a>"]     = { "ggVG", desc = "Select All" },
          ["<C-c>"]     = { 'ggVG"+y', desc = "Copy All to Clipboard" },
          ["<C-x>"]     = { "dd", desc = "Cut Current Line" },
          ["<C-v>"]     = { '"+p', desc = "Paste Clipboard" },
          ["<C-z>"]     = { "u", desc = "Undo" },
          ["<C-S-z>"]   = { "<C-r>", desc = "Redo" },
          ["<C-home>"]  = { "gg", desc = "Top of File" },
          ["<C-end>"]   = { "G", desc = "Bottom of File" },
        },

        v = {
          -- Visual mode copy
          ["<C-c>"] = { '"+y', desc = "Copy Selection to Clipboard" },
          -- Visual comment
          ["<C-/>"] = { "gc", desc = "Toggle Block Comment", noremap = false },
        },

        i = {
          -- Exit insert mode quickly
          ["jk"] = { "<Esc>", desc = "Escape insert mode" },
        },
      },
    },
  },
}
