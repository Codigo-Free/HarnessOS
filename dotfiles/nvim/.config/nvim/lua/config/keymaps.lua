-- HarnessOS — Neovim Keymaps
local map = vim.keymap.set

-- Better escape
map("i", "jk", "<Esc>", { desc = "Exit insert mode" })
map("i", "kj", "<Esc>", { desc = "Exit insert mode" })

-- Window navigation (vim-style)
map("n", "<C-h>", "<C-w>h", { desc = "Focus left window" })
map("n", "<C-j>", "<C-w>j", { desc = "Focus lower window" })
map("n", "<C-k>", "<C-w>k", { desc = "Focus upper window" })
map("n", "<C-l>", "<C-w>l", { desc = "Focus right window" })

-- Resize windows
map("n", "<C-Up>",    ":resize +2<CR>",          { silent = true })
map("n", "<C-Down>",  ":resize -2<CR>",           { silent = true })
map("n", "<C-Left>",  ":vertical resize -2<CR>",  { silent = true })
map("n", "<C-Right>", ":vertical resize +2<CR>",  { silent = true })

-- Move lines up/down
map("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
map("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })

-- Keep cursor centered
map("n", "<C-d>", "<C-d>zz")
map("n", "<C-u>", "<C-u>zz")
map("n", "n", "nzzzv")
map("n", "N", "Nzzzv")

-- Buffer navigation
map("n", "<S-l>", ":bnext<CR>",     { silent = true, desc = "Next buffer" })
map("n", "<S-h>", ":bprevious<CR>", { silent = true, desc = "Prev buffer" })
map("n", "<leader>bd", ":bdelete<CR>", { desc = "Delete buffer" })

-- File tree (nvim-tree / oil)
map("n", "<leader>e", ":NvimTreeToggle<CR>", { desc = "Toggle file tree" })

-- Telescope
map("n", "<leader>ff", "<cmd>Telescope find_files<CR>",   { desc = "Find files" })
map("n", "<leader>fg", "<cmd>Telescope live_grep<CR>",    { desc = "Live grep" })
map("n", "<leader>fb", "<cmd>Telescope buffers<CR>",      { desc = "Buffers" })
map("n", "<leader>fh", "<cmd>Telescope help_tags<CR>",    { desc = "Help tags" })
map("n", "<leader>fr", "<cmd>Telescope oldfiles<CR>",     { desc = "Recent files" })

-- LSP (set in lsp.lua via on_attach)

-- Save / Quit
map("n", "<leader>w", ":w<CR>",  { desc = "Save" })
map("n", "<leader>q", ":q<CR>",  { desc = "Quit" })
map("n", "<leader>Q", ":qa!<CR>", { desc = "Force quit all" })

-- Clear search highlight
map("n", "<Esc>", ":noh<CR>", { silent = true })

-- AI Copilot suggestion accept
-- (copilot.lua will override Tab in insert mode)
