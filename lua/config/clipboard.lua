local M = {}

local function executable(name)
  return vim.fn.executable(name) == 1
end

function M.setup()
  local uname = vim.uv.os_uname()
  local release = (uname.release or ""):lower()
  local is_wsl = release:find("microsoft", 1, true) ~= nil

  -- Neovim's native clipboard provider handles Linux, macOS, Windows, SSH,
  -- tmux, and OSC 52. WSL is the one environment where an explicit bridge
  -- remains more predictable.
  if not is_wsl or not executable("clip.exe") or not executable("powershell.exe") then
    return
  end

  local copy = { "clip.exe" }
  local paste = {
    "powershell.exe",
    "-NoLogo",
    "-NoProfile",
    "-Command",
    [=[ [Console]::Out.Write($(Get-Clipboard -Raw).ToString().Replace("`r", "")) ]=],
  }

  vim.g.clipboard = {
    name = "Neovim WSL clipboard",
    copy = {
      ["+"] = copy,
      ["*"] = copy,
    },
    paste = {
      ["+"] = paste,
      ["*"] = paste,
    },
    cache_enabled = 0,
  }
end

return M
