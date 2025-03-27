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
-- MAPPINGS

-- Redo
kmap.set("n", "U", "<C-r>", { desc = "Redo" })

-- Split navigation using CTRL + {j, k, h, l}
kmap.set("n", "<c-k>", "<c-w>k", { desc = "Split window up" })
kmap.set("n", "<c-j>", "<c-w>j", { desc = "Split window down" })
kmap.set("n", "<c-l>", "<c-w>l", { desc = "Split window right" })
kmap.set("n", "<c-h>", "<c-w>h", { desc = "Split window left" })

-- Resize split windows using arrow keys
kmap.set("n", "<c-up>", "<c-w>-", { desc = "Resize split window up" })
kmap.set("n", "<c-down>", "<c-w>+", { desc = "Resize split window down" })
kmap.set("n", "<c-right>", "<c-w>>", { desc = "Resize split window right" })
kmap.set("n", "<c-left>", "<c-w><", { desc = "Resize split window left" })

-- Undo Tree
kmap.set("n", "<leader>ut", vim.cmd.UndotreeToggle, { desc = "Toggle UndoTree" })

-- Basic spell checking mappings (simplified)
kmap.set("n", "z=", "<cmd>spellsuggest<cr>", { desc = "Show spelling suggestions" })
kmap.set("n", "<leader>ts", "<cmd>set spell!<cr>", { desc = "Toggle spell checking" })
