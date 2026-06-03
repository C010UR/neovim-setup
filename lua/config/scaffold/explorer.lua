--- Snacks explorer actions wired through config.scaffold.

---@class ConfigScaffoldExplorer
local M = {}

---@param picker snacks.Picker
---@return string
local function target_dir(picker)
  local transfer = require("config.scaffold.transfer")
  return (transfer.resolve_target_dir(picker:dir(), picker:cwd())) --[[@as string]]
end

---@param picker snacks.Picker
---@param dir string
local function refresh_target(picker, dir)
  local Tree = require("snacks.explorer.tree")
  local ExplorerActions = require("snacks.explorer.actions")
  Tree:refresh(dir)
  Tree:open(dir)
  ExplorerActions.update(picker, { target = dir })
end

---@param picker snacks.Picker
---@param paths string[]
---@param operation "copy"|"move"
local function relocate(picker, paths, operation)
  ---@type ConfigScaffold
  local scaffold = require("config.scaffold")
  local transfer = require("config.scaffold.transfer")
  local Tree = require("snacks.explorer.tree")
  local target = target_dir(picker)
  local default = #paths == 1 and transfer.default_relocate_destination(paths[1], target, operation) or target
  local prompt = operation == "copy" and "Copy to" or "Move to"

  Snacks.input({
    prompt = prompt,
    default = default,
    completion = "file",
  }, function(value)
    if not value or value:match("^%s*$") then
      return
    end

    local dest = vim.fs.normalize(vim.fn.fnamemodify(value, ":p"))

    local function done(ok, dest_dir)
      if not ok then
        return
      end
      for _, from in ipairs(paths) do
        Tree:refresh(vim.fs.dirname(from))
      end
      Tree:refresh(dest_dir)
      picker.list:set_selected()
      refresh_target(picker, dest_dir)
    end

    if #paths == 1 then
      local to, err = transfer.resolve_relocate_destination(paths[1], dest, operation)
      if not to then
        Snacks.notify.warn(err or "Invalid destination.", { title = "Scaffold" })
        return
      end
      if operation == "copy" then
        done(scaffold.copy_path(paths[1], to), vim.fs.dirname(to))
        return
      end
      scaffold.rename_file({
        from = paths[1],
        to = to,
        on_rename = function(_, _, ok)
          done(ok, vim.fs.dirname(to))
        end,
      })
      return
    end

    local dest_dir = vim.fn.isdirectory(dest) == 1 and dest or vim.fs.dirname(dest)
    if operation == "copy" then
      scaffold.copy_paths(paths, dest_dir, {
        on_done = function(ok)
          done(ok, dest_dir)
        end,
      })
    else
      scaffold.move_paths(paths, dest_dir, {
        on_done = function(ok)
          done(ok, dest_dir)
        end,
      })
    end
  end)
end

---@param picker snacks.Picker
---@param item snacks.picker.Item|nil
function M.rename(picker, item)
  if not item then
    return
  end

  local Tree = require("snacks.explorer.tree")
  local ExplorerActions = require("snacks.explorer.actions")
  ---@type ConfigScaffold
  local scaffold = require("config.scaffold")
  scaffold.rename_file({
    from = item.file,
    on_rename = function(to, from, ok)
      if not ok then
        return
      end
      Tree:refresh(vim.fs.dirname(from))
      Tree:refresh(vim.fs.dirname(to))
      ExplorerActions.update(picker, { target = to })
    end,
  })
end

---@param picker snacks.Picker
---@param item snacks.picker.Item|nil
function M.copy(picker, item)
  local paths = vim.tbl_map(Snacks.picker.util.path, picker:selected({ fallback = true }))
  if #paths == 0 then
    if not item then
      return
    end
    paths = { Snacks.picker.util.path(item) }
  end
  relocate(picker, paths, "copy")
end

---@param picker snacks.Picker
function M.paste(picker)
  local files = vim.split(vim.fn.getreg(vim.v.register or "+") or "", "\n", { plain = true })
  files = vim.tbl_filter(function(file)
    return file ~= "" and vim.fn.filereadable(file) == 1
  end, files)

  if #files == 0 then
    Snacks.notify.warn(("The `%s` register does not contain any files"):format(vim.v.register or "+"))
    return
  end

  relocate(picker, files, "copy")
end

---@param picker snacks.Picker
function M.move(picker)
  local paths = vim.tbl_map(Snacks.picker.util.path, picker:selected({ fallback = true }))
  if #paths == 0 then
    Snacks.notify.warn("No files selected to move. Renaming instead.")
    return M.rename(picker, picker:current())
  end
  relocate(picker, paths, "move")
end

return M
