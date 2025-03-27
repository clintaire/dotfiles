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
    if not is_arch then
        return
    end

    -- Check essential dependencies only
    local essential = {"texlive-most", "latexmk", "zathura"}
    local missing = {}

    for _, pkg in ipairs(essential) do
        if vim.fn.system("pacman -Q " .. pkg .. " 2>/dev/null") == "" then
            table.insert(missing, pkg)
        end
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
