local settings = require("config.settings")
local large_file = require("util.large_file")
local js_tool = require("util.js_tool")

local session_disabled = {}

local function add_large_file_root_guard(name)
  local resolved = vim.lsp.config[name]
  local original_root_dir = resolved.root_dir
  local root_markers = resolved.root_markers
  local workspace_required = resolved.workspace_required == true

  vim.lsp.config(name, {
    root_dir = function(bufnr, on_dir)
      if large_file.is(bufnr) or large_file.check_lines(bufnr) then
        return
      end

      if type(original_root_dir) == "function" then
        original_root_dir(bufnr, on_dir)
        return
      end

      if type(original_root_dir) == "string" then
        on_dir(original_root_dir)
        return
      end

      if root_markers then
        local project_root = vim.fs.root(bufnr, root_markers)
        if project_root then
          on_dir(project_root)
          return
        end
      end

      if not workspace_required then
        on_dir(nil)
      end
    end,
  })
end

local function highlight_group(bufnr)
  return "ConfigLspHighlight_" .. bufnr
end

local function enable_document_highlight(bufnr, client)
  if vim.b[bufnr].config_lsp_document_highlight then
    return
  end
  if not client:supports_method("textDocument/documentHighlight") then
    return
  end

  vim.b[bufnr].config_lsp_document_highlight = true
  local group = vim.api.nvim_create_augroup(highlight_group(bufnr), { clear = true })

  vim.api.nvim_create_autocmd("CursorHold", {
    group = group,
    buffer = bufnr,
    callback = vim.lsp.buf.document_highlight,
  })
  vim.api.nvim_create_autocmd({ "CursorMoved", "InsertEnter", "BufLeave" }, {
    group = group,
    buffer = bufnr,
    callback = vim.lsp.buf.clear_references,
  })
  vim.api.nvim_create_autocmd("BufWipeout", {
    group = group,
    buffer = bufnr,
    once = true,
    callback = function()
      pcall(vim.api.nvim_del_augroup_by_name, highlight_group(bufnr))
    end,
  })
end

local function cleanup_document_highlight(bufnr)
  local keep = false
  for _, client in ipairs(vim.lsp.get_clients({ bufnr = bufnr })) do
    if client:supports_method("textDocument/documentHighlight") then
      keep = true
      break
    end
  end

  if keep then
    return
  end

  vim.b[bufnr].config_lsp_document_highlight = false
  pcall(vim.api.nvim_buf_call, bufnr, vim.lsp.buf.clear_references)
  pcall(vim.api.nvim_del_augroup_by_name, highlight_group(bufnr))
end

local function typescript_settings()
  local inlay_hints = {
    parameterNames = {
      enabled = "literals",
      suppressWhenArgumentMatchesName = true,
    },
    parameterTypes = { enabled = true },
    variableTypes = {
      enabled = false,
      suppressWhenTypeMatchesName = true,
    },
    propertyDeclarationTypes = { enabled = true },
    functionLikeReturnTypes = { enabled = true },
    enumMemberValues = { enabled = true },
  }

  return {
    vtsls = {
      autoUseWorkspaceTsdk = true,
      experimental = {
        completion = {
          enableServerSideFuzzyMatch = true,
        },
      },
    },
    typescript = {
      format = { enable = false },
      preferGoToSourceDefinition = true,
      updateImportsOnFileMove = { enabled = "always" },
      suggest = {
        autoImports = true,
        completeFunctionCalls = true,
        paths = true,
      },
      preferences = {
        importModuleSpecifier = "shortest",
        includePackageJsonAutoImports = "auto",
        preferTypeOnlyAutoImports = true,
        quoteStyle = "auto",
      },
      inlayHints = inlay_hints,
      tsserver = {
        experimental = {
          enableProjectDiagnostics = settings.typescript.project_diagnostics,
        },
      },
    },
    javascript = {
      format = { enable = false },
      preferGoToSourceDefinition = true,
      updateImportsOnFileMove = { enabled = "always" },
      suggest = {
        autoImports = true,
        completeFunctionCalls = true,
        paths = true,
      },
      preferences = {
        importModuleSpecifier = "shortest",
        includePackageJsonAutoImports = "auto",
        quoteStyle = "auto",
      },
      inlayHints = vim.deepcopy(inlay_hints),
    },
  }
end

local function executable_available(name)
  local binary = settings.lsp.executables[name]
  return not binary or vim.fn.executable(binary) == 1
end

local function configured_name_set()
  local result = {}
  for _, name in ipairs(settings.lsp.servers) do
    result[name] = true
  end
  return result
end

