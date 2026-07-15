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
    cmd = { "ConformInfo", "Format" },
    keys = {
      { "<Space>f", "<cmd>Format<cr>", mode = "n", desc = "Format buffer" },
      { "<Space>f", ":Format<cr>", mode = "x", desc = "Format selection" },
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
          json5 = { "prettierd", "prettier", stop_after_first = true },
          jsonc = { "prettierd", "prettier", stop_after_first = true },
          yaml = { "prettierd", "prettier", stop_after_first = true },
          markdown = { "prettierd", "prettier", stop_after_first = true },
          bash = { "shfmt" },
          sh = { "shfmt" },
          toml = { "taplo" },
          rust = { "rustfmt", lsp_format = "fallback" },
          c = { "clang_format" },
          cpp = { "clang_format" },
        },
      })

      vim.api.nvim_create_user_command("Format", format_range, {
        range = true,
        desc = "Format buffer or selected range",
        force = true,
      })
    end,
  },
}
