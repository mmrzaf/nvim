local settings = require("config.settings").dev
local root = require("util.root")
local shellwords = require("util.shellwords")

local M = {
  job_id = nil,
  log_buf = nil,
  log_win = nil,
  namespace = vim.api.nvim_create_namespace("ConfigJustLogs"),
}

local header = {
  "just logs",
  string.rep("─", 80),
  "",
}

local function strip_ansi(text)
  text = text:gsub("\27%[[0-9;:%?]*[ -/]*[@-~]", "")
  text = text:gsub("\27%].-[\7\27\\]", "")
  return text:gsub("\r", "")
end

local function sanitize(lines, prefix, drop_trailing_sentinel)
  lines = lines or {}
  local output = {}
  local last = #lines
  if drop_trailing_sentinel and last > 0 and lines[last] == "" then
    last = last - 1
  end

  for index = 1, last do
    local line = strip_ansi(lines[index] or "")
    output[#output + 1] = line == "" and "" or (prefix or "") .. line
  end
  return output
end

local function with_modifiable(bufnr, callback)
  local previous = vim.bo[bufnr].modifiable
  vim.bo[bufnr].modifiable = true
  local ok, err = pcall(callback)
  vim.bo[bufnr].modifiable = previous
  if not ok then
    error(err)
  end
end

local function get_log_buf()
  if M.log_buf and vim.api.nvim_buf_is_valid(M.log_buf) then
    return M.log_buf
  end

  local bufnr = vim.api.nvim_create_buf(false, true)
  M.log_buf = bufnr
  vim.bo[bufnr].buftype = "nofile"
  vim.bo[bufnr].bufhidden = "hide"
  vim.bo[bufnr].swapfile = false
  vim.bo[bufnr].filetype = "justlog"
  vim.bo[bufnr].modifiable = true
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, header)
  vim.bo[bufnr].modifiable = false
  vim.api.nvim_buf_set_name(bufnr, "just://logs")

  vim.api.nvim_set_hl(0, "ConfigJustInfo", { link = "DiagnosticInfo", default = true })
  vim.api.nvim_set_hl(0, "ConfigJustWarn", { link = "DiagnosticWarn", default = true })
  vim.api.nvim_set_hl(0, "ConfigJustError", { link = "DiagnosticError", default = true })

  return bufnr
end

local function ensure_log_win()
  local bufnr = get_log_buf()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_buf(win) == bufnr then
      M.log_win = win
      return win
    end
  end

  local current = vim.api.nvim_get_current_win()
  vim.cmd("botright " .. settings.log_height .. "split")
  local win = vim.api.nvim_get_current_win()
  M.log_win = win
  vim.api.nvim_win_set_buf(win, bufnr)
  vim.wo[win].number = false
  vim.wo[win].relativenumber = false
  vim.wo[win].signcolumn = "no"
  vim.wo[win].wrap = false
  vim.wo[win].cursorline = false
  vim.wo[win].winfixheight = true
  vim.api.nvim_set_current_win(current)
  return win
end

local function classify(line)
  local lowered = line:lower()
  if lowered:find("error", 1, true)
    or lowered:find("fatal", 1, true)
    or lowered:find("failed", 1, true)
    or lowered:find("failure", 1, true)
  then
    return "ConfigJustError"
  end
  if lowered:find("warn", 1, true) or lowered:find("[stderr]", 1, true) then
    return "ConfigJustWarn"
  end
  if lowered:find("info", 1, true) then
    return "ConfigJustInfo"
  end
end

local function trim_log(bufnr)
  local count = vim.api.nvim_buf_line_count(bufnr)
  local excess = count - settings.max_log_lines
  if excess <= 0 then
    return
  end
  local first_data_line = #header
  with_modifiable(bufnr, function()
    vim.api.nvim_buf_set_lines(bufnr, first_data_line, first_data_line + excess, false, {})
  end)
end

local function append(lines, prefix, drop_trailing_sentinel)
  lines = sanitize(lines, prefix, drop_trailing_sentinel)
  if #lines == 0 then
    return
  end

  local bufnr = get_log_buf()
  local start = vim.api.nvim_buf_line_count(bufnr)
  with_modifiable(bufnr, function()
    vim.api.nvim_buf_set_lines(bufnr, start, start, false, lines)
  end)

  for index, line in ipairs(lines) do
    local hl = classify(line)
    if hl then
      local row = start + index - 1
      vim.api.nvim_buf_set_extmark(bufnr, M.namespace, row, 0, {
        end_row = row + 1,
        end_col = 0,
        hl_group = hl,
        hl_eol = true,
      })
    end
  end

  trim_log(bufnr)
  if M.log_win and vim.api.nvim_win_is_valid(M.log_win) then
    local line_count = vim.api.nvim_buf_line_count(bufnr)
    pcall(vim.api.nvim_win_set_cursor, M.log_win, { line_count, 0 })
  end
