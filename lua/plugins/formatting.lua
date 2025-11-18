return {
	{
		"stevearc/conform.nvim",
		event = { "VeryLazy" },
		keys = {
			{
				"<leader>f",
				function()
					require("conform").format({ async = true, lsp_fallback = true })
				end,
				desc = "Format file (on demand)",
				mode = "n",
			},
		},
		opts = {
			notify_on_error = false,
			format_on_save = false,
			-- format_on_save = function(bufnr)
			-- 	local max = 300 * 1024
			-- 	local ok, stats = pcall(vim.uv.fs_stat, vim.api.nvim_buf_get_name(bufnr))
			-- 	if ok and stats and stats.size > max then
			-- 		return nil
			-- 	end
			-- 	return { lsp_fallback = true, timeout_ms = 2000 }
			-- end,

			formatters_by_ft = {
				lua = { "stylua" },
				go = { "gofumpt", "goimports", stop_after_first = true },
				javascript = { "biome", "prettierd", "prettier", stop_after_first = true },
				typescript = { "biome", "prettierd", "prettier", stop_after_first = true },
				javascriptreact = { "biome", "prettierd", "prettier", stop_after_first = true },
				typescriptreact = { "biome", "prettierd", "prettier", stop_after_first = true },
				html = { "biome", "prettierd", "prettier", stop_after_first = true },
				css = { "biome", "prettierd", "prettier", stop_after_first = true },
				json = { "jq", "biome", "prettierd", "prettier", stop_after_first = true },
				yaml = { "prettierd", "prettier", stop_after_first = true },
				python = { "ruff_fix", "ruff_format", "black", stop_after_first = true },
				markdown = { "prettierd", "prettier", stop_after_first = true },
				java = { "google-java-format", stop_after_first = true },
				kotlin = { "ktfmt", stop_after_first = true },
				rust = { "rustfmt" },
				c = { "clang_format" },
				cpp = { "clang_format" },
				dart = { "dart_format" },
				sh = { "shfmt" },
				sql = { "sqlfluff", "pg_format", stop_after_first = true },
				xml = { "xmlformatter" },
				toml = { "taplo" },
			},
		},
	},
}
