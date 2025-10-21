return {
	{
		"neovim/nvim-lspconfig",
		event = { "BufReadPre", "BufNewFile" },
		dependencies = { "mason-org/mason.nvim", "WhoIsSethDaniel/mason-tool-installer.nvim" },
		config = function()
			-- Diagnostics UX
			local signs = { Error = "", Warn = "", Hint = "", Info = "" }
			vim.diagnostic.config({
				signs = {
					text = {
						[vim.diagnostic.severity.ERROR] = signs.Error,
						[vim.diagnostic.severity.WARN] = signs.Warn,
						[vim.diagnostic.severity.HINT] = signs.Hint,
						[vim.diagnostic.severity.INFO] = signs.Info,
					},
				},
				virtual_text = { spacing = 2, prefix = "●" },
				float = { border = "rounded" },
				severity_sort = true,
				update_in_insert = false,
			})
			local capabilities = vim.lsp.protocol.make_client_capabilities()
			local ok_blink, blink = pcall(require, "blink.cmp")
			if ok_blink and blink.get_lsp_capabilities then
				capabilities = blink.get_lsp_capabilities(capabilities)
			end
			-- LSP attach: buffer-local keymaps
			vim.api.nvim_create_autocmd("LspAttach", {
				group = vim.api.nvim_create_augroup("lsp-attach", { clear = true }),
				callback = function(args)
					local bufnr = args.buf
					local client = vim.lsp.get_client_by_id(args.data.client_id)
					local function bmap(mode, lhs, rhs, desc)
						vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
					end
					bmap("n", "gd", vim.lsp.buf.definition, "LSP: definition")
					bmap("n", "gr", vim.lsp.buf.references, "LSP: references")
					bmap("n", "K", vim.lsp.buf.hover, "LSP: hover")
					bmap("n", "gi", vim.lsp.buf.implementation, "LSP: implementation")
					bmap("n", "<leader>rn", vim.lsp.buf.rename, "LSP: rename")
					bmap("n", "<leader>ca", vim.lsp.buf.code_action, "LSP: code action")
					bmap({ "n", "v" }, "<leader>cf", function()
						vim.lsp.buf.format({ async = false })
					end, "LSP: format")
					if
						vim.lsp.inlay_hint
						and client
						and client.server_capabilities
						and client.server_capabilities.inlayHintProvider
					then
						pcall(vim.lsp.inlay_hint.enable, true, { bufnr = bufnr })
					end
				end,
			})

			-- 0.11-native LSP config/enable
			local lsp = vim.lsp
			lsp.config("lua_ls", {
				settings = {
					Lua = {
						diagnostics = { globals = { "vim" } },
						workspace = { checkThirdParty = false },
						format = { enable = false },
					},
				},
			})
			lsp.config("basedpyright", {
				settings = {
					basedpyright = {
						analysis = {
							diagnosticMode = "openFilesOnly",
							typeCheckingMode = "recommended",
							disableOrganizeImports = true,
						},
					},
				},
			})
			lsp.config("ruff", { })
			lsp.config("vtsls", {
				filetypes = { "typescript", "javascript", "typescriptreact", "javascriptreact" },
				settings = {
					typescript = {
						inlayHints = {
							parameterTypes = { enabled = true },
							functionLikeReturnTypes = { enabled = true },
						},
						suggest = { completeFunctionCalls = true },
					},
				},
			})
			lsp.config("gopls", {
				settings = {
					gopls = { analyses = { unusedparams = true, shadow = true }, staticcheck = true, gofumpt = true },
				},
			})
			lsp.config("bashls", {})
			lsp.config("jsonls", {})
			lsp.config("yamlls", {})
			lsp.config("eslint", {
				settings = {
					format = false,
					workingDirectory = { mode = "auto" },
					codeActionOnSave = { enable = true, rules = { "all" } },
					experimental = { useFlatConfig = true },
				},
			})

			lsp.enable({ "lua_ls", "basedpyright", "ruff", "vtsls", "gopls", "bashls", "jsonls", "yamlls", "eslint" })
		end,
	},
}
