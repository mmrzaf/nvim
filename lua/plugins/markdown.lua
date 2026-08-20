local large_file = require("util.large_file")
local max_markview_lines = 5000

local function preview_allowed(bufnr)
  bufnr = bufnr or 0

  if large_file.is(bufnr) or large_file.check_lines(bufnr) then
    return false, "Markview is disabled for large files"
  end

  local lines = vim.api.nvim_buf_line_count(bufnr)
  if lines > max_markview_lines then
    return false, string.format("Markview is limited to %d lines (buffer has %d)", max_markview_lines, lines)
  end

  return true
end

return {
  {
    "OXY2DEV/markview.nvim",
    version = "28.*",
    lazy = false,
    dependencies = {
      "catppuccin/nvim",
      "nvim-treesitter/nvim-treesitter",
    },
    config = function()
      require("markview").setup({
        preview = {
          enable = false,
          icon_provider = "internal",
          map_gx = false,
          max_buf_lines = max_markview_lines,
          filetypes = { "markdown" },
          condition = function(bufnr)
            local allowed = preview_allowed(bufnr)
            if not allowed then
              return false
            end
            return nil
          end,
        },
        latex = { enable = false },
        typst = { enable = false },
        yaml = { enable = false },
      })

      local function run(command)
        local allowed, reason = preview_allowed(0)
        if not allowed then
          vim.notify(reason, vim.log.levels.WARN)
          return
        end
        vim.cmd(command)
      end

      local group = vim.api.nvim_create_augroup("ConfigMarkview", { clear = true })
      vim.api.nvim_create_autocmd("FileType", {
        group = group,
        pattern = "markdown",
        callback = function(args)
          local keymaps = require("config.keymaps")
          keymaps.bufmap(args.buf, "n", "<leader>mp", function()
            run("Markview toggle")
          end, "Toggle Markdown preview")

          keymaps.bufmap(args.buf, "n", "<leader>ms", function()
            run("Markview splitToggle")
          end, "Toggle Markdown split preview")

          keymaps.refresh_clue(args.buf)
        end,
      })
    end,
  },
}
