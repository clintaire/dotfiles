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
-- INIT FILE

-- Variables
local opt = vim.opt
_G.opt = opt -- Make opt global
local g = vim.g
_G.g = g -- Make g global
local cmd = vim.cmd
_G.cmd = cmd -- Make cmd global

vim.opt.termguicolors = true

-- Leader key
g.mapleader = ","

-- Ensure global variables are defined before requiring other modules
require("core.lazy")       -- lazy.nvim plugin manager
require("core.utils")      -- Utility functions
require("core.mappings")   -- Mappings
require("core.scripts")    -- Scripts
require("core.settings")   -- Editor settings

require("plugins.configs") -- All setups and configurations
require("plugins.plugins") -- Plugins
require("plugins.setups")  -- Setup of plugins
