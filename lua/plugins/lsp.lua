return {
	-- Core installers
	{ "mason-org/mason.nvim",                     build = ":MasonUpdate", config = true },
	{ "mason-org/mason-lspconfig.nvim" },
	{ "WhoIsSethDaniel/mason-tool-installer.nvim" },

	-- Optional: JSON schemastore for better jsonls
	{ "b0o/schemastore.nvim",                     lazy = true },

	-- LSP
	{
		"neovim/nvim-lspconfig",
		event = { "BufReadPre", "BufNewFile" },
		dependencies = {
			"mason-org/mason.nvim",
			"mason-org/mason-lspconfig.nvim",
			"WhoIsSethDaniel/mason-tool-installer.nvim",
			"b0o/schemastore.nvim",
		},
		config = function()
			---------------------------------------------------------------------------
			-- Mason + friends
			---------------------------------------------------------------------------
			local mason = require("mason")
			local mlsp = require("mason-lspconfig")
			local mti = require("mason-tool-installer")

			mason.setup()

			mti.setup({
				ensure_installed = {
					-- formatters
					"stylua",
					"biome",
					"prettierd",
					"jq",
					"gofumpt",
					"goimports",
					-- linters
					"ruff",
					"golangci-lint",
					"eslint_d",
					"stylelint",
				},
			})

			---------------------------------------------------------------------------
			-- UI & diagnostics
			---------------------------------------------------------------------------
			vim.diagnostic.config({
				signs = {
					text = {
						[vim.diagnostic.severity.ERROR] = "",
						[vim.diagnostic.severity.WARN] = "",
						[vim.diagnostic.severity.HINT] = "",
						[vim.diagnostic.severity.INFO] = "",
					},
				},
			})

			vim.diagnostic.config({
				virtual_text = { spacing = 2, prefix = "●" },
				float = { border = "rounded" },
				severity_sort = true,
				update_in_insert = false,
			})

			vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover,
				{ border = "rounded" })
			vim.lsp.handlers["textDocument/signatureHelp"] =
			    vim.lsp.with(vim.lsp.handlers.signature_help, { border = "rounded" })

			---------------------------------------------------------------------------
			-- Capabilities (blink.cmp if present)
			---------------------------------------------------------------------------
			local capabilities = vim.lsp.protocol.make_client_capabilities()
			local ok_blink, blink = pcall(require, "blink.cmp")
			if ok_blink and blink.get_lsp_capabilities then
				capabilities = blink.get_lsp_capabilities(capabilities)
			end

			---------------------------------------------------------------------------
			-- One place for buffer-local maps & inlay hints (0.11+ API)
			---------------------------------------------------------------------------
			vim.api.nvim_create_autocmd("LspAttach", {
				group = vim.api.nvim_create_augroup("lsp-attach", { clear = true }),
				callback = function(args)
					local bufnr = args.buf
					local bmap = function(mode, lhs, rhs, desc)
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

					-- Inlay hints: support both 0.11 signature and older fallback
					local ih = vim.lsp.inlay_hint
					if ih and ih.enable then
						pcall(ih.enable, true, { bufnr = bufnr }) -- 0.10+
					end
					local ih = vim.lsp.inlay_hint
					if ih then
						if type(ih.enable) == "function" then
							-- 0.11+: enable(bufnr, true)
							pcall(ih.enable, bufnr, true)
						else
							-- Older style: enable(true, { bufnr = bufnr })
							pcall(ih, bufnr, true)
						end
					end
				end,
			})


			---------------------------------------------------------------------------
			-- Servers via handlers table inside setup()
			---------------------------------------------------------------------------
			local lspconfig = require("lspconfig")

			mlsp.setup({
				ensure_installed = {
					"lua_ls",
					"basedpyright",
					"ruff",
					"vtsls",
					"gopls",
					"bashls",
					"jsonls",
					"eslint",
				},

				handlers = {
					-- Default handler (most servers)
					function(server)
						lspconfig[server].setup({
							capabilities = capabilities,
						})
					end,

					-- Lua
					["lua_ls"] = function()
						lspconfig.lua_ls.setup({
							capabilities = capabilities,
							settings = {
								Lua = {
									diagnostics = { globals = { "vim" } },
									workspace = { checkThirdParty = false },
									format = { enable = false }, -- use stylua
								},
							},
						})
					end,

					-- TypeScript/JavaScript via vtsls
					["vtsls"] = function()
						lspconfig.vtsls.setup({
							capabilities = capabilities,
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
					end,

					-- Go
					["gopls"] = function()
						lspconfig.gopls.setup({
							capabilities = capabilities,
							settings = {
								gopls = {
									analyses = { unusedparams = true, shadow = true },
									staticcheck = true,
									gofumpt = true,
								},
							},
						})
					end,

					-- Bash
					["bashls"] = function()
						lspconfig.bashls.setup({
							capabilities = capabilities,
						})
					end,

					-- JSON with schemastore (if available)
					["jsonls"] = function()
						local ok_ss, schemastore = pcall(require, "schemastore")
						lspconfig.jsonls.setup({
							capabilities = capabilities,
							settings = {
								json = {
									schemas = ok_ss and schemastore.json.schemas() or
									    nil,
									validate = { enable = true },
								},
							},
						})
					end,

					-- Python: basedpyright (types)
					["basedpyright"] = function()
						lspconfig.basedpyright.setup({
							capabilities = capabilities,
							settings = {
								basedpyright = {
									analysis = {
										diagnosticMode = "openFilesOnly",
										typeCheckingMode = "standard",
									},
								},
							},
						})
					end,

					-- Python: ruff (lint + quickfixes)
					["ruff"] = function()
						lspconfig.ruff.setup({
							capabilities = capabilities,
						})
					end,

					-- Optional: ESLint LSP
					["eslint"] = function()
						lspconfig.eslint.setup({
							capabilities = capabilities,
							settings = {
								format = false,
								workingDirectory = { mode = "auto" },
								codeActionOnSave = { enable = true, rules = { "all" } },
								experimental = { useFlatConfig = true },
							},
						})
					end,
				},
			})
		end,
	},
}
