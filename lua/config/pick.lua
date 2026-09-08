--- Compatibility routing for pickers. New code should use
--- `require("config.finder")` directly; this keeps the dashboard and
--- scaffold integrations working through a single API.

local root = require("config.root")
local finder = require("config.finder")

local M = {}
local commands = {
  files = "files",
  live_grep = "grep",
  grep = "grep",
  oldfiles = "oldfiles",
}

function M.open(command, opts)
  command = commands[command ~= "auto" and command or "files"] or command or "files"
  opts = vim.deepcopy(opts or {})

  -- Finder scope handles the core search entry points (uniform UI + scoping).
  if command == "files" or command == "grep" then
    return finder.open(command, opts)
  end

  -- Fallback to Snacks.picker for everything else (oldfiles, git, buffers, etc.)
  if not opts.cwd and opts.root ~= false then
    opts.cwd = root.get({ buf = opts.buf, normalize = true })
  end
  return Snacks.picker.pick(command, opts)
end

function M.wrap(command, opts)
  opts = opts or {}
  return function()
    M.open(command, vim.deepcopy(opts))
  end
end

function M.config_files()
  return M.wrap("files", { cwd = vim.fn.stdpath("config") })
end

return setmetatable(M, {
  __call = function(_, ...)
    return M.wrap(...)
  end,
})
