--- Project root detection built on Neovim's native `vim.fs.root()`.
---
--- Resolution order for `get()`:
--- 1. Nearest ancestor directory (of the buffer's file, or cwd for unnamed
---    buffers) containing any marker from `vim.g.root_markers`.
--- 2. If a root was found outside the directory Neovim was started with,
---    it is clamped back to the startup directory.
--- 3. Fallback: the startup directory (first existing directory argument)
---    or the current working directory.

---@class ConfigRoot
---@overload fun(opts?: { normalize?: boolean, buf?: number }): string
---@type ConfigRoot|table
local M = setmetatable({}, {
  __call = function(self, ...)
    return self.get(...)
  end,
})

local DEFAULT_MARKERS = {
  -- Equal priority: the nearest ancestor containing ANY of these wins.
  {
    ".git",
    "package.json",
    "composer.json",
    "Cargo.toml",
    "go.mod",
    "pyproject.toml",
    "stylua.toml",
    ".luarc.json",
    "lua",
  },
}

local function is_win()
  return vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1
end

local function normalize(path)
  return path and path ~= "" and vim.fs.normalize(path) or nil
end

function M.realpath(path)
  if not path or path == "" then
    return nil
  end
  local resolved = is_win() and path or vim.uv.fs_realpath(path) or path
  return normalize(resolved)
end

--- Marker spec passed to `vim.fs.root()`. A nested list means equal priority.
---@return (string|string[])[]
function M.markers()
  if type(vim.g.root_markers) == "table" then
    return vim.g.root_markers
  end
  return vim.deepcopy(DEFAULT_MARKERS)
end

---@return string|nil
local function startup_dir()
  for i = 0, vim.fn.argc(-1) - 1 do
    local arg = vim.fn.argv(i)
    if type(arg) == "string" and arg ~= "" then
      -- Handles ~, env vars, trailing slashes, relative paths and `..`.
      local resolved = M.realpath(vim.fn.expand(arg))
      if resolved and vim.fn.isdirectory(resolved) == 1 then
        return resolved
      end
    end
  end
  return nil
end

--- Clamp `root` to the startup directory: if the startup dir lies inside the
--- detected root (e.g. `nvim ~/Projects/repo/subdir` inside a bigger repo),
--- prefer the startup dir. Unrelated roots are left untouched.
---@param root string|nil
---@param base string|nil
---@return string|nil
local function clamp(root, base)
  if not root or not base or root == base then
    return root
  end
  if base:find(root .. "/", 1, true) == 1 then
    return base
  end
  return root
end

function M.bufpath(buf)
  return M.realpath(vim.api.nvim_buf_get_name(assert(buf)))
end

function M.cwd()
  return M.realpath(vim.uv.cwd()) or ""
end

function M.startup_dir()
  return startup_dir()
end

--- Resolve the project root for a buffer using `vim.fs.root()`.
---@param opts? { normalize?: boolean, buf?: number }
---@return string
function M.get(opts)
  opts = opts or {}
  local buf = opts.buf or 0
  local base = startup_dir()

  local root = vim.fs.root(buf, M.markers())
  root = clamp(root and M.realpath(root) or nil, base)

  if not root then
    root = base or M.cwd()
  end

  -- Paths are always normalized; `normalize` is kept for call-site compat.
  if opts.normalize or not is_win() then
    return root
  end
  return root:gsub("/", "\\")
end

function M.git()
  return M.realpath(vim.fs.root(0, ".git")) or M.get({ normalize = true })
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

--- Show what native root resolution picks for the current buffer.
function M.info()
  local lines = {
    ("root: %s"):format(M.get({ normalize = true })),
    ("startup dir: %s"):format(startup_dir() or "-"),
    ("cwd: %s"):format(M.cwd()),
    ("markers: " .. vim.inspect(M.markers())),
  }
  vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO, { title = "Project Root" })
  return lines
end

function M.setup()
  vim.api.nvim_create_user_command("ProjectRoot", function()
    M.info()
  end, { desc = "Show the natively detected project root" })
end

return M
