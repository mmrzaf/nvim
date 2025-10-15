return {
	{
		"nvim-treesitter/nvim-treesitter",
		event = "BufReadPre",
		build = ":TSUpdate",
		opts = {
			ensure_installed = {
				"lua",
				"vim",
				"vimdoc",
				"bash",
				"json",
				"yaml",
				"markdown",
				"regex",
				"python",
				"javascript",
				"typescript",
				"tsx",
				"go",
				"html",
				"css",
				"toml",
				"java",
				"kotlin",
			},
			highlight = { enable = true, additional_vim_regex_highlighting = false },
			indent = { enable = true },
			incremental_selection = {
				enable = true,
				keymaps = { init_selection = "gnn", node_incremental = "grn", node_decremental = "grm" },
			},
		},
		config = function(_, opts)
			require("nvim-treesitter.configs").setup(opts)
		end,
	},
}
