---@class ConfigScaffoldPhpPsr4
local M = {}

local cache = {} ---@type table<string, table<string, string>>
local cache_autocmd = false

local function normalize_dir(dir)
  dir = vim.fs.normalize(dir)
  if dir ~= "" and not dir:match("/$") then
    dir = dir .. "/"
  end
  return dir
end

function M.invalidate_cache()
  cache = {}
end

---@param project_root string
---@return table<string, string>
local function parse_composer_psr4(project_root)
  if cache[project_root] then
    return cache[project_root]
  end

  local composer_path = project_root .. "/composer.json"
  if vim.uv.fs_stat(composer_path) == nil then
    cache[project_root] = {}
    return cache[project_root]
  end

  local content
  if vim.fn.filereadable(composer_path) == 1 then
    content = table.concat(vim.fn.readfile(composer_path), "\n")
  end
  if not content then
    cache[project_root] = {}
    return cache[project_root]
  end

  local ok, data = pcall(vim.json.decode, content)
  if not ok or type(data) ~= "table" then
    cache[project_root] = {}
    return cache[project_root]
  end

  cache[project_root] = vim.tbl_get(data, "autoload", "psr-4") or {}
  return cache[project_root]
end

---@param path string
---@return string
function M.project_root(path)
  return vim.fs.root(path, "composer.json") or vim.fs.normalize(vim.uv.cwd() or "")
end

---@param path string
---@param project_root string
---@return string
function M.namespace_for(path, project_root)
  path = vim.fs.normalize(path)
  project_root = vim.fs.normalize(project_root)

  local rel = (path:sub(#project_root + 1):gsub("^/", ""))
  local psr4 = parse_composer_psr4(project_root)

  local best_len = 0
  local namespace = nil

  for prefix, dir in pairs(psr4) do
    dir = normalize_dir(dir)
    if dir == "" then
      dir = "src/"
    end
    if rel:sub(1, #dir) == dir then
      if #dir > best_len then
        best_len = #dir
        local subpath = rel:sub(#dir + 1)
        subpath = (subpath:gsub("%.php$", ""))
        subpath = (subpath:gsub("/[^/]+$", ""))
        subpath = (subpath:gsub("/", "\\"))
        prefix = (prefix:gsub("\\$", ""))
        namespace = prefix .. (subpath ~= "" and ("\\" .. subpath) or "")
      end
    end
  end

  if namespace then
    return (namespace:gsub("^\\", ""))
  end

  local dir = vim.fs.dirname(path)
  local rel_dir = (dir:sub(#project_root + 1):gsub("^/", ""))
  if rel_dir == "" then
    return ""
  end

  return (rel_dir:gsub("/", "\\"))
end

function M.setup_cache_autocmd()
  if cache_autocmd then
    return
  end
  cache_autocmd = true

  vim.api.nvim_create_autocmd({ "BufWritePost", "DirChanged" }, {
    group = vim.api.nvim_create_augroup("config_scaffold_php_cache", { clear = true }),
    callback = function(ev)
      local match = ev.match
      if match and match:match("composer%.json$") then
        M.invalidate_cache()
        return
      end
      if ev.event == "DirChanged" then
        M.invalidate_cache()
      end
    end,
  })
end

return M
