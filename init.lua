pcall(function() return vim.loader.enable() end)
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '
require('config.disable_builtins')
require('config.options')
require('config.keymaps')
require('config.autocmds')
require('config.lazy')

require('clipboard').setup()
require('dev').setup()


--vim.cmd.colorscheme("catppuccin")
vim.cmd.colorscheme("kanagawa")
-- vim.cmd.colorscheme('default')
