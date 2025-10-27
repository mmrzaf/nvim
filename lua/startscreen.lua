local M = {}

local cfg = {
	title = "    Neovim  ",
	header = { "make today a clean edit" },
	max_recent = 8,

	width_min = 46,
	pad_h = 3, -- left/right inner padding
	pad_v = 1, -- top/bottom inner padding
	border = "rounded", -- "rounded" | "single" | "double" | "solid"
	zindex = 50,

	highlights = {
		win = "NormalFloat",
		border = "FloatBorder",
		header = "Title",
		key = "Special",
		hint = "Comment",
		footer = "NonText",
	},

	auto_close_on_any_key = false,
}

local state = { buf = nil, win = nil, recents = {} }

local function is_open()
	return state.win and vim.api.nvim_win_is_valid(state.win) and state.buf and vim.api.nvim_buf_is_valid(state.buf)
end

local function close()
	if state.win and vim.api.nvim_win_is_valid(state.win) then
		pcall(vim.api.nvim_win_close, state.win, true)
	end
	if state.buf and vim.api.nvim_buf_is_valid(state.buf) then
		pcall(vim.api.nvim_buf_delete, state.buf, { force = true })
	end
	state.buf, state.win, state.recents = nil, nil, {}
end

local function has_telescope()
	return pcall(require, "telescope.builtin")
end
local function trim_home(p)
	return (p or ""):gsub("^" .. vim.pesc(vim.loop.os_homedir()), "~")
end
local function truncate_middle(str, max)
	if #str <= max then
		return str
	end
	if max < 10 then
		return str:sub(1, max)
	end
	local half = math.floor((max - 1) / 2) - 1
	return str:sub(1, half) .. "…" .. str:sub(-half)
end

