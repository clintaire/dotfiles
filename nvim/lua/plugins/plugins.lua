--
-- ███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗
-- ████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║
-- ██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║
-- ██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║
-- ██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║
-- ╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝
--
-- Thanks @ Arfan Zubi
-- https://github.com/3rfaan/dotfiles
-- Neovim Lua Config File by Arfan Zubi
-- PLUGINS

return {
    -------- Appearance
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

    "nvim-lualine/lualine.nvim", -- Status line

    -------- Neovim Tools
    require("plugins.configs.snacks"),    -- Collection of QoL plugins
    require("plugins.configs.which-key"), -- Show keymaps
    "mbbill/undotree",                    -- Undo tree

    {
        "nvim-treesitter/nvim-treesitter", -- Treesitter
        build = ":TSUpdate"
    },
    {
        "hrsh7th/nvim-cmp", -- Auto completion
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

    ------- LSP
    "williamboman/mason.nvim",           -- LSP packet manager
    "williamboman/mason-lspconfig.nvim", -- lspconfig integration
    "neovim/nvim-lspconfig",             -- LSP configuration

    ------- Editing
    "stevearc/conform.nvim",           -- Formatter
    "lewis6991/gitsigns.nvim",         -- Git signs
    "windwp/nvim-autopairs",           -- Auto closing brackets, parenthesis etc.
    "norcalli/nvim-colorizer.lua",     -- Hex color highlighting
    "hiphish/rainbow-delimiters.nvim", -- Brackets, parenthesis colorizer

    -- Fix duplicate LaTeX entries - keep only these
    "lervag/vimtex",
    "L3MON4D3/LuaSnip",
    "saadparwaiz1/cmp_luasnip",
}
