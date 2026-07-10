local settings = require("config.settings").treesitter
local large_file = require("util.large_file")

return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false,
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter").setup()

      local group = vim.api.nvim_create_augroup("ConfigTreesitter", { clear = true })
      vim.api.nvim_create_autocmd("FileType", {
        group = group,
        pattern = settings.filetypes,
        callback = function(args)
          if large_file.is(args.buf) or large_file.check_lines(args.buf) then
            return
          end
          pcall(vim.treesitter.start, args.buf)
        end,
      })

      vim.api.nvim_create_user_command("ConfigInstallParsers", function()
        require("nvim-treesitter").install(settings.parsers)
      end, { desc = "Install configured Treesitter parsers", force = true })
    end,
  },
}
