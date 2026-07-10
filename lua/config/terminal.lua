local M = {}

local terminals = {}

local function terminal_maps(bufnr)
  local opts = { buffer = bufnr, silent = true }
  vim.keymap.set("t", "<Esc><Esc>", [[<C-\><C-n>]], vim.tbl_extend("force", opts, { desc = "Leave terminal mode" }))
  vim.keymap.set("t", "<C-h>", [[<Cmd>wincmd h<CR>]], vim.tbl_extend("force", opts, { desc = "Window left" }))
  vim.keymap.set("t", "<C-j>", [[<Cmd>wincmd j<CR>]], vim.tbl_extend("force", opts, { desc = "Window down" }))
  vim.keymap.set("t", "<C-k>", [[<Cmd>wincmd k<CR>]], vim.tbl_extend("force", opts, { desc = "Window up" }))
  vim.keymap.set("t", "<C-l>", [[<Cmd>wincmd l<CR>]], vim.tbl_extend("force", opts, { desc = "Window right" }))
end

local function on_open(term)
  terminal_maps(term.bufnr)
  vim.cmd("startinsert")
end

local function close_other_terminals(target)
  for _, term in pairs(terminals) do
    if term ~= target and term:is_open() then
      term:close()
    end
  end
end

local function toggle(term, size)
  if not term:is_open() then
    close_other_terminals(term)
  end
  term:toggle(size)
end

function M.setup()
  local Terminal = require("toggleterm.terminal").Terminal

  terminals.shell = Terminal:new({
    display_name = "shell",
    direction = "horizontal",
    dir = "git_dir",
    hidden = true,
    close_on_exit = true,
    on_open = on_open,
  })

  if vim.fn.executable("lazygit") == 1 then
    terminals.git = Terminal:new({
      cmd = "lazygit",
      display_name = "lazygit",
      direction = "float",
      dir = "git_dir",
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
end

function M.toggle_shell()
  local size = math.min(14, math.max(5, vim.o.lines - 4))
  toggle(terminals.shell, size)
end

function M.toggle_git()
  if not terminals.git then
    vim.notify("lazygit is not installed", vim.log.levels.WARN)
    return
  end
  toggle(terminals.git)
end

return M
