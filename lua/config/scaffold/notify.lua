---@class ConfigScaffoldNotify
local M = {}

local TITLE = "Scaffold"

---@param pairs ScaffoldFilePair[]
---@param resolve_by_path fun(path: string): ScaffoldProvider|nil
---@return integer
local function relocate_target_count(pairs, resolve_by_path)
  local n = 0
  for _, pair in ipairs(pairs) do
    local provider = resolve_by_path(pair.to)
    if provider and provider.file_move then
      n = n + 1
    end
  end
  return n
end

---@param pairs ScaffoldFilePair[]
---@param synced integer
---@param operation ScaffoldTransferMode
---@param resolve_by_path fun(path: string): ScaffoldProvider|nil
function M.relocate_sync(pairs, synced, operation, resolve_by_path)
  local total = relocate_target_count(pairs, resolve_by_path)
  if total == 0 then
    return
  end

  if synced > 0 then
    local verb = operation == "copy" and "Copied" or "Moved"
    vim.notify(
      ("%s and updated declarations in %d/%d file(s)"):format(verb, synced, total),
      vim.log.levels.INFO,
      { title = TITLE }
    )
    return
  end

  vim.notify(
    "Relocated file(s) but declarations were not updated. Ensure the project root is detected.",
    vim.log.levels.WARN,
    { title = TITLE }
  )
end

---@param synced integer
---@param lsp_applied boolean
---@param detail? string
function M.stale_refs(synced, lsp_applied, detail)
  if lsp_applied or synced > 0 then
    return
  end
  vim.notify(
    detail or "Relocated files; declarations were not updated locally. Other files may still reference old paths.",
    vim.log.levels.WARN,
    { title = TITLE }
  )
end

---@param synced boolean
---@param lsp_applied boolean
function M.single_file_move(synced, lsp_applied)
  if lsp_applied then
    return
  end
  local msg = synced and "File moved; declarations updated locally. Project references may be stale."
    or "File moved; workspace rename did not apply — references may be stale."
  vim.notify(msg, vim.log.levels.WARN, { title = TITLE })
end

function M.lsp_applied()
  vim.notify("Project references updated via LSP.", vim.log.levels.INFO, { title = TITLE })
end

---@return string
function M.title()
  return TITLE
end

return M
