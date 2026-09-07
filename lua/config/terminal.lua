local root = require("util.root")
local M = {}

local terminals = {
  shell = {},
  git = {},
}
local Terminal

local function terminal_maps(bufnr, term)
  local keymaps = require("config.keymaps")
  keymaps.bufmap(bufnr, "t", "<Esc><Esc>", [[<C-\><C-n>]], "Leave terminal mode")
  keymaps.bufmap(bufnr, "t", "<C-h>", [[<Cmd>wincmd h<CR>]], "Window left")
  keymaps.bufmap(bufnr, "t", "<C-j>", [[<Cmd>wincmd j<CR>]], "Window down")
  keymaps.bufmap(bufnr, "t", "<C-k>", [[<Cmd>wincmd k<CR>]], "Window up")
  keymaps.bufmap(bufnr, "t", "<C-l>", [[<Cmd>wincmd l<CR>]], "Window right")
  -- Double <C-\> to hide the terminal; a bare <C-\> mapping would force a
  -- timeoutlen wait on the canonical <C-\><C-n> mode-leave chord.
  keymaps.bufmap(bufnr, "t", [[<C-\><C-\>]], function()
    term:toggle()
  end, "Toggle current terminal")
end

local function on_open(term)
  terminal_maps(term.bufnr, term)
  vim.cmd("startinsert")
end

local function each_terminal(callback)
  for _, kind in pairs(terminals) do
    for _, term in pairs(kind) do
      callback(term)
    end
  end
end

local function close_other_terminals(target)
  each_terminal(function(term)
    if term ~= target and term:is_open() then
      term:close()
    end
  end)
end

local function toggle(term, size)
  if not term:is_open() then
    close_other_terminals(term)
  end
  term:toggle(size)
end

local function project_shell(project_root)
  if not terminals.shell[project_root] then
    terminals.shell[project_root] = Terminal:new({
      display_name = "shell",
      direction = "horizontal",
      dir = project_root,
      hidden = true,
      close_on_exit = true,
      on_open = on_open,
    })
  end
  return terminals.shell[project_root]
end

local function project_git(project_root)
  if not terminals.git[project_root] then
    terminals.git[project_root] = Terminal:new({
      cmd = "lazygit",
      display_name = "lazygit",
      direction = "float",
      dir = project_root,
      hidden = true,
      close_on_exit = true,
      float_opts = {
        border = "rounded",
        width = function()
          return math.floor(vim.o.columns * 0.92)
        end,
        height = function()
          return math.floor(vim.o.lines * 0.90)
        end,
      },
      on_open = on_open,
    })
  end
  return terminals.git[project_root]
end

function M.setup()
  Terminal = require("toggleterm.terminal").Terminal
end

function M.toggle_shell()
  local size = math.min(14, math.max(5, vim.o.lines - 4))
  toggle(project_shell(root.get(0)), size)
end

function M.toggle_git()
  if vim.fn.executable("lazygit") ~= 1 then
    vim.notify("lazygit is not installed", vim.log.levels.WARN)
    return
  end
  toggle(project_git(root.get(0)))
end

return M
