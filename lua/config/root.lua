local uri = require("config.uri")

---@class ConfigRoot
---@overload fun(opts?: { normalize?: boolean, buf?: number }): string
---@type ConfigRoot|table
local M = {}

---@diagnostic disable-next-line: param-type-mismatch
setmetatable(M, {
  __call = function(self, ...)
    return self.get(...)
  end,
})

M.cache = {}
M.detectors = {}

local STARTUP_DIR
local function startup_directory_arg()
  if vim.fn.argc(-1) ~= 1 then
    return nil
  end
  local arg = vim.fn.argv(0) --[[@as string]]
  if arg == "" or vim.fn.isdirectory(arg) == 0 then
    return nil
  end
  return M.realpath(arg)
end

local function is_win()
  return vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1
end

local function normalize(path)
  if not path or path == "" then
    return nil
  end
  return vim.fs.normalize(path)
end

function M.startup_dir()
  if STARTUP_DIR == nil then
    STARTUP_DIR = startup_directory_arg()
  end
  return STARTUP_DIR
end

function M.detectors.cwd()
  return { M.startup_dir() or normalize(vim.uv.cwd()) }
end

function M.detectors.startup()
  local startup = M.startup_dir()
  return startup and { startup } or {}
end

function M.bufpath(buf)
  return M.realpath(vim.api.nvim_buf_get_name(assert(buf)))
end

function M.cwd()
  return M.realpath(vim.uv.cwd()) or ""
end

function M.realpath(path)
  if not path or path == "" then
    return nil
  end
  local resolved = is_win() and path or vim.uv.fs_realpath(path) or path
  return normalize(resolved)
end

