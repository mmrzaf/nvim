return {
	{
		"akinsho/toggleterm.nvim",
		version = "*",
		cmd = { "ToggleTerm", "TermExec" },
		keys = {
			{ "<leader>tt", "<cmd>ToggleTerm direction=float<cr>", desc = "Toggle terminal" },
		},
		opts = {
			size = 12,
			open_mapping = [[<Nop>]],
			shade_terminals = false,
			direction = "float",
			float_opts = {
				border = "rounded",
				title = "Terminal ",
				title_pos = "center",
			},
		},
	},
}
