-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local del = vim.keymap.del
local map = vim.keymap.set

del("n", "<leader>l")
del("n", "<leader>L")
del("n", "<leader>K")
del("n", "<leader>-")
del("n", "<leader>|")


map("n", "<leader>bc", function()
  local path = Utils.relativePath()

  if path == nil then
    vim.notify('Buffer is not a file')
  else
    vim.fn.setreg("+", path)
    vim.notify('Copied "' .. path .. '" to the clipboard')
  end
end, { desc = "Copy buffer path" })

map("n", "<leader>bC", function()

  local path = Utils.relativePath()

  if path == nil then
    vim.notify('Buffer is not a file')
  else
    path = path .. ":" .. Utils.currentLineNumber()
    vim.fn.setreg("+", path)
    vim.notify('Copied "' .. path .. '" to the clipboard')
  end
end, { desc = "Copy buffer path with line number" })
