---@class ConfigScaffoldTransfer
local M = {}

---@param path string|nil
---@return string|nil
function M.normalize(path)
  if not path or path == "" then
    return nil
  end
  return vim.fs.normalize(path)
end

---@param dir string
---@return string
function M.dir_name(dir)
  local norm = M.normalize(dir) or ""
  return (norm:gsub("/$", ""))
end

---@param path string
---@return string
function M.parent_dir(path)
  return M.dir_name(vim.fs.dirname(M.normalize(path) or path))
end

---@param path string
---@param target_dir string
---@return string
function M.destination_path(path, target_dir)
  path = M.normalize(path) --[[@as string]]
  target_dir = M.normalize(target_dir) --[[@as string]]
  return target_dir .. "/" .. vim.fn.fnamemodify(path, ":t")
end

---@param from string
---@param to string
---@return boolean
function M.is_noop_relocate(from, to)
  local nfrom = M.normalize(from)
  local nto = M.normalize(to)
  return nfrom ~= nil and nto ~= nil and nfrom == nto
end

---@param ancestor string
---@param path string
---@return boolean
function M.is_strict_descendant(ancestor, path)
  local nancestor = M.normalize(ancestor)
  local npath = M.normalize(path)
  if not nancestor or not npath or nancestor == npath then
    return false
  end
  return npath:find(nancestor .. "/", 1, true) == 1
end

---@param path string
---@return string
function M.unique_sibling_path(path)
  path = M.normalize(path) --[[@as string]]
  local dir = vim.fs.dirname(path)
  local name = vim.fn.fnamemodify(path, ":t")
  local stem, ext = name:match("^(.+)(%.[^.]+)$")
  if not stem then
    stem, ext = name, ""
  end
  local suffix = "-copy"
  local candidate = dir .. "/" .. stem .. suffix .. ext
  local n = 2
  while vim.uv.fs_stat(candidate) do
    candidate = dir .. "/" .. stem .. suffix .. n .. ext
    n = n + 1
  end
  return candidate
end

---@param from string
---@param target_dir string
---@param operation? "copy"|"move"
---@return string
function M.default_relocate_destination(from, target_dir, operation)
  from = M.normalize(from) --[[@as string]]
  target_dir = M.normalize(target_dir) --[[@as string]]
  local to = M.destination_path(from, target_dir)

  if operation == "move" then
    if not M.is_noop_relocate(from, to) then
      return to
    end
    return from
  end

  if target_dir == from or M.is_noop_relocate(from, to) then
    return M.unique_sibling_path(from)
  end
  local name = vim.fn.fnamemodify(from, ":t")
  if M.dir_name(target_dir) == name then
    return M.unique_sibling_path(from)
  end
  return to
end

---@param from string
---@param dest string
---@param operation? "copy"|"move"
---@return string|nil to
---@return string|nil err
function M.resolve_relocate_destination(from, dest, operation)
  from = M.normalize(from) --[[@as string]]
  dest = M.normalize(vim.fn.fnamemodify(dest, ":p")) --[[@as string]]
  local name = vim.fn.fnamemodify(from, ":t")

  local to
  if vim.fn.isdirectory(dest) == 1 then
    if dest == from then
      if operation == "copy" then
        to = M.unique_sibling_path(from)
      else
        return nil, "Enter the full new path (e.g. rename Hotfix to ../Hotfix2)."
      end
    else
      to = dest .. "/" .. name
    end
  else
    to = dest
  end

  to = M.normalize(to) --[[@as string]]
  if M.is_noop_relocate(from, to) then
    return nil,
      operation == "move" and "Destination must differ from the source path."
        or "Source and destination are the same path."
  end
  if M.is_directory(from) and M.is_strict_descendant(from, to) then
    return nil, "Destination cannot be inside the source directory."
  end
  return to
end

---@param dir string|nil
---@param cwd string|nil
---@return string|nil
function M.resolve_target_dir(dir, cwd)
  local ndir = M.normalize(dir)
  local ncwd = M.normalize(cwd)
  if not ndir then
    return ncwd
  end
  if not ncwd or ndir == ncwd then
    return ndir
  end
  local parent = M.normalize(vim.fs.dirname(ndir))
  if parent and M.dir_name(parent) == M.dir_name(ncwd) then
    return ncwd
  end
  return ndir
end

---@param path string|nil
---@return string|nil
function M.resolve_path(path)
  path = M.normalize(path)
  if not path then
    return nil
  end
  if vim.uv.fs_stat(path) then
    return vim.fs.normalize(vim.fn.fnamemodify(path, ":p"))
  end
  return path
end

function M.partition_paths(paths, target_dir)
  local relocate, skipped = {}, {}
  for _, path in ipairs(paths) do
    path = M.normalize(path)
    if not path then
      goto continue
    end
    local to = M.destination_path(path, target_dir)
    if M.is_noop_relocate(path, to) then
      skipped[#skipped + 1] = path
    else
      relocate[#relocate + 1] = path
    end
    ::continue::
  end
  return relocate, skipped
end

---@param path string|nil
---@return boolean
function M.is_directory(path)
  path = M.normalize(path)
  return path ~= nil and vim.fn.isdirectory(path) == 1
end

---@param path string
---@param root string
---@return string|nil
function M.relative_path(path, root)
  local norm_path = M.normalize(path)
  local norm_root = M.normalize(root)
  if not norm_path or not norm_root then
    return nil
  end
  if #norm_root > 0 and norm_path:sub(1, #norm_root) ~= norm_root then
    return nil
  end
  local rel = norm_path:sub(#norm_root + 1)
  rel = (rel:gsub("^/", ""))
  return rel ~= "" and rel or nil
end

---@param dir string
---@return string[]
function M.collect_files(dir)
  local norm_dir = M.normalize(dir)
  if not norm_dir or not M.is_directory(norm_dir) then
    return {}
  end

  local files = {}
  local function walk(root)
    for name, typ in vim.fs.dir(root) do
      if name ~= "." and name ~= ".." then
        local path = M.normalize(root .. "/" .. name)
        if path then
          if typ == "directory" then
            walk(path)
          elseif typ == "file" then
            files[#files + 1] = path
          end
        end
      end
    end
  end

  walk(norm_dir)
  table.sort(files)
  return files
end

---@param from_root string
---@param to_root string
---@return ScaffoldFilePair[]
function M.file_pairs_for_tree(from_root, to_root)
  from_root = M.normalize(from_root) --[[@as string]]
  to_root = M.normalize(to_root) --[[@as string]]
  local pairs = {}
  for _, file in ipairs(M.collect_files(from_root)) do
    local rel = M.relative_path(file, from_root)
    if rel then
      pairs[#pairs + 1] = { from = file, to = to_root .. "/" .. rel }
    end
  end
  return pairs
end

---@param from_root string
---@param to_root string
---@return ScaffoldFilePair[]
function M.file_pairs_after_copy(from_root, to_root)
  from_root = M.normalize(from_root) --[[@as string]]
  to_root = M.normalize(to_root) --[[@as string]]
  local pairs = {}
  for _, to_file in ipairs(M.collect_files(to_root)) do
    local rel = M.relative_path(to_file, to_root)
    if rel then
      pairs[#pairs + 1] = { from = from_root .. "/" .. rel, to = to_file }
    end
  end
  return pairs
end

return M
