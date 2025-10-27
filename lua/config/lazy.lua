local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable",
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
	spec = { { import = "plugins" } },
	defaults = { lazy = true, version = false },
	install = { colorscheme = {} },
	change_detection = { enabled = false },
	performance = {
		rtp = {
			disabled_plugins = {
				"gzip",
				"tarPlugin",
				"zipPlugin",
				"matchparen",
				"matchit",
				"tohtml",
				"tutor",
				--"shada",
				"spellfile",
			},
		},
	},
})