local function select_lsp_config(action)
  local filetype = vim.bo.filetype
  local allowed = configured_name_set()
  local choices = {}

  for _, config in ipairs(vim.lsp.get_configs({ filetype = filetype })) do
    if allowed[config.name] then
      local enabled = vim.lsp.is_enabled(config.name)
      if action == "enable" then
        if executable_available(config.name) and (session_disabled[config.name] or not enabled) then
          choices[#choices + 1] = config.name
        end
      elseif enabled then
        choices[#choices + 1] = config.name
      end
    end
  end

  table.sort(choices)
  if #choices == 0 then
    vim.notify(
      string.format("No configured LSPs to %s for filetype %q", action, filetype),
      vim.log.levels.INFO,
      { title = "LSP session" }
    )
    return
  end

  vim.ui.select(choices, {
    prompt = string.format("%s LSP config for session (global)", action == "enable" and "Enable" or "Disable"),
  }, function(name)
    if not name then
      return
    end

    if action == "enable" then
      session_disabled[name] = nil
      vim.lsp.enable(name)
      vim.notify("Enabled LSP config for this session: " .. name)
    else
      session_disabled[name] = true
      vim.lsp.enable(name, false)
      vim.notify("Disabled LSP config for this session: " .. name)
    end
  end)
end

return {
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    cmd = {
      "LspInfo",
      "LspLog",
      "ConfigRefreshLsp",
      "ConfigEnableLsp",
      "ConfigDisableLsp",
    },
    dependencies = {
      "mason-org/mason.nvim",
      "saghen/blink.cmp",
    },
    config = function()
      local capabilities = vim.lsp.protocol.make_client_capabilities()
      local ok, blink = pcall(require, "blink.cmp")
      if ok then
        capabilities = blink.get_lsp_capabilities(capabilities)
      end

      local servers = {
        lua_ls = {
          settings = {
            Lua = {
              runtime = { version = "LuaJIT" },
              diagnostics = { globals = { "vim" } },
              workspace = {
                checkThirdParty = false,
                library = { vim.env.VIMRUNTIME },
              },
              telemetry = { enable = false },
              format = { enable = false },
            },
          },
        },
        ty = {},
        ruff = {},
        vtsls = {
          settings = typescript_settings(),
          before_init = function(_, config)
            local root_dir = config.root_dir or vim.uv.cwd()
            local tsdk = js_tool.typescript_sdk(root_dir)
            if tsdk then
              config.settings = config.settings or {}
              config.settings.typescript = config.settings.typescript or {}
              config.settings.typescript.tsdk = tsdk
            end
          end,
        },
        eslint = {
          settings = {
            validate = "on",
            run = "onType",
            format = false,
            quiet = false,
            onIgnoredFiles = "off",
            workingDirectory = { mode = "auto" },
            codeAction = {
              disableRuleComment = { enable = true, location = "separateLine" },
              showDocumentation = { enable = true },
            },
            codeActionOnSave = { enable = false, mode = "all" },
            problems = { shortenToSingleLine = false },
          },
        },
        gopls = {
          settings = {
            gopls = {
              gofumpt = true,
              staticcheck = true,
              analyses = {
                shadow = true,
                unusedparams = true,
              },
            },
          },
        },
        clangd = {
          cmd = { "clangd", "--background-index", "--clang-tidy" },
        },
        rust_analyzer = {
          settings = {
            ["rust-analyzer"] = vim.fn.executable("cargo-clippy") == 1 and {
              check = { command = "clippy" },
            } or {},
          },
        },
        bashls = {},
        jsonls = {},
        yamlls = {},
        html = {},
        cssls = {},
        marksman = {},
      }

      for name, config in pairs(servers) do
        config.capabilities = vim.tbl_deep_extend("force", {}, capabilities, config.capabilities or {})
        vim.lsp.config(name, config)
        add_large_file_root_guard(name)
      end

      local group = vim.api.nvim_create_augroup("ConfigLsp", { clear = true })
      vim.api.nvim_create_autocmd("LspAttach", {
        group = group,
        callback = function(args)
          local client = vim.lsp.get_client_by_id(args.data.client_id)
          if not client then
            return
          end

          if large_file.is(args.buf) or large_file.check_lines(args.buf) then
            vim.schedule(function()
              pcall(vim.lsp.buf_detach_client, args.buf, client.id)
            end)
            return
          end

          if client.name == "ruff" then
            client.server_capabilities.hoverProvider = false
          end

          if client.name == "vtsls" or client.name == "eslint" then
            client.server_capabilities.documentFormattingProvider = false
            client.server_capabilities.documentRangeFormattingProvider = false
          end

          enable_document_highlight(args.buf, client)

          if client.name == "vtsls" and client:supports_method("textDocument/inlayHint") then
            vim.lsp.inlay_hint.enable(true, { bufnr = args.buf })
          end
        end,
      })

      vim.api.nvim_create_autocmd("LspDetach", {
        group = group,
        callback = function(args)
          vim.schedule(function()
            if vim.api.nvim_buf_is_valid(args.buf) then
              cleanup_document_highlight(args.buf)
            end
          end)
        end,
      })

      local function refresh_lsp(notify)
        local enabled = 0
        local disabled = 0

        for _, name in ipairs(settings.lsp.servers) do
          local available = executable_available(name)
          local should_enable = available and not session_disabled[name]
          local is_enabled = vim.lsp.is_enabled(name)

          if should_enable and not is_enabled then
            vim.lsp.enable(name)
            enabled = enabled + 1
          elseif not should_enable and is_enabled then
            vim.lsp.enable(name, false)
            disabled = disabled + 1
          end
        end

        if notify then
          vim.notify(string.format("LSP environment refreshed: %d enabled, %d disabled", enabled, disabled))
        end
      end

      vim.api.nvim_create_user_command("ConfigRefreshLsp", function()
        refresh_lsp(true)
      end, { desc = "Re-scan environment while preserving session-disabled LSP configs", force = true })

      vim.api.nvim_create_user_command("ConfigEnableLsp", function()
        select_lsp_config("enable")
      end, { desc = "Enable a relevant configured LSP for this session", force = true })

      vim.api.nvim_create_user_command("ConfigDisableLsp", function()
        select_lsp_config("disable")
      end, { desc = "Disable a relevant configured LSP for this session", force = true })

      refresh_lsp(false)
    end,
  },
}
