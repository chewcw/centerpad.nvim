local v = vim.api

local center_buf = {}

-- function to toggle zen mode on
local turn_on = function(config)
  -- Get reference to current_win
  local main_win = v.nvim_get_current_win()

  -- get the user's current options for split directions
  local useropts = {
    splitbelow = vim.o.splitbelow,
    splitright = vim.o.splitright,
  }

  -- Make sure that the user doesn't have more than one window/buffer open at the moment
  if #v.nvim_tabpage_list_wins(0) > 1 and vim.g.center_buf_win_ids[main_win] == "1" then
    print("Please only have one window and buffer open")
    return
  end

  -- create scratch window to the left
  vim.o.splitright = false
  vim.cmd(string.format("%svnew", config.leftpad))
  local leftpad = v.nvim_get_current_buf()
  local left_win_id = vim.fn.win_findbuf(leftpad)[1]
  v.nvim_buf_set_name(leftpad, "leftpad-" .. tostring(main_win))
  v.nvim_set_current_win(main_win)
  vim.api.nvim_set_option_value("buftype", "nofile", { buf = leftpad })
  vim.api.nvim_set_option_value("filetype", "centerpad", { buf = leftpad })
  vim.api.nvim_set_option_value("bufhidden", "hide", { buf = leftpad })
  vim.api.nvim_set_option_value("swapfile", false, { buf = leftpad })
  vim.api.nvim_set_option_value("modifiable", false, { buf = leftpad })
  vim.api.nvim_set_option_value("buflisted", false, { buf = leftpad })
  vim.api.nvim_set_option_value("readonly", true, { buf = leftpad })
  vim.api.nvim_set_option_value("modified", false, { buf = leftpad })
  vim.api.nvim_set_option_value("number", false, { win = left_win_id })
  vim.api.nvim_set_option_value("relativenumber", false, { win = left_win_id })

  -- create scratch window to the right
  vim.o.splitright = true
  vim.cmd(string.format("%svnew", config.rightpad))
  local rightpad = v.nvim_get_current_buf()
  local right_win_id = vim.fn.win_findbuf(rightpad)[1]
  v.nvim_buf_set_name(rightpad, "rightpad-" .. tostring(main_win))
  v.nvim_set_current_win(main_win)
  vim.api.nvim_set_option_value("buftype", "nofile", { buf = rightpad })
  vim.api.nvim_set_option_value("filetype", "centerpad", { buf = rightpad })
  vim.api.nvim_set_option_value("bufhidden", "hide", { buf = rightpad })
  vim.api.nvim_set_option_value("swapfile", false, { buf = rightpad })
  vim.api.nvim_set_option_value("modifiable", false, { buf = rightpad })
  vim.api.nvim_set_option_value("buflisted", false, { buf = rightpad })
  vim.api.nvim_set_option_value("readonly", true, { buf = rightpad })
  vim.api.nvim_set_option_value("modified", false, { buf = rightpad })
  vim.api.nvim_set_option_value("number", false, { win = right_win_id })
  vim.api.nvim_set_option_value("relativenumber", false, { win = right_win_id })

  local center_buf_win_ids = vim.g.center_buf_win_ids or {}
  center_buf_win_ids[tostring(main_win)] = "1"
  vim.g.center_buf_win_ids = center_buf_win_ids

  -- reset the user's split opts
  vim.o.splitbelow = useropts.splitbelow
  vim.o.splitright = useropts.splitright
end

-- function to toggle zen mode off
local turn_off = function(config)
  -- Get reference to current_win
  local main_win = v.nvim_get_current_win()

  -- Get reference to current_buffer
  local curr_buf = v.nvim_get_current_buf()
  local curr_bufname = v.nvim_buf_get_name(curr_buf)

  -- Make sure the currently focused buffer is not a scratch buffer
  if curr_bufname == "leftpad-" .. tostring(main_win) or curr_bufname == "rightpad-" .. tostring(main_win) then
    print("If you want to toggle off zen mode, switch focus out of a scratch buffer")
    return
  end

  -- Delete the scratch buffers
  local windows = v.nvim_tabpage_list_wins(0)
  for _, win in ipairs(windows) do
    local bufnr = v.nvim_win_get_buf(win)
    local cur_name = v.nvim_buf_get_name(bufnr)
    if string.match(cur_name, "leftpad%-" .. main_win) or string.match(cur_name, "rightpad%-" .. main_win) then
      v.nvim_buf_delete(bufnr, { force = true })
    end
  end

  local center_buf_win_ids = vim.g.center_buf_win_ids or {}
  center_buf_win_ids[tostring(main_win)] = "0"
  vim.g.center_buf_win_ids = center_buf_win_ids
end

-- function for user to run, toggling on/off
center_buf.toggle = function(config)
  -- set default options
  config = config or { leftpad = 36, rightpad = 36 }

  local current_win_id = v.nvim_get_current_win()
  -- Ignore if this buffer name contains leftpad- or rightpad-
  local curr_buf = v.nvim_win_get_buf(current_win_id)
  local curr_bufname = v.nvim_buf_get_name(curr_buf)
  if string.match(curr_bufname, "leftpad%-") or string.match(curr_bufname, "rightpad%-") then
    return
  end
  local center_buf_win_ids = vim.g.center_buf_win_ids or {}
  if center_buf_win_ids[tostring(current_win_id)] == "1" then
    turn_off(config)
  else
    turn_on(config)
  end
end

center_buf.run_command = function(...)
  local args = { ... }
  if #args == 1 then
    center_buf.toggle({ leftpad = args[1], rightpad = args[1] })
  elseif #args == 2 then
    center_buf.toggle({ leftpad = args[1], rightpad = args[2] })
  else
    center_buf.toggle()
  end
end

return center_buf
