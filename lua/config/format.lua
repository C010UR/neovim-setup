---@class ConfigFormatter
---@field name string
---@field primary? boolean
---@field format fun(bufnr: number)
---@field sources fun(bufnr: number): string[]
---@field priority number

---@class ConfigFormat
---@overload fun(opts?: { force?: boolean, buf?: number })
local M = setmetatable({}, {
  __call = function(_, ...)
    return M.format(...)
  end,
})

M.formatters = {}

-- Formatters are registered by plugin specs and resolved by priority.

local function notify(msg, level, opts)
  vim.notify(msg, level or vim.log.levels.INFO, opts or {})
end

function M.register(formatter)
  M.formatters[#M.formatters + 1] = formatter
  table.sort(M.formatters, function(a, b)
    return a.priority > b.priority
  end)
end

function M.formatexpr()
  if package.loaded["conform"] then
    return require("conform").formatexpr()
  end
  return vim.lsp.formatexpr({ timeout_ms = 3000 })
end

function M.resolve(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  local have_primary = false
  return vim.tbl_map(function(formatter)
    local sources = formatter.sources(buf)
    local active = #sources > 0 and (not formatter.primary or not have_primary)
    have_primary = have_primary or (active and formatter.primary) or false
    return setmetatable({ active = active, resolved = sources }, { __index = formatter })
  end, M.formatters)
end

function M.enabled(buf)
  buf = (buf == nil or buf == 0) and vim.api.nvim_get_current_buf() or buf
  local global_autoformat = vim.g.autoformat
  local buffer_autoformat = vim.b[buf].autoformat
  if buffer_autoformat ~= nil then
    return buffer_autoformat
  end
  return global_autoformat == nil or global_autoformat
end

function M.info(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  local global_autoformat = vim.g.autoformat == nil or vim.g.autoformat
  local buffer_autoformat = vim.b[buf].autoformat
  local enabled = M.enabled(buf)
  local lines = {
    "# Status",
    ("- [%s] global **%s**"):format(global_autoformat and "x" or " ", global_autoformat and "enabled" or "disabled"),
    ("- [%s] buffer **%s**"):format(
      enabled and "x" or " ",
      buffer_autoformat == nil and "inherit" or buffer_autoformat and "enabled" or "disabled"
    ),
  }

  local have = false
  for _, formatter in ipairs(M.resolve(buf)) do
    if #formatter.resolved > 0 then
      have = true
      lines[#lines + 1] = "\n# " .. formatter.name .. (formatter.active and " ***(active)***" or "")
      for _, source in ipairs(formatter.resolved) do
        lines[#lines + 1] = ("- [%s] **%s**"):format(formatter.active and "x" or " ", source)
      end
    end
  end

  if not have then
    lines[#lines + 1] = "\n***No formatters available for this buffer.***"
  end

  notify(table.concat(lines, "\n"), enabled and vim.log.levels.INFO or vim.log.levels.WARN, {
    title = "Format (" .. (enabled and "enabled" or "disabled") .. ")",
  })
end

function M.enable(enable, buf)
  if enable == nil then
    enable = true
  end
  if buf then
    vim.b.autoformat = enable
  else
    vim.g.autoformat = enable
    vim.b.autoformat = nil
  end
  M.info()
end

function M.toggle(buf)
  M.enable(not M.enabled(), buf)
end

function M.format(opts)
  opts = opts or {}
  local buf = opts.buf or vim.api.nvim_get_current_buf()
  if not (opts.force or M.enabled(buf)) then
    return
  end

  local done = false
  for _, formatter in ipairs(M.resolve(buf)) do
    if formatter.active then
      done = true
      local ok, err = pcall(formatter.format, buf)
      if not ok then
        notify(err, vim.log.levels.ERROR, { title = ("Formatter %s failed"):format(formatter.name) })
      end
    end
  end

  if not done and opts.force then
    notify("No formatter available", vim.log.levels.WARN, { title = "Format" })
  end
end

function M.setup()
  vim.api.nvim_create_autocmd("BufWritePre", {
    group = vim.api.nvim_create_augroup("config_autoformat", { clear = true }),
    callback = function(event)
      M.format({ buf = event.buf })
    end,
  })

  vim.api.nvim_create_user_command("Format", function()
    M.format({ force = true })
  end, { desc = "Format selection or buffer" })

  vim.api.nvim_create_user_command("FormatInfo", function()
    M.info()
  end, { desc = "Show info about the current buffer's formatters" })

  -- Keep the LazyFormat command names for compatibility with older habits.

  vim.api.nvim_create_user_command("LazyFormat", function()
    M.format({ force = true })
  end, { desc = "Format selection or buffer" })

  vim.api.nvim_create_user_command("LazyFormatInfo", function()
    M.info()
  end, { desc = "Show info about the current buffer's formatters" })
end

function M.snacks_toggle(buf)
  return Snacks.toggle({
    name = "Auto Format (" .. (buf and "Buffer" or "Global") .. ")",
    get = function()
      if not buf then
        return vim.g.autoformat == nil or vim.g.autoformat
      end
      return M.enabled()
    end,
    set = function(state)
      M.enable(state, buf)
    end,
  })
end

return M
