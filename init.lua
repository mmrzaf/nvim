pcall(function()
	return vim.loader.enable()
end)
vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.opt.termguicolors = true

require("dev").setup()
require("config.disable_builtins")
require("config.options")
require("config.keymaps")
require("config.autocmds")
require("config.lazy")

vim.cmd.colorscheme("kanagawa")
