return {
	{
		"saghen/blink.cmp",
		version = "1.*",
		dependencies = { "rafamadriz/friendly-snippets" },
		event = { "InsertEnter", "CmdlineEnter" },
		opts = function()
			---@module 'blink.cmp'
			---@type blink.cmp.Config
			return {
				appearance = { nerd_font_variant = "mono" },
				keymap = {
					preset = "none",
					["<C-space>"] = { "show", "show_documentation", "hide_documentation" },
					["<C-e>"] = { "hide", "fallback" },
					["<CR>"] = { "accept", "fallback" },

					["<Tab>"] = { "snippet_forward", "fallback" },
					["<S-Tab>"] = { "snippet_backward", "fallback" },

					["<Up>"] = { "select_prev", "fallback" },
					["<Down>"] = { "select_next", "fallback" },
					["<C-p>"] = { "select_prev", "fallback_to_mappings" },
					["<C-n>"] = { "select_next", "fallback_to_mappings" },

					["<C-b>"] = { "scroll_documentation_up", "fallback" },
					["<C-f>"] = { "scroll_documentation_down", "fallback" },

					["<C-k>"] = { "show_signature", "hide_signature", "fallback" },
				},
				completion = {
					keyword = { range = "full" },
					trigger = { show_on_keyword = true },
					list = { selection = { preselect = true, auto_insert = true } },
					documentation = { auto_show = true, auto_show_delay_ms = 250 },
					ghost_text = { enabled = true },
					accept = { auto_brackets = { enabled = true } },
					menu = {
						auto_show = true,
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
