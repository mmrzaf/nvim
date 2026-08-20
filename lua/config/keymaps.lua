local diagnostics = require("config.diagnostics")

local M = {}

function M.map(mode, lhs, rhs, desc, opts)
  opts = opts or {}
  opts.desc = desc
  opts.silent = opts.silent ~= false
  vim.keymap.set(mode, lhs, rhs, opts)
end

function M.bufmap(bufnr, mode, lhs, rhs, desc, opts)
  opts = vim.tbl_extend("force", opts or {}, { buffer = bufnr })
  M.map(mode, lhs, rhs, desc, opts)
end

function M.refresh_clue(bufnr)
  vim.schedule(function()
    local ok, clue = pcall(require, "mini.clue")
    if ok then
      clue.ensure_buf_triggers(bufnr or 0)
    end
  end)
end

local map = M.map

local function toggle_option(name, label)
  return function()
    local enabled = vim.api.nvim_get_option_value(name, { scope = "local" })
    vim.api.nvim_set_option_value(name, not enabled, { scope = "local" })
    vim.notify(string.format("%s: %s", label, not enabled and "on" or "off"))
  end
end

local function delete_buffer(force)
  local ok, bufremove = pcall(require, "mini.bufremove")
  if ok then
    bufremove.delete(0, force)
  else
    vim.cmd(force and "bdelete!" or "bdelete")
  end
end

local function delete_other_buffers()
  local current = vim.api.nvim_get_current_buf()
  local ok, bufremove = pcall(require, "mini.bufremove")
  local skipped = 0

  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if bufnr ~= current and vim.bo[bufnr].buflisted then
      if vim.bo[bufnr].modified then
        skipped = skipped + 1
      elseif ok then
        bufremove.delete(bufnr, false)
      else
        pcall(vim.api.nvim_buf_delete, bufnr, {})
      end
    end
  end

  if skipped > 0 then
    vim.notify(string.format("Kept %d modified buffer%s", skipped, skipped == 1 and "" or "s"))
  end
end

local function open_config_keymaps()
  local path = vim.fs.joinpath(vim.fn.stdpath("config"), "KEYMAPS.md")
  if vim.uv.fs_stat(path) then
    vim.cmd("edit " .. vim.fn.fnameescape(path))
  else
    vim.notify("KEYMAPS.md is missing from the config", vim.log.levels.WARN)
  end
end

local function yank_current_path(absolute)
  local name = vim.api.nvim_buf_get_name(0)
  if name == "" or name:match("^[%a][%w+.-]*://") then
    vim.notify("Current buffer has no filesystem path", vim.log.levels.WARN)
    return
  end

  local path = absolute and vim.fs.normalize(name) or vim.fn.fnamemodify(name, ":.")
  vim.fn.setreg('"', path, "v")
  vim.fn.setreg("0", path, "v")
  vim.fn.setreg("+", path, "v")
  vim.notify((absolute and "Absolute" or "Relative") .. " path yanked: " .. path)
end

local function lsp_buffer_info()
  local clients = vim.lsp.get_clients({ bufnr = 0 })
  if #clients == 0 then
    vim.notify("No LSP clients attached to this buffer", vim.log.levels.INFO, { title = "LSP clients" })
    return
  end

  table.sort(clients, function(a, b)
    return a.name < b.name
  end)

  local lines = {}
  for _, client in ipairs(clients) do
    local root = client.root_dir or "[no workspace root]"
    lines[#lines + 1] = string.format("%s — %s", client.name, root)
  end

  vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO, { title = "LSP clients" })
end

local function lsp_or_native(method, action, native)
  return function()
    if #vim.lsp.get_clients({ bufnr = 0, method = method }) > 0 then
      action()
    else
      vim.cmd("normal! " .. native)
    end
  end
end

-- Standard -------------------------------------------------------------------
-- Native Vim/Neovim grammar owns editing/navigation. Leader mappings are
-- reserved for workflows and are grouped by stable namespaces documented in
-- KEYMAPS.md. Avoid adding aliases unless they represent a distinct workflow.

-- Core -----------------------------------------------------------------------
map("n", "<Esc>", "<cmd>nohlsearch<cr>", "Clear search highlight")
map("n", "<leader>w", "<cmd>write<cr>", "Write file")
map("n", "<leader>W", "<cmd>wall<cr>", "Write all files")
map("n", "<leader>q", "<cmd>confirm quit<cr>", "Quit window")
map("n", "<leader>Q", "<cmd>confirm qall<cr>", "Quit Neovim")

