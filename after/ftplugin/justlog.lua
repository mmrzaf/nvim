vim.opt_local.number = false
vim.opt_local.relativenumber = false
vim.opt_local.signcolumn = "no"
vim.opt_local.wrap = false
vim.opt_local.spell = false
vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = true, silent = true, desc = "Close log window" })
