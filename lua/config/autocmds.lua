local group = vim.api.nvim_create_augroup("ConfigCore", { clear = true })
local large_file = require("util.large_file")

vim.api.nvim_create_autocmd("TextYankPost", {
  group = group,
  callback = function()
    vim.hl.on_yank({ timeout = 150 })
  end,
})

vim.api.nvim_create_autocmd("BufWritePre", {
  group = group,
  callback = function(args)
    local path = vim.api.nvim_buf_get_name(args.buf)
    if path == "" or path:match("^%w+://") then
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
        vim.notify("Large-file mode: LSP, Treesitter, Markview, and AI are limited", vim.log.levels.WARN)
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
  pattern = { "lua", "javascript", "javascriptreact", "typescript", "typescriptreact", "json", "yaml", "html", "css" },
  callback = function()
    vim.bo.shiftwidth = 2
    vim.bo.tabstop = 2
    vim.bo.softtabstop = 2
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
    vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = args.buf, silent = true, desc = "Close window" })
  end,
})
