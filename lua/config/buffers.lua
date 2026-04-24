---@class ConfigBuffers
local M = {}

local function current_buf(buf)
  if buf == nil or buf == 0 then
    return vim.api.nvim_get_current_buf()
  end
  return buf
end

local function snacks()
  return require("snacks")
end

function M.is_real_file_buffer(buf)
  if not buf or not vim.api.nvim_buf_is_valid(buf) then
    return false
  end
  if not vim.bo[buf].buflisted or vim.bo[buf].buftype ~= "" then
    return false
  end

  local name = vim.api.nvim_buf_get_name(buf)
  return name ~= "" and vim.fn.isdirectory(name) == 0
end

function M.real_file_buffers(exclude)
  local info = vim.fn.getbufinfo({ buflisted = 1 })
  info = vim.tbl_filter(function(item)
    return item.bufnr ~= exclude and M.is_real_file_buffer(item.bufnr)
  end, info)
  table.sort(info, function(a, b)
    return (a.lastused or 0) > (b.lastused or 0)
  end)
  return info
end

local function confirm_delete(buf)
  if not vim.bo[buf].modified then
    return true
  end

  local ok, choice = pcall(vim.fn.confirm, ("Save changes to %q?"):format(vim.fn.bufname(buf)), "&Yes\n&No\n&Cancel")
  if not ok or choice == 0 or choice == 3 then
    return false
  end
  if choice == 1 then
    local wrote, err = pcall(vim.api.nvim_buf_call, buf, function()
      vim.cmd.write()
    end)
    if not wrote then
      vim.notify(tostring(err), vim.log.levels.ERROR)
      return false
    end
  end
  return true
end

local function replace_windows(buf, replacement)
  for _, win in ipairs(vim.fn.win_findbuf(buf)) do
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_set_buf(win, replacement)
    end
  end
end

local function explorer_pickers()
  local ok, pickers = pcall(snacks().picker.get, { source = "explorer" })
  return ok and pickers or {}
end

local function delete_buffer(buf)
  if vim.api.nvim_buf_is_valid(buf) then
    pcall(vim.cmd, "bdelete! " .. buf)
  end
end

function M.close(buf)
  buf = current_buf(buf)
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end

  local remaining = M.real_file_buffers(buf)
  local target = remaining[1] and remaining[1].bufnr or nil

  if target then
    if not confirm_delete(buf) then
      return
    end
    replace_windows(buf, target)
    delete_buffer(buf)
    return
  end

  local closing_last_real_file = M.is_real_file_buffer(buf)
  local pickers = closing_last_real_file and explorer_pickers() or {}
  if closing_last_real_file and #pickers > 0 then
    if not confirm_delete(buf) then
      return
    end

    replace_windows(buf, vim.api.nvim_create_buf(true, false))
    delete_buffer(buf)

    for _, picker in ipairs(pickers) do
      pcall(function()
        picker:close()
      end)
    end
    return
  end

  snacks().bufdelete.delete(buf)
end

return M
