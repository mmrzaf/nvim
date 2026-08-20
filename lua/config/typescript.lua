local js_tool = require("util.js_tool")

local M = {}

local jobs = {}
local ts_filetypes = {
  javascript = true,
  javascriptreact = true,
  typescript = true,
  typescriptreact = true,
}

local tsconfig_names = { "tsconfig.json", "jsconfig.json" }
local eslint_config_names = {
  "eslint.config.js",
  "eslint.config.mjs",
  "eslint.config.cjs",
  "eslint.config.ts",
  "eslint.config.mts",
  "eslint.config.cts",
  ".eslintrc",
  ".eslintrc.js",
  ".eslintrc.cjs",
  ".eslintrc.json",
  ".eslintrc.yaml",
  ".eslintrc.yml",
}

local function buffer_dir(bufnr)
  local name = vim.api.nvim_buf_get_name(bufnr or 0)
  if name == "" or name:match("^[%a][%w+.-]*://") then
    return vim.uv.cwd()
  end
  return vim.fs.dirname(name)
end

local function extend_command(prefix, ...)
  local command = vim.deepcopy(prefix)
  for _, value in ipairs({ ... }) do
    command[#command + 1] = value
  end
  return command
end

local function joined_output(result)
  local stdout = result.stdout or ""
  local stderr = result.stderr or ""
  if stdout ~= "" and stderr ~= "" and not stdout:match("\n$") then
    return stdout .. "\n" .. stderr
  end
  return stdout .. stderr
end

local function modified_buffers_under(cwd)
  local root = vim.fs.normalize(cwd)
  local modified = {}

  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr) and vim.bo[bufnr].modified then
      local name = vim.api.nvim_buf_get_name(bufnr)
      if name ~= "" and not name:match("^[%a][%w+.-]*://") then
        local path = vim.fs.normalize(name)
        if path == root or vim.startswith(path, root .. "/") then
          modified[#modified + 1] = path
        end
      end
    end
  end

  table.sort(modified)
  return modified
end

local function notify_modified(cwd, action, refuse)
  local modified = modified_buffers_under(cwd)
  if #modified == 0 then
    return true
  end

  local preview = {}
  for index = 1, math.min(#modified, 4) do
    preview[#preview + 1] = vim.fn.fnamemodify(modified[index], ":~:.")
  end
  local suffix = #modified > 4 and string.format(" (+%d more)", #modified - 4) or ""
  local message = string.format("%s reads files on disk; modified buffers: %s%s", action, table.concat(preview, ", "), suffix)

  if refuse then
    vim.notify("Refusing " .. message, vim.log.levels.ERROR)
    return false
  end

  vim.notify(message, vim.log.levels.WARN)
  return true
end

local function set_quickfix(title, items, open)
  vim.fn.setqflist({}, " ", { title = title, items = items })
  if open and #items > 0 then
    vim.cmd("botright copen")
  end
end

local function run_job(kind, command, opts, on_exit)
  if jobs[kind] then
    vim.notify(kind .. " is already running", vim.log.levels.WARN)
    return
  end

  jobs[kind] = vim.system(command, opts, function(result)
    jobs[kind] = nil
    vim.schedule(function()
      on_exit(result)
    end)
  end)
end

local function parse_tsc_output(text, cwd)
  local items = {}
  local last

  for line in vim.gsplit(text or "", "\n", { plain = true, trimempty = true }) do
    local file, lnum, col, severity, code, message = line:match("^(.-)%((%d+),(%d+)%)%: (%a+) TS(%d+)%: (.*)$")
    if file then
      last = {
        filename = file:sub(1, 1) == "/" and file or vim.fs.joinpath(cwd, file),
        lnum = tonumber(lnum),
        col = tonumber(col),
        type = severity == "error" and "E" or "W",
        text = string.format("TS%s: %s", code, message),
      }
      items[#items + 1] = last
    elseif last and line:match("^%s+") then
      last.text = last.text .. " " .. vim.trim(line)
    elseif line ~= "" then
      last = { text = line, type = "E" }
      items[#items + 1] = last
    end
  end

  return items
end

local function has_project_references(config)
  local fd = io.open(config, "r")
  if not fd then
    return false
  end
  local content = fd:read("*a") or ""
  fd:close()
  return content:match('"references"%s*:') ~= nil
end

local function eslint_context(bufnr)
  local start = buffer_dir(bufnr)
  local workspace = js_tool.workspace(start)
  local config = js_tool.find_up(eslint_config_names, start, workspace)
  local package = js_tool.find_up("package.json", start, workspace)

  local root_markers = vim.deepcopy(eslint_config_names)
  root_markers[#root_markers + 1] = "package.json"
  local boundary = js_tool.find_up(root_markers, start, workspace)
  local cwd = boundary and vim.fs.dirname(boundary)
  if not cwd then
    return nil, "No ESLint config or package.json found above the current buffer"
  end

  local eslint = js_tool.resolve("eslint", start)
  if not eslint then
    return nil, "ESLint is not available in this project/environment"
  end

  return {
    argv = eslint.argv,
    source = eslint.source,
    exec_cwd = eslint.cwd,
    cwd = cwd,
    config = config,
    package = package,
  }
end

local function parse_eslint_json(stdout)
  local ok, decoded = pcall(vim.json.decode, stdout or "")
  if not ok or type(decoded) ~= "table" then
    return nil
  end

  local items = {}
  for _, result in ipairs(decoded) do
    for _, message in ipairs(result.messages or {}) do
      items[#items + 1] = {
        filename = result.filePath,
        lnum = message.line or 1,
        col = message.column or 1,
        end_lnum = message.endLine,
        end_col = message.endColumn,
        type = message.severity == 2 and "E" or "W",
        text = (message.ruleId and (message.ruleId .. ": ") or "") .. (message.message or "ESLint issue"),
      }
    end
  end
  return items
end

local function source_action(bufnr, kind, client_name)
  local clients = vim.lsp.get_clients({ bufnr = bufnr })
  local found = false
  for _, client in ipairs(clients) do
    if client.name == client_name and client:supports_method("textDocument/codeAction") then
      found = true
      break
    end
  end

  if not found then
    vim.notify(client_name .. " is not attached with code-action support", vim.log.levels.WARN)
    return
  end

  vim.api.nvim_buf_call(bufnr, function()
    vim.lsp.buf.code_action({
      apply = true,
      context = { only = { kind } },
      filter = function(_, client_id)
        local client = vim.lsp.get_client_by_id(client_id)
        return client ~= nil and client.name == client_name
      end,
    })
  end)
end

function M.typecheck(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local start = buffer_dir(bufnr)
  local config = js_tool.find_up(tsconfig_names, start)
  if not config then
    vim.notify("No tsconfig.json or jsconfig.json found", vim.log.levels.WARN)
    return
  end

  local tsc = js_tool.resolve("tsc", start)
  if not tsc then
    vim.notify("TypeScript compiler (tsc) is not available in this project/environment", vim.log.levels.WARN)
    return
  end

  local cwd = vim.fs.dirname(config)
  notify_modified(cwd, "TypeScript typecheck", false)

  if has_project_references(config) then
    vim.notify(
      "This TypeScript config uses project references. Non-emitting tsc cannot fully validate a reference graph; use :TypeScriptBuildCheck / <leader>cB for explicit build mode.",
      vim.log.levels.WARN
    )
    return
  end

  local command = extend_command(tsc.argv, "--noEmit", "--pretty", "false", "-p", config)
  local label = "TypeScript typecheck"
  vim.notify(string.format("%s started (%s)", label, tsc.source))
  local exec_cwd = tsc.cwd or cwd
  run_job(label, command, { cwd = exec_cwd, text = true }, function(result)
    local items = parse_tsc_output(joined_output(result), exec_cwd)
    set_quickfix(label, items, result.code ~= 0)

    if result.code == 0 then
      vim.notify(label .. " passed")
    else
      vim.notify(string.format("%s failed (%d issue%s)", label, #items, #items == 1 and "" or "s"), vim.log.levels.ERROR)
    end
  end)
end

function M.buildcheck(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local start = buffer_dir(bufnr)
  local config = js_tool.find_up(tsconfig_names, start)
  if not config then
    vim.notify("No tsconfig.json or jsconfig.json found", vim.log.levels.WARN)
    return
  end

  if not has_project_references(config) then
    M.typecheck(bufnr)
    return
  end

  local tsc = js_tool.resolve("tsc", start)
  if not tsc then
    vim.notify("TypeScript compiler (tsc) is not available in this project/environment", vim.log.levels.WARN)
    return
  end

  local cwd = vim.fs.dirname(config)
  notify_modified(cwd, "TypeScript solution build-check", false)

  local command = extend_command(tsc.argv, "-b", config, "--pretty", "false")
  local label = "TypeScript solution build-check"
  vim.notify(
    string.format("%s started (%s); build mode may update configured outputs and .tsbuildinfo", label, tsc.source),
    vim.log.levels.WARN
  )

  local exec_cwd = tsc.cwd or cwd
  run_job(label, command, { cwd = exec_cwd, text = true }, function(result)
    local items = parse_tsc_output(joined_output(result), exec_cwd)
    set_quickfix(label, items, result.code ~= 0)

    if result.code == 0 then
      vim.notify(label .. " passed")
    else
      vim.notify(string.format("%s failed (%d issue%s)", label, #items, #items == 1 and "" or "s"), vim.log.levels.ERROR)
    end
  end)
end

function M.lint(bufnr, fix)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local ctx, err = eslint_context(bufnr)
  if not ctx then
    vim.notify(err, vim.log.levels.WARN)
    return
  end

  if not notify_modified(ctx.cwd, fix and "ESLint --fix" or "ESLint project lint", fix) then
    return
  end

  local command = extend_command(ctx.argv, ctx.cwd, "--format", "json")
  if fix then
    command[#command + 1] = "--fix"
  end

  local label = fix and "ESLint project fix" or "ESLint project lint"
  vim.notify(string.format("%s started (%s)", label, ctx.source))
  run_job(label, command, { cwd = ctx.exec_cwd or ctx.cwd, text = true }, function(result)
    if fix then
      vim.cmd("checktime")
    end
    local items = parse_eslint_json(result.stdout)
    if not items then
      local detail = vim.trim((result.stderr or "") ~= "" and result.stderr or (result.stdout or ""))
      set_quickfix(label, detail ~= "" and { { text = detail, type = "E" } } or {}, result.code ~= 0)
      vim.notify(label .. " failed to produce valid JSON output", vim.log.levels.ERROR)
      return
    end

    set_quickfix(label, items, #items > 0)
    if result.code == 0 and #items == 0 then
      vim.notify(label .. " passed")
    else
      vim.notify(string.format("%s: %d issue%s", label, #items, #items == 1 and "" or "s"), result.code == 0 and vim.log.levels.WARN or vim.log.levels.ERROR)
    end
  end)
end

function M.info(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local start = buffer_dir(bufnr)
  local config = js_tool.find_up(tsconfig_names, start)
  local eslint = eslint_context(bufnr)
  local tsc = js_tool.resolve("tsc", start)
  local tsdk = js_tool.typescript_sdk(start)

  local lines = {
    "TypeScript project tools",
    "buffer: " .. (vim.api.nvim_buf_get_name(bufnr) ~= "" and vim.api.nvim_buf_get_name(bufnr) or "[unnamed]"),
    "workspace: " .. js_tool.workspace(start),
    "tsconfig: " .. (config or "not found"),
    "tsc: " .. (tsc and (table.concat(tsc.argv, " ") .. " [" .. tsc.source .. "]") or "not available"),
    "tsc exec cwd: " .. (tsc and tsc.cwd or "n/a"),
    "tsdk: " .. (tsdk or "auto/bundled"),
  }

  if type(eslint) == "table" then
    lines[#lines + 1] = "eslint: " .. table.concat(eslint.argv, " ") .. " [" .. eslint.source .. "]"
    lines[#lines + 1] = "eslint target: " .. eslint.cwd
    lines[#lines + 1] = "eslint exec cwd: " .. (eslint.exec_cwd or eslint.cwd)
    lines[#lines + 1] = "eslint config: " .. (eslint.config or "inferred from package/project")
  else
    lines[#lines + 1] = "eslint: not available"
  end

  vim.notify(table.concat(lines, "\n"))
end

function M.is_typescript_buffer(bufnr)
  return ts_filetypes[vim.bo[bufnr or 0].filetype] == true
end

function M.setup()
  vim.api.nvim_create_user_command("TypeScriptTypecheck", function()
    M.typecheck(0)
  end, { desc = "Run project-local TypeScript typecheck", force = true })

  vim.api.nvim_create_user_command("TypeScriptBuildCheck", function()
    M.buildcheck(0)
  end, { desc = "Run TypeScript project-reference build check", force = true })

  vim.api.nvim_create_user_command("TypeScriptLint", function(args)
    M.lint(0, args.bang)
  end, { bang = true, desc = "Run project-local ESLint (! applies fixes)", force = true })

  vim.api.nvim_create_user_command("TypeScriptInfo", function()
    M.info(0)
  end, { desc = "Show TypeScript/ESLint project tool resolution", force = true })

  local group = vim.api.nvim_create_augroup("ConfigTypeScript", { clear = true })
  vim.api.nvim_create_autocmd("FileType", {
    group = group,
    pattern = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
    callback = function(args)
      local keymaps = require("config.keymaps")
      local function map(lhs, rhs, desc)
        keymaps.bufmap(args.buf, "n", lhs, rhs, desc)
      end

      map("<leader>ct", function()
        M.typecheck(args.buf)
      end, "TypeScript typecheck project")
      map("<leader>cB", function()
        M.buildcheck(args.buf)
      end, "TypeScript build-check solution")
      map("<leader>cl", function()
        M.lint(args.buf, false)
      end, "ESLint project lint")
      map("<leader>cL", function()
        M.lint(args.buf, true)
      end, "ESLint project lint and fix")
      map("<leader>ci", function()
        M.info(args.buf)
      end, "TypeScript project info")
      map("<leader>co", function()
        source_action(args.buf, "source.organizeImports", "vtsls")
      end, "TypeScript organize imports")
      map("<leader>cs", function()
        source_action(args.buf, "source.sortImports", "vtsls")
      end, "TypeScript sort imports")
      map("<leader>cu", function()
        source_action(args.buf, "source.removeUnusedImports", "vtsls")
      end, "TypeScript remove unused imports")
      map("<leader>cU", function()
        source_action(args.buf, "source.removeUnused.ts", "vtsls")
      end, "TypeScript remove unused code")
      map("<leader>cm", function()
        source_action(args.buf, "source.addMissingImports.ts", "vtsls")
      end, "TypeScript add missing imports")
      map("<leader>cF", function()
        source_action(args.buf, "source.fixAll.ts", "vtsls")
      end, "TypeScript fix all")
      map("<leader>ce", function()
        source_action(args.buf, "source.fixAll.eslint", "eslint")
      end, "ESLint fix current file")

      keymaps.refresh_clue(args.buf)
    end,
  })
end

return M
