local settings = require("config.settings")
local large_file = require("util.large_file")

return {
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    cmd = { "LspInfo", "LspLog", "LspRestart", "LspStart", "LspStop" },
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
        ty = {
          settings = {
            ty = {
              diagnosticMode = "openFilesOnly",
            },
          },
        },
        ruff = {},
        vtsls = {},
        eslint = {
          settings = {
            format = false,
            workingDirectory = { mode = "auto" },
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

          local function map(mode, lhs, rhs, desc)
            vim.keymap.set(mode, lhs, rhs, {
              buffer = args.buf,
              silent = true,
              desc = desc,
            })
          end

          map("n", "gd", vim.lsp.buf.definition, "LSP definition")
          map("n", "gD", vim.lsp.buf.declaration, "LSP declaration")
          map("n", "K", vim.lsp.buf.hover, "LSP hover")
          map("n", "<leader>la", vim.lsp.buf.code_action, "LSP code action")
          map("n", "<leader>lr", vim.lsp.buf.rename, "LSP rename")
          map("n", "<leader>ls", vim.lsp.buf.signature_help, "LSP signature help")
          map("n", "<leader>lR", "<cmd>FzfLua lsp_references<cr>", "LSP references")
          map("n", "<leader>li", "<cmd>FzfLua lsp_implementations<cr>", "LSP implementations")

          if client.name == "ruff" then
            client.server_capabilities.hoverProvider = false
          end

        end,
      })

      local enabled = {}
      for _, name in ipairs(settings.lsp.servers) do
        local binary = settings.lsp.executables[name]
        if not binary or vim.fn.executable(binary) == 1 then
          enabled[#enabled + 1] = name
        end
      end
      vim.lsp.enable(enabled)
    end,
  },
}
