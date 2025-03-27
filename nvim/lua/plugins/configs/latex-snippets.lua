--
-- ███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗
-- ████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║
-- ██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║
-- ██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║
-- ██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║
-- ╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝
--
-- Neovim Lua Config File - LaTeX Snippets
-- LATEX SNIPPETS

local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node

-- Only load in LaTeX files
local tex_utils = {}
tex_utils.in_mathzone = function()
    return vim.fn["vimtex#syntax#in_mathzone"]() == 1
end
tex_utils.in_text = function()
    return not tex_utils.in_mathzone()
end

local M = {}

M.setup = function()
    ls.add_snippets("tex", {
        -- Basic document structure
        s("begin", {
            t("\\begin{"), i(1, "environment"), t("}"),
            i(2),
            t({"", "\\end{"}), f(function(args) return args[1][1] end, {1}), t("}")
        }),

        -- Document template
        s("template", {
            t({"\\documentclass{article}",
               "\\usepackage[utf8]{inputenc}",
               "\\usepackage[T1]{fontenc}",
               "\\usepackage{amsmath}",
               "\\usepackage{amsfonts}",
               "\\usepackage{amssymb}",
               "\\usepackage{graphicx}",
               "\\usepackage[english]{babel}", -- Explicitly set English language
               "",
               "\\title{"}), i(1, "Title"), t({"}",
               "\\author{"}), i(2, "Author"), t({"}",
               "\\date{\\today}",
               "",
               "\\begin{document}",
               "",
               "\\maketitle",
               "",
               ""}), i(0), t({"",
               "",
               "\\end{document}"
               })
        }),

        -- Math environments
        s("beg", {
            t("\\begin{equation}"),
            t({"", "\t"}), i(1),
            t({"", "\\end{equation}"}),
        }),

        s("align", {
            t("\\begin{align}"),
            t({"", "\t"}), i(1),
            t({"", "\\end{align}"}),
        }),

        -- Theorem environments
        s("thm", {
            t("\\begin{theorem}"),
            t({"", "\t"}), i(1),
            t({"", "\\end{theorem}"}),
        }),

        s("lemma", {
            t("\\begin{lemma}"),
            t({"", "\t"}), i(1),
            t({"", "\\end{lemma}"}),
        }),

        s("proof", {
            t("\\begin{proof}"),
            t({"", "\t"}), i(1),
            t({"", "\\end{proof}"}),
        }),

        -- Math-specific snippets (only expand in math mode)
        s({trig="([^\\])ff", wordTrig=false, regTrig=true, condition=tex_utils.in_mathzone}, {
            f(function(_, snip) return snip.captures[1] end, {}),
            t("\\frac{"), i(1), t("}{"), i(2), t("}")
        }),

        s({trig="([^\\])sum", wordTrig=false, regTrig=true, condition=tex_utils.in_mathzone}, {
            f(function(_, snip) return snip.captures[1] end, {}),
            t("\\sum_{"), i(1, "i=1"), t("}^{"), i(2, "n"), t("} ")
        }),

        s({trig="([^\\])lim", wordTrig=false, regTrig=true, condition=tex_utils.in_mathzone}, {
            f(function(_, snip) return snip.captures[1] end, {}),
            t("\\lim_{"), i(1, "n \\to \\infty"), t("} ")
        }),

        s({trig="([^\\])int", wordTrig=false, regTrig=true, condition=tex_utils.in_mathzone}, {
            f(function(_, snip) return snip.captures[1] end, {}),
            t("\\int_{"), i(1, "a"), t("}^{"), i(2, "b"), t("} "), i(3), t(" \\, d"), i(4, "x")
        }),
    })
end

return M
