return {
	{
		"mfussenegger/nvim-lint",
		event = { "BufReadPost", "BufWritePost", "InsertLeave" },
		config = function()
			local lint = require("lint")
			lint.linters_by_ft = {
				javascript = { "eslint_d" },
				javascriptreact = { "eslint_d" },
				typescript = { "eslint_d" },
				typescriptreact = { "eslint_d" },
				css = { "stylelint" },
				python = { "ruff" },
				go = { "golangcilint" },
			}
			local grp = vim.api.nvim_create_augroup("nvim-lint", { clear = true })
			vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost", "InsertLeave" }, {
				group = grp,
				callback = function()
					lint.try_lint()
				end,
			})
		end,
	},
}
