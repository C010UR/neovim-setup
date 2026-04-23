local format = require("config.format")

local M = {}
local uv = vim.uv or vim.loop

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
M._did_setup_progress_messages = false
M._terminal_progress = {}

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

local function contains(list, value)
  return type(list) == "table" and vim.tbl_contains(list, value)
end

local function buffer_name(buf)
  local name = vim.api.nvim_buf_get_name(buf)
  return name ~= "" and vim.fs.normalize(name) or nil
end

local function buffer_dir(buf)
  local name = buffer_name(buf)
  return name and vim.fs.dirname(name) or nil
end

local function matches_standalone(buf, standalone)
  if type(standalone) ~= "table" then
    return false
  end

  local ft = vim.bo[buf].filetype
  if contains(standalone.filetypes, ft) then
    return true
  end

  local name = buffer_name(buf)
  if not name then
    return false
  end

  local base = vim.fs.basename(name)
  if contains(standalone.filenames, base) then
    return true
  end

  local ext = base:match("%.([^.]+)$")
  return ext ~= nil and contains(standalone.extensions, ext)
end

local function resolve_root(root_dir, buf, on_dir)
  if type(root_dir) == "function" then
    local called = false
    local result = root_dir(buf, function(path)
      called = true
      if path then
        on_dir(path)
      end
    end)
    if type(result) == "string" and result ~= "" then
      called = true
      on_dir(result)
    elseif result == false then
      called = true
    end
    return called
  end

  if type(root_dir) == "string" and root_dir ~= "" then
    on_dir(root_dir)
    return true
  end

  return false
end

function M.resolve_root_dir(opts)
  opts = opts or {}
  if opts.root_dir == nil and opts.root_markers == nil and opts.workspace_required == nil and opts.standalone == nil then
    return nil
  end

  local config = {
    root_dir = opts.root_dir,
    root_markers = vim.deepcopy(opts.root_markers),
    workspace_required = opts.workspace_required,
    standalone = vim.deepcopy(opts.standalone),
  }

  return function(buf, on_dir)
    if resolve_root(config.root_dir, buf, on_dir) then
      return
    end

    local root = config.root_markers and vim.fs.root(buf, config.root_markers) or nil
    if root then
      on_dir(root)
      return
    end

    if config.workspace_required then
      return
    end

    if matches_standalone(buf, config.standalone) then
      local dir = buffer_dir(buf)
      if dir then
        on_dir(dir)
      end
    end
  end
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

      if package.loaded["nvim-navic"] and client.server_capabilities.documentSymbolProvider then
        local navic = require("nvim-navic")
        if not vim.b[buf].navic_client_id then
          local ok = pcall(navic.attach, client, buf)
          if ok then
            vim.b[buf].navic_client_id = client.id
          end
        end
      end
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

local function progress_message_id(client_id, token)
  return string.format("lsp.%s.%s", client_id, token)
end

local function progress_message_text(value)
  if type(value.message) == "string" and value.message ~= "" then
    return value.message
  end
  if value.kind == "end" then
    return "done"
  end
  return "working"
end

local function progress_message_percent(value)
  if type(value.percentage) == "number" then
    return math.max(0, math.min(100, math.floor(value.percentage + 0.5)))
  end
  return value.kind == "end" and 100 or nil
end

local function in_tmux()
  return type(vim.env.TMUX) == "string" and vim.env.TMUX ~= ""
end

-- tmux only forwards terminal-specific OSC sequences when they are wrapped in
-- the DCS passthrough form and `allow-passthrough` is enabled.
local function wrap_tmux_passthrough(content)
  return "\027Ptmux;" .. content:gsub("\027", "\027\027") .. "\027\\"
end

local function send_terminal_escape(content)
  if #vim.api.nvim_list_uis() == 0 then
    return
  end
  if in_tmux() then
    content = wrap_tmux_passthrough(content)
  end
  vim.api.nvim_ui_send(content)
end

local function terminal_progress_sequence(state, percent)
  if percent == nil then
    return string.format("\027]9;4;%d\027\\", state)
  end
  return string.format("\027]9;4;%d;%d\027\\", state, percent)
end

local function prune_terminal_progress()
  for client_id in pairs(M._terminal_progress) do
    if not vim.lsp.get_client_by_id(client_id) then
      M._terminal_progress[client_id] = nil
    end
  end
end

local function latest_terminal_progress()
  prune_terminal_progress()

  local latest = nil
  for _, progress in pairs(M._terminal_progress) do
    for _, item in pairs(progress.tokens or {}) do
      if not latest or item.updated > latest.updated then
        latest = item
      end
    end
  end
  return latest
end

local function update_terminal_progress(client_id, token, value)
  if value.kind == "end" then
    local progress = M._terminal_progress[client_id]
    if not progress then
      return
    end
    progress.tokens[token] = nil
    if vim.tbl_isempty(progress.tokens) then
      M._terminal_progress[client_id] = nil
    end
    return
  end

  local progress = M._terminal_progress[client_id] or { tokens = {} }
  progress.tokens[token] = {
    kind = value.kind,
    percentage = value.percentage,
    updated = uv.hrtime(),
  }
  M._terminal_progress[client_id] = progress
end

local function emit_terminal_progress()
  if not in_tmux() then
    return
  end

  local item = latest_terminal_progress()
  if not item then
    send_terminal_escape(terminal_progress_sequence(0))
    return
  end

  local percent = progress_message_percent(item)
  if percent then
    send_terminal_escape(terminal_progress_sequence(1, percent))
  else
    send_terminal_escape(terminal_progress_sequence(3))
  end
end

function M.enable_progress_messages()
  if M._did_setup_progress_messages or vim.fn.has("nvim-0.12") == 0 then
    return
  end
  M._did_setup_progress_messages = true

  vim.api.nvim_create_autocmd("LspProgress", {
    group = vim.api.nvim_create_augroup("config_lsp_progress_messages", { clear = true }),
    callback = function(event)
      local data = event.data or {}
      local params = data.params or {}
      local value = params.value or {}
      local client = data.client_id and vim.lsp.get_client_by_id(data.client_id) or nil
      local token = params.token ~= nil and tostring(params.token) or nil
      if not client or not token or token == "" or type(value.kind) ~= "string" then
        return
      end

      vim.api.nvim_echo({ { progress_message_text(value) } }, false, {
        id = progress_message_id(client.id, token),
        kind = "progress",
        percent = progress_message_percent(value),
        source = "vim.lsp",
        status = value.kind == "end" and "success" or "running",
        title = value.title or client.name,
      })
      update_terminal_progress(client.id, token, value)
      emit_terminal_progress()
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
        return client:supports_method("textDocument/formatting")
          or client:supports_method("textDocument/rangeFormatting")
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
