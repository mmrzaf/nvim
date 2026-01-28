return {
	{
		"catppuccin/nvim",
		name = "catppuccin",
		priority = 1000,
		config = function()
			require("catppuccin").setup({
				flavour = "macchiato",
				background = { light = "latte", dark = "mocha" },
				transparent_background = false,
				float = { transparent = false, solid = false },
				show_end_of_buffer = false,
				term_colors = false,
				dim_inactive = { enabled = false, shade = "dark", percentage = 0.15 },
				no_italic = false,
				no_bold = false,
				no_underline = false,
				styles = {
					comments = { "italic" },
					conditionals = { "italic" },
					loops = {},
					functions = {},
					keywords = {},
					strings = {},
					variables = {},
					numbers = {},
					booleans = {},
					properties = {},
					types = {},
					operators = {},
				},
				color_overrides = {},
				custom_highlights = {},
				default_integrations = true,
				auto_integrations = false,
				integrations = {
					cmp = true,
					gitsigns = true,
					nvimtree = true,
					treesitter = true,
					neotree = true,
					telescope = true,
					notify = false,
					mini = { enabled = true, indentscope_color = "" },
					fzf = true,
					lualine = true,
					mason = true,
				},
			})

			vim.cmd.colorscheme("catppuccin")
		end,
	},
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
		"folke/tokyonight.nvim",
		lazy = false,
		priority = 1000,
		config = function()
			require("tokyonight").setup({
				style = "night", -- or "storm"
				transparent = false,
				styles = {
					sidebars = "dark",
					floats = "dark",
				},
				on_colors = function(colors)
					colors.bg = "#000000"
					colors.bg_dark = "#000000"
				end,
			})
			vim.cmd.colorscheme("tokyonight")
		end,
	},
}
