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
---@return number # Current line number (1-indexed)
M.currentLineNumber = function()
  return vim.api.nvim_win_get_cursor(0)[1]
end

_G.Utils = M
return M
