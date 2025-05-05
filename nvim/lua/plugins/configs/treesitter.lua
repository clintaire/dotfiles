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
-- TREESITTER

-- Simple check if tree-sitter CLI is available (no background callbacks)
local has_treesitter = vim.fn.executable("tree-sitter") == 1

-- Only display message, don't create complex hooks
if not has_treesitter then
    vim.notify("Install tree-sitter with: sudo pacman -S tree-sitter", vim.log.levels.WARN)
end

-- Use original setup style from nvim1/nvim2
require("nvim-treesitter.configs").setup({
    ensure_installed = { "bash", "c", "lua", "vim" },
    sync_install = false,
    auto_install = false, -- Disable auto-install to prevent issues
    highlight = { enable = true },
})
