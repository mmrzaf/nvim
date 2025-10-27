return {
	{ "junegunn/fzf", build = "./install --bin", enabled = true },
	{
		"ibhagwan/fzf-lua",
		cmd = "FzfLua",
		opts = function(_, _)
			local fzf = require("fzf-lua")
			local config = fzf.config
			local actions = fzf.actions
			local function symbols_filter(_)
				return true
			end
			config.defaults.keymap.fzf["ctrl-q"] = "select-all+accept"
			config.defaults.keymap.fzf["ctrl-u"] = "half-page-up"
			config.defaults.keymap.fzf["ctrl-d"] = "half-page-down"
			config.defaults.keymap.fzf["ctrl-x"] = "jump"
			config.defaults.keymap.fzf["ctrl-f"] = "preview-page-down"
			config.defaults.keymap.fzf["ctrl-b"] = "preview-page-up"
			config.defaults.keymap.builtin["<c-f>"] = "preview-page-down"
			config.defaults.keymap.builtin["<c-b>"] = "preview-page-up"
			local img_previewer
			for _, v in ipairs({
				{ cmd = "ueberzug", args = {} },
				{ cmd = "chafa", args = { "{file}", "--format=symbols" } },
				{ cmd = "viu", args = { "-b" } },
			}) do
				if vim.fn.executable(v.cmd) == 1 then
					img_previewer = vim.list_extend({ v.cmd }, v.args)
					break
				end
			end
			return {
				fzf_colors = true,
				fzf_opts = { ["--no-scrollbar"] = true },
				defaults = { formatter = "path.dirname_first" },
				previewers = {
					builtin = {
						extensions = {
							png = img_previewer,
							jpg = img_previewer,
							jpeg = img_previewer,
							gif = img_previewer,
							webp = img_previewer,
						},
						ueberzug_scaler = "fit_contain",
					},
				},
				ui_select = function(fzf_opts, items)
					local title = " " .. vim.trim((fzf_opts.prompt or "Select"):gsub("%s*:%s*$", "")) .. " "
					return vim.tbl_deep_extend(
						"force",
						fzf_opts,
						{ prompt = " ", winopts = { title = title, title_pos = "center" } },
						fzf_opts.kind == "codeaction"
								and {
									winopts = {
										layout = "vertical",
										height = math.floor(math.min(vim.o.lines * 0.8 - 16, #items + 4) + 0.5) + 16,
										width = 0.5,
										preview = not vim.tbl_isempty(
											vim.lsp.get_clients({ bufnr = 0, name = "vtsls" })
										) and {
											layout = "vertical",
											vertical = "down:15,border-top",
											hidden = "hidden",
										} or { layout = "vertical", vertical = "down:15,border-top" },
									},
								}
							or {
								winopts = {
									width = 0.5,
									height = math.floor(math.min(vim.o.lines * 0.8, #items + 4) + 0.5),
								},
							}
					)
				end,
				winopts = { width = 0.8, height = 0.8, row = 0.5, col = 0.5, preview = { scrollchars = { "┃", "" } } },
				files = { cwd_prompt = false },
				grep = {},
				lsp = {
					symbols = {
						symbol_hl = function(s)
							return "TroubleIcon" .. s
						end,
						symbol_fmt = function(s)
							return s:lower() .. "	"
						end,
						child_prefix = false,
					},
					code_actions = { previewer = vim.fn.executable("delta") == 1 and "codeaction_native" or nil },
				},
			}
		end,
		config = function(_, opts)
			require("fzf-lua").setup(opts)
		end,
		keys = {
			{ "<c-j>", "<c-j>", ft = "fzf", mode = "t", nowait = true },
			{ "<c-k>", "<c-k>", ft = "fzf", mode = "t", nowait = true },
			-- buffers/files/search
			{ "<leader>,", "<cmd>FzfLua buffers sort_mru=true sort_lastused=true<cr>", desc = "Switch Buffer" },
			{ "<leader>fb", "<cmd>FzfLua buffers sort_mru=true sort_lastused=true<cr>", desc = "Buffers" },
			{ "<leader>fg", "<cmd>FzfLua git_files<cr>", desc = "Find Files (git-files)" },
			{ "<leader>ff", "<cmd>FzfLua files<CR>", desc = "Find files (fzf)" },
			{ "<leader>fr", "<cmd>FzfLua oldfiles<cr>", desc = "Recent" },
			-- git
			{ "<leader>gc", "<cmd>FzfLua git_commits<CR>", desc = "Commits" },
			{ "<leader>gs", "<cmd>FzfLua git_status<CR>", desc = "Status" },
			-- search
			{ "<leader>/", "<cmd>FzfLua live_grep<cr>", desc = "Search in project (rg+fzf)" },
			{ '<leader>s"', "<cmd>FzfLua registers<cr>", desc = "Registers" },
			{ "<leader>sa", "<cmd>FzfLua autocmds<cr>", desc = "Auto Commands" },
			{ "<leader>sb", "<cmd>FzfLua grep_curbuf<cr>", desc = "Buffer" },
			{ "<leader>sc", "<cmd>FzfLua command_history<cr>", desc = "Command History" },
			{ "<leader>sC", "<cmd>FzfLua commands<cr>", desc = "Commands" },
			{ "<leader>sd", "<cmd>FzfLua diagnostics_document<cr>", desc = "Document Diagnostics" },
			{ "<leader>sD", "<cmd>FzfLua diagnostics_workspace<cr>", desc = "Workspace Diagnostics" },
			{ "<leader>sh", "<cmd>FzfLua help_tags<cr>", desc = "Help Pages" },
			{ "<leader>sH", "<cmd>FzfLua highlights<cr>", desc = "Search Highlight Groups" },
			{ "<leader>sj", "<cmd>FzfLua jumps<cr>", desc = "Jumplist" },
			{ "<leader>sk", "<cmd>FzfLua keymaps<cr>", desc = "Key Maps" },
			{ "<leader>sl", "<cmd>FzfLua loclist<cr>", desc = "Location List" },
			{ "<leader>sM", "<cmd>FzfLua man_pages<cr>", desc = "Man Pages" },
			{ "<leader>sm", "<cmd>FzfLua marks<cr>", desc = "Jump to Mark" },
			{ "<leader>sR", "<cmd>FzfLua resume<cr>", desc = "Resume" },
			{
				"<leader>ss",
				function()
					require("fzf-lua").lsp_document_symbols({
						regex_filter = function()
							return true
						end,
					})
				end,
				desc = "Goto Symbol",
			},
			{
				"<leader>sS",
				function()
					require("fzf-lua").lsp_live_workspace_symbols({
						regex_filter = function()
							return true
						end,
					})
				end,
				desc = "Goto Symbol (Workspace)",
			},
			-- convenience
			{ "<leader><leader>", "<cmd>FzfLua files<CR>", desc = "Find files (fzf)" },
		},
	},
}
