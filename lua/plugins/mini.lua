local function open_files_at_current()
  local files = require("mini.files")
  local path = vim.api.nvim_buf_get_name(0)
  if path == "" or path:match("^[%a][%w+.-]*://") then
    path = require("util.root").get(0)
  end
  files.open(path, true)
end

local function open_files_at_root()
  require("mini.files").open(require("util.root").get(0), true)
end

return {
  {
    "nvim-mini/mini.nvim",
    lazy = false,
    keys = {
      { "<leader>fe", open_files_at_current, desc = "Explore current file" },
      { "<leader>fE", open_files_at_root, desc = "Explore project root" },
    },
    config = function()
      require("mini.ai").setup({ n_lines = 500 })
      require("mini.surround").setup()
      require("mini.pairs").setup()
      require("mini.splitjoin").setup()
      require("mini.bufremove").setup({ silent = true })
      require("mini.icons").setup()
      require("mini.trailspace").setup()
      require("mini.files").setup({
        options = {
          permanent_delete = false,
          use_as_default_explorer = true,
          lsp_timeout = 1000,
        },
        windows = {
          preview = true,
          width_focus = 40,
          width_nofocus = 18,
          width_preview = 55,
        },
      })

      local clue = require("mini.clue")
      local keymaps = require("config.keymaps")
      clue.setup({
        triggers = {
          { mode = { "n", "x" }, keys = "<leader>" },
          { mode = "n", keys = "[" },
          { mode = "n", keys = "]" },
          { mode = "i", keys = "<C-x>" },
          { mode = { "n", "x" }, keys = "g" },
          { mode = { "n", "x" }, keys = "'" },
          { mode = { "n", "x" }, keys = "`" },
          { mode = { "n", "x" }, keys = '"' },
          { mode = { "i", "c" }, keys = "<C-r>" },
          { mode = "n", keys = "<C-w>" },
          { mode = { "n", "x" }, keys = "z" },
        },
        clues = {
          keymaps.groups,
          clue.gen_clues.square_brackets(),
          clue.gen_clues.builtin_completion(),
          clue.gen_clues.g(),
          clue.gen_clues.marks(),
          clue.gen_clues.registers({ show_contents = true }),
          clue.gen_clues.windows({
            submode_move = true,
            submode_navigate = true,
            submode_resize = true,
          }),
          clue.gen_clues.z(),
        },
        window = {
          delay = 250,
          config = {
            border = "rounded",
            width = "auto",
          },
        },
      })
    end,
  },
}
