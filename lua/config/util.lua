local root = require("config.root")

---@class Utils
local M = {}

M.relativePath = function()
  local absolute_path = root.bufpath(vim.api.nvim_get_current_buf())
  local project_root = root.get({ normalize = true })
  if absolute_path == nil or project_root == nil then
    return nil
  end
  return absolute_path:sub(#project_root + 2)
end

M.currentLineNumber = function()
  return vim.api.nvim_win_get_cursor(0)[1]
end

M.parsePath = function(path)
  local file_path, row, col = path:match("^(.+):(%d+):(%d+)$")
  if not file_path then
    file_path, row = path:match("^(.+):(%d+)$")
  end
  if not file_path then
    file_path = path
  else
    row = tonumber(row)
    col = col and tonumber(col) or nil
  end

  local full_path
  if file_path:match("^[~/]") then
    full_path = vim.fn.expand(file_path)
    if vim.fn.filereadable(full_path) == 0 then
      local project_root = root.get({ normalize = true })
      full_path = vim.fs.normalize(project_root .. file_path)
    end
  else
    full_path = vim.fs.normalize(root.get({ normalize = true }) .. "/" .. file_path)
  end

  return {
    path = full_path,
    exists = vim.fn.filereadable(full_path) == 1,
    row = row,
    col = col,
  }
end

_G.Utils = M
return M
