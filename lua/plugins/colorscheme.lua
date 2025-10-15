return {
	{
		"rebelot/kanagawa.nvim",
		name = "kanagawa",
		priority = 1000,
		opts = {
			compile = true,
			theme = "dragon",
			overrides = function(colors)
				return {
					Normal = { bg = colors.theme.ui.bg_dim },
				}
			end,
		},
	},
	{
		"catppuccin/nvim",
		name = "catppuccin",
		lazy = true,
		priority = 900,
		opts = {
			flavour = "mocha",
			transparent_background = false,
			styles = {
				comments = { "italic" },
				conditionals = {}, -- "none"
				loops = {}, -- "none"
				functions = { "bold" },
				keywords = {}, -- "none"
				strings = {}, -- "none"
				variables = {}, -- "none"
			},
			integrations = {
				fzf = true,
				lualine = true,
				mason = true,
				cmp = true,
				treesitter = true,
				gitsigns = true,
			},
		},
	},
}
