-- Keymap helper ---------------------------------------------------------------
local function map(mode, lhs, rhs, opts)
  -- allow: map('n','x',func,{ desc = '...' })
  --        map('n','x',func,'Desc')
  local o = { silent = true, noremap = true }
  if type(opts) == 'string' then
    o.desc = opts
  elseif type(opts) == 'table' then
    for k, v in pairs(opts) do o[k] = v end
  end
  vim.keymap.set(mode, lhs, rhs, o)
end

-- Basic motions & utility -----------------------------------------------------
map("n", "<Esc>", "<cmd>nohlsearch<CR>", "Clear search highlights")
map({ "n", "x" }, "<leader>y", '"+y', "Yank → system clipboard")

-- Save / quit kept simple and unique
map("n", "<leader>w", "<cmd>write<CR>", "Save file")

-- FZF/Lua pickers
map("n", "<leader><leader>", "<cmd>FzfLua files<CR>", "Find files (fzf)")
map("n", "<leader>/", "<cmd>FzfLua live_grep<CR>", "Search in project (rg+fzf)")

-- Ctrl-click to go to definition ---------------------------------------------
map({ "n", "i" }, "<C-LeftMouse>", function()
  local m = vim.fn.getmousepos()
  if m.winid == 0 then return end
  vim.api.nvim_set_current_win(m.winid)
  vim.api.nvim_win_set_cursor(m.winid, { m.winrow, math.max(0, m.wincol - 1) })
  if vim.lsp.buf then vim.lsp.buf.definition() end
end, "Ctrl-Click → LSP goto definition")

-- LSP / diagnostics -----------------------------------------------------------
map("n", "gd", vim.lsp.buf.definition, "LSP: go to definition")
map("n", "gD", vim.lsp.buf.declaration, "LSP: go to declaration")
map("n", "gr", vim.lsp.buf.references, "LSP: references")
map("n", "gi", vim.lsp.buf.implementation, "LSP: implementation")
map("n", "K",  vim.lsp.buf.hover, "LSP: hover")
map("n", "<C-k>", vim.lsp.buf.signature_help, "LSP: signature help")
map("n", "<leader>rn", vim.lsp.buf.rename, "LSP: rename")
map("n", "<leader>ca", vim.lsp.buf.code_action, "LSP: code action")
map("n", "<leader>ws", vim.lsp.buf.workspace_symbol, "LSP: workspace symbol")
map("n", "<leader>wd", vim.lsp.buf.document_symbol, "LSP: document symbol")

map("n", "[d", vim.diagnostic.goto_prev, "Prev diagnostic")
map("n", "]d", vim.diagnostic.goto_next, "Next diagnostic")
map("n", "<leader>e", function()
  vim.diagnostic.open_float(nil, { border = "rounded" })
end, "Show diagnostic float")
map("n", "<leader>dq", vim.diagnostic.setloclist, "Diagnostics → loclist")

-- Formatting ------------------------------------------------------------------
map("n", "<leader>f", function()
  vim.lsp.buf.format({ async = false })
end, "LSP: format buffer")

-- Windows / buffers -----------------------------------------------------------
-- Keep <leader>h free for 'nohlsearch' above. Use <C-h/j/k/l> for window nav.
map("n", "<C-h>", "<C-w>h", "Go to left window")
map("n", "<C-j>", "<C-w>j", "Go to below window")
map("n", "<C-k>", "<C-w>k", "Go to above window")
map("n", "<C-l>", "<C-w>l", "Go to right window")

map("n", "<leader>c", "<cmd>bd<CR>", "Close buffer")

-- Jump list -------------------------------------------------------------------
map("n", "<C-o>", "<C-o>", "Jump older position")
map("n", "<C-i>", "<C-i>", "Jump newer position")

-- Terminal --------------------------------------------------------------------
map("n", "<leader>t",  "<cmd>split  | terminal<CR>", "Open terminal (split)")
map("n", "<leader>tv", "<cmd>vsplit | terminal<CR>", "Open terminal (vsplit)")
map("t", "<Esc>", "<C-\\><C-n>", "Terminal → Normal")
map("n", "<C-/>", "<cmd>split  | terminal<CR>", "Open terminal (split)")
map("n", "<C-?>", "<cmd>vsplit | terminal<CR>", "Open terminal (vsplit)")
map("n", "<leader>tt", "<cmd>ToggleTerm direction=float<CR>", "ToggleTerm (float)")

-- Smart quit: close floats, try 'qa', then confirm if needed ------------------
local function smart_quit()
  -- auto-write real files if you want:
  -- for _, b in ipairs(vim.api.nvim_list_bufs()) do
  --   if vim.bo[b].buflisted and vim.bo[b].buftype == '' and vim.bo[b].modified then
  --     pcall(vim.api.nvim_buf_call, b, function() vim.cmd('silent write') end)
  --   end
  -- end
  for _, w in ipairs(vim.api.nvim_list_wins()) do
    local cfg = vim.api.nvim_win_get_config(w)
    if cfg.relative ~= '' then pcall(vim.api.nvim_win_close, w, true) end
  end
  if not pcall(vim.cmd, 'qa') then vim.cmd('confirm qa') end
end

vim.api.nvim_create_user_command('Wq', smart_quit, {})
vim.api.nvim_create_user_command('Q',  'confirm qa', {})
map('n', '<leader>q', smart_quit, "Smart quit")

-- Grep helper -----------------------------------------------------------------
map('n', '<leader>sg', function()
  if vim.fn.executable('rg') == 1 then
    vim.cmd('silent grep! -n "" | copen')
    vim.fn.inputsave()
    local q = vim.fn.input('rg > ')
    vim.fn.inputrestore()
    if q ~= '' then vim.cmd('silent grep! ' .. q .. ' | copen') end
  else
    vim.fn.inputsave()
    local q = vim.fn.input('vimgrep /pattern/ > ')
    vim.fn.inputrestore()
    if q ~= '' then vim.cmd('silent vimgrep /' .. q .. '/gj **/* | copen') end
  end
end, { desc = 'Search project' })

