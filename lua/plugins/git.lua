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
        local gs = require("gitsigns")
        local function map(mode, lhs, rhs, desc)
          vim.keymap.set(mode, lhs, rhs, {
            buffer = bufnr,
            silent = true,
            desc = desc,
          })
        end

        map("n", "]h", function()
          gs.nav_hunk("next")
        end, "Next Git hunk")
        map("n", "[h", function()
          gs.nav_hunk("prev")
        end, "Previous Git hunk")
        map("n", "<leader>hp", gs.preview_hunk, "Preview Git hunk")
        map("n", "<leader>hs", gs.stage_hunk, "Stage Git hunk")
        map("n", "<leader>hr", gs.reset_hunk, "Reset Git hunk")
        map("x", "<leader>hs", function()
          gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
        end, "Stage selected Git hunk")
        map("x", "<leader>hr", function()
          gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
        end, "Reset selected Git hunk")
        map("n", "<leader>hS", gs.stage_buffer, "Stage buffer")
        map("n", "<leader>hu", gs.undo_stage_hunk, "Undo staged hunk")
        map("n", "<leader>hb", function()
          gs.blame_line({ full = true })
        end, "Blame line")
        map("n", "<leader>hd", gs.diffthis, "Diff against index")
        map("n", "<leader>hD", function()
          gs.diffthis("~")
        end, "Diff against previous commit")
        map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<cr>", "Select Git hunk")
      end,
    },
  },
}
