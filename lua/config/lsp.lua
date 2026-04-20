local format = require("config.format")

local M = {}

M.kind_filter = {
  default = {
    "Class",
    "Constructor",
    "Enum",
    "Field",
    "Function",
    "Interface",
    "Method",
    "Module",
    "Namespace",
    "Package",
    "Property",
    "Struct",
    "Trait",
  },
  markdown = false,
  help = false,
  lua = {
    "Class",
    "Constructor",
    "Enum",
    "Field",
    "Function",
    "Interface",
    "Method",
    "Module",
    "Namespace",
    "Property",
    "Struct",
    "Trait",
  },
}

M._server_keys = {}
M._did_setup_keymaps = false

-- Server-specific keymaps are registered up front and attached lazily when an
-- LSP client connects to a buffer.

local function supports_any(client, methods)
  methods = type(methods) == "string" and { methods } or methods
  for _, method in ipairs(methods or {}) do
    method = method:find("/") and method or ("textDocument/" .. method)
    if client:supports_method(method) then
      return true
    end
  end
  return false
end

function M.register_keys(server, spec)
  M._server_keys[server] = M._server_keys[server] or {}
  vim.list_extend(M._server_keys[server], spec or {})
end

function M.enable_keymaps()
  if M._did_setup_keymaps then
    return
  end
  M._did_setup_keymaps = true

  vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("config_lsp_keymaps", { clear = true }),
    callback = function(event)
      local client = vim.lsp.get_client_by_id(event.data.client_id)
      if not client then
        return
      end
      local buf = event.buf
      local applied = vim.b[buf].config_lsp_applied_keys or {}
      for _, server in ipairs({ "*", client.name }) do
        for _, keys in ipairs(M._server_keys[server] or {}) do
          if not keys.has or supports_any(client, keys.has) then
            local enabled = keys.enabled == nil or keys.enabled(buf)
            local mode = keys.mode or "n"
            local id = table.concat(type(mode) == "table" and mode or { mode }, ",") .. ":" .. keys[1]
            if enabled and not applied[id] then
              local opts = {
                buffer = buf,
                desc = keys.desc,
                expr = keys.expr,
                silent = keys.silent ~= false,
                nowait = keys.nowait,
                remap = keys.remap,
              }
              vim.keymap.set(mode, keys[1], keys[2], opts)
              applied[id] = true
            end
          end
        end
      end
      vim.b[buf].config_lsp_applied_keys = applied
    end,
  })
end

function M.formatter(opts)
  opts = opts or {}
  local filter = opts.filter or {}
  filter = type(filter) == "string" and { name = filter } or filter
  return vim.tbl_deep_extend("force", {
    name = "LSP",
    primary = true,
    priority = 1,
    format = function(buf)
      M.format(vim.tbl_deep_extend("force", {}, filter, { bufnr = buf }))
    end,
    sources = function(buf)
      local clients = vim.lsp.get_clients(vim.tbl_deep_extend("force", {}, filter, { bufnr = buf }))
      local active = vim.tbl_filter(function(client)
        return client:supports_method("textDocument/formatting") or client:supports_method("textDocument/rangeFormatting")
      end, clients)
      return vim.tbl_map(function(client)
        return client.name
      end, active)
    end,
  }, opts)
end

function M.format(opts)
  opts = vim.tbl_deep_extend("force", {}, opts or {})
  if package.loaded["conform"] then
    opts.formatters = nil
    require("conform").format(opts)
  else
    vim.lsp.buf.format(opts)
  end
end

M.action = setmetatable({}, {
  __index = function(_, action)
    return function()
      vim.lsp.buf.code_action({
        apply = true,
        context = {
          only = { action },
          diagnostics = {},
        },
      })
    end
  end,
})

function M.execute(opts)
  local filter = opts.filter or {}
  filter = type(filter) == "string" and { name = filter } or filter
  local buf = vim.api.nvim_get_current_buf()
  local client = vim.lsp.get_clients(vim.tbl_deep_extend("force", {}, filter, { bufnr = buf }))[1]
  if not client then
    vim.notify("No matching LSP client available", vim.log.levels.WARN, { title = "LSP" })
    return
  end

  local params = {
    command = opts.command,
    arguments = opts.arguments,
  }

  return client:exec_cmd(vim.tbl_extend("force", params, { title = opts.title }), { bufnr = buf }, opts.handler)
end

function M.code_actions(filter)
  filter = filter or {}
  local ret = {}
  for _, client in ipairs(vim.lsp.get_clients(filter)) do
    vim.list_extend(ret, vim.tbl_get(client, "server_capabilities", "codeActionProvider", "codeActionKinds") or {})
    local regs = client.dynamic_capabilities and client.dynamic_capabilities:get("codeActionProvider", filter) or {}
    for _, reg in ipairs(regs or {}) do
      vim.list_extend(ret, vim.tbl_get(reg, "registerOptions", "codeActionKinds") or {})
    end
  end
  return vim.fn.uniq(vim.fn.sort(ret))
end

function M.register_lsp_formatter(filter, opts)
  format.register(M.formatter(vim.tbl_deep_extend("force", opts or {}, { filter = filter })))
end

return M
