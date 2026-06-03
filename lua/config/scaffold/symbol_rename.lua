local notify = require("config.scaffold.notify")
local registry = require("config.scaffold.registry")
local transfer = require("config.scaffold.transfer")

---@class ConfigScaffoldSymbolRename
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

---@param buf integer
---@param rename_file fun(opts: table)
local function finish_rename(buf, rename_file)
  local pending = registry._pending_rename[buf]
  registry._pending_rename[buf] = nil
  local rename = pending and pending.provider.rename
  if not rename then
    return
  end

  local new_symbol = rename.symbol_at_cursor(buf)
  if not new_symbol or new_symbol == pending.old_symbol then
    return
  end

  local ctx = {
    buf = buf,
    path = pending.path,
    old_symbol = pending.old_symbol or "",
    new_symbol = new_symbol,
    old_stem = pending.old_stem,
  }

  if not rename.should_rename_file(ctx) then
    return
  end

  local new_path = rename.new_path(ctx)
  if not new_path or new_path == pending.path then
    return
  end

  rename_file({ from = pending.path, to = new_path })
  vim.notify(("Renamed file to %s"):format(vim.fn.fnamemodify(new_path, ":t")), vim.log.levels.INFO, {
    title = notify.title(),
  })
end

---@param buf integer
---@param rename_file fun(opts: table)
function M.rename_symbol(buf, rename_file)
  buf = buf or vim.api.nvim_get_current_buf()
  local provider = registry.resolve(buf)
  local path = buffer_path(buf)

  if provider and provider.rename and path then
    registry._pending_rename[buf] = {
      provider = provider,
      old_symbol = provider.rename.symbol_at_cursor(buf),
      old_stem = vim.fn.fnamemodify(path, ":t:r"),
      path = path,
    }
  end

  vim.lsp.buf.rename(nil, { bufnr = buf })
end

---@param rename_file fun(opts: table)
function M.setup(rename_file)
  local group = vim.api.nvim_create_augroup("config_scaffold_symbol_rename", { clear = true })

  vim.api.nvim_create_autocmd("LspAttach", {
    group = group,
    callback = function(ev)
      local buf = ev.buf
      if not vim.api.nvim_buf_is_valid(buf) then
        return
      end
      local provider = registry.resolve(buf)
      if not provider or not provider.rename then
        return
      end
      if #vim.lsp.get_clients({ bufnr = buf, method = "textDocument/rename" }) == 0 then
        return
      end
      vim.keymap.set("n", "<leader>cr", function()
        M.rename_symbol(buf, rename_file)
      end, { buffer = buf, desc = "Rename Symbol", silent = true })
    end,
  })

  vim.api.nvim_create_autocmd("LspRequest", {
    group = group,
    callback = function(ev)
      if ev.data.request.method ~= "textDocument/rename" or ev.data.request.type ~= "complete" then
        return
      end

      local buf = ev.buf
      if not vim.api.nvim_buf_is_valid(buf) or not registry._pending_rename[buf] then
        return
      end

      if ev.data.request.response and ev.data.request.response.err then
        registry._pending_rename[buf] = nil
        return
      end

      vim.schedule(function()
        if vim.api.nvim_buf_is_valid(buf) then
          finish_rename(buf, rename_file)
        else
          registry._pending_rename[buf] = nil
        end
      end)
    end,
  })
end

return M
