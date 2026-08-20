local root = require("util.root")

local function project_picker(name, opts)
  return function()
    local fzf = require("fzf-lua")
    local picker_opts = vim.tbl_extend("force", { cwd = root.get(0) }, opts or {})
    fzf[name](picker_opts)
  end
end

return {
  {
    "ibhagwan/fzf-lua",
    event = "VeryLazy",
    cmd = "FzfLua",
    dependencies = { "nvim-mini/mini.nvim" },
    keys = {
      -- Find / inspect
      { "<leader>fa", project_picker("global"), desc = "Find anything" },
      { "<leader>ff", project_picker("files"), desc = "Find project files" },
      { "<leader>fg", project_picker("git_files"), desc = "Find Git files" },
      { "<leader>fb", "<cmd>FzfLua buffers sort_mru=true sort_lastused=true<cr>", desc = "Find buffers" },
      { "<leader>fr", "<cmd>FzfLua oldfiles<cr>", desc = "Recent files" },
      { "<leader>fH", "<cmd>FzfLua history<cr>", desc = "File/buffer history" },
      { "<leader>fh", "<cmd>FzfLua helptags<cr>", desc = "Find help" },
      { "<leader>fk", "<cmd>FzfLua keymaps<cr>", desc = "Find keymaps" },
      { "<leader>fc", "<cmd>FzfLua commands<cr>", desc = "Find commands" },
      { "<leader>f:", "<cmd>FzfLua command_history<cr>", desc = "Command history" },
      { "<leader>f/", "<cmd>FzfLua search_history<cr>", desc = "Search history" },
      { '<leader>f"', "<cmd>FzfLua registers<cr>", desc = "Find registers" },
      { "<leader>fm", "<cmd>FzfLua marks<cr>", desc = "Find marks" },
      { "<leader>fj", "<cmd>FzfLua jumps<cr>", desc = "Find jumps" },
      { "<leader>fC", "<cmd>FzfLua changes<cr>", desc = "Find changes" },
      { "<leader>fu", "<cmd>FzfLua undotree<cr>", desc = "Undo history" },
      { "<leader>ft", "<cmd>FzfLua tabs<cr>", desc = "Find tabs" },
      { "<leader>fq", "<cmd>FzfLua quickfix<cr>", desc = "Find quickfix entries" },
      { "<leader>fl", "<cmd>FzfLua loclist<cr>", desc = "Find location-list entries" },
      { "<leader>fR", "<cmd>FzfLua resume<cr>", desc = "Resume picker" },

      -- Search
      { "<leader>/", project_picker("live_grep"), desc = "Live grep project" },
      { "<leader>sg", project_picker("live_grep_glob"), desc = "Live grep with glob" },
      { "<leader>sw", project_picker("grep_cword"), mode = "n", desc = "Search word in project" },
      { "<leader>sw", project_picker("grep_visual"), mode = "x", desc = "Search selection in project" },
      { "<leader>sW", project_picker("grep_cWORD"), desc = "Search WORD in project" },
      { "<leader>sb", "<cmd>FzfLua grep_curbuf<cr>", desc = "Search current buffer" },
      { "<leader>sl", "<cmd>FzfLua lines<cr>", desc = "Search open-buffer lines" },
      { "<leader>sd", "<cmd>FzfLua diagnostics_document<cr>", desc = "Search buffer diagnostics" },
      { "<leader>sD", "<cmd>FzfLua diagnostics_workspace<cr>", desc = "Search workspace diagnostics" },
      { "<leader>sf", "<cmd>FzfLua lsp_finder<cr>", desc = "Search LSP locations" },
      { "<leader>ss", "<cmd>FzfLua lsp_document_symbols<cr>", desc = "Search document symbols" },
      { "<leader>sS", "<cmd>FzfLua lsp_live_workspace_symbols<cr>", desc = "Search workspace symbols" },

      -- Git discovery
      { "<leader>gs", project_picker("git_status"), desc = "Git status" },
      { "<leader>gc", project_picker("git_commits"), desc = "Git commits" },
      { "<leader>gC", project_picker("git_bcommits"), desc = "Git buffer commits" },
      { "<leader>gB", project_picker("git_branches"), desc = "Git branches" },
      { "<leader>gf", project_picker("git_diff"), desc = "Git changed files" },
      { "<leader>gh", project_picker("git_hunks"), desc = "Git hunks" },
      { "<leader>gl", project_picker("git_reflog"), desc = "Git reflog" },
      { "<leader>gS", project_picker("git_stash"), desc = "Git stash" },
      { "<leader>gt", project_picker("git_tags"), desc = "Git tags" },
      { "<leader>gw", project_picker("git_worktrees"), desc = "Git worktrees" },
    },
    config = function()
      local fzf = require("fzf-lua")
      fzf.setup({
        "default-title",
        defaults = {
          file_icons = "mini",
        },
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
            true,
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
