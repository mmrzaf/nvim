local settings = require("config.settings").large_file
local M = {}

function M.is(bufnr)
  bufnr = bufnr or 0
  return vim.b[bufnr].config_large_file == true
end

function M.detect(bufnr, filename)
  bufnr = bufnr or 0
  filename = filename or vim.api.nvim_buf_get_name(bufnr)
  if filename == "" or filename:match("^%w+://") then
    return false
  end

  local stat = vim.uv.fs_stat(filename)
  if stat and stat.size >= settings.bytes then
    vim.b[bufnr].config_large_file = true
    vim.bo[bufnr].swapfile = false
    vim.bo[bufnr].undofile = false
    return true
  end

  return false
end

function M.check_lines(bufnr)
  bufnr = bufnr or 0
  if M.is(bufnr) then
    return true
  end
  if vim.api.nvim_buf_line_count(bufnr) >= settings.lines then
    vim.b[bufnr].config_large_file = true
    vim.bo[bufnr].swapfile = false
    vim.bo[bufnr].undofile = false
    return true
  end
  return false
end

return M
