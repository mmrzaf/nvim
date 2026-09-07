vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- This configuration is pure Lua and does not use legacy remote-plugin hosts.
vim.g.loaded_node_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_python3_provider = 0
vim.g.loaded_ruby_provider = 0

local version = vim.version()
if version.major == 0 and version.minor < 12 then
  error("This config requires Neovim 0.12 or newer")
end

require("config.options")
require("config.clipboard").setup()
require("config.diagnostics")
require("config.keymaps")
require("config.autocmds")
require("config.typescript").setup()
require("config.lazy")

require("config.just").setup()
