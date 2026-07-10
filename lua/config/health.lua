local settings = require("config.settings")
local M = {}

local function executable(name, required)
  if vim.fn.executable(name) == 1 then
    vim.health.ok(name .. " found")
    return true
  end
  if required then
    vim.health.error(name .. " missing")
  else
    vim.health.warn(name .. " missing")
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

local function check_versioned_executable(name, command, minimum, required)
  if not executable(name, required) then
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
  else
    local wanted = table.concat(minimum, ".")
    local report = (output or name) .. " is too old; " .. wanted .. "+ required"
    if required then
      vim.health.error(report)
    else
      vim.health.warn(report)
    end
  end
end

local function check_treesitter_cli()
  vim.health.start("Treesitter")
  check_versioned_executable("tree-sitter", { "tree-sitter", "--version" }, { 0, 26, 1 }, true)
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
    vim.health.warn("lazy-lock.json is missing; launch once, then commit the generated lockfile")
  end

  vim.health.start("Core executables")
  for _, name in ipairs({ "git", "rg", "fd", "curl", "tar" }) do
    executable(name, true)
  end
  check_versioned_executable("fzf", { "fzf", "--version" }, { 0, 36, 0 }, true)
  executable("unzip", false)
  executable("just", false)
  executable("lazygit", false)

  local compiler = vim.fn.executable("cc") == 1 or vim.fn.executable("gcc") == 1 or vim.fn.executable("clang") == 1
  if compiler then
    vim.health.ok("C compiler found")
  else
    vim.health.error("No C compiler found")
  end

  check_treesitter_cli()

  vim.health.start("LSP servers")
  for _, server in ipairs(settings.lsp.servers) do
    local binary = settings.lsp.executables[server]
    if binary and vim.fn.executable(binary) == 1 then
      vim.health.ok(server .. " (" .. binary .. ")")
    else
      vim.health.warn(server .. " missing" .. (binary and " (" .. binary .. ")" or ""))
    end
  end

  vim.health.start("Formatters")
  for _, name in ipairs(settings.formatting.executables) do
    executable(name, false)
  end

  vim.health.start("Clipboard")
  if type(vim.g.clipboard) == "table" then
    vim.health.ok("Custom clipboard bridge active: " .. (vim.g.clipboard.name or "unnamed"))
  else
    local providers = {
      { "wl-copy", "Wayland" },
      { "xclip", "X11 (xclip)" },
      { "xsel", "X11 (xsel)" },
      { "pbcopy", "macOS" },
      { "win32yank.exe", "Windows" },
      { "clip.exe", "WSL/Windows" },
    }
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
      vim.health.warn("No clipboard provider detected; run :checkhealth provider")
    end
  end
end

return M
