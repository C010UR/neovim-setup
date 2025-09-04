---@class Utils
local M = {}

---Get the relative path of the current buffer from the project root
---@return string|nil # Relative path or nil if path or root cannot be determined
M.relativePath = function()
  local absolutePath = LazyVim.root.bufpath(vim.api.nvim_get_current_buf())
  local root = LazyVim.root.get()

  if absolutePath == nil or root == nil then
    return nil
  end

  return string.sub(absolutePath, string.len(root) + 2)
end

---Get the current line number of the cursor
---@return integer # Current line number (1-indexed)
M.currentLineNumber = function()
  return vim.api.nvim_win_get_cursor(0)[1]
end

---Parse a file path with optional line and column numbers
---@param path string # Input path in format "file.lua", "file.lua:42", or "file.lua:42:10"
---@return {path: string, exists: integer, row: integer|nil, col: integer|nil} # Parsed path components
M.parsePath = function(path)
  local filePath, row, col

  -- Try to match "file:line:col" format
  filePath, row, col = path:match("^(.+):(%d+):(%d+)$")

  if not filePath then
    -- Try to match "file:line" format
    filePath, row = path:match("^(.+):(%d+)$")
  end

  if not filePath then
    -- No line/col info, use entire path
    filePath = path
  else
    row = tonumber(row)
    col = col and tonumber(col) or nil
  end

  -- Resolve full path
  local fullPath
  if filePath:match("^[~/]") then
    -- Absolute or home path
    fullPath = vim.fn.expand(filePath)

    if vim.fn.filereadable(fullPath) == 0 then
      local root = LazyVim.root.get()
      fullPath = vim.fs.normalize(root  .. filePath)
    end
  else
    -- Relative path - prepend project root
    local root = LazyVim.root.get()
    fullPath = vim.fs.normalize(root .. "/" .. filePath)
  end

  return {
    path = fullPath,
    exists = vim.fn.filereadable(fullPath) == 0,
    row = row,
    col = col,
  }
end

_G.Utils = M
return M