end

local function just_context()
  local file = root.justfile(0)
  if not file then
    vim.notify("No Justfile found above the current buffer", vim.log.levels.WARN)
    return
  end
  return file, vim.fs.dirname(file)
end

function M.run(args)
  if vim.fn.executable("just") ~= 1 then
    vim.notify("just is not installed", vim.log.levels.ERROR)
    return
  end

  if M.job_id then
    vim.notify("A just task is already running; stop it with <leader>jk", vim.log.levels.WARN)
    return
  end

  local justfile, cwd = just_context()
  if not justfile then
    return
  end

  args = args or {}
  local command = { "just", "--justfile", justfile }
  vim.list_extend(command, args)

  local display_command = vim.iter(command):map(vim.fn.shellescape):join(" ")
  ensure_log_win()
  append({
    "",
    "$ " .. display_command,
    string.rep("─", 80),
  })

  local job_id
  job_id = vim.fn.jobstart(command, {
    cwd = cwd,
    stdout_buffered = false,
    stderr_buffered = false,
    on_stdout = function(_, data)
      vim.schedule(function()
        append(data, nil, true)
      end)
    end,
    on_stderr = function(_, data)
      vim.schedule(function()
        append(data, "[stderr] ", true)
      end)
    end,
    on_exit = function(_, code)
      M.job_id = nil
      vim.schedule(function()
        append({
          string.rep("─", 80),
          "just exited with code " .. code,
          "",
        })
      end)
    end,
  })

  if job_id <= 0 then
    vim.notify("Failed to start just", vim.log.levels.ERROR)
    return
  end

  M.job_id = job_id
  vim.notify("Started just task")
end

function M.choose()
  if vim.fn.executable("just") ~= 1 then
    vim.notify("just is not installed", vim.log.levels.ERROR)
    return
  end

  local justfile, cwd = just_context()
  if not justfile then
    return
  end

  vim.system({ "just", "--justfile", justfile, "--summary" }, { cwd = cwd, text = true }, function(result)
    vim.schedule(function()
      if result.code ~= 0 then
        vim.notify(result.stderr ~= "" and result.stderr or "Unable to list just recipes", vim.log.levels.ERROR)
        return
      end

      local recipes = vim.split(vim.trim(result.stdout or ""), "%s+", { trimempty = true })
      if #recipes == 0 then
        vim.notify("No just recipes found", vim.log.levels.WARN)
        return
      end

      pcall(require, "fzf-lua")
      vim.ui.select(recipes, { prompt = "Just recipe" }, function(choice)
        if choice then
          M.run({ choice })
        end
      end)
    end)
  end)
end

function M.prompt()
  vim.ui.input({ prompt = "just arguments: " }, function(input)
    if not input or vim.trim(input) == "" then
      return
    end
    local args, err = shellwords.parse(input)
    if not args then
      vim.notify(err, vim.log.levels.ERROR)
      return
    end
    M.run(args)
  end)
end

function M.show_logs()
  ensure_log_win()
end

function M.clear_logs()
  local bufnr = get_log_buf()
  with_modifiable(bufnr, function()
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, header)
  end)
  vim.api.nvim_buf_clear_namespace(bufnr, M.namespace, 0, -1)
end

function M.stop()
  if not M.job_id then
    vim.notify("No just task is running", vim.log.levels.INFO)
    return
  end
  pcall(vim.fn.jobstop, M.job_id)
  M.job_id = nil
end

function M.setup()
  vim.keymap.set("n", "<leader>jr", M.choose, { desc = "Choose and run just recipe" })
  vim.keymap.set("n", "<leader>ja", M.prompt, { desc = "Run just with arguments" })
  vim.keymap.set("n", "<leader>jl", M.show_logs, { desc = "Show just logs" })
  vim.keymap.set("n", "<leader>jc", M.clear_logs, { desc = "Clear just logs" })
  vim.keymap.set("n", "<leader>jk", M.stop, { desc = "Stop just task" })

  vim.api.nvim_create_user_command("JustChoose", M.choose, { desc = "Choose and run just recipe", force = true })
  vim.api.nvim_create_user_command("JustRun", M.prompt, { desc = "Run just with arguments", force = true })
  vim.api.nvim_create_user_command("JustLogs", M.show_logs, { desc = "Show just logs", force = true })
  vim.api.nvim_create_user_command("JustStop", M.stop, { desc = "Stop just task", force = true })

  local group = vim.api.nvim_create_augroup("ConfigJust", { clear = true })
  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = group,
    callback = function()
      if M.job_id then
        pcall(vim.fn.jobstop, M.job_id)
      end
    end,
  })
end

return M
