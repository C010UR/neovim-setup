require("config.scaffold.types")

---@class ConfigScaffoldRegistry
local M = {}

---@type table<string, ScaffoldProvider>
M.providers = {}

---@type table<string, string>
M.by_filetype = {}

---@type table<string, string>
M.by_extension = {}

---@type table<integer, ScaffoldRenamePending>
M._pending_rename = {}

local transfer = require("config.scaffold.transfer")
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
---@return ScaffoldProvider|nil
function M.resolve(buf)
  if not vim.api.nvim_buf_is_valid(buf) then
    return nil
  end

  local ft = vim.bo[buf].filetype
  local name = M.by_filetype[ft]
  if name then
    return M.providers[name]
  end

  local path = buffer_path(buf)
  if not path then
    return nil
  end

  name = M.by_extension[file_extension(path):lower()]
  if name then
    return M.providers[name]
  end

  return nil
end

---@param path string
---@return ScaffoldProvider|nil
function M.resolve_by_path(path)
  local norm = normalize(path)
  if not norm then
    return nil
  end
  local name = M.by_extension[file_extension(norm):lower()]
  return name and M.providers[name] or nil
end

---@param name string
---@param provider ScaffoldProvider
function M.register(name, provider)
  M.providers[name] = provider

  for _, ft in ipairs(provider.filetypes or {}) do
    M.by_filetype[ft] = name
  end

  for _, ext in ipairs(provider.extensions or {}) do
    M.by_extension[ext:lower()] = name
  end
end

return M
