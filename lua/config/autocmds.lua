local group = vim.api.nvim_create_augroup("ConfigCore", { clear = true })
local large_file = require("util.large_file")
local clipboard_warning_shown = false

vim.api.nvim_create_autocmd("TextYankPost", {
  group = group,
  callback = function()
    vim.hl.on_yank({ timeout = 150 })

    local event = vim.v.event
    if event.operator ~= "y" then
      return
    end

    local ok, err = pcall(vim.fn.setreg, "+", event.regcontents, event.regtype)
    if not ok and not clipboard_warning_shown then
      clipboard_warning_shown = true
      vim.schedule(function()
        vim.notify("Unable to copy yank to system clipboard: " .. tostring(err), vim.log.levels.WARN)
      end)
    end
  end,
})

vim.api.nvim_create_autocmd("BufWritePre", {
  group = group,
  callback = function(args)
    local path = vim.api.nvim_buf_get_name(args.buf)
    if path == "" or path:match("^[%a][%w+.-]*://") then
      return
    end
    local parent = vim.fs.dirname(path)
    if parent and vim.fn.isdirectory(parent) == 0 then
      vim.fn.mkdir(parent, "p")
    end
  end,
})

vim.api.nvim_create_autocmd("BufReadPost", {
  group = group,
  callback = function(args)
    large_file.check_lines(args.buf)

    local mark = vim.api.nvim_buf_get_mark(args.buf, '"')
    local line_count = vim.api.nvim_buf_line_count(args.buf)
    if vim.api.nvim_get_current_buf() == args.buf and mark[1] > 0 and mark[1] <= line_count then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end

    if large_file.is(args.buf) and not vim.b[args.buf].config_large_file_notified then
      vim.b[args.buf].config_large_file_notified = true
      vim.schedule(function()
        vim.notify(
          "Large-file mode: LSP, Treesitter, completion, formatting, Gitsigns, and Markview are limited",
          vim.log.levels.WARN
        )
      end)
    end
  end,
})

vim.api.nvim_create_autocmd("BufReadPre", {
  group = group,
  callback = function(args)
    large_file.detect(args.buf, args.file)
  end,
})

vim.api.nvim_create_autocmd({ "FocusGained", "TermClose", "TermLeave" }, {
  group = group,
  command = "checktime",
})

vim.api.nvim_create_autocmd("FileType", {
  group = group,
  pattern = {
    "lua",
    "javascript",
    "javascriptreact",
    "typescript",
    "typescriptreact",
    "json",
    "json5",
    "jsonc",
    "yaml",
    "html",
    "css",
  },
  callback = function(args)
    vim.bo[args.buf].shiftwidth = 2
    vim.bo[args.buf].tabstop = 2
    vim.bo[args.buf].softtabstop = 2
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  group = group,
  pattern = { "markdown", "text", "gitcommit" },
  callback = function()
    vim.opt_local.spell = true
    vim.opt_local.wrap = true
    vim.opt_local.linebreak = true
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  group = group,
  pattern = { "help", "qf", "checkhealth" },
  callback = function(args)
    require("config.keymaps").bufmap(args.buf, "n", "q", "<cmd>close<cr>", "Close window")
  end,
})
