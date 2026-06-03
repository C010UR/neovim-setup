---@class ConfigScaffoldLsp
local M = {}

local function timeout_ms()
  local ms = vim.g.config_scaffold_lsp_rename_timeout_ms
  if type(ms) == "number" and ms > 0 then
    return ms
  end
  return 10000
end

---@param pairs ScaffoldFilePair[]
---@return integer|nil
local function rename_bufnr(pairs)
  local bufnr = vim.fn.bufnr(pairs[1].from, true)
  return bufnr >= 0 and bufnr or nil
end

---@param clients vim.lsp.Client[]
---@param priority string[]
---@return vim.lsp.Client[]
local function prioritize_clients(clients, priority)
  if not priority or #priority == 0 then
    return clients
  end
  local preferred, rest = {}, {}
  for _, client in ipairs(clients) do
    if vim.tbl_contains(priority, client.name) then
      preferred[#preferred + 1] = client
    else
      rest[#rest + 1] = client
    end
  end
  table.sort(preferred, function(a, b)
    local ai, bi = #priority + 1, #priority + 1
    for i, name in ipairs(priority) do
      if a.name == name then
        ai = i
      end
      if b.name == name then
        bi = i
      end
    end
    return ai < bi
  end)
  return vim.list_extend(preferred, rest)
end

---@param pairs ScaffoldFilePair[]
---@param client_priority? string[]
---@return vim.lsp.Client[]
local function rename_clients(pairs, client_priority)
  ---@type vim.lsp.get_clients.Filter
  local filter = { method = "workspace/willRenameFiles" }
  local bufnr = rename_bufnr(pairs)
  if bufnr then
    filter.bufnr = bufnr
  end
  local clients = vim.lsp.get_clients(filter)
  if client_priority and #client_priority > 0 then
    return prioritize_clients(clients, client_priority)
  end
  return clients
end

---@param pairs ScaffoldFilePair[]
---@return table
function M.rename_changes(pairs)
  local files = {}
  for _, pair in ipairs(pairs) do
    files[#files + 1] = {
      oldUri = vim.uri_from_fname(pair.from),
      newUri = vim.uri_from_fname(pair.to),
    }
  end
  return { files = files }
end

---@param pairs ScaffoldFilePair[]
---@param opts? { client_priority?: string[] }
---@return boolean
function M.will_rename(pairs, opts)
  opts = opts or {}
  if #pairs == 0 then
    return false
  end

  local changes = M.rename_changes(pairs)
  local bufnr = rename_bufnr(pairs) or 0
  local applied = false

  for _, client in ipairs(rename_clients(pairs, opts.client_priority)) do
    local resp = client:request_sync("workspace/willRenameFiles", changes, timeout_ms(), bufnr)
    if resp and resp.result then
      vim.lsp.util.apply_workspace_edit(resp.result, client.offset_encoding)
      applied = true
    end
  end
  return applied
end

---@param pairs ScaffoldFilePair[]
function M.did_rename(pairs)
  if #pairs == 0 then
    return
  end

  local changes = M.rename_changes(pairs)
  for _, client in ipairs(vim.lsp.get_clients({ method = "workspace/didRenameFiles" })) do
    client:notify("workspace/didRenameFiles", changes)
  end
end

return M
