pcall(function()
	return vim.loader.enable()
end)
vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.opt.termguicolors = true

require("config.disable_builtins")
require("config.options")
require("config.keymaps")
require("config.autocmds")
require("config.lazy")
require("dev").setup()
require("startscreen").setup({
	title = "  󰧮  Welcome  ",
	header = { "move the work forward" },
	border = "rounded",
})

vim.cmd.colorscheme("kanagawa")
