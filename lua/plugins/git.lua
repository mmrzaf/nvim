local large_file = require("util.large_file")

return {
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      signs = {
        add = { text = "+" },
        change = { text = "~" },
        delete = { text = "_" },
        topdelete = { text = "‾" },
        changedelete = { text = "~" },
        untracked = { text = "┆" },
      },
      current_line_blame = false,
      attach_to_untracked = true,
      max_file_length = 20000,
      on_attach = function(bufnr)
        if large_file.is(bufnr) or large_file.check_lines(bufnr) then
          return false
        end

        local gs = require("gitsigns")
        local keymaps = require("config.keymaps")
        local function map(mode, lhs, rhs, desc)
          keymaps.bufmap(bufnr, mode, lhs, rhs, desc)
        end

        map("n", "]h", function()
          gs.nav_hunk("next")
        end, "Next Git hunk")
        map("n", "[h", function()
          gs.nav_hunk("prev")
        end, "Previous Git hunk")
        map("n", "]H", function()
          gs.nav_hunk("next", { target = "staged" })
        end, "Next staged Git hunk")
        map("n", "[H", function()
          gs.nav_hunk("prev", { target = "staged" })
        end, "Previous staged Git hunk")

        map("n", "<leader>gp", gs.preview_hunk, "Preview Git hunk")
        map("n", "<leader>ga", gs.stage_hunk, "Stage/unstage Git hunk")
        map("n", "<leader>gr", gs.reset_hunk, "Reset Git hunk")
        map("x", "<leader>ga", function()
          gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
        end, "Stage/unstage selected Git hunk")
        map("x", "<leader>gr", function()
          gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
        end, "Reset selected Git hunk")
        map("n", "<leader>gA", gs.stage_buffer, "Stage Git buffer")
        map("n", "<leader>gb", function()
          gs.blame_line({ full = true })
        end, "Blame Git line")
        map("n", "<leader>gd", gs.diffthis, "Diff against Git index")
        map("n", "<leader>gD", function()
          gs.diffthis("~")
        end, "Diff against previous commit")
        map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<cr>", "Select Git hunk")

        keymaps.refresh_clue(bufnr)
      end,
    },
  },
}
