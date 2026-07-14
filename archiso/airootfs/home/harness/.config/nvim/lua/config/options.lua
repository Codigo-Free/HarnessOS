-- HarnessOS — Neovim Options
local opt = vim.opt

opt.number         = true
opt.relativenumber = true
opt.signcolumn     = "yes"
opt.cursorline     = true
opt.termguicolors  = true
opt.background     = "dark"

opt.tabstop        = 4
opt.shiftwidth     = 4
opt.expandtab      = true
opt.smartindent    = true

opt.wrap           = false
opt.linebreak      = true

opt.splitbelow     = true
opt.splitright     = true

opt.ignorecase     = true
opt.smartcase      = true
opt.hlsearch       = false
opt.incsearch      = true

opt.scrolloff      = 8
opt.sidescrolloff  = 8

opt.updatetime     = 200
opt.timeoutlen     = 300

opt.undofile       = true
opt.swapfile       = false
opt.backup         = false

opt.clipboard      = "unnamedplus"

opt.completeopt    = "menu,menuone,noselect"
opt.pumheight      = 10

opt.foldmethod     = "expr"
opt.foldexpr       = "nvim_treesitter#foldexpr()"
opt.foldenable     = false

vim.g.mapleader      = " "
vim.g.maplocalleader = "\\"
