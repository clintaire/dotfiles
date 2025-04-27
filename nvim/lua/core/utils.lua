--
-- ███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗
-- ████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║
-- ██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║
-- ██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║
-- ██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║
-- ╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝
--
-- Neovim Lua Config File
-- UTILITY FUNCTIONS

local M = {}

-- Check if executable exists
M.executable = function(name)
    return vim.fn.executable(name) > 0
end

-- Utility function to detect the package manager
M.detect_package_manager = function()
    if M.executable("pacman") then
        return "pacman"
    elseif M.executable("apt") then
        return "apt"
    elseif M.executable("dnf") then
        return "dnf"
    else
        return nil
    end
end

return M
