-- lua/just_logs.lua
local M = {}

M.procs = {}
M.log_buf = nil
M.log_win = nil
M.log_height = 12 -- tweak if you want a taller/shorter log pane
M.ns = vim.api.nvim_create_namespace("just_logs")

-- remove ANSI color/CSI/OSC sequences
local function strip_ansi(s)
	if not s then
		return s
	end
	-- CSI: ESC [ ... command
	s = s:gsub("\27%[[0-9;:%?]*[ -/]*[@-~]", "")
	-- OSC: ESC ] ... (terminated by BEL or ST)
	s = s:gsub("\27%].-[\7\27\\]", "")
	return s
end

-- sanitize and normalize incoming job lines
local function sanitize_lines(lines)
	if not lines then
		return {}
	end
	local out = {}
	for _, l in ipairs(lines) do
		if l and l ~= "" then
			-- drop all carriage returns (progress updaters use these mid-line)
			l = l:gsub("\r", "")
			l = strip_ansi(l)
			if l ~= "" then
				table.insert(out, l)
			end
		end
	end
	return out
end

-- Create (or reuse) the scratch buffer that holds logs
-- Create (or reuse) the scratch buffer that holds logs
local function get_log_buf()
	if M.log_buf and vim.api.nvim_buf_is_valid(M.log_buf) then
		return M.log_buf
	end

	local buf = vim.api.nvim_create_buf(false, true) -- listed=false, scratch
	M.log_buf = buf

	-- buffer options
	vim.bo[buf].buftype = "nofile"
	vim.bo[buf].swapfile = false
	vim.bo[buf].bufhidden = "wipe"
	vim.bo[buf].filetype = "log"

	-- write header while modifiable is true, then lock it
	vim.bo[buf].modifiable = true
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "just logs:", "──────────", "" })
	vim.bo[buf].modifiable = false

	-- optional highlight links (safe even if groups don’t exist)
	vim.api.nvim_set_hl(0, "JustLogInfo", { link = "DiagnosticOk", default = true })
	vim.api.nvim_set_hl(0, "JustLogWarn", { link = "DiagnosticWarn", default = true })
	vim.api.nvim_set_hl(0, "JustLogError", { link = "DiagnosticError", default = true })
	vim.api.nvim_set_hl(0, "JustLogDefault", { link = "Comment", default = true })

	return buf
end

-- Ensure we have a bottom horizontal split showing the log buffer
local function ensure_log_win()
	local buf = get_log_buf()

	-- if already visible in some window, reuse it
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		if vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_buf(win) == buf then
			M.log_win = win
			return win
		end
	end

	local curwin = vim.api.nvim_get_current_win()

	-- open bottom split with fixed height, show our buffer, then return focus
	vim.cmd("botright " .. tostring(M.log_height) .. "split")
	M.log_win = vim.api.nvim_get_current_win()
	vim.api.nvim_win_set_buf(M.log_win, buf)

	-- window-local options
	vim.wo[M.log_win].number = false
	vim.wo[M.log_win].relativenumber = false
	vim.wo[M.log_win].wrap = false
	vim.wo[M.log_win].cursorline = false
	vim.wo[M.log_win].signcolumn = "no"

	-- put cursor back to where the user was
	if curwin ~= M.log_win then
		vim.api.nvim_set_current_win(curwin)
	end

	return M.log_win
end

-- utility to toggle modifiable only during writes
local function with_modifiable(buf, f)
	local prev = vim.bo[buf].modifiable
	vim.bo[buf].modifiable = true
	local ok, err = pcall(f)
	vim.bo[buf].modifiable = prev
	if not ok then
		error(err)
	end
end

-- very dumb classifier for highlight choice
local function classify_line(s)
	local l = s:lower()
	if l:find("error", 1, true) or l:find("[stderr]", 1, true) then
		return "JustLogError"
	elseif l:find("warn", 1, true) then
		return "JustLogWarn"
	elseif l:find("info", 1, true) then
		return "JustLogInfo"
	else
		return nil -- no highlight
	end
end

