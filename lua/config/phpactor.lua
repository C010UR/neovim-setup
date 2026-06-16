---@class ConfigPhpactor
local M = {}
local uv = vim.uv or vim.loop

M.MAX_BRANCHES = 5
M._project_id_cache = {}
-- Neovim on Linux does not support didChangeWatchedFiles dynamic registration, so
-- phpactor's "lsp" watcher never receives events; prefer realtime watchers.
M.ENABLED_WATCHERS = { "inotify", "watchman", "find", "php" }

local CACHE_ROOT = vim.fn.expand("~/.cache/phpactor")
local LRU_DIR = CACHE_ROOT .. "/branch-lru"

---@return string
function M.phpactor_bin()
  local bin = vim.fn.exepath("phpactor")
  if bin ~= "" then
    return bin
  end
  return "phpactor"
end

---@param name string
---@return string
function M.sanitize_branch(name)
  if not name or name == "" then
    return "default"
  end
  name = name:gsub("^refs/heads/", "")
  if name == "HEAD" then
    return "detached"
  end
  return (name:gsub("[^%w%-_%.]", "_"))
end

---@param root? string
---@return string
function M.git_branch(root)
  root = root or uv.cwd()
  local out = vim.fn.systemlist({ "git", "-C", root, "rev-parse", "--abbrev-ref", "HEAD" })
  if vim.v.shell_error ~= 0 or #out == 0 then
    return "default"
  end
  local branch = out[1]
  if branch == "HEAD" then
    local commit = vim.fn.systemlist({ "git", "-C", root, "rev-parse", "--short", "HEAD" })
    if vim.v.shell_error == 0 and commit[1] then
      return "detached-" .. commit[1]
    end
    return "detached"
  end
  return branch
end

---@param root string
---@return string
function M.project_id(root)
  root = vim.fs.normalize(root)
  if M._project_id_cache[root] then
    return M._project_id_cache[root]
  end
  local lines = vim.fn.systemlist({ M.phpactor_bin(), "config:dump", "-d", root })
  for _, line in ipairs(lines) do
    local id = line:match("%%project_id%%:%s*(%S+)")
    if id then
      M._project_id_cache[root] = id
      return id
    end
  end
  local hash = vim.fn.sha256(root):sub(1, 6)
  local id = vim.fs.basename(root) .. "-" .. hash
  M._project_id_cache[root] = id
  return id
end

---@param root? string
---@return string
function M.sanitized_branch(root)
  return M.sanitize_branch(M.git_branch(root))
end

---@param root? string
---@return table<string, any>
function M.config_options(root)
  root = root or uv.cwd()
  local branch = M.sanitized_branch(root)
  return {
    ["language_server_completion.trim_leading_dollar"] = true,
    ["indexer.enabled_watchers"] = M.ENABLED_WATCHERS,
    ["indexer.index_path"] = string.format("%%cache%%/index/%%project_id%%/branches/%s", branch),
    ["worse_reflection.cache_dir"] = string.format("%%cache%%/worse-reflection/%%project_id%%/branches/%s", branch),
  }
end

---@param root? string
---@return string
function M.config_extra(root)
  return vim.json.encode(M.config_options(root))
end

---@param params lsp.InitializeParams
---@param config vim.lsp.ClientConfig
function M.before_init(params, config)
  local root = config.root_dir or uv.cwd()
  M.touch_branch_lru(root)
  params.initializationOptions =
    vim.tbl_deep_extend("force", params.initializationOptions or {}, M.config_options(root))
  config.init_options = vim.tbl_deep_extend("force", config.init_options or {}, params.initializationOptions)
end

---@param config? vim.lsp.ClientConfig
---@return string[]
function M.cmd_argv(config)
  local root = (config and config.root_dir) or uv.cwd()
  M.touch_branch_lru(root)
  return { M.phpactor_bin(), "language-server" }
end

---@param dispatchers vim.lsp.rpc.Dispatchers
---@param config vim.lsp.ClientConfig
---@return vim.lsp.rpc.PublicClient
function M.start_rpc(dispatchers, config)
  local root = config.root_dir or uv.cwd()
  return vim.lsp.rpc.start(M.cmd_argv(config), dispatchers, { cwd = root })
end

---@param project_id string
---@return string
function M.lru_path(project_id)
  return LRU_DIR .. "/" .. project_id .. ".json"
end

---@param project_id string
---@return table
function M.read_lru(project_id)
  local path = M.lru_path(project_id)
  if vim.fn.filereadable(path) == 0 then
    return { branches = {} }
  end
  local lines = vim.fn.readfile(path)
  if #lines == 0 then
    return { branches = {} }
  end
  local ok, data = pcall(vim.json.decode, table.concat(lines, "\n"))
  if not ok or type(data) ~= "table" then
    return { branches = {} }
  end
  data.branches = data.branches or {}
  return data
end

---@param project_id string
---@param data table
function M.write_lru(project_id, data)
  vim.fn.mkdir(LRU_DIR, "p")
  vim.fn.writefile({ vim.json.encode(data) }, M.lru_path(project_id))
end

---@param project_id string
---@param branch string
---@return string
function M.branch_index_dir(project_id, branch)
  return string.format("%s/index/%s/branches/%s", CACHE_ROOT, project_id, branch)
