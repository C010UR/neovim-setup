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
    vim.notify("Buffer is not a file", vim.log.levels.ERROR)
  else
    vim.fn.setreg("+", path)
    vim.notify('Copied "' .. path .. '" to the clipboard')
  end
end, { desc = "Copy buffer path" })

map("n", "<leader>bC", function()
  local path = Utils.relativePath()

  if path == nil then
    vim.notify("Buffer is not a file", vim.log.levels.ERROR)
  else
    path = path .. ":" .. Utils.currentLineNumber()
    vim.fn.setreg("+", path)
    vim.notify('Copied "' .. path .. '" to the clipboard')
  end
end, { desc = "Copy buffer path with line number" })

map("n", "<leader>bn", function()
  local clipboard = vim.fn.getreg("+"):gsub("^%s*(.-)%s*$", "%1")

  if clipboard == "" then
    vim.notify("Clipboard is empty", vim.log.levels.WARN)
    return
  end

  local parsed = Utils.parsePath(clipboard)

  if vim.fn.filereadable(parsed.path) == 0 then
    vim.notify('File not found: "' .. clipboard .. '"', vim.log.levels.ERROR)
    return
  end

  vim.cmd("edit " .. vim.fn.fnameescape(parsed.path))

  if parsed.row ~= nil then
    local row = math.min(parsed.row, vim.api.nvim_buf_line_count(0))
    local col = parsed.col or 0

    if parsed.col then
      local line_content = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1] or ""
      col = math.min(parsed.col, #line_content)
    end

    vim.api.nvim_win_set_cursor(0, { row, col })

    vim.cmd("normal! zz")

    if parsed.col then
      vim.notify(string.format('Opened "%s:%d:%d', parsed.path, row, col + 1))
    else
      vim.notify(string.format('Opened "%s:%d"', parsed.path, row))
    end
  else
    vim.notify(string.format('Opened "%s"', parsed.path))
  end
end, { desc = "Open buffer from clipboard path" })
