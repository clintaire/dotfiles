local vim = vim

vim.g.mapleader = " "

-- Escape to normal mode the easy way
vim.keymap.set("i", "jk", "<Esc>")

-- Move selected lines in visual mode up or down
vim.keymap.set("v", "<A-Down>", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "<A-Up>", ":m '<-2<CR>gv=gv")

-- Tabline navigation (similar to Ctrl+Tab in editors)
vim.keymap.set("n", "<C-Tab>", ":TablineBufferNext<CR>", { silent = true })
vim.keymap.set("n", "<C-S-Tab>", ":TablineBufferPrevious<CR>", { silent = true })

-- Window hopping with Ctrl (like VSCode's Ctrl+Arrow)
vim.keymap.set("n", "<C-Left>", "<C-w>h")
vim.keymap.set("n", "<C-Down>", "<C-w>j")
vim.keymap.set("n", "<C-Up>", "<C-w>k")
vim.keymap.set("n", "<C-Right>", "<C-w>l")

-- Split windows (Ctrl+\ for vertical, Ctrl+- for horizontal)
vim.keymap.set("n", "<C-\\>", ":vs<CR>")
vim.keymap.set("n", "<C-->", ":split<CR>")

-- Buffers (Ctrl+Tab and Ctrl+Shift+Tab for next/previous buffer)
vim.keymap.set("n", "<C-Tab>", ":bnext<CR>", { silent = true })
vim.keymap.set("n", "<C-S-Tab>", ":bprevious<CR>", { silent = true })
vim.keymap.set("n", "<C-w>", ":bd<CR>", { silent = true }) -- Close buffer (like Ctrl+W)

-- Open terminal (Ctrl+`)
vim.keymap.set("n", "<C-`>", ":below 18 sp<CR>:term<CR>i", { silent = true })

-- Copy/Paste (Ctrl+C, Ctrl+V)
vim.keymap.set("v", "<C-c>", '"+y')
vim.keymap.set("n", "<C-v>", '"+p')
vim.keymap.set("v", "<C-v>", '"+p')

-- Yank to clipboard (Ctrl+Shift+C)
vim.keymap.set("n", "<C-S-c>", '"+y')
vim.keymap.set("v", "<C-S-c>", '"+y')

-- Find and replace (Ctrl+F for search, Ctrl+H for replace)
vim.keymap.set("n", "<C-f>", "/")
vim.keymap.set("n", "<C-h>", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])

-- Save file (Ctrl+S)
vim.keymap.set("n", "<C-s>", ":w<CR>")

-- Close Neovim (Ctrl+Q)
vim.keymap.set("n", "<C-q>", ":q<CR>")

-- Format code (Alt+Shift+F)
vim.keymap.set("n", "<A-S-f>", function()
  vim.lsp.buf.format()
end)

-- Navigate diagnostics (F8 for next, Shift+F8 for previous)
vim.keymap.set("n", "<F8>", "<cmd>cnext<CR>zz")
vim.keymap.set("n", "<S-F8>", "<cmd>cprev<CR>zz")

-- Set file executable (Ctrl+E)
vim.keymap.set("n", "<C-e>", "<cmd>!chmod +x %<CR>", { silent = true })