-- Normal yanks are mirrored to + by TextYankPost. Deletes/changes stay local.
map({ "n", "x" }, "<leader>p", '"+p', "Paste from system clipboard")
map({ "n", "x" }, "<leader>P", '"+P', "Paste before from system clipboard")

-- Windows --------------------------------------------------------------------
map("n", "<C-h>", "<C-w>h", "Window left")
map("n", "<C-j>", "<C-w>j", "Window down")
map("n", "<C-k>", "<C-w>k", "Window up")
map("n", "<C-l>", "<C-w>l", "Window right")
map("n", "<C-Up>", "<cmd>resize +2<cr>", "Increase window height")
map("n", "<C-Down>", "<cmd>resize -2<cr>", "Decrease window height")
map("n", "<C-Left>", "<cmd>vertical resize -2<cr>", "Decrease window width")
map("n", "<C-Right>", "<cmd>vertical resize +2<cr>", "Increase window width")

-- Buffers --------------------------------------------------------------------
-- Navigation uses native [b/]b. Leader-b is for buffer lifecycle/state.
map("n", "<leader>bd", function()
  delete_buffer(false)
end, "Delete buffer")
map("n", "<leader>bD", function()
  delete_buffer(true)
end, "Force delete buffer")
map("n", "<leader>bo", delete_other_buffers, "Delete other buffers")

-- Files ----------------------------------------------------------------------
map("n", "<leader>fy", function()
  yank_current_path(false)
end, "Yank relative file path")
map("n", "<leader>fY", function()
  yank_current_path(true)
end, "Yank absolute file path")

-- LSP grammar ----------------------------------------------------------------
-- Neovim owns K, gra/gri/grn/grr/grt/grx/gO and insert <C-S>. gd/gD retain
-- their native fallback when no attached LSP supports the corresponding call.
map("n", "gd", lsp_or_native("textDocument/definition", vim.lsp.buf.definition, "gd"), "LSP or native definition")
map("n", "gD", lsp_or_native("textDocument/declaration", vim.lsp.buf.declaration, "gD"), "LSP or native declaration")

-- Code -----------------------------------------------------------------------
map("n", "<leader>cI", vim.lsp.buf.incoming_calls, "Incoming calls")
map("n", "<leader>cO", vim.lsp.buf.outgoing_calls, "Outgoing calls")

-- LSP lifecycle/session ------------------------------------------------------
map("n", "<leader>li", lsp_buffer_info, "LSP clients for buffer")
map("n", "<leader>ll", "<cmd>LspLog<cr>", "LSP log")
map("n", "<leader>lh", "<cmd>checkhealth vim.lsp<cr>", "LSP health")
map("n", "<leader>lm", "<cmd>Mason<cr>", "Mason tools")
map("n", "<leader>lM", "<cmd>ConfigSyncMason<cr>", "Sync pinned Mason wrappers")
map("n", "<leader>lr", "<cmd>ConfigRefreshLsp<cr>", "Refresh LSP environment")
map("n", "<leader>lR", "<cmd>lsp restart<cr>", "Restart LSP clients for buffer")
map("n", "<leader>le", "<cmd>ConfigEnableLsp<cr>", "Enable LSP config for session")
map("n", "<leader>ld", "<cmd>ConfigDisableLsp<cr>", "Disable LSP config for session")
map("n", "<leader>lx", "<cmd>lsp stop<cr>", "Stop LSP clients for buffer")

