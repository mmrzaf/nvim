local large_file = require("util.large_file")
local js_tool = require("util.js_tool")

-- Filetypes where Prettier is the only acceptable formatter: never fall back to
-- an LSP formatter just because the project has no Prettier CLI.
local external_only = {}
for _, ft in ipairs(require("config.settings").filetypes.prettier) do
  external_only[ft] = true
end

local function buffer_dir(bufnr)
  local name = vim.api.nvim_buf_get_name(bufnr)
  if name == "" or name:match("^[%a][%w+.-]*://") then
    return vim.uv.cwd()
  end
  return vim.fs.dirname(name)
end

local function project_prettier(bufnr)
  local resolved = js_tool.resolve("prettier", buffer_dir(bufnr))
  if not resolved then
    -- An intentionally missing command lets Conform report this formatter as
    -- unavailable instead of silently switching to an LSP formatter.
    return { command = "__config_prettier_unavailable__" }
  end

  local prefix = vim.list_slice(resolved.argv, 2)
  local function args(ctx, range)
    local result = vim.deepcopy(prefix)
    vim.list_extend(result, { "--stdin-filepath", "$FILENAME" })
    if range then
      local util = require("conform.util")
      local start_offset, end_offset = util.get_offsets_from_range(ctx.buf, ctx.range)
      vim.list_extend(result, { "--range-start=" .. start_offset, "--range-end=" .. end_offset })
    end
    return result
  end

  return {
    command = resolved.argv[1],
    args = function(_, ctx)
      return args(ctx, false)
    end,
    range_args = function(_, ctx)
      return args(ctx, true)
    end,
    cwd = function()
      return resolved.cwd or js_tool.package_dir(buffer_dir(bufnr))
    end,
  }
end

local function format_range(args)
  local bufnr = vim.api.nvim_get_current_buf()
  if large_file.is(bufnr) or large_file.check_lines(bufnr) then
    vim.notify("Formatting is disabled for large files", vim.log.levels.WARN)
    return
  end

  local range
  if args.count ~= -1 then
    local end_line = vim.api.nvim_buf_get_lines(bufnr, args.line2 - 1, args.line2, true)[1] or ""
    range = {
      start = { args.line1, 0 },
      ["end"] = { args.line2, #end_line },
    }
  end

  local filetype = vim.bo[bufnr].filetype
  require("conform").format({
    bufnr = bufnr,
    async = false,
    timeout_ms = 3000,
    lsp_format = external_only[filetype] and "never" or "fallback",
    range = range,
  })
end

return {
  {
    "stevearc/conform.nvim",
    cmd = { "ConformInfo", "Format" },
    keys = {
      { "<leader>cf", "<cmd>Format<cr>", mode = "n", desc = "Format buffer" },
      { "<leader>cf", ":Format<cr>", mode = "x", desc = "Format selection" },
    },
    config = function()
      local conform = require("conform")
      local function prettier_chain()
        return { "project_prettier", stop_after_first = true }
      end

      conform.setup({
        notify_on_error = true,
        notify_no_formatters = true,
        default_format_opts = {
          lsp_format = "fallback",
          timeout_ms = 3000,
        },
        formatters_by_ft = {
          lua = { "stylua" },
          python = { "ruff_format" },
          go = { "goimports", "gofumpt" },
          javascript = prettier_chain(),
          javascriptreact = prettier_chain(),
          typescript = prettier_chain(),
          typescriptreact = prettier_chain(),
          html = prettier_chain(),
          css = prettier_chain(),
          json = prettier_chain(),
          json5 = prettier_chain(),
          jsonc = prettier_chain(),
          yaml = prettier_chain(),
          markdown = prettier_chain(),
          bash = { "shfmt" },
          sh = { "shfmt" },
          toml = { "taplo" },
          rust = { "rustfmt" },
          c = { "clang_format" },
          cpp = { "clang_format" },
        },
        formatters = {
          project_prettier = project_prettier,
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
