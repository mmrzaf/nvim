return {
	{
		"saghen/blink.cmp",
		version = "1.*",
		dependencies = { "rafamadriz/friendly-snippets" },
		event = { "InsertEnter", "CmdlineEnter" },
		opts = function()
			---@type blink.cmp.Config
			return {
				appearance = { nerd_font_variant = "mono" },
				keymap = {
					preset = "default",
					["<C-f>"] = { "scroll_documentation_down", "fallback" },
					["<C-b>"] = { "scroll_documentation_up", "fallback" },
					["<Tab>"] = { "snippet_forward", "fallback" },
					["<S-Tab>"] = { "snippet_backward", "fallback" },
				},
				completion = {
					trigger = { show_on_keyword = true },
					list = { selection = { preselect = true, auto_insert = true } },
					documentation = { auto_show = true, auto_show_delay_ms = 250 },
					ghost_text = { enabled = true },
					accept = { auto_brackets = { enabled = true } },
					menu = {
						auto_show = false,
						draw = { columns = { { "label", "label_description", gap = 1 }, { "kind_icon", "kind" } } },
					},
				},
				signature = { enabled = true, window = { show_documentation = true } },
				fuzzy = { implementation = "prefer_rust_with_warning" },
				sources = {
					default = { "lsp", "path", "snippets", "buffer" },
					-- per_filetype = { sql = { 'dadbod' } }, -- example of adding per-filetype providers
				},
				snippets = { preset = "default" },
				cmdline = {
					enabled = true,
					keymap = { preset = "inherit" },
					completion = {
						menu = {
							auto_show = function()
								return vim.fn.getcmdtype() == ":"
							end,
						},
					},
				},
				term = { enabled = true },
			}
		end,
		config = function(_, opts)
			require("blink.cmp").setup(opts)
		end,
		opts_extend = { "sources.default" },
	},
}
