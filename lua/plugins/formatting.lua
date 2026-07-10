local settings = require("config.settings").formatting
local large_file = require("util.large_file")

local function format_range(args)
  local range
  if args.count ~= -1 then
    local end_line = vim.api.nvim_buf_get_lines(0, args.line2 - 1, args.line2, true)[1] or ""
    range = {
      start = { args.line1, 0 },
      ["end"] = { args.line2, #end_line },
    }
  end

  require("conform").format({
    async = true,
    lsp_format = "fallback",
    range = range,
  })
end

return {
  {
    "stevearc/conform.nvim",
    event = "BufWritePre",
    cmd = { "ConformInfo", "Format" },
    keys = {
      { "<leader>cf", "<cmd>Format<cr>", mode = "n", desc = "Format buffer" },
      { "<leader>cf", ":Format<cr>", mode = "x", desc = "Format selection" },
    },
    config = function()
      local conform = require("conform")

      conform.setup({
        notify_on_error = true,
        notify_no_formatters = true,
        default_format_opts = {
          lsp_format = "fallback",
        },
        formatters_by_ft = {
          lua = { "stylua" },
          python = { "ruff_format" },
          go = { "goimports", "gofumpt" },
          javascript = { "prettierd", "prettier", stop_after_first = true },
          javascriptreact = { "prettierd", "prettier", stop_after_first = true },
          typescript = { "prettierd", "prettier", stop_after_first = true },
          typescriptreact = { "prettierd", "prettier", stop_after_first = true },
          html = { "prettierd", "prettier", stop_after_first = true },
          css = { "prettierd", "prettier", stop_after_first = true },
          json = { "prettierd", "prettier", stop_after_first = true },
          yaml = { "prettierd", "prettier", stop_after_first = true },
          markdown = { "prettierd", "prettier", stop_after_first = true },
          bash = { "shfmt" },
          sh = { "shfmt" },
          toml = { "taplo" },
          rust = { "rustfmt", lsp_format = "fallback" },
          c = { "clang_format" },
          cpp = { "clang_format" },
        },
        format_on_save = function(bufnr)
          if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
            return
          end
          if large_file.is(bufnr) or large_file.check_lines(bufnr) then
            return
          end
          if not settings.autoformat_filetypes[vim.bo[bufnr].filetype] then
            return
          end
          return {
            timeout_ms = 2000,
            lsp_format = "fallback",
          }
        end,
      })

      vim.api.nvim_create_user_command("Format", format_range, {
        range = true,
        desc = "Format buffer or selected range",
        force = true,
      })

      vim.api.nvim_create_user_command("FormatDisable", function(args)
        if args.bang then
          vim.b.disable_autoformat = true
          vim.notify("Autoformat disabled for this buffer")
        else
          vim.g.disable_autoformat = true
          vim.notify("Autoformat disabled globally")
        end
      end, { bang = true, desc = "Disable autoformat; use ! for current buffer", force = true })

      vim.api.nvim_create_user_command("FormatEnable", function(args)
        if args.bang then
          vim.b.disable_autoformat = false
          vim.notify("Autoformat enabled for this buffer")
        else
          vim.g.disable_autoformat = false
          vim.b.disable_autoformat = false
          vim.notify("Autoformat enabled")
        end
      end, { bang = true, desc = "Enable autoformat; use ! for current buffer", force = true })
    end,
  },
}
