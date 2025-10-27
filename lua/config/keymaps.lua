local function map(mode, lhs, rhs, opts)
	local o = { silent = true, noremap = true }
	if type(opts) == "string" then
		o.desc = opts
	elseif type(opts) == "table" then
		for k, v in pairs(opts) do
			o[k] = v
		end
	end
	vim.keymap.set(mode, lhs, rhs, o)
end

-- Basics
map("n", "<Esc>", "<cmd>nohlsearch<CR>", "Clear search highlights")
map({ "n", "x" }, "<leader>y", '"+y', "Yank → system clipboard")
map({ "n", "x" }, "<leader>p", '"+p', "Paste from system clipboard (after)")
map("n", "<leader>P", '"+P', "Paste from system clipboard (before)")
map("n", "<leader>w", "<cmd>write<CR>", "Save file")

-- Window navigation
map("n", "<C-h>", "<C-w>h", "Go to left window")
map("n", "<C-j>", "<C-w>j", "Go to below window")
map("n", "<C-k>", "<C-w>k", "Go to above window")
map("n", "<C-l>", "<C-w>l", "Go to right window")

-- Diagnostics (global toggles; LSP attach maps live in plugins/lsp.lua)
map("n", "<leader>dv", function()
	local vt = vim.diagnostic.config().virtual_text
	vim.diagnostic.config({ virtual_text = not vt })
end, { desc = "Diagnostics: toggle virtual text" })
map("n", "[d", vim.diagnostic.get_prev, "Prev diagnostic")
map("n", "]d", vim.diagnostic.get_next, "Next diagnostic")
map("n", "<leader>e", function()
	vim.diagnostic.open_float(nil, { border = "rounded" })
end, "Show diagnostic float")
map("n", "<leader>dq", vim.diagnostic.setloclist, "Diagnostics → loclist")

-- Smart quit: close floats, then try qa, confirm if needed
local function smart_quit()
	for _, w in ipairs(vim.api.nvim_list_wins()) do
		local cfg = vim.api.nvim_win_get_config(w)
		if cfg.relative ~= "" then
			pcall(vim.api.nvim_win_close, w, true)
		end
	end
	if not pcall(vim.cmd, "qa") then
		vim.cmd("confirm qa")
	end
end
vim.api.nvim_create_user_command("Wq", smart_quit, {})
vim.api.nvim_create_user_command("Q", "confirm qa", {})
map("n", "<leader>q", smart_quit, "Smart quit")

-- Ctrl-click goto definition (when LSP active)
map({ "n", "i" }, "<C-LeftMouse>", function()
	local m = vim.fn.getmousepos()
	if m.winid == 0 then
		return
	end
	vim.api.nvim_set_current_win(m.winid)
	vim.api.nvim_win_set_cursor(m.winid, { m.winrow, math.max(0, m.wincol - 1) })
	if vim.lsp.buf then
		vim.lsp.buf.definition()
	end
end, "Ctrl-Click → LSP goto definition")
