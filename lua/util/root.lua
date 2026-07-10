local M = {}

local markers = {
  ".git",
  "Justfile",
  "justfile",
  "pyproject.toml",
  "package.json",
  "go.mod",
  "Cargo.toml",
}

local function start_dir(bufnr)
  local name = vim.api.nvim_buf_get_name(bufnr or 0)
  if name ~= "" then
    return vim.fs.dirname(name)
  end
  return vim.uv.cwd()
end

function M.get(bufnr)
  local start = start_dir(bufnr)
  local found = vim.fs.find(markers, { upward = true, path = start })[1]
  if found then
    return vim.fs.dirname(found)
  end
  return start
end

function M.justfile(bufnr)
  local start = start_dir(bufnr)
  return vim.fs.find({ "Justfile", "justfile", ".justfile" }, {
    upward = true,
    path = start,
  })[1]
end

return M
