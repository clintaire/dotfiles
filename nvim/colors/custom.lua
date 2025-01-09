-- ~/.config/nvim/colors/custom.lua

-- Define a utility function for setting highlights
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

-- Base colors
local colors = {
    background = "#1e1f22",
    foreground = "#a9b7c6",
    dim_foreground = "#787878",
    bright_foreground = "#a9b7c6",
    cursor = "#cc7832",
    search_match_bg = "#ff6b6b",
    selection_bg = "#4b2222",
    black = "#282828",
    red = "#cc7832",
    green = "#6a8759",
    yellow = "#cc7832",
    blue = "#6897bb",
    magenta = "#a9b7c6",
    cyan = "#6897bb",
    white = "#a9b7c6",
    bright_black = "#928374",
    bright_white = "#ffffff",
}

-- Apply colors to common groups
vim.cmd("highlight clear")
vim.o.background = "dark"
vim.g.colors_name = "custom"

-- Set general highlights
highlight("Normal", colors.foreground, colors.background)
highlight("CursorLine", nil, colors.dim_foreground)
highlight("Visual", nil, colors.selection_bg)
highlight("Search", colors.background, colors.search_match_bg)
highlight("IncSearch", colors.background, colors.search_match_bg)
highlight("Cursor", colors.cursor, colors.bright_foreground)
highlight("ColorColumn", nil, colors.selection_bg)

-- Syntax highlights
highlight("Comment", colors.dim_foreground, nil, "italic")
highlight("Constant", colors.yellow)
highlight("String", colors.green)
highlight("Identifier", colors.blue)
highlight("Function", colors.magenta)
highlight("Statement", colors.red)
highlight("Type", colors.blue)
highlight("Special", colors.cyan)
highlight("Error", colors.red, nil, "bold")
highlight("Todo", colors.magenta, nil, "bold")
