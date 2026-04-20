local root = require("config.root")

local M = {}
local commands = {
  files = "files",
  live_grep = "grep",
  oldfiles = "recent",
}

function M.open(command, opts)
  command = commands[command ~= "auto" and command or "files"] or command or "files"
  opts = vim.deepcopy(opts or {})

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
