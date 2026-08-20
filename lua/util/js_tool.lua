local M = {}

local cli_packages = {
  eslint = "eslint",
  prettier = "prettier",
  tsc = "typescript",
}

local workspace_markers = {
  ".pnp.cjs",
  ".pnp.loader.mjs",
  "pnpm-workspace.yaml",
  "pnpm-lock.yaml",
  "yarn.lock",
  "package-lock.json",
  "npm-shrinkwrap.json",
  "bun.lock",
  "bun.lockb",
  ".git",
}

local function normalize(path)
  return path and vim.fs.normalize(path) or nil
end

local function as_list(names)
  return type(names) == "table" and names or { names }
end

local function parent(dir)
  local value = vim.fs.dirname(dir)
  if not value or value == dir then
    return nil
  end
  return value
end

local function find_up_unbounded(names, start)
  return vim.fs.find(names, { upward = true, path = start })[1]
end

-- Find a file/directory while walking toward `boundary`, never escaping it.
function M.find_up(names, start, boundary)
  local dir = normalize(start or vim.uv.cwd())
  boundary = normalize(boundary or M.workspace(dir))

  while dir and dir ~= "" do
    for _, name in ipairs(as_list(names)) do
      local candidate = vim.fs.joinpath(dir, name)
      if vim.uv.fs_stat(candidate) then
        return candidate
      end
    end

    if dir == boundary then
      break
    end
    dir = parent(dir)
  end
end

function M.workspace(start)
  start = normalize(start or vim.uv.cwd())
  local marker = find_up_unbounded(workspace_markers, start)
  if marker then
    return vim.fs.dirname(marker)
  end

  local package = find_up_unbounded("package.json", start)
  return package and vim.fs.dirname(package) or start
end

function M.package_dir(start)
  start = normalize(start or vim.uv.cwd())
  local workspace = M.workspace(start)
  local package = M.find_up("package.json", start, workspace)
  return package and vim.fs.dirname(package) or workspace
end

local function package_declares(dir, package_name)
  local path = vim.fs.joinpath(dir, "package.json")
  local fd = io.open(path, "r")
  if not fd then
    return false
  end
  local content = fd:read("*a") or ""
  fd:close()

  local ok, package = pcall(vim.json.decode, content)
  if not ok or type(package) ~= "table" then
    return false
  end

  for _, key in ipairs({ "dependencies", "devDependencies", "peerDependencies", "optionalDependencies" }) do
    if type(package[key]) == "table" and package[key][package_name] ~= nil then
      return true
    end
  end
  return false
end

local function pnp_root(start, workspace)
  local pnp = M.find_up({ ".pnp.cjs", ".pnp.loader.mjs" }, start, workspace)
  return pnp and vim.fs.dirname(pnp) or nil
end

local function search_node_modules(name, start, boundary)
  local dir = normalize(start)
  boundary = normalize(boundary)

  while dir and dir ~= "" do
    local candidate = vim.fs.joinpath(dir, "node_modules", ".bin", name)
    if vim.fn.executable(candidate) == 1 then
      return candidate
    end

    if dir == boundary then
      break
    end
    dir = parent(dir)
  end
end

-- Resolve a project-owned JavaScript CLI without assuming node_modules exists.
-- Returns { argv = {...}, cwd = string, source = string, workspace = string } or nil.
function M.resolve(name, start)
  start = normalize(start or vim.uv.cwd())
  local workspace = M.workspace(start)
  local pnp = pnp_root(start, workspace)

  if pnp and vim.fn.executable("yarn") == 1 then
    local package_dir = M.package_dir(start)
    local package_name = cli_packages[name] or name
    local declared_in_package = package_declares(package_dir, package_name)
    local declared_in_root = package_dir ~= pnp and package_declares(pnp, package_name)

    if declared_in_package or declared_in_root then
      local exec_cwd = declared_in_package and package_dir or pnp
      return {
        argv = { "yarn", "exec", name },
        cwd = exec_cwd,
        source = declared_in_package and "Yarn PnP workspace" or "Yarn PnP root",
        workspace = pnp,
      }
    end
  end

  local local_bin = search_node_modules(name, start, workspace)
  if local_bin then
    return {
      argv = { local_bin },
      cwd = M.package_dir(start),
      source = "project node_modules",
      workspace = workspace,
    }
  end

  local global = vim.fn.exepath(name)
  if global ~= "" then
    return {
      argv = { global },
      cwd = M.package_dir(start),
      source = "PATH",
      workspace = workspace,
    }
  end
end

function M.typescript_sdk(start)
  start = normalize(start or vim.uv.cwd())
  local workspace = M.workspace(start)
  local dir = start

  while dir and dir ~= "" do
    local yarn_sdk = vim.fs.joinpath(dir, ".yarn", "sdks", "typescript", "lib")
    if vim.uv.fs_stat(yarn_sdk) then
      return yarn_sdk
    end

    local node_sdk = vim.fs.joinpath(dir, "node_modules", "typescript", "lib")
    if vim.uv.fs_stat(node_sdk) then
      return node_sdk
    end

    if dir == workspace then
      break
    end
    dir = parent(dir)
  end
end

return M
