local diagnostics = require("config.diagnostics")

local function map(mode, lhs, rhs, desc, opts)
  opts = opts or {}
  opts.desc = desc
  opts.silent = opts.silent ~= false
  vim.keymap.set(mode, lhs, rhs, opts)
end

map("n", "<Esc>", "<cmd>nohlsearch<cr>", "Clear search highlight")
map("n", "<leader>w", "<cmd>write<cr>", "Write file")
map("n", "<leader>q", "<cmd>confirm quit<cr>", "Quit window")
map("n", "<leader>Q", "<cmd>confirm qall<cr>", "Quit Neovim")

map({ "n", "x" }, "<leader>y", '"+y', "Yank to system clipboard")
map("n", "<leader>Y", '"+Y', "Yank line to system clipboard")
map({ "n", "x" }, "<leader>p", '"+p', "Paste from system clipboard")
map({ "n", "x" }, "<leader>P", '"+P', "Paste before from system clipboard")

map("n", "<C-h>", "<C-w>h", "Window left")
map("n", "<C-j>", "<C-w>j", "Window down")
map("n", "<C-k>", "<C-w>k", "Window up")
map("n", "<C-l>", "<C-w>l", "Window right")

map("n", "<C-Up>", "<cmd>resize +2<cr>", "Increase window height")
map("n", "<C-Down>", "<cmd>resize -2<cr>", "Decrease window height")
map("n", "<C-Left>", "<cmd>vertical resize -2<cr>", "Decrease window width")
map("n", "<C-Right>", "<cmd>vertical resize +2<cr>", "Increase window width")

map("n", "[b", "<cmd>bprevious<cr>", "Previous buffer")
map("n", "]b", "<cmd>bnext<cr>", "Next buffer")
map("n", "<leader>bd", "<cmd>bdelete<cr>", "Delete buffer")

map("n", "[q", "<cmd>cprevious<cr>", "Previous quickfix item")
map("n", "]q", "<cmd>cnext<cr>", "Next quickfix item")
map("n", "[l", "<cmd>lprevious<cr>", "Previous location item")
map("n", "]l", "<cmd>lnext<cr>", "Next location item")

map("n", "<leader>e", function()
  vim.diagnostic.open_float(nil, { focus = false })
end, "Show diagnostic")

map("n", "<leader>dq", vim.diagnostic.setloclist, "Diagnostics to location list")
map("n", "<leader>dv", diagnostics.toggle_virtual_text, "Toggle diagnostic virtual text")

map("n", "<leader>uh", function()
  local bufnr = vim.api.nvim_get_current_buf()
  local enabled = vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr })
  vim.lsp.inlay_hint.enable(not enabled, { bufnr = bufnr })
end, "Toggle inlay hints")

map("x", "<", "<gv", "Indent left and reselect")
map("x", ">", ">gv", "Indent right and reselect")
map("x", "J", ":move '>+1<cr>gv=gv", "Move selection down")
map("x", "K", ":move '<-2<cr>gv=gv", "Move selection up")
