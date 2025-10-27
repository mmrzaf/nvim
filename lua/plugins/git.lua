return {
	{
		"lewis6991/gitsigns.nvim",
		event = "BufReadPre",
		opts = {
			signs = {
				add = { text = "▎" },
				change = { text = "▎" },
				delete = { text = "▁" },
				topdelete = { text = "▔" },
				changedelete = { text = "▎" },
			},
			signs_staged_enable = true,
			current_line_blame = false,
		},
	},
	{
		"kdheepak/lazygit.nvim",
		dependencies = {
			"nvim-lua/plenary.nvim",
		},
		cmd = "LazyGit",
		keys = {
			{ "<leader>gg", "<cmd>LazyGit<cr>", desc = "Open LazyGit" },
		},
		config = function()
			-- floating window settings (optional tweaks)
			vim.g.lazygit_floating_window_use_plenary = 1
			vim.g.lazygit_floating_window_winblend = 0
			vim.g.lazygit_floating_window_scaling_factor = 0.9
			vim.g.lazygit_use_neovim_remote = 1
		end,
	},
}
