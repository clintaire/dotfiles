--
-- ███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗
-- ████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║
-- ██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║
-- ██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║
-- ██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║
-- ╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝
--
-- Neovim Lua Config File - LaTeX Environment Setup Helper
-- LATEX SETUP HELPER

local M = {}

-- Simplify the dependency check function to prevent memory leaks
M.check_dependencies = function()
    local is_arch = vim.fn.filereadable("/etc/arch-release") == 1
    local is_debian = vim.fn.filereadable("/etc/debian_version") == 1
    local essential = {"texlive-most", "latexmk", "zathura"}
    local missing = {}

    if is_arch then
        for _, pkg in ipairs(essential) do
            if vim.fn.system("pacman -Q " .. pkg .. " 2>/dev/null") == "" then
                table.insert(missing, pkg)
            end
        end
    elseif is_debian then
        for _, pkg in ipairs(essential) do
            if vim.fn.system("dpkg -s " .. pkg .. " 2>/dev/null | grep 'Status: install'") == "" then
                table.insert(missing, pkg)
            end
        end
    else
        vim.notify("Unsupported package manager. Please install LaTeX dependencies manually.", vim.log.levels.WARN)
        return
    end

    if #missing > 0 then
        vim.notify("Missing LaTeX packages: " .. table.concat(missing, ", "), vim.log.levels.WARN)
    end
end

-- Single command with no complex callbacks
vim.api.nvim_create_user_command("LaTeXCheckDeps",
    function()
        M.check_dependencies()
    end,
    { desc = "Check LaTeX dependencies" }
)

return M
