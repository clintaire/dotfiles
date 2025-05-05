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

-- Utility function to detect the package manager
local function detect_package_manager()
    if vim.fn.executable("pacman") == 1 then
        return "pacman"
    elseif vim.fn.executable("apt") == 1 then
        return "apt"
    elseif vim.fn.executable("dnf") == 1 then
        return "dnf"
    else
        return nil
    end
end

local utils = require("core.utils")

-- Command to install tree-sitter CLI based on the detected package manager
local package_manager = utils.detect_package_manager()
if package_manager == "pacman" then
    cmd([[
      command! InstallTreeSitterCLI terminal sudo pacman -S tree-sitter
      echo "Tree-sitter CLI installed successfully."
    ]])
elseif package_manager == "apt" then
    cmd([[
      command! InstallTreeSitterCLI terminal sudo apt install tree-sitter-cli
      echo "Tree-sitter CLI installed successfully."
    ]])
elseif package_manager == "dnf" then
    cmd([[
      command! InstallTreeSitterCLI terminal sudo dnf install tree-sitter-cli
      echo "Tree-sitter CLI installed successfully."
    ]])
else
    vim.notify("No supported package manager detected.", vim.log.levels.ERROR)
end

if not package_manager then
    vim.notify("No supported package manager detected. Please install tree-sitter manually.", vim.log.levels.ERROR)
end

-- Command to install all configured parsers
cmd([[
  command! TreesitterInstallParsers TSInstall all
]])

-- Run "xrdb" after writing .Xresources
cmd("autocmd BufWritePost ~/.Xresources !xrdb %")
