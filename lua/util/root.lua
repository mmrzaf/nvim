local M = {}

-- Nearest marker wins. This intentionally prefers a nested package over an
-- outer monorepo .git directory when the current file belongs to that package.
local markers = {
  ".git",
  "Justfile",
  "justfile",
  ".justfile",
  "pyproject.toml",
  "requirements.txt",
  "package.json",
  "tsconfig.json",
  "jsconfig.json",
  "pnpm-workspace.yaml",
  "deno.json",
  "deno.jsonc",
  "go.mod",
  "go.work",
  "Cargo.toml",
  ".clangd",
  "compile_commands.json",
  "compile_flags.txt",
  "CMakeLists.txt",
  "meson.build",
  "Makefile",
}

local function start_dir(bufnr)
  local name = vim.api.nvim_buf_get_name(bufnr or 0)
  if name ~= "" and not name:match("^[%a][%w+.-]*://") then
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