function M.statusline_path(buf)
  buf = buf or 0
  local path = M.bufpath(buf)
  if not path then
    local name = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ":t")
    if name == "" then
      return nil
    end
    return name
  end

  local cwd = M.cwd()
  if cwd == "" then
    return path
  end

  local compare_path, compare_cwd = path, cwd
  if is_win() then
    compare_path = compare_path:lower()
    compare_cwd = compare_cwd:lower()
  end

  if compare_path:find(compare_cwd, 1, true) == 1 then
    return "~/" .. path:sub(#cwd + 2)
  end

  return path
end

function M.detectors.lsp(buf)
  local bufpath = M.bufpath(buf)
  if not bufpath then
    return {}
  end

  local roots = {}
  local clients = vim.lsp.get_clients({ bufnr = buf })
  clients = vim.tbl_filter(function(client)
    return not vim.tbl_contains(vim.g.root_lsp_ignore or {}, client.name)
  end, clients)

  for _, client in ipairs(clients) do
    for _, workspace in pairs(client.config.workspace_folders or {}) do
      roots[#roots + 1] = uri.to_fname(workspace.uri)
    end
    if client.root_dir then
      roots[#roots + 1] = client.root_dir
    end
  end

  return vim.tbl_filter(function(path)
    path = normalize(path)
    if not path then
      return false
    end
    return bufpath:find(path, 1, true) == 1
  end, roots)
end

---@param name string
---@param patterns string|string[]
---@return boolean
local function matches_pattern(name, patterns)
  local list ---@type string[]
  if type(patterns) == "string" then
    list = { patterns }
  else
    list = patterns
  end
  for _, p in ipairs(list) do
    if name == p then
      return true
    end
    if p:sub(1, 1) == "*" and name:find(vim.pesc(p:sub(2)) .. "$") then
      return true
    end
  end
  return false
end

---@param path string
---@param patterns string|string[]
---@return string|nil
function M.pattern_root(path, patterns)
  local norm = M.realpath(path)
  if not norm then
    return nil
  end

  local search = vim.fn.isdirectory(norm) == 1 and norm or vim.fs.dirname(norm)
  local pattern = vim.fs.find(function(name)
    return matches_pattern(name, patterns)
  end, { path = search, upward = true })[1]

  return pattern and M.realpath(vim.fs.dirname(pattern)) or nil
end

function M.detectors.pattern(buf, patterns)
  local path = M.bufpath(buf) or M.cwd()
  local root_dir = M.pattern_root(path, patterns)
  -- If Neovim was started with a directory argument, don't let pattern
  -- detection escape above that directory.
  local startup = M.startup_dir()
  if root_dir and startup then
    startup = normalize(startup)
    if startup and startup ~= root_dir and startup:find(root_dir, 1, true) == 1 then
      root_dir = startup
    end
  end
  return root_dir and { root_dir } or {}
end

---@param opts? { spec?: any }
---@return table
local function root_spec(opts)
  if opts and opts.spec then
    return opts.spec
  end
  if type(vim.g.root_spec) == "table" then
    return vim.g.root_spec
  end
  vim.notify_once("vim.g.root_spec is not set; define it in lua/config/options.lua", vim.log.levels.WARN)
  return { "lsp", { ".git", "lua" }, "cwd" }
end

--- Resolve project root from a filesystem path using marker patterns only (never LSP).
---@param path string
---@param opts? { spec?: any }
---@return string
function M.from_path(path, opts)
  opts = opts or {}
  local norm = M.realpath(path)
  if not norm then
    return M.cwd()
  end

  local spec = root_spec(opts)
  for _, item in ipairs(spec) do
    if type(item) == "table" then
      local found = M.pattern_root(norm, item)
      if found then
        return found
      end
    end
  end

  return M.cwd()
end

function M.resolve(spec)
  if M.detectors[spec] then
    return M.detectors[spec]
  end
  if type(spec) == "function" then
    return spec
  end
  return function(buf)
    return M.detectors.pattern(buf, spec)
  end
end

function M.detect(opts)
  opts = opts or {}
  opts.spec = root_spec(opts)
  opts.buf = (opts.buf == nil or opts.buf == 0) and vim.api.nvim_get_current_buf() or opts.buf

  local ret = {}
  for _, spec in ipairs(opts.spec) do
    local paths = M.resolve(spec)(opts.buf)
    paths = paths or {}
    paths = type(paths) == "table" and paths or { paths }
    local roots = {}
    for _, path in ipairs(paths) do
      local resolved = M.realpath(path)
      if resolved and not vim.tbl_contains(roots, resolved) then
        roots[#roots + 1] = resolved
      end
    end
    table.sort(roots, function(a, b)
      return #a > #b
    end)
    if #roots > 0 then
      ret[#ret + 1] = { spec = spec, paths = roots }
      if opts.all == false then
        break
      end
    end
  end
  return ret
end

function M.get(opts)
  opts = opts or {}
  local buf = opts.buf or vim.api.nvim_get_current_buf()
  local custom_spec = opts.spec ~= nil
  local cached = not custom_spec and M.cache[buf] or nil
  if not cached then
    local roots = M.detect({ all = false, buf = buf, spec = opts.spec })
    cached = roots[1] and roots[1].paths[1] or M.cwd()
    if not custom_spec then
      M.cache[buf] = cached
    end
  end
  if opts.normalize or not is_win() then
    return cached
  end
  return cached:gsub("/", "\\")
end

function M.git()
  local root = M.get({ normalize = true })
  local git_root = vim.fs.find(".git", { path = root, upward = true })[1]
  return git_root and vim.fs.dirname(git_root) or root
end

function M.info()
  local spec = root_spec()
  local roots = M.detect({ all = true })
  local lines = {}
  local first = true
  for _, root in ipairs(roots) do
    for _, path in ipairs(root.paths) do
      lines[#lines + 1] = ("- [%s] %s (%s)"):format(
        first and "x" or " ",
        path,
        type(root.spec) == "table" and table.concat(root.spec, ", ") or root.spec
      )
      first = false
    end
  end
  lines[#lines + 1] = ""
  lines[#lines + 1] = "vim.g.root_spec = " .. vim.inspect(spec)
  vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO, { title = "Project Roots" })
  return roots[1] and roots[1].paths[1] or M.cwd()
end

function M.setup()
  vim.api.nvim_create_user_command("ProjectRoot", function()
    M.info()
  end, { desc = "Show detected project roots" })

  vim.api.nvim_create_autocmd({ "LspAttach", "BufWritePost", "DirChanged", "BufEnter" }, {
    group = vim.api.nvim_create_augroup("config_root_cache", { clear = true }),
    callback = function(event)
      M.cache[event.buf] = nil
    end,
  })
end

return M
