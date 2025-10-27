return {
	{ "nvim-tree/nvim-web-devicons", lazy = true },

	-- Statusline (stable, light)
	{
		"nvim-lualine/lualine.nvim",
		opts = { options = { theme = "auto", section_separators = "", component_separators = "" } },
	},

	-- Bufferline
	{
		"akinsho/bufferline.nvim",
		event = "VeryLazy",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		keys = {
			{ "<S-h>", "<cmd>BufferLineCyclePrev<cr>", desc = "Prev Buffer" },
			{ "<S-l>", "<cmd>BufferLineCycleNext<cr>", desc = "Next Buffer" },
			{ "[b", "<cmd>BufferLineCyclePrev<cr>", desc = "Prev Buffer" },
			{ "]b", "<cmd>BufferLineCycleNext<cr>", desc = "Next Buffer" },
			{ "[B", "<cmd>BufferLineMovePrev<cr>", desc = "Move buffer prev" },
			{ "]B", "<cmd>BufferLineMoveNext<cr>", desc = "Move buffer next" },
			{
				"<leader>c",
				function()
					local n = vim.api.nvim_get_current_buf()
					pcall(vim.api.nvim_buf_delete, n, {})
				end,
				desc = "Close buffer",
			},
		},
		opts = {
			options = {
				close_command = function(n)
					pcall(vim.api.nvim_buf_delete, n, {})
				end,
				right_mouse_command = function(n)
					pcall(vim.api.nvim_buf_delete, n, {})
				end,
				diagnostics = "nvim_lsp",
				always_show_bufferline = false,
				diagnostics_indicator = function(_, _, diag)
					local parts = {}
					if diag.error then
						table.insert(parts, " " .. diag.error)
					end
					if diag.warning then
						table.insert(parts, " " .. diag.warning)
					end
					return table.concat(parts, " ")
				end,
			},
		},
	},
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
