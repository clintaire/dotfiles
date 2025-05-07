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

-- Initialize kmap
local kmap = vim.keymap

-- Redo
kmap.set("n", "U", "<C-r>", { desc = "Redo" })

-- Simplified key mappings using Vim defaults where possible

local kmap = vim.keymap

-- WRAPPED LINE NAVIGATION: More intuitive navigation for wrapped lines
kmap.set('n', 'j', "v:count == 0 ? 'gj' : 'j'", {expr = true, desc = "Down (respects wrapped lines)"})
kmap.set('n', 'k', "v:count == 0 ? 'gk' : 'k'", {expr = true, desc = "Up (respects wrapped lines)"})

-- COMMON ACTIONS: Simple, memorable shortcuts
kmap.set("n", "<leader>w", ":w<CR>", { desc = "Save file" })
kmap.set("n", "<leader>q", ":q<CR>", { desc = "Quit" })
kmap.set("n", "<leader>Q", ":q!<CR>", { desc = "Force quit" })

-- LINE OPERATIONS: Natural mnemonics for common operations
kmap.set("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move selected lines down" })
kmap.set("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move selected lines up" })

-- SPELL CHECKING: Simple toggle using mnemonic
kmap.set("n", "<leader>s", "<cmd>set spell!<CR>", { desc = "Toggle spell checking" })

-- ESCAPE: Quicker escape from insert mode
kmap.set("i", "jk", "<Esc>", { desc = "Exit insert mode" })

-- BUFFER NAVIGATION: Similar to browser tabs
kmap.set("n", "<Tab>", ":bnext<CR>", { desc = "Next buffer" })
kmap.set("n", "<S-Tab>", ":bprevious<CR>", { desc = "Previous buffer" })

-- Resize split windows using arrow keys
kmap.set("n", "<c-up>", "<c-w>-", { desc = "Resize split window up" })
kmap.set("n", "<c-down>", "<c-w>+", { desc = "Resize split window down" })
kmap.set("n", "<c-right>", "<c-w>>", { desc = "Resize split window right" })
kmap.set("n", "<c-left>", "<c-w><", { desc = "Resize split window left" })

-- Undo Tree
if vim.fn.exists(":UndotreeToggle") == 2 then
    kmap.set("n", "<leader>ut", vim.cmd.UndotreeToggle, { desc = "Toggle UndoTree" })
end

-- Basic spell checking mappings (simplified)
kmap.set("n", "z=", "<cmd>spellsuggest<cr>", { desc = "Show spelling suggestions" })
kmap.set("n", "<leader>ts", "<cmd>set spell!<cr>", { desc = "Toggle spell checking" })

-- CODE EXECUTION: Run code with code_runner
kmap.set("n", "<leader>r", ":RunCode<CR>", { desc = "Run code" })
kmap.set("n", "<leader>rf", ":RunFile<CR>", { desc = "Run current file" })
kmap.set("n", "<leader>rp", ":RunProject<CR>", { desc = "Run project" })
kmap.set("n", "<leader>rc", ":RunClose<CR>", { desc = "Close runner" })

-- DEBUGGING: DAP keymaps
kmap.set("n", "<leader>db", ":DapToggleBreakpoint<CR>", { desc = "Toggle breakpoint" })
kmap.set("n", "<leader>dc", ":DapContinue<CR>", { desc = "Start/continue debugging" })
kmap.set("n", "<leader>di", ":DapStepInto<CR>", { desc = "Step into" })
kmap.set("n", "<leader>do", ":DapStepOver<CR>", { desc = "Step over" })
kmap.set("n", "<leader>dt", ":DapTerminate<CR>", { desc = "Terminate debug session" })
kmap.set("n", "<leader>du", ":lua require('dapui').toggle()<CR>", { desc = "Toggle DAP UI" })
