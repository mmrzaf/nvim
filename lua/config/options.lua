local o = vim.opt
vim.o.laststatus = 3
vim.o.showmode = false
vim.o.termguicolors = true
vim.o.mouse = "a"
vim.o.clipboard = "unnamedplus"
vim.o.timeoutlen = 400
vim.o.updatetime = 200
vim.o.completeopt = "menu,menuone,noselect"

o.number = true
o.relativenumber = true
o.signcolumn = "yes"
o.cursorline = false

o.splitbelow = true
o.splitright = true

o.ignorecase = true
o.smartcase = true

o.scrolloff = 6
o.sidescrolloff = 8

o.wrap = false
o.list = true
o.listchars = { tab = "→ ", trail = "·", nbsp = "␣" }

o.swapfile = false
o.backup = false
o.undofile = true

vim.o.cmdheight = 0
vim.o.showtabline = 2

vim.opt.shortmess:append("c")
