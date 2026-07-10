return {
  {
    "akinsho/toggleterm.nvim",
    version = "2.*",
    cmd = { "ToggleTerm", "TermExec" },
    keys = {
      {
        "<C-\\>",
        function()
          require("config.terminal").toggle_shell()
        end,
        mode = { "n", "t" },
        desc = "Toggle shell terminal",
      },
      {
        "<leader>gg",
        function()
          require("config.terminal").toggle_git()
        end,
        desc = "Toggle LazyGit",
      },
    },
    config = function()
      require("toggleterm").setup({
        size = 14,
        open_mapping = nil,
        shade_terminals = false,
        start_in_insert = true,
        insert_mappings = false,
        terminal_mappings = false,
        persist_size = true,
        persist_mode = true,
        direction = "horizontal",
        close_on_exit = true,
        auto_scroll = true,
        shell = vim.o.shell,
      })
      require("config.terminal").setup()
    end,
  },
}
