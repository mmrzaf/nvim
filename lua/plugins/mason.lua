return {
	{
		"mason-org/mason.nvim",
		build = ":MasonUpdate",
		config = true,
		lazy = false,
		cmd = { "Mason", "MasonInstall", "MasonUpdate" },
	},
	{
		"mason-org/mason-lspconfig.nvim",
		dependencies = { "mason-org/mason.nvim" },
		event = "VeryLazy",
	},

	{
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		lazy = false,
		dependencies = { "mason-org/mason.nvim" },
		config = function()
			require("mason-tool-installer").setup({
				run_on_start = true,
				start_delay = 150,
				ensure_installed = {
					-- LSP servers
					"lua-language-server",

					-- Python
					"ty",
					"ruff",

					"vtsls",
					"gopls",
					"bash-language-server",
					"json-lsp",
					"yaml-language-server",
					"eslint-lsp",
					"rust-analyzer",
					"clangd",
					"sqlls",

					-- formatters
					"stylua",
					"biome",
					"prettierd",
					"jq",
					"gofumpt",
					"goimports",
					"google-java-format",
					"ktlint",
					"ktfmt",
					"clang-format",
					"shfmt",
					"sqlfluff",
					"xmlformatter",
					"taplo",

					-- linters / extras
					"golangci-lint",
					"eslint_d",
					"stylelint",
				},
			})
		end,
	},
}
