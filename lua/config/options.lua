local o = vim.opt

o.number = true
o.relativenumber = true
o.signcolumn = "yes"
o.cursorline = false
o.termguicolors = true
o.background = "dark"
o.mouse = "a"
o.confirm = true
o.hidden = true

o.splitbelow = true
o.splitright = true
o.equalalways = false

o.ignorecase = true
o.smartcase = true
o.incsearch = true
o.hlsearch = true

o.scrolloff = 6
o.sidescrolloff = 8
o.wrap = false
o.linebreak = true

o.list = true
o.fillchars:append({ eob = " " })

o.listchars = {
  tab = "» ",
  trail = "·",
  extends = "›",
  precedes = "‹",
  nbsp = "␣",
}

o.expandtab = true
o.shiftwidth = 4
o.tabstop = 4
o.softtabstop = 4
o.shiftround = true
o.autoindent = true

o.swapfile = true
o.backup = false
o.writebackup = true
o.undofile = true
o.undolevels = 10000

o.timeoutlen = 400
o.updatetime = 200
o.completeopt = { "menu", "menuone", "noselect" }
o.pumheight = 12

o.laststatus = 3
o.showmode = true
o.showtabline = 1
o.cmdheight = 1
o.winborder = "rounded"
o.shortmess:append({ I = true, c = true })

o.grepprg = "rg --vimgrep --smart-case --hidden --glob=!.git"
o.grepformat = "%f:%l:%c:%m"
o.wildmode = { "longest:full", "full" }
o.wildignorecase = true
o.autoread = true

o.statusline = " %f %m%r%=%y  %l:%c  %p%% "
