local root = require("config.root")
local registry = require("config.scaffold.registry")
local notify = require("config.scaffold.notify")
local transfer = require("config.scaffold.transfer")

---@class ConfigScaffoldBuffer
local M = {}

local normalize = transfer.normalize

---@param buf integer
---@return string|nil
local function buffer_path(buf)
  local path = normalize(vim.api.nvim_buf_get_name(buf))
  if not path or vim.fn.isdirectory(path) == 1 then
    return nil
  end
  return path
end

---@param path string
---@return string
local function file_extension(path)
  return path:match("%.([^.]+)$") or ""
end

---@param buf integer
---@return boolean
local function is_empty_buffer(buf)
  for _, line in ipairs(vim.api.nvim_buf_get_lines(buf, 0, -1, false)) do
    if line:match("%S") then
      return false
    end
  end
  return true
end

---@param path string
---@return boolean
local function is_empty_file(path)
  local stat = vim.uv.fs_stat(path)
  return stat ~= nil and stat.type == "file" and stat.size == 0
end

---@param buf integer
---@return ScaffoldContext|nil
local function build_context(buf)
  local path = buffer_path(buf)
  if not path then
    return nil
  end

  return {
    buf = buf,
    path = path,
    root = root.get({ buf = buf, normalize = true }),
    stem = vim.fn.fnamemodify(path, ":t:r"),
    ext = file_extension(path),
  }
end

---@param buf integer
function M.maybe_scaffold(buf)
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  if vim.b[buf].config_scaffolded or not vim.bo[buf].modifiable then
    return
  end

  local path = buffer_path(buf)
  if not path then
    return
  end

  local provider = registry.resolve(buf)
  if not provider or type(provider.build) ~= "function" then
    return
  end

  if provider.should_scaffold and not provider.should_scaffold(buf) then
    return
  end

  if not is_empty_buffer(buf) and not is_empty_file(path) then
    return
  end

  local ctx = build_context(buf)
  if not ctx then
    return
  end

  local result = provider.build(ctx)
  if not result or not result.lines or #result.lines == 0 then
    return
  end

  vim.b[buf].config_scaffolded = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, result.lines)

  local cursor = result.cursor or { line = #result.lines, col = 0 }
  local win = vim.fn.bufwinid(buf)
  if win ~= -1 then
    pcall(vim.api.nvim_win_set_cursor, win, { cursor.line, cursor.col or 0 })
  end

  vim.notify(("Scaffolded %s"):format(vim.fn.fnamemodify(path, ":t")), vim.log.levels.INFO, {
    title = notify.title(),
  })
end

return M
