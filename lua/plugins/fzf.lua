return {
  {
    "ibhagwan/fzf-lua",
    event = "VeryLazy",
    cmd = "FzfLua",
    keys = {
      { "<leader><leader>", "<cmd>FzfLua files<cr>", desc = "Find files" },
      { "<leader>ff", "<cmd>FzfLua files<cr>", desc = "Find files" },
      { "<leader>fg", "<cmd>FzfLua git_files<cr>", desc = "Find Git files" },
      { "<leader>fb", "<cmd>FzfLua buffers sort_mru=true sort_lastused=true<cr>", desc = "Find buffers" },
      { "<leader>fr", "<cmd>FzfLua oldfiles<cr>", desc = "Recent files" },
      { "<leader>/", "<cmd>FzfLua live_grep<cr>", desc = "Live grep" },
      { "<leader>sw", "<cmd>FzfLua grep_cword<cr>", desc = "Search word" },
      { "<leader>sb", "<cmd>FzfLua grep_curbuf<cr>", desc = "Search buffer" },
      { "<leader>sh", "<cmd>FzfLua helptags<cr>", desc = "Help tags" },
      { "<leader>sk", "<cmd>FzfLua keymaps<cr>", desc = "Keymaps" },
      { "<leader>sc", "<cmd>FzfLua commands<cr>", desc = "Commands" },
      { "<leader>sd", "<cmd>FzfLua diagnostics_document<cr>", desc = "Buffer diagnostics" },
      { "<leader>sD", "<cmd>FzfLua diagnostics_workspace<cr>", desc = "Workspace diagnostics" },
      { "<leader>ss", "<cmd>FzfLua lsp_document_symbols<cr>", desc = "Document symbols" },
      { "<leader>sS", "<cmd>FzfLua lsp_live_workspace_symbols<cr>", desc = "Workspace symbols" },
      { "<leader>sr", "<cmd>FzfLua resume<cr>", desc = "Resume search" },
      { "<leader>gs", "<cmd>FzfLua git_status<cr>", desc = "Git status" },
      { "<leader>gc", "<cmd>FzfLua git_commits<cr>", desc = "Git commits" },
    },
    config = function()
      local fzf = require("fzf-lua")
      fzf.setup({
        "max-perf",
        winopts = {
          height = 0.85,
          width = 0.85,
          row = 0.5,
          col = 0.5,
          border = "rounded",
          preview = {
            border = "border",
            layout = "flex",
          },
        },
        fzf_opts = {
          ["--layout"] = "reverse",
        },
        keymap = {
          fzf = {
            ["ctrl-u"] = "half-page-up",
            ["ctrl-d"] = "half-page-down",
            ["ctrl-f"] = "preview-page-down",
            ["ctrl-b"] = "preview-page-up",
          },
        },
        files = {
          cwd_prompt = false,
          hidden = true,
          follow = false,
        },
        grep = {
          hidden = true,
          follow = false,
        },
      })
      fzf.register_ui_select()
    end,
  },
}
