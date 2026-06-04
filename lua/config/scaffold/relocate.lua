local lsp = require("config.scaffold.lsp")
local notify = require("config.scaffold.notify")
local registry = require("config.scaffold.registry")
local transfer = require("config.scaffold.transfer")

---@class ConfigScaffoldRelocate
local M = {}

local normalize = transfer.normalize
local is_directory = transfer.is_directory
local file_pairs_for_tree = transfer.file_pairs_for_tree
local file_pairs_after_copy = transfer.file_pairs_after_copy

local function lsp_file_rename_enabled()
  return vim.g.config_scaffold_lsp_file_rename ~= false
end

---@param pairs ScaffoldFilePair[]
---@param client_priority? string[]
---@return boolean
local function lsp_will_rename(pairs, client_priority)
  if not lsp_file_rename_enabled() or #pairs == 0 then
    return false
  end
  return lsp.will_rename(pairs, { client_priority = client_priority })
end

---@param pairs ScaffoldFilePair[]
local function lsp_did_rename(pairs)
  if not lsp_file_rename_enabled() or #pairs == 0 then
    return
  end
  lsp.did_rename(pairs)
end

---@param path string
---@return ScaffoldProvider|nil
local function ensure_provider(path)
  local provider = registry.resolve_by_path(path)
  if provider then
    return provider
  end
  local ext = path:match("%.([^.]+)$")
  if not ext then
    return nil
  end
  pcall(function()
    require("config.scaffold." .. ext).register()
  end)
  return registry.resolve_by_path(path)
end

local function normalize_pairs_after_rename(pairs)
  for i, pair in ipairs(pairs) do
    pairs[i] = {
      from = transfer.resolve_path(pair.from) or normalize(pair.from) --[[@as string]],
      to = transfer.resolve_path(pair.to) or normalize(pair.to) --[[@as string]],
    }
  end
end

---@param from string
---@param to string
---@param operation ScaffoldTransferMode
---@return ScaffoldFileMoveContext
local function build_file_move_context(from, to, operation)
  local bufnr = vim.fn.bufnr(to, true)
  if bufnr < 0 then
    bufnr = vim.fn.bufadd(to)
    pcall(vim.fn.bufload, bufnr)
  end

  return {
    operation = operation,
    from = from,
    to = to,
    old_stem = vim.fn.fnamemodify(from, ":t:r"),
    new_stem = vim.fn.fnamemodify(to, ":t:r"),
    buf = bufnr >= 0 and bufnr or nil,
  }
end

---@param from string
---@param to string
---@param operation ScaffoldTransferMode
---@param lsp_applied boolean
---@param warn? boolean
---@return boolean
local function sync_relocated_file(from, to, operation, lsp_applied, warn)
  local provider = ensure_provider(to)
  local file_move = provider and provider.file_move
  if not file_move then
    return false
  end

  local ctx = build_file_move_context(from, to, operation)
  if not file_move.should_handle(ctx) then
    return false
  end

  local expected = file_move.expected(ctx)
  if not expected then
    return false
  end

  local synced = file_move.sync_buffer(ctx, expected)
  if warn and operation == "move" and not lsp_applied then
    notify.single_file_move(synced, lsp_applied)
  end
  return synced
end

---@param pairs ScaffoldFilePair[]
---@param operation ScaffoldTransferMode
---@param lsp_applied boolean
---@return integer
local function sync_file_pairs(pairs, operation, lsp_applied)
  local synced = 0
  for _, pair in ipairs(pairs) do
    if sync_relocated_file(pair.from, pair.to, operation, lsp_applied, false) then
      synced = synced + 1
    end
  end
  return synced
end

---@class ScaffoldRenameOp
---@field from string
---@field to string

