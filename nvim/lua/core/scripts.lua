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
-- SCRIPTS

-- Colorscheme
cmd("colorscheme catppuccin-mocha")

-- Format on save (Commented out because Conform.nvim takes care of this)
--cmd("autocmd BufWritePre * lua vim.lsp.buf.format()")

-- Run ":so" after writing .zshrc
cmd("autocmd BufWritePost ~/.zshrc so %")

-- Command to install tree-sitter CLI (simple version)
cmd([[
  command! InstallTreeSitterCLI terminal sudo pacman -S tree-sitter
]])

-- Command to install all configured parsers
cmd([[
  command! TreesitterInstallParsers TSInstall all
]])

-- Run "xrdb" after writing .Xresources
cmd("autocmd BufWritePost ~/.Xresources !xrdb %")
