vim.g.mapleader = " "
vim.g.maplocalleader = " "

local version = vim.version()
if version.major == 0 and version.minor < 12 then
  error("This config requires Neovim 0.12 or newer")
end

require("config.options")
require("config.clipboard").setup()
require("config.diagnostics")
require("config.keymaps")
require("config.autocmds")
require("config.lazy")

require("config.dev").setup()