local function collect_recent(maxn)
	local out, seen = {}, {}
	for _, f in ipairs(vim.v.oldfiles or {}) do
		if vim.loop.fs_stat(f) and not seen[f] then
			out[#out + 1] = f
			seen[f] = true
			if #out >= maxn then
				break
			end
		end
	end
	return out
end

local function map(buf, lhs, rhs, desc)
	vim.keymap.set("n", lhs, rhs, { buffer = buf, nowait = true, silent = true, desc = "Start: " .. (desc or lhs) })
end

local function act_new()
	close()
	vim.cmd("enew | startinsert")
end

local function act_find()
	close()
	if has_telescope() then
		require("telescope.builtin").find_files()
	else
		local p = vim.fn.input("Find file: ", "", "file")
		if p ~= "" then
			vim.cmd.edit(p)
		end
	end
end

local function act_grep()
	close()
	if has_telescope() then
		require("telescope.builtin").live_grep()
	else
		local pat = vim.fn.input("Grep: ")
		if pat == "" then
			return
		end
		vim.cmd("vimgrep /" .. vim.fn.escape(pat, "/") .. "/gj **/*")
		vim.cmd("copen")
	end
end

local function act_config()
	close()
	vim.cmd("e $MYVIMRC")
end

local function act_edit()
	close()
	local p = vim.fn.input("Edit: ", "", "file")
	if p ~= "" then
		vim.cmd.edit(p)
	end
end

local function act_quit()
	close()
	vim.cmd("qa")
end

local function act_recent(i)
	local f = state.recents[i]
	if f then
		close()
		vim.cmd.edit(vim.fn.fnameescape(f))
	end
end

local function build_lines(width)
	local lines = {}

	-- header
	lines[#lines + 1] = ""
	for _, l in ipairs(cfg.header) do
		lines[#lines + 1] = "  " .. l
	end
	lines[#lines + 1] = ""

	-- menu
	local menu = {
		{ "n", "New file", act_new },
		{ "f", "Find file", act_find },
		{ "g", "Live grep", act_grep },
		{ "e", "Edit path…", act_edit },
		{ "c", "Open config", act_config },
		{ "q", "Quit", act_quit },
	}
	for _, m in ipairs(menu) do
		lines[#lines + 1] = ("  %s  %s"):format(m[1], m[2])
	end

	-- recents
	state.recents = collect_recent(cfg.max_recent)
	if #state.recents > 0 then
		lines[#lines + 1] = ""
		lines[#lines + 1] = "  Recent"
		local maxw = math.max(24, width - (cfg.pad_h * 2) - 8)
		for i, f in ipairs(state.recents) do
			local short = truncate_middle(trim_home(f), maxw)
			lines[#lines + 1] = ("   %d  %s"):format(i, short)
		end
	end

	lines[#lines + 1] = ""
	lines[#lines + 1] = "  Press n/f/g/e/c/q or 1.." .. tostring(cfg.max_recent)
	lines[#lines + 1] = ""

	return lines
end

local function center_dims(lines)
	local ui = vim.api.nvim_list_uis()[1] or { width = 120, height = 40 }
	local longest = 0
	for _, l in ipairs(lines) do
		longest = math.max(longest, vim.fn.strdisplaywidth(l))
	end
	local content_w = math.max(cfg.width_min, longest + cfg.pad_h * 2)
	local content_h = #lines + cfg.pad_v * 2
	local win_w = math.min(content_w + 2, ui.width - 4) -- +2 for border
	local win_h = math.min(content_h + 2, ui.height - 4)
	local col = math.floor((ui.width - win_w) / 2)
	local row = math.floor((ui.height - win_h) / 3) -- slightly high
	return win_w, win_h, col, row
end

local function render()
	if not is_open() then
		return
	end

	local win_w = vim.api.nvim_win_get_width(state.win)
	local lines = build_lines(win_w)

	vim.bo[state.buf].modifiable = true
	vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, {})

	-- top padding
	for _ = 1, cfg.pad_v do
		table.insert(lines, 1, "")
	end
	-- side padding
	for i, s in ipairs(lines) do
		lines[i] = string.rep(" ", cfg.pad_h) .. s
	end
	-- bottom padding
	for _ = 1, cfg.pad_v do
		lines[#lines + 1] = ""
	end

	vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)
	vim.bo[state.buf].modifiable = false

	-- highlights
	local function hl(line, start, finish, group)
		pcall(vim.api.nvim_buf_add_highlight, state.buf, -1, group, line, start, finish)
	end

	local L0 = 0
	local header_start = L0 + cfg.pad_v + 1
	for i = 1, #cfg.header do
		hl(header_start + i - 1, cfg.pad_h, -1, cfg.highlights.header)
	end

	local menu_start = header_start + #cfg.header + 2
	local menu_len = 6
	for i = 0, menu_len - 1 do
		local ln = menu_start + i
		hl(ln, cfg.pad_h + 2, cfg.pad_h + 3, cfg.highlights.key) -- key char
		hl(ln, cfg.pad_h + 4, -1, cfg.highlights.hint) -- label
	end

	if #state.recents > 0 then
		local label = menu_start + menu_len + 1
		hl(label, cfg.pad_h, -1, cfg.highlights.header)
		for i = 1, #state.recents do
			local ln = label + i
			hl(ln, cfg.pad_h + 3, cfg.pad_h + 4, cfg.highlights.key) -- number
			hl(ln, cfg.pad_h + 6, -1, cfg.highlights.hint) -- path
		end
	end

	local footer = #lines - 1
	hl(footer, cfg.pad_h, -1, cfg.highlights.footer)
end

local function open_window(lines)
	if state.buf and vim.api.nvim_buf_is_valid(state.buf) then
		pcall(vim.api.nvim_buf_delete, state.buf, { force = true })
	end
	state.buf = vim.api.nvim_create_buf(false, true)

	local win_w, win_h, col, row = center_dims(lines)
	state.win = vim.api.nvim_open_win(state.buf, true, {
		relative = "editor",
		row = row,
		col = col,
		width = win_w,
		height = win_h,
		border = cfg.border,
		title = cfg.title,
		title_pos = "center",
		noautocmd = true,
		zindex = cfg.zindex,
	})

	-- buffer/window opts
	vim.bo[state.buf].buftype = "nofile"
	vim.bo[state.buf].bufhidden = "wipe"
	vim.bo[state.buf].swapfile = false
	vim.bo[state.buf].filetype = "startscreen"
	vim.wo[state.win].wrap = false
	vim.wo[state.win].cursorline = false
	vim.wo[state.win].signcolumn = "no"
	vim.wo[state.win].statuscolumn = ""
	vim.wo[state.win].winhighlight = string.format(
		"Normal:%s,NormalFloat:%s,FloatBorder:%s,CursorLine:%s",
		cfg.highlights.win,
		cfg.highlights.win,
		cfg.highlights.border,
		cfg.highlights.win
	)

	-- keymaps
	map(state.buf, "n", act_new, "New")
	map(state.buf, "f", act_find, "Find")
	map(state.buf, "g", act_grep, "Grep")
	map(state.buf, "e", act_edit, "Edit")
	map(state.buf, "c", act_config, "Config")
	map(state.buf, "q", act_quit, "Quit")
	for i = 1, cfg.max_recent do
		map(state.buf, tostring(i), function()
			act_recent(i)
		end, "Recent " .. i)
	end

	if cfg.auto_close_on_any_key then
		vim.keymap.set("n", "<Any>", function()
			if is_open() then
				close()
			end
		end, { buffer = state.buf, nowait = true, silent = true })
	end

	render()
end

function M.setup(opts)
	if opts then
		for k, v in pairs(opts) do
			if type(v) == "table" and type(cfg[k]) == "table" then
				for kk, vv in pairs(v) do
					cfg[k][kk] = vv
				end
			else
				cfg[k] = v
			end
		end
	end

	vim.api.nvim_create_autocmd("VimEnter", {
		callback = function()
			if vim.fn.argc() ~= 0 then
				return
			end
			if vim.bo.buftype ~= "" then
				return
			end
			if vim.fn.line("$") > 1 or vim.fn.getline(1) ~= "" then
				return
			end
			local preview = build_lines(vim.o.columns)
			open_window(preview)
		end,
	})

	vim.api.nvim_create_autocmd("VimResized", {
		callback = function()
			if is_open() then
				render()
			end
		end,
	})

	vim.api.nvim_create_autocmd("InsertEnter", {
		callback = function()
			if is_open() then
				close()
			end
		end,
	})

	vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
		callback = function()
			if is_open() and vim.bo.filetype ~= "startscreen" then
				close()
			end
		end,
	})

	vim.api.nvim_create_autocmd("WinLeave", {
		callback = function()
			if is_open() then
				local cur = vim.api.nvim_get_current_win()
				if cur ~= state.win then
					close()
				end
			end
		end,
	})

	vim.api.nvim_create_autocmd("BufWipeout", {
		pattern = "*",
		callback = function(args)
			if state.buf and args.buf == state.buf then
				state.buf, state.win = nil, nil
			end
		end,
	})
end

return M