end

---@param project_id string
---@param branch string
---@return string
function M.branch_reflection_dir(project_id, branch)
  return string.format("%s/worse-reflection/%s/branches/%s", CACHE_ROOT, project_id, branch)
end

---@param path string
function M.rm_rf(path)
  if vim.fn.isdirectory(path) == 1 then
    vim.fn.delete(path, "rf")
  end
end

---@param root string
---@param project_id? string
function M.prune_branch_caches(root, project_id)
  project_id = project_id or M.project_id(root)
  local data = M.read_lru(project_id)
  if #data.branches <= M.MAX_BRANCHES then
    return
  end

  for i = M.MAX_BRANCHES + 1, #data.branches do
    local branch = data.branches[i].name
    M.rm_rf(M.branch_index_dir(project_id, branch))
    M.rm_rf(M.branch_reflection_dir(project_id, branch))
  end

  local trimmed = {}
  for i = 1, M.MAX_BRANCHES do
    trimmed[i] = data.branches[i]
  end
  data.branches = trimmed
  M.write_lru(project_id, data)
end

---@param root string
---@param branch? string
---@return string branch
---@return string project_id
function M.touch_branch_lru(root, branch)
  root = vim.fs.normalize(root)
  branch = branch or M.sanitize_branch(M.git_branch(root))
  local project_id = M.project_id(root)
  local data = M.read_lru(project_id)
  local now = os.time()
  local branches = {}

  for _, entry in ipairs(data.branches) do
    if entry.name ~= branch then
      branches[#branches + 1] = entry
    end
  end
  branches[#branches + 1] = { name = branch, used_at = now }
  table.sort(branches, function(a, b)
    return (a.used_at or 0) > (b.used_at or 0)
  end)
  data.branches = branches
  M.write_lru(project_id, data)
  M.prune_branch_caches(root, project_id)
  return branch, project_id
end

---@param cwd? string
---@return string|nil
function M.git_root(cwd)
  cwd = cwd or uv.cwd()
  return vim.fs.root(cwd, { ".git" })
end

---@param root string
---@return boolean
function M.is_php_project(root)
  return vim.fs.root(root, {
    "composer.json",
    ".phpactor.json",
    ".phpactor.yml",
    "phpactor.json",
    "phpactor.yml",
  }) == root
end

---@return string|nil
function M.client_root()
  local client = vim.lsp.get_clients({ bufnr = 0, name = "phpactor" })[1]
    or vim.lsp.get_clients({ name = "phpactor" })[1]
  local root = client and (client.root_dir or vim.tbl_get(client, "config", "root_dir")) or nil
  return type(root) == "string" and root ~= "" and root or nil
end

function M.handle_branch_change()
  local root = M.client_root() or M.git_root()
  if not root or not M.is_php_project(root) then
    return
  end

  local branch = M.touch_branch_lru(root)
  vim.notify(
    ("Branch changed — phpactor using index for %s"):format(branch),
    vim.log.levels.INFO,
    { title = "PHP LSP" }
  )
  vim.defer_fn(function()
    vim.cmd("lsp restart phpactor")
  end, 500)
end

---@param bufnr? integer
---@return vim.lsp.Client[]
function M.clients(bufnr)
  local clients = {}
  if bufnr then
    clients = vim.lsp.get_clients({ bufnr = bufnr, name = "phpactor" })
  end
  if #clients == 0 then
    clients = vim.lsp.get_clients({ name = "phpactor" })
  end
  return clients
end

function M.reindex()
  local clients = M.clients(vim.api.nvim_get_current_buf())
  if #clients == 0 then
    vim.notify("phpactor is not running for any PHP workspace", vim.log.levels.WARN, { title = "PHP LSP" })
    return
  end
  local method = "phpactor/indexer/reindex"
  ---@cast method any
  local notified = false
  for _, client in ipairs(clients) do
    notified = client:notify(method, {}) or notified
  end
  if not notified then
    vim.notify("Failed to notify phpactor reindex", vim.log.levels.WARN, { title = "PHP LSP" })
    return
  end
  vim.notify("phpactor reindex started", vim.log.levels.INFO, { title = "PHP LSP" })
end

---@param keep_current? boolean
function M.clean_branch_caches(keep_current)
  local root = M.git_root()
  if not root then
    vim.notify("Not in a git repository", vim.log.levels.WARN, { title = "PHP LSP" })
    return
  end

  local project_id = M.project_id(root)
  local current = M.sanitize_branch(M.git_branch(root))
  local data = M.read_lru(project_id)
  local removed = 0

  for _, entry in ipairs(data.branches) do
    if not keep_current or entry.name ~= current then
      M.rm_rf(M.branch_index_dir(project_id, entry.name))
      M.rm_rf(M.branch_reflection_dir(project_id, entry.name))
      removed = removed + 1
    end
  end

  if keep_current then
    data.branches = vim.tbl_filter(function(entry)
      return entry.name == current
    end, data.branches)
  else
    data.branches = {}
  end
  M.write_lru(project_id, data)
  vim.notify(("Removed %d branch index cache(s)"):format(removed), vim.log.levels.INFO, { title = "PHP LSP" })
end

return M