local function append_to_log(lines)
	lines = sanitize_lines(lines)
	if #lines == 0 then
		return
	end

	local buf = get_log_buf()
	-- make sure window exists so the user sees updates
	ensure_log_win()

	local start_line = vim.api.nvim_buf_line_count(buf)
	with_modifiable(buf, function()
		vim.api.nvim_buf_set_lines(buf, start_line, start_line, false, lines)
	end)

	-- add highlights for the newly appended lines
	for i, s in ipairs(lines) do
		local hl = classify_line(s)
		if hl then
			-- clear any existing highlight on this line in our namespace, then add
			vim.api.nvim_buf_add_highlight(buf, M.ns, hl, start_line + i - 1, 0, -1)
		end
	end

	-- auto-scroll to bottom if the log window is open
	if M.log_win and vim.api.nvim_win_is_valid(M.log_win) then
		local line_count = vim.api.nvim_buf_line_count(buf)
		vim.api.nvim_win_set_cursor(M.log_win, { line_count, 0 })
	end
end

function M.run_just(args)
	local fname = vim.fn.getcwd() .. "/Justfile"
	if vim.fn.filereadable(fname) == 0 then
		vim.notify("No Justfile in cwd", vim.log.levels.WARN)
		return
	end

	-- make sure the pane is visible before output starts
	ensure_log_win()
	append_to_log({
		"",
		"▶ Running: just" .. (args and #args > 0 and (" " .. table.concat(args, " ")) or ""),
		"────────────────────",
	})

	local cmd = { "just" }
	if type(args) == "table" and #args > 0 then
		for _, a in ipairs(args) do
			table.insert(cmd, a)
		end
	end

	local job_id = vim.fn.jobstart(cmd, {
		stdout_buffered = false,
		stderr_buffered = false,

		on_stdout = function(_, data, _)
			if data then
				vim.schedule(function()
					append_to_log(data)
				end)
			end
		end,

		on_stderr = function(_, data, _)
			if data then
				vim.schedule(function()
					local tagged = {}
					for _, l in ipairs(sanitize_lines(data)) do
						table.insert(tagged, "[stderr] " .. l)
					end
					append_to_log(tagged)
				end)
			end
		end,

		on_exit = function(_, code, _)
			M.procs[job_id] = nil
			vim.schedule(function()
				append_to_log({
					"────────────────────",
					"just exited with code: " .. tostring(code),
					"",
				})
			end)
		end,
	})

	if job_id > 0 then
		M.procs[job_id] = true
		vim.notify("Started just (job " .. job_id .. ")", vim.log.levels.INFO)
	else
		vim.notify("Failed to start just", vim.log.levels.ERROR)
	end
end

function M.show_logs()
	ensure_log_win()
end

function M.clear_logs()
	local buf = get_log_buf()
	with_modifiable(buf, function()
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "just logs:", "──────────", "" })
	end)
	-- clear our highlights
	vim.api.nvim_buf_clear_namespace(buf, M.ns, 0, -1)
end

function M.kill_all()
	for pid, _ in pairs(M.procs) do
		pcall(vim.fn.jobstop, pid)
	end
	M.procs = {}
end

function M.setup(opts)
	opts = opts or {}
	if type(opts.height) == "number" then
		M.log_height = opts.height
	end

	vim.keymap.set("n", "<leader>j", function()
		M.run_just()
	end, { desc = "Run just" })
	vim.keymap.set("n", "<leader>jj", function()
		-- prompt for args and run: e.g. "build --verbose"
		local input = vim.fn.input("just args: ")
		if input ~= nil then
			local parsed = {}
			for token in string.gmatch(input, "%S+") do
				table.insert(parsed, token)
			end
			M.run_just(parsed)
		end
	end, { desc = "Run just with args" })
	vim.keymap.set("n", "<leader>jl", M.show_logs, { desc = "Show just logs" })
	vim.keymap.set("n", "<leader>jc", M.clear_logs, { desc = "Clear just logs" })

	vim.api.nvim_create_autocmd("VimLeavePre", {
		callback = function()
			M.kill_all()
		end,
	})
end

return M
