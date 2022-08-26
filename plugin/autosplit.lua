if vim.g.autosplit_loaded ~= nil then
  return
end
vim.g.autosplit_loaded = 1

local api, fn = vim.api, vim.fn

local augroup = api.nvim_create_augroup('autosplit', {})
local pending = nil

local DEFAULT_BT = {'help'}
local DEFAULT_FT = {'man', 'fugitive', 'gitcommit'}

local function create_bufenter()
  return api.nvim_create_autocmd('BufEnter', {
    group = augroup,
    desc = 'autosplit',
    callback = function()
      if not pending then return end

      local buf = api.nvim_get_current_buf()
      if not api.nvim_buf_is_loaded(buf) then return end

      local win = api.nvim_get_current_win()
      local prev = pending[win]
      if not prev then return end

      if not api.nvim_win_is_valid(win) or not api.nvim_win_is_valid(prev) then
        pending[win] = nil
        return
      end

      if vim.g.autosplit_all then
        require('autosplit')(win, prev)
      else
        local bts = vim.g.autosplit_bt
        if type(bts) ~= 'table' then bts = DEFAULT_BT end
        local fts = vim.g.autosplit_ft
        if type(fts) ~= 'table' then fts = DEFAULT_FT end

        local bt = api.nvim_buf_get_option(buf, 'buftype')
        local ft = api.nvim_buf_get_option(buf, 'filetype')

        if vim.tbl_contains(bts, bt) or vim.tbl_contains(fts, ft) then
          require('autosplit')(win, prev)
        end
      end

      pending[win] = nil
    end,
  })
end

api.nvim_create_autocmd('WinNew', {
  group = augroup,
  desc = 'autosplit',
  callback = function()
    local win = api.nvim_get_current_win()
    if pending and pending[win] then
      return
    end

    local prev = fn.winnr('#')
    if prev == 0 then
      return
    elseif pending then
      pending[win] = fn.win_getid(prev)
    else
      pending = { [win] = fn.win_getid(prev) }
      local autocmd = create_bufenter()
      -- BufEnter should be triggered just after WinNew
      vim.schedule(function()
        api.nvim_del_autocmd(autocmd)
        pending = nil
      end)
    end
  end,
})
