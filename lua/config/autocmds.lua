local aug = vim.api.nvim_create_augroup
local au = vim.api.nvim_create_autocmd

au('TextYankPost', { group = aug('yank_highlight', { clear = true }), callback = function() vim.highlight.on_yank({ timeout = 120 }) end })
au('VimResized', { group = aug('resize_splits', { clear = true }), command = 'tabdo wincmd =' })
au('BufReadPost', { group = aug('restore_cursor', { clear = true }), callback = function()
  local m = vim.api.nvim_buf_get_mark(0, '"')
  local l = vim.api.nvim_buf_line_count(0)
  if m[1] > 0 and m[1] <= l then pcall(vim.api.nvim_win_set_cursor, 0, m) end
end })
au({ 'FocusGained', 'BufEnter' }, { group = aug('checktime', { clear = true }), command = 'checktime' })

-- keep scratch/aux buffers harmless
au('BufEnter', { group = aug('scratch_sane', { clear = true }), callback = function()
  local bt = vim.bo.buftype
  if bt == 'nofile' or bt == 'quickfix' or bt == 'help' or bt == 'prompt' then
    vim.bo.modified = false
    vim.bo.swapfile = false
  end
end })

-- trim trailing spaces on write (except markdown/diff)
au('BufWritePre', { group = aug('trim_ws', { clear = true }), callback = function()
  if vim.bo.filetype ~= 'markdown' and not vim.wo.diff then
    local view = vim.fn.winsaveview()
    vim.cmd([[%s/\s\+$//e]])
    vim.fn.winrestview(view)
  end
end })
