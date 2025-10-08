local M = {}

M.procs = {}

function M.run_just()
  local fname = vim.fn.getcwd() .. "/Justfile"
  if vim.fn.filereadable(fname) == 0 then
    vim.notify("No Justfile in cwd", vim.log.levels.WARN)
    return
  end
  local job_id = vim.fn.jobstart({ "just" }, {
    stdout_buffered = true,
    stderr_buffered = true,
    on_stdout = function(_, data, _)
      if data then
        vim.schedule(function()
          print(table.concat(data, "\n"))
        end)
      end
    end,
    on_stderr = function(_, data, _)
      if data then
        vim.schedule(function()
          vim.notify(table.concat(data, "\n"), vim.log.levels.ERROR)
        end)
      end
    end,
    on_exit = function(_, code, _)
      M.procs[job_id] = nil
      vim.schedule(function()
        vim.notify("just exited with code: " .. tostring(code), vim.log.levels.INFO)
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

function M.kill_all()
  for pid, _ in pairs(M.procs) do
    vim.fn.jobstop(pid)
  end
  M.procs = {}
end

function M.setup()
  vim.keymap.set("n", "<leader>j", M.run_just, { desc = "Run just" })

  vim.api.nvim_create_autocmd("VimLeavePre", {
    callback = function() M.kill_all() end,
  })
end

return M

