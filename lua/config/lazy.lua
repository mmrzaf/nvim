local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  if vim.fn.executable("git") ~= 1 then
    vim.notify("git is required to bootstrap lazy.nvim", vim.log.levels.ERROR)
    return
  end
  local output = vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "--branch=stable",
    "https://github.com/folke/lazy.nvim.git",
    lazypath,
  })

  if vim.v.shell_error ~= 0 then
    vim.notify("Failed to install lazy.nvim:\n" .. output, vim.log.levels.ERROR)
    return
  end
end

vim.opt.rtp:prepend(lazypath)

local ok, lazy = pcall(require, "lazy")
if not ok then
  vim.notify("lazy.nvim is installed but could not be loaded", vim.log.levels.ERROR)
  return
end

lazy.setup({
  spec = {
    { import = "plugins" },
  },
  defaults = {
    lazy = false,
    version = false,
  },
  install = {
    colorscheme = { "catppuccin-nvim", "habamax", "default" },
  },
  checker = {
    enabled = false,
  },
  change_detection = {
    notify = false,
  },
  ui = {
    border = "rounded",
  },
})
