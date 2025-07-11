--
-- ███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗
-- ████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║
-- ██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║
-- ██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║
-- ██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║
-- ╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝
--

local has_treesitter = vim.fn.executable("tree-sitter") == 1

if not has_treesitter then
    vim.notify("Install tree-sitter with: sudo pacman -S tree-sitter", vim.log.levels.WARN)
end

require("nvim-treesitter.configs").setup({
    ensure_installed = { "bash", "c", "lua", "vim" },
    sync_install = false,
    auto_install = false, -- Disable auto-install to prevent issues
    highlight = { enable = true },
})
