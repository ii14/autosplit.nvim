local api, fn = vim.api, vim.fn

---Make the current split vertical if there is enough space for it
return function(win, prev)
  if not win or not prev then
    prev = fn.winnr('#')
    -- if prev is 0 it's probably a new tab. invalid anyway
    if prev == 0 then return end
    prev = fn.win_getid(prev)

    win = api.nvim_get_current_win()
  end

  local textwidth = vim.g.autosplit_tw
  if type(textwidth) ~= 'number' or textwidth < 1 then
    textwidth = 80
  end
  local twcurr = api.nvim_buf_get_option(api.nvim_win_get_buf(win), 'textwidth')
  if twcurr == 0 then
    twcurr = textwidth
  end
  local twprev = api.nvim_buf_get_option(api.nvim_win_get_buf(prev), 'textwidth')
  if twprev == 0 then
    twprev = textwidth
  end

  -- win_splitmove triggers WinNew, temporarily disable it
  local eventignore = api.nvim_get_option('eventignore')
  api.nvim_command('set eventignore+=WinNew')
  local ok, err = pcall(fn.win_splitmove, win, prev, {
    -- the vertical condition is not perfect, it doesn't take into account
    -- that there already might be another vertical split and after :wincmd =
    -- the space for next vertical split might be actually there. maybe checking
    -- &columns and excluding splits with &winfixedwidth would be better?
    vertical = api.nvim_win_get_width(prev) >= twcurr + twprev,
  })
  api.nvim_set_option('eventignore', eventignore)
  assert(ok, err)
end
