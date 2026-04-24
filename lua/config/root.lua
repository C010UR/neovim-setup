local uri = require("config.uri")

---@class ConfigRoot
---@overload fun(opts?: { normalize?: boolean, buf?: number }): string
local M = {}

setmetatable(M, {
  __call = function(self, ...)
    return self.get(...)
  end,
})

M.spec = { "lsp", { ".git", "lua" }, "cwd" }
-- Root detection prefers active LSP workspaces, then common project markers,
-- and finally falls back to the current working directory.
M.cache = {}
M.detectors = {}

local function is_win()
  return vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1
end

local function normalize(path)
  if not path or path == "" then
    return nil
  end
  return vim.fs.normalize(path)
end

function M.detectors.cwd()
  return { normalize(vim.uv.cwd()) }
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
    return path and bufpath:find(path, 1, true) == 1
  end, roots)
end

function M.detectors.pattern(buf, patterns)
  patterns = type(patterns) == "string" and { patterns } or patterns
  local path = M.bufpath(buf) or vim.uv.cwd()
  local pattern = vim.fs.find(function(name)
    for _, p in ipairs(patterns) do
      if name == p then
        return true
      end
      if p:sub(1, 1) == "*" and name:find(vim.pesc(p:sub(2)) .. "$") then
        return true
      end
    end
    return false
  end, { path = path, upward = true })[1]
  return pattern and { vim.fs.dirname(pattern) } or {}
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
  opts.spec = opts.spec or (type(vim.g.root_spec) == "table" and vim.g.root_spec or M.spec)
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
  local cached = M.cache[buf]
  if not cached then
    local roots = M.detect({ all = false, buf = buf })
    cached = roots[1] and roots[1].paths[1] or M.cwd()
    M.cache[buf] = cached
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
  local spec = type(vim.g.root_spec) == "table" and vim.g.root_spec or M.spec
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
