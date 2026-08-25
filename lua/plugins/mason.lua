local settings = require("config.settings")

local function specs()
  return settings.mason and settings.mason.ensure_installed or {}
end

local function refresh_lsp()
  vim.schedule(function()
    if vim.fn.exists(":ConfigRefreshLsp") == 2 then
      vim.cmd("ConfigRefreshLsp")
    end
  end)
end

local function missing_requirement(spec)
  for _, executable in ipairs(spec.requires or {}) do
    if vim.fn.executable(executable) ~= 1 then
      return executable
    end
  end
end

local function install_specs(targets, notify)
  if #targets == 0 then
    return
  end

  local installable = {}
  for _, spec in ipairs(targets) do
    local missing = missing_requirement(spec)
    if not missing then
      installable[#installable + 1] = spec
    elseif notify then
      vim.notify(string.format("%s is required to install Mason package %s", missing, spec.name), vim.log.levels.WARN)
    end
  end
  if #installable == 0 then
    return
  end

  local registry = require("mason-registry")
  registry.refresh(function()
    local pending = 0

    local function done()
      pending = pending - 1
      if pending == 0 then
        refresh_lsp()
      end
    end

    for _, spec in ipairs(installable) do
      local ok, package = pcall(registry.get_package, spec.name)
      if not ok then
        vim.schedule(function()
          vim.notify("Mason package not found: " .. spec.name, vim.log.levels.WARN)
        end)
      elseif not package:is_installing() then
        pending = pending + 1
        package:install({ version = spec.version }, function(success, result)
          if not success then
            vim.schedule(function()
              vim.notify(
                string.format("Failed to install Mason package %s@%s: %s", spec.name, spec.version, tostring(result)),
                vim.log.levels.WARN
              )
            end)
          elseif notify then
            vim.schedule(function()
              vim.notify(string.format("Installed Mason package %s@%s", spec.name, spec.version))
            end)
          end
          done()
        end)
      end
    end
  end)
end

local function ensure_missing_packages()
  local registry = require("mason-registry")
  local missing = {}

  for _, spec in ipairs(specs()) do
    if not registry.is_installed(spec.name) then
      missing[#missing + 1] = spec
    else
      local ok, package = pcall(registry.get_package, spec.name)
      if ok then
        local installed = package:get_installed_version()
        if installed and installed ~= spec.version then
          vim.schedule(function()
            vim.notify(
              string.format(
                "Mason package %s is %s; config pins %s. Run :ConfigSyncMason to reconcile explicitly.",
                spec.name,
                installed,
                spec.version
              ),
              vim.log.levels.WARN
            )
          end)
        end
      end
    end
  end

  install_specs(missing, false)
end

local function sync_pinned_packages()
  local registry = require("mason-registry")
  registry.refresh(function()
    local queue = vim.deepcopy(specs())
    local index = 1

    local function next_package()
      local spec = queue[index]
      index = index + 1
      if not spec then
        refresh_lsp()
        vim.schedule(function()
          vim.notify("Pinned Mason packages are synchronized")
        end)
        return
      end

      local missing = missing_requirement(spec)
      if missing then
        vim.schedule(function()
          vim.notify(string.format("%s is required to install Mason package %s", missing, spec.name), vim.log.levels.WARN)
        end)
        next_package()
        return
      end

      local ok, package = pcall(registry.get_package, spec.name)
      if not ok then
        vim.schedule(function()
          vim.notify("Mason package not found: " .. spec.name, vim.log.levels.WARN)
        end)
        next_package()
        return
      end

      if package:is_installing() then
        vim.schedule(function()
          vim.notify(
            string.format("Mason package %s is already installing; sync skipped it this run", spec.name),
            vim.log.levels.WARN
          )
        end)
        next_package()
        return
      end

      local installed = package:is_installed() and package:get_installed_version() or nil
      if installed == spec.version then
        next_package()
        return
      end

      local function install()
        package:install({ version = spec.version }, function(success, result)
          if not success then
            vim.schedule(function()
              vim.notify(
                string.format("Failed to install %s@%s: %s", spec.name, spec.version, tostring(result)),
                vim.log.levels.ERROR
              )
            end)
          end
          next_package()
        end)
      end

      if package:is_installed() then
        package:uninstall({}, function(success, result)
          if not success then
            vim.schedule(function()
              vim.notify(string.format("Failed to uninstall %s: %s", spec.name, tostring(result)), vim.log.levels.ERROR)
            end)
            next_package()
            return
          end
          install()
        end)
      else
        install()
      end
    end

    next_package()
  end)
end

return {
  {
    "mason-org/mason.nvim",
    lazy = false,
    cmd = { "Mason", "MasonInstall", "MasonUpdate", "ConfigSyncMason" },
    config = function()
      require("mason").setup({
        PATH = "prepend",
        ui = {
          border = "rounded",
        },
      })

      vim.api.nvim_create_user_command("ConfigSyncMason", sync_pinned_packages, {
        desc = "Explicitly reconcile pinned Mason-managed editor wrappers",
        force = true,
      })

      ensure_missing_packages()
    end,
  },
}