-- Diagnostics ----------------------------------------------------------------
map("n", "<leader>dd", function()
  vim.diagnostic.open_float(nil, { focus = false })
end, "Show line diagnostics")
map("n", "<leader>dl", vim.diagnostic.setloclist, "Diagnostics to location list")
map("n", "<leader>dq", vim.diagnostic.setqflist, "Diagnostics to quickfix")
map("n", "<leader>dv", diagnostics.toggle_virtual_text, "Toggle diagnostic virtual text")
map("n", "<leader>dV", diagnostics.toggle_virtual_lines, "Toggle current-line diagnostic virtual lines")
map("n", "<leader>du", diagnostics.toggle_underline, "Toggle diagnostic underline")
map("n", "<leader>dx", function()
  local bufnr = vim.api.nvim_get_current_buf()
  local enabled = vim.diagnostic.is_enabled({ bufnr = bufnr })
  vim.diagnostic.enable(not enabled, { bufnr = bufnr })
end, "Toggle diagnostics for buffer")
map("n", "<leader>dX", function()
  vim.diagnostic.enable(not vim.diagnostic.is_enabled())
end, "Toggle diagnostics globally")
map("n", "]e", function()
  vim.diagnostic.jump({ count = 1, severity = vim.diagnostic.severity.ERROR })
end, "Next error")
map("n", "[e", function()
  vim.diagnostic.jump({ count = -1, severity = vim.diagnostic.severity.ERROR })
end, "Previous error")
map("n", "]w", function()
  vim.diagnostic.jump({ count = 1, severity = vim.diagnostic.severity.WARN })
end, "Next warning")
map("n", "[w", function()
  vim.diagnostic.jump({ count = -1, severity = vim.diagnostic.severity.WARN })
end, "Previous warning")

-- UI / editor state ----------------------------------------------------------
map("n", "<leader>ui", function()
  local bufnr = vim.api.nvim_get_current_buf()
  local enabled = vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr })
  vim.lsp.inlay_hint.enable(not enabled, { bufnr = bufnr })
end, "Toggle inlay hints")
map("n", "<leader>uw", toggle_option("wrap", "Wrap"), "Toggle wrap")
map("n", "<leader>us", toggle_option("spell", "Spell"), "Toggle spell")
map("n", "<leader>ul", toggle_option("list", "List characters"), "Toggle list characters")
map("n", "<leader>un", toggle_option("number", "Line numbers"), "Toggle line numbers")
map("n", "<leader>ur", toggle_option("relativenumber", "Relative numbers"), "Toggle relative numbers")
map("n", "<leader>uc", toggle_option("cursorline", "Cursor line"), "Toggle cursor line")
map("n", "<leader>ut", function()
  local ok, trailspace = pcall(require, "mini.trailspace")
  if not ok then
    vim.notify("mini.trailspace is not loaded", vim.log.levels.WARN)
    return
  end
  trailspace.trim()
  trailspace.trim_last_lines()
end, "Trim trailing whitespace")
map("n", "<leader>uh", "<cmd>checkhealth config<cr>", "Config health")
map("n", "<leader>uH", "<cmd>checkhealth<cr>", "All health checks")
map("n", "<leader>uk", open_config_keymaps, "Open keymap guide")
map("n", "<leader>up", "<cmd>Lazy<cr>", "Plugin manager")

-- Editing --------------------------------------------------------------------
map("n", "n", "nzzzv", "Next search result")
map("n", "N", "Nzzzv", "Previous search result")
map("n", "<C-d>", "<C-d>zz", "Half page down and center")
map("n", "<C-u>", "<C-u>zz", "Half page up and center")
map("x", "<", "<gv", "Indent left and reselect")
map("x", ">", ">gv", "Indent right and reselect")
map("x", "J", ":move '>+1<cr>gv=gv", "Move selection down")
map("x", "K", ":move '<-2<cr>gv=gv", "Move selection up")

M.groups = {
  { mode = { "n", "x" }, keys = "<leader>b", desc = "+Buffers" },
  { mode = { "n", "x" }, keys = "<leader>c", desc = "+Code" },
  { mode = { "n", "x" }, keys = "<leader>d", desc = "+Diagnostics" },
  { mode = { "n", "x" }, keys = "<leader>f", desc = "+Find / files" },
  { mode = { "n", "x" }, keys = "<leader>g", desc = "+Git" },
  { mode = { "n", "x" }, keys = "<leader>j", desc = "+Just" },
  { mode = { "n", "x" }, keys = "<leader>l", desc = "+LSP session" },
  { mode = { "n", "x" }, keys = "<leader>m", desc = "+Markdown" },
  { mode = { "n", "x" }, keys = "<leader>s", desc = "+Search" },
  { mode = { "n", "x" }, keys = "<leader>t", desc = "+Terminal" },
  { mode = { "n", "x" }, keys = "<leader>u", desc = "+UI / utility" },
}

vim.api.nvim_create_user_command("ConfigKeymaps", open_config_keymaps, {
  desc = "Open the config keymap standard",
  force = true,
})

return M
