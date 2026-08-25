local settings = require("config.settings")
local M = {}

local function executable(name, severity)
  if vim.fn.executable(name) == 1 then
    vim.health.ok(name .. " found")
    return true
  end

  local message = name .. " missing"
  if severity == "error" then
    vim.health.error(message)
  elseif severity == "warn" then
    vim.health.warn(message)
  else
    vim.health.info(message .. " (optional in the current environment)")
  end
  return false
end

local function command_version(command)
  local result = vim.system(command, { text = true }):wait(2000)
  if result.code == 0 then
    return vim.trim(result.stdout ~= "" and result.stdout or result.stderr or "")
  end
end

local function version_at_least(actual, required)
  for index = 1, math.max(#actual, #required) do
    local have = actual[index] or 0
    local need = required[index] or 0
    if have ~= need then
      return have > need
    end
  end
  return true
end

local function parse_version(text)
  local major, minor, patch = text:match("(%d+)%.(%d+)%.(%d+)")
  if not major then
    major, minor = text:match("(%d+)%.(%d+)")
    patch = "0"
  end
  if not major then
    return nil
  end
  return { tonumber(major), tonumber(minor), tonumber(patch) }
end

local function check_versioned_executable(name, command, minimum, severity)
  if not executable(name, severity) then
    return
  end

  local output = command_version(command)
  local parsed = output and parse_version(output)
  if not parsed then
    vim.health.warn(name .. " was found, but its version could not be parsed")
    return
  end

  if version_at_least(parsed, minimum) then
    vim.health.ok(output)
    return
  end

  local wanted = table.concat(minimum, ".")
  local report = (output or name) .. " is too old; " .. wanted .. "+ required"
  if severity == "error" then
    vim.health.error(report)
  else
    vim.health.warn(report)
  end
end

local function check_treesitter()
  vim.health.start("Treesitter")
  check_versioned_executable("tree-sitter", { "tree-sitter", "--version" }, { 0, 26, 1 }, "error")

  for _, parser in ipairs(settings.treesitter.parsers) do
    local call_ok, loaded, err = pcall(vim.treesitter.language.add, parser)
    if call_ok and loaded then
      vim.health.ok(parser .. " parser available")
    else
      local detail = call_ok and err or loaded
      vim.health.warn(parser .. " parser unavailable" .. (detail and ": " .. tostring(detail) or ""))
    end
  end
end

function M.check()
  vim.health.start("Neovim")
  local version = vim.version()
  local current = string.format("%d.%d.%d", version.major, version.minor, version.patch)
  if version.major > 0 or version.minor >= 12 then
    vim.health.ok("Neovim " .. current)
  else
    vim.health.error("Neovim 0.12+ required; found " .. current)
  end

  vim.health.start("Environment")
  local uname = vim.uv.os_uname()
  vim.health.info(string.format("%s %s (%s)", uname.sysname, uname.release, uname.machine))
  vim.health.info("Config: " .. vim.fn.stdpath("config"))
  vim.health.info("Data: " .. vim.fn.stdpath("data"))

  vim.health.start("Configuration")
  local lockfile = vim.fn.stdpath("config") .. "/lazy-lock.json"
  if vim.uv.fs_stat(lockfile) then
    vim.health.ok("Plugin lockfile found")
  else
    vim.health.warn("lazy-lock.json is missing; restore or regenerate it intentionally")
  end

  vim.health.start("Core executables")
  for _, name in ipairs({ "git", "rg", "curl", "tar" }) do
    executable(name, "error")
  end
  check_versioned_executable("fzf", { "fzf", "--version" }, { 0, 37, 0 }, "error")
  executable("fd", "info")
  executable("unzip", "info")
  executable("just", "info")
  executable("lazygit", "info")

  local compiler = vim.fn.executable("cc") == 1 or vim.fn.executable("gcc") == 1 or vim.fn.executable("clang") == 1
  if compiler then
    vim.health.ok("C compiler found")
  else
    vim.health.error("No C compiler found")
  end

  check_treesitter()

  vim.health.start("TypeScript editor tooling")
  executable("node", "warn")
  executable("npm", "warn")

  vim.health.start("Pinned Mason editor tools")
  local registry_ok, registry = pcall(require, "mason-registry")
  if not registry_ok then
    vim.health.warn("mason-registry is unavailable; pinned tool versions could not be checked")
  else
    for _, spec in ipairs(settings.mason.ensure_installed or {}) do
      if not registry.is_installed(spec.name) then
        local requirements = table.concat(spec.requires or {}, "/")
        local suffix = requirements ~= "" and " when " .. requirements .. " are available" or ""
        vim.health.warn(string.format("%s@%s is not installed; Mason will install it%s", spec.name, spec.version, suffix))
      else
        local package_ok, package = pcall(registry.get_package, spec.name)
        local installed = package_ok and package:get_installed_version() or nil
        if installed == spec.version then
          vim.health.ok(string.format("%s@%s", spec.name, installed))
        elseif installed then
          vim.health.warn(string.format("%s is %s; config pins %s (run :ConfigSyncMason)", spec.name, installed, spec.version))
        else
          vim.health.warn(spec.name .. " is installed, but its version could not be determined")
        end
      end
    end
  end

  vim.health.start("LSP servers in current environment")
  local mason_managed = {
    eslint = true,
    vtsls = true,
  }
  for _, server in ipairs(settings.lsp.servers) do
    local binary = settings.lsp.executables[server]
    if not binary then
      vim.health.info(server .. " has no executable probe configured")
    elseif vim.fn.executable(binary) == 1 then
      vim.health.ok(server .. " (" .. binary .. ")")
    elseif mason_managed[server] then
      vim.health.warn(server .. " unavailable (" .. binary .. "); Mason is configured to install this editor-side wrapper")
    else
      vim.health.info(server .. " unavailable (" .. binary .. "); this is valid outside projects/environments that provide it")
    end
  end

  vim.health.start("Formatters in current environment")
  local mason_managed_formatters = { shfmt = true }
  for _, name in ipairs(settings.formatting.executables) do
    if vim.fn.executable(name) == 1 then
      vim.health.ok(name .. " found")
    elseif mason_managed_formatters[name] then
      vim.health.warn(name .. " unavailable; Mason is configured to install it globally")
    else
      vim.health.info(name .. " unavailable; Conform will use it only when the current project/environment provides it")
    end
  end

  vim.health.start("Optional lint helpers")
  if vim.fn.executable("shellcheck") == 1 then
    vim.health.ok("shellcheck found; bash-language-server can use it for shell diagnostics")
  else
    vim.health.info("shellcheck unavailable; Bash LSP still works, but shell lint diagnostics are reduced")
  end
  if vim.fn.executable("cargo-clippy") == 1 then
    vim.health.ok("cargo-clippy found; rust-analyzer uses Clippy for check diagnostics")
  else
    vim.health.info("cargo-clippy unavailable; rust-analyzer falls back to cargo check diagnostics")
  end

  vim.health.start("Clipboard")
  if type(vim.g.clipboard) == "table" then
    vim.health.ok("Custom clipboard bridge active: " .. (vim.g.clipboard.name or "unnamed"))
  else
    local providers
    if vim.env.WAYLAND_DISPLAY and vim.env.WAYLAND_DISPLAY ~= "" then
      providers = {
        { "wl-copy", "Wayland" },
        { "xclip", "X11 fallback" },
        { "xsel", "X11 fallback" },
      }
    elseif vim.env.DISPLAY and vim.env.DISPLAY ~= "" then
      providers = {
        { "xclip", "X11" },
        { "xsel", "X11" },
        { "wl-copy", "Wayland fallback" },
      }
    else
      providers = {
        { "wl-copy", "Wayland" },
        { "xclip", "X11" },
        { "xsel", "X11" },
        { "pbcopy", "macOS" },
        { "win32yank.exe", "Windows" },
        { "clip.exe", "WSL/Windows" },
      }
    end

    local found
    for _, provider in ipairs(providers) do
      if vim.fn.executable(provider[1]) == 1 then
        found = provider
        break
      end
    end

    if found then
      vim.health.ok(string.format("Clipboard provider candidate found: %s (%s)", found[1], found[2]))
    elseif vim.env.SSH_TTY or vim.env.SSH_CONNECTION then
      vim.health.info("No local clipboard executable; Neovim may use OSC 52 over SSH")
    else
      vim.health.warn("No clipboard provider detected; install wl-clipboard for Wayland or xclip/xsel for X11")
    end
  end
end

return M
