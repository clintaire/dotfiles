--
-- ███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗
-- ████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║
-- ██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║
-- ██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║
-- ██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║
-- ╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝
--

return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    lazy = false,
  },
  {
    "folke/noice.nvim",
    event = "VeryLazy",
    dependencies = {
      "MunifTanjim/nui.nvim",
      "rcarriga/nvim-notify",
    }
  },

  "nvim-lualine/lualine.nvim",

  require("plugins.configs.snacks"),
  require("plugins.configs.which-key"),
  "mbbill/undotree",

  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate"
  },
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "hrsh7th/cmp-cmdline",
      "hrsh7th/cmp-vsnip",
      "hrsh7th/vim-vsnip",
      "f3fora/cmp-spell",
    }
  },

  {
    "CRAG666/code_runner.nvim",
    dependencies = {"nvim-lua/plenary.nvim"},
    config = function()
      require("plugins.configs.code_runner").setup()
    end,
    event = "VeryLazy",
  },

  "williamboman/mason.nvim",
  "williamboman/mason-lspconfig.nvim",
  {
    "neovim/nvim-lspconfig",
    version = "0.1.7",
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
    }
  },

  {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    cmd = { "ConformInfo" },
    keys = {
      {
        "<leader>f",
        function()
          require("conform").format({ async = true, lsp_fallback = true })
        end,
        mode = "",
        desc = "Format buffer",
      },
    },
    opts = {
      formatters_by_ft = {
        lua = { "stylua" },
        python = { "isort", "black" },
        javascript = { { "prettierd", "prettier" } },
      },
      format_on_save = { timeout_ms = 500, lsp_fallback = true },
    },
  },

  "lewis6991/gitsigns.nvim",
  "windwp/nvim-autopairs",
  "norcalli/nvim-colorizer.lua",
  "hiphish/rainbow-delimiters.nvim",

  "lervag/vimtex",
  "L3MON4D3/LuaSnip",
  "saadparwaiz1/cmp_luasnip",

  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "rcarriga/nvim-dap-ui",
      "mfussenegger/nvim-dap-python",
      "leoluz/nvim-dap-go",
      "jbyuki/one-small-step-for-vimkind",
    }
  },

  "simrat39/rust-tools.nvim",
  "fatih/vim-go",
  "mfussenegger/nvim-jdtls",
  "jalvesaq/Nvim-R",
  "vim-perl/vim-perl",
  "StanAngeloff/php.vim",
  "keith/swift.vim",
  "neovimhaskell/haskell-vim",
  "OmniSharp/omnisharp-vim",
  "tikhomirov/vim-glsl",
  "JuliaEditorSupport/julia-vim",
  "iamcco/markdown-preview.nvim",

  {
    "sourcegraph/cody.nvim",
    cmd = "CodyAsk",
    build = ":CodyUpdate",
    config = function()
      require("cody").setup({
        api = {
          url = "http://localhost:11434/v1",
          model = "mistral",
        },
      })
    end,
  },
}
