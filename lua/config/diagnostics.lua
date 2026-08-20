local M = {}

M.virtual_text = {
  spacing = 2,
  source = "if_many",
  prefix = "●",
}

vim.diagnostic.config({
  severity_sort = true,
  update_in_insert = false,
  underline = true,
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = "E",
      [vim.diagnostic.severity.WARN] = "W",
      [vim.diagnostic.severity.INFO] = "I",
      [vim.diagnostic.severity.HINT] = "H",
    },
  },
  virtual_text = M.virtual_text,
  float = {
    border = "rounded",
    source = "if_many",
    header = "",
    prefix = "",
  },
})

function M.toggle_virtual_text()
  local enabled = vim.diagnostic.config().virtual_text ~= false
  vim.diagnostic.config({
    virtual_text = enabled and false or vim.deepcopy(M.virtual_text),
  })
end

function M.toggle_virtual_lines()
  local enabled = vim.diagnostic.config().virtual_lines
  vim.diagnostic.config({
    virtual_lines = enabled and false or { current_line = true },
  })
end

function M.toggle_underline()
  local enabled = vim.diagnostic.config().underline ~= false
  vim.diagnostic.config({ underline = not enabled })
end

return M
