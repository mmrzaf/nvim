local M = {}

local function has(exe)
	return vim.fn.executable(exe) == 1
end
local uname = vim.loop.os_uname()
local is_mac = vim.fn.has("mac") == 1
local is_win = vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1
local is_wsl = (uname.release or ""):lower():find("microsoft") ~= nil
local on_wayland = os.getenv("WAYLAND_DISPLAY") ~= nil
local in_tmux = os.getenv("TMUX") ~= nil
local in_ssh = os.getenv("SSH_TTY") or os.getenv("SSH_CONNECTION")

local provider = nil

if on_wayland and has("wl-copy") and has("wl-paste") then
	provider = {
		name = "wl-clipboard",
		copy = {
			["+"] = "wl-copy --type text/plain",
			["*"] = "wl-copy --primary --type text/plain",
		},
		paste = {
			["+"] = "wl-paste --no-newline",
			["*"] = "wl-paste --primary --no-newline",
		},
	}
elseif has("xclip") then
	provider = {
		name = "xclip",
		copy = { ["+"] = "xclip -selection clipboard -in", ["*"] = "xclip -selection primary -in" },
		paste = { ["+"] = "xclip -selection clipboard -out", ["*"] = "xclip -selection primary -out" },
	}
elseif has("xsel") then
	provider = {
		name = "xsel",
		copy = { ["+"] = "xsel --clipboard --input", ["*"] = "xsel --primary --input" },
		paste = { ["+"] = "xsel --clipboard --output", ["*"] = "xsel --primary --output" },
	}
elseif is_mac and has("pbcopy") and has("pbpaste") then
	provider = {
		name = "pbcopy",
		copy = { ["+"] = "pbcopy", ["*"] = "pbcopy" },
		paste = { ["+"] = "pbpaste", ["*"] = "pbpaste" },
	}
elseif is_wsl and has("clip.exe") then
	provider = {
		name = "wsl-clip",
		copy = { ["+"] = "clip.exe", ["*"] = "clip.exe" },
		paste = {
			["+"] = [[powershell.exe -NoProfile -Command Get-Clipboard]],
			["*"] = [[powershell.exe -NoProfile -Command Get-Clipboard]],
		},
	}
elseif is_win and has("win32yank.exe") then
	provider = {
		name = "win32yank",
		copy = { ["+"] = "win32yank.exe -i --crlf", ["*"] = "win32yank.exe -i --crlf" },
		paste = { ["+"] = "win32yank.exe -o --lf", ["*"] = "win32yank.exe -o --lf" },
	}
end

local use_osc52 = (not provider) or in_tmux or in_ssh

local function enable_osc52_clipboard()
	local ok, osc52 = pcall(require, "osc52")
	if not ok then
		return
	end
	vim.g.clipboard = {
		name = "osc52",
		copy = { ["+"] = osc52.copy, ["*"] = osc52.copy },
		paste = { ["+"] = osc52.paste, ["*"] = osc52.paste },
	}
	vim.api.nvim_create_autocmd("TextYankPost", {
		group = vim.api.nvim_create_augroup("clipboard_osc52", { clear = true }),
		callback = function()
			if vim.v.event.operator == "y" then
				local reg = vim.v.event.regname
				if reg == "" then
					reg = '"'
				end
				require("osc52").copy_register(reg)
			end
		end,
	})
end

function M.setup()
	if provider and not use_osc52 then
		vim.g.clipboard = provider
	elseif use_osc52 then
		enable_osc52_clipboard()
	end

	vim.o.clipboard = "unnamedplus"
end

return M
