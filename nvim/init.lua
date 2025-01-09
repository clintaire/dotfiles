-- Set leader key
vim.g.mapleader = " "

-- Add LuaRocks paths
local function add_luarocks_paths()
    local lua_version = _VERSION:match("%d+%.%d+")
    local home = os.getenv("HOME")
    local luarocks_path = home .. "/.luarocks/share/lua/" .. lua_version .. "/?.lua;" ..
                          home .. "/.luarocks/share/lua/" .. lua_version .. "/?/init.lua"
    local luarocks_cpath = home .. "/.luarocks/lib/lua/" .. lua_version .. "/?.so"

    package.path = package.path .. ";" .. luarocks_path
    package.cpath = package.cpath .. ";" .. luarocks_cpath
end

add_luarocks_paths()

-- Set Ruby provider
vim.g.ruby_host_prog = "/usr/bin/ruby"

-- Basic settings
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.mouse = "a"
vim.opt.clipboard = "unnamedplus"
vim.opt.termguicolors = true

-- Enable syntax highlighting and filetype detection
vim.cmd("syntax on")
vim.cmd("filetype plugin indent on")

-- Load Packer
vim.cmd [[packadd packer.nvim]]

-- Plugin setup using Packer
require('packer').startup(function(use)
    use 'wbthomason/packer.nvim'
    use 'nvim-treesitter/nvim-treesitter'
    use 'neovim/nvim-lspconfig'
    use 'williamboman/mason.nvim'
    use 'williamboman/mason-lspconfig.nvim'
    use 'hrsh7th/nvim-cmp'
    use 'hrsh7th/cmp-nvim-lsp'
    use 'nvim-lua/plenary.nvim'
    use 'nvim-telescope/telescope.nvim'
    use 'dense-analysis/ale'
    use 'jamessan/vim-gnupg'
    use {
        'rest-nvim/rest.nvim',
        requires = {
            'nvim-lua/plenary.nvim',
            'j-hui/fidget.nvim',
        }
    }
    use 'tpope/vim-fugitive'
    use 'lewis6991/gitsigns.nvim'
    use 'L3MON4D3/LuaSnip'
    use 'rafamadriz/friendly-snippets'
    use 'nvim-lualine/lualine.nvim'
    use 'akinsho/bufferline.nvim'
    use {'nvim-telescope/telescope-fzf-native.nvim', run = 'make' }
    use 'nvim-telescope/telescope-frecency.nvim'
    use 'jose-elias-alvarez/null-ls.nvim'
end)

-- Treesitter configuration
require('nvim-treesitter.configs').setup {
    ensure_installed = { "lua", "python", "javascript", "typescript", "html", "css", "json" },
    highlight = { enable = true },
}

-- Mason setup for LSP
require("mason").setup()
require("mason-lspconfig").setup({
    ensure_installed = { "pyright", "ts_ls", "clangd" }
})

-- LSP Configuration
local lspconfig = require('lspconfig')

-- Python (pyright)
lspconfig.pyright.setup {
    settings = {
        python = {
            analysis = {
                typeCheckingMode = "strict"
            }
        }
    }
}

-- JavaScript/TypeScript (ts_ls)
lspconfig.ts_ls.setup {}

-- C/C++ (clangd)
lspconfig.clangd.setup {}

-- Remove redundant tsserver setup
-- lspconfig.tsserver.setup {}

-- Autocompletion setup
local cmp = require('cmp')
cmp.setup {
    mapping = {
        ['<C-n>'] = cmp.mapping.select_next_item(),
        ['<C-p>'] = cmp.mapping.select_prev_item(),
        ['<CR>'] = cmp.mapping.confirm({ select = true }),
    },
    sources = {
        { name = 'nvim_lsp' },
    },
}

-- Telescope configuration
require('telescope').setup {
    defaults = {
        mappings = {
            i = {
                ["<C-n>"] = "move_selection_next",
                ["<C-p>"] = "move_selection_previous",
            },
        },
    },
}

-- ALE configuration
vim.g.ale_fixers = {
    ['python'] = {'black', 'isort'},
    ['javascript'] = {'eslint'},
    ['typescript'] = {'eslint'}
}
vim.g.ale_lint_on_save = 1
vim.g.ale_fix_on_save = 1

-- REST API setup
local status_ok, rest_nvim = pcall(require, 'rest-nvim')
if status_ok then
    rest_nvim.setup()
end

-- Gitsigns configuration
require('gitsigns').setup()

-- LuaSnip configuration
require('luasnip.loaders.from_vscode').lazy_load()

-- Lualine configuration
require('lualine').setup {
    options = {
        theme = 'auto',
    },
}

-- Bufferline configuration
require('bufferline').setup {}

-- Diagnostics configuration
vim.diagnostic.config({
    virtual_text = false,
    signs = true,
    update_in_insert = true,
    float = {
        source = "always",
        border = "rounded",
    },
})

-- Keybindings
vim.api.nvim_set_keymap('n', '<leader>w', ':w<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>q', ':q<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>gs', ':Git<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>cf', ':lua vim.lsp.buf.format({ async = true })<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>ff', ':Telescope find_files<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>fg', ':Telescope live_grep<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<C-h>', '<C-w>h', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<C-l>', '<C-w>l', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<C-j>', '<C-w>j', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<C-k>', '<C-w>k', { noremap = true, silent = true })

-- Custom Color Scheme
vim.cmd("highlight clear")
vim.o.background = "dark"
vim.g.colors_name = "custom"

local function highlight(group, fg, bg, style)
    local cmd = string.format(
        "highlight %s guifg=%s guibg=%s gui=%s",
        group,
        fg or "NONE",
        bg or "NONE",
        style or "NONE"
    )
    vim.cmd(cmd)
end

local colors = {
    background = "#1e1f22",
    foreground = "#a9b7c6",
    dim_foreground = "#787878",
    bright_foreground = "#a9b7c6",
    cursor = "#cc7832",
    search_match_bg = "#ff6b6b",
    selection_bg = "#4b2222",
}

highlight("Normal", colors.foreground, colors.background)
highlight("CursorLine", nil, colors.dim_foreground)
highlight("Visual", nil, colors.selection_bg)
highlight("Search", colors.background, colors.search_match_bg)
highlight("IncSearch", colors.background, colors.search_match_bg)
highlight("Cursor", colors.cursor, colors.bright_foreground)