---@param pairs ScaffoldFilePair[]
---@param renames ScaffoldRenameOp[]
---@return boolean
local function commit_renames(pairs, renames)
  local client_priority
  local first_provider = registry.resolve_by_path(pairs[1].to)
  if first_provider and first_provider.lsp_client_priority then
    client_priority = first_provider.lsp_client_priority
  end
  local lsp_applied = lsp_will_rename(pairs, client_priority)
  local ok_any = false
  local failed = {}

  for _, op in ipairs(renames) do
    local from = transfer.resolve_path(op.from) or op.from
    local to = transfer.resolve_path(op.to) or op.to
    if vim.uv.fs_stat(from) == nil then
      failed[#failed + 1] = from
    elseif Snacks.rename._rename(from, to) then
      ok_any = true
      op.from, op.to = from, to
    else
      failed[#failed + 1] = from
    end
  end

  if not ok_any then
    if #failed > 0 then
      vim.notify(
        "Move failed (missing file or rename error):\n- " .. table.concat(failed, "\n- "),
        vim.log.levels.ERROR,
        { title = notify.title() }
      )
    end
    return false
  end

  lsp_did_rename(pairs)
  normalize_pairs_after_rename(pairs)
  local synced = sync_file_pairs(pairs, "move", lsp_applied)
  notify.relocate_sync(pairs, synced, "move", registry.resolve_by_path)
  if lsp_applied then
    notify.lsp_applied()
  elseif synced == 0 then
    local any_targets = false
    for _, pair in ipairs(pairs) do
      local provider = registry.resolve_by_path(pair.to)
      if provider and provider.file_move then
        any_targets = true
        break
      end
    end
    if any_targets then
      notify.stale_refs(synced, false)
    end
  end

  return ok_any
end

---@param paths string[]
---@param target_dir string
---@return ScaffoldFilePair[] pairs
---@return ScaffoldRenameOp[] renames
local function plan_moves(paths, target_dir)
  local pairs = {}
  local renames = {}

  for _, raw in ipairs(paths) do
    local path = normalize(raw)
    if not path then
      goto continue
    end
    local to = transfer.destination_path(path, target_dir)
    if transfer.is_noop_relocate(path, to) then
      goto continue
    end
    renames[#renames + 1] = { from = path, to = to }
    if is_directory(path) then
      vim.list_extend(pairs, file_pairs_for_tree(path, to))
    else
      pairs[#pairs + 1] = { from = path, to = to }
    end
    ::continue::
  end

  return pairs, renames
end

---@param from string
---@param to string
function M.after_copy(from, to)
  from = normalize(from) --[[@as string]]
  to = normalize(to) --[[@as string]]

  local pairs = is_directory(to) and file_pairs_after_copy(from, to) or { { from = from, to = to } }
  normalize_pairs_after_rename(pairs)
  local synced = sync_file_pairs(pairs, "copy", false)
  notify.relocate_sync(pairs, synced, "copy", registry.resolve_by_path)
end

---@param from string
---@param to string
---@return boolean
function M.copy_path(from, to)
  from = normalize(from) --[[@as string]]
  to = normalize(to) --[[@as string]]
  if from == to then
    Snacks.notify.warn("Source and destination are the same path.", { title = notify.title() })
    return false
  end
  if is_directory(from) and transfer.is_strict_descendant(from, to) then
    Snacks.notify.warn("Destination cannot be inside the source directory.", { title = notify.title() })
    return false
  end
  if vim.uv.fs_stat(to) then
    Snacks.notify.warn("File already exists:\n- `" .. to .. "`", { title = notify.title() })
    return false
  end

  Snacks.picker.util.copy_path(from, to)
  if not vim.uv.fs_stat(to) then
    return false
  end

  M.after_copy(from, to)
  return true
end

---@param paths string[]
---@param target_dir string
---@param opts? { on_done?: fun(ok: boolean) }
function M.copy_paths(paths, target_dir, opts)
  opts = opts or {}
  target_dir = normalize(target_dir) --[[@as string]]

  local relocate, skipped = transfer.partition_paths(paths, target_dir)
  if #relocate == 0 then
    if #skipped > 0 then
      Snacks.notify.warn(
        ("Already in `%s`. Choose a different destination path."):format(vim.fn.fnamemodify(target_dir, ":t")),
        { title = notify.title() }
      )
    end
    if opts.on_done then
      opts.on_done(false)
    end
    return
  end

  if #skipped > 0 then
    Snacks.notify.info(
      ("Skipping %d item(s) already in the target folder."):format(#skipped),
      { title = notify.title() }
    )
  end

  local ok_any = false
  for _, path in ipairs(relocate) do
    local to = transfer.destination_path(path, target_dir)
    if M.copy_path(path, to) then
      ok_any = true
    end
  end

  if opts.on_done then
    opts.on_done(ok_any)
  end
end

---@param paths string[]
---@param target_dir string
---@param opts? { on_done?: fun(ok: boolean) }
function M.move_paths(paths, target_dir, opts)
  opts = opts or {}
  target_dir = normalize(target_dir) --[[@as string]]

  local relocate, skipped = transfer.partition_paths(paths, target_dir)
  local pairs, renames = plan_moves(relocate, target_dir)
  if #renames == 0 then
    if #skipped > 0 or #relocate > 0 then
      Snacks.notify.warn(
        "Cannot move into the same folder. Put the cursor on the destination directory, then press `m`.",
        { title = notify.title() }
      )
    end
    if opts.on_done then
      opts.on_done(false)
    end
    return
  end

  if #skipped > 0 then
    Snacks.notify.info(
      ("Skipping %d item(s) already in the target folder."):format(#skipped),
      { title = notify.title() }
    )
  end

  local ok_any = commit_renames(pairs, renames)
  if opts.on_done then
    opts.on_done(ok_any)
  end
end

---@param opts? {from: string, to: string, on_rename?: fun(to:string, from:string, ok:boolean)}
---@return boolean|nil
function M.rename_tree(opts)
  opts = opts or {}
  local from = normalize(opts.from) --[[@as string]]
  local to = normalize(opts.to) --[[@as string]]
  local pairs = file_pairs_for_tree(from, to)
  local ok = commit_renames(pairs, { { from = from, to = to } })

  if opts.on_rename then
    opts.on_rename(to, from, ok)
  end
  return ok
end

---@param opts? {from?: string, to?: string, file?: string, on_rename?: fun(to:string, from:string, ok:boolean)}
function M.rename_file(opts)
  opts = opts or {}
  local from = normalize(vim.fn.fnamemodify(opts.from or opts.file or vim.api.nvim_buf_get_name(0), ":p"))
  if not from then
    return
  end

  local to = opts.to and normalize(vim.fn.fnamemodify(opts.to, ":p")) or nil

  local function do_rename()
    assert(to, "to is required")
    if is_directory(from) then
      return M.rename_tree({ from = from, to = to, on_rename = opts.on_rename })
    end

    local pairs = { { from = from, to = to } }
    local client_priority
    local provider = ensure_provider(to)
    if provider and provider.lsp_client_priority then
      client_priority = provider.lsp_client_priority
    end
    local lsp_applied = lsp_will_rename(pairs, client_priority)
    local ok = Snacks.rename._rename(from, to)
    if ok then
      lsp_did_rename(pairs)
      normalize_pairs_after_rename(pairs)
      local synced = sync_relocated_file(pairs[1].from, pairs[1].to, "move", lsp_applied, false)
      notify.relocate_sync(pairs, synced and 1 or 0, "move", registry.resolve_by_path)
      if lsp_applied then
        notify.lsp_applied()
      elseif not synced then
        local has_provider = provider and provider.file_move ~= nil
        if has_provider then
          notify.stale_refs(0, false, "File moved; declarations were not updated locally.")
        end
      end
    end
    if opts.on_rename then
      opts.on_rename(to, from, ok)
    end
    return ok
  end

  if to then
    return do_rename()
  end

  local root_dir = normalize(vim.fn.getcwd(0)) or ""
  if from:find(root_dir, 1, true) ~= 1 then
    root_dir = vim.fs.dirname(from)
  end

  vim.ui.input({
    prompt = "New File Name: ",
    default = from:sub(#root_dir + 2),
    completion = "file",
  }, function(value)
    if not value or value == "" or value == from:sub(#root_dir + 2) then
      return
    end
    to = normalize(root_dir .. "/" .. value)
    do_rename()
  end)
end

return M
