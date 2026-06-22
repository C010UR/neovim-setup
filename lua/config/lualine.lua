local M = {}

local uv = vim.uv or vim.loop

local SPINNER_FRAMES = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }

local lsp_state = {
  progress = {},
  setup_ran = false,
}

local function sanitize_statusline(text)
  if text == nil then
    return ""
  end
  if type(text) ~= "string" then
    text = tostring(text)
  end
  return text:gsub("%%", "%%%%")
end

local function refresh_statusline()
  vim.schedule(vim.cmd.redrawstatus)
end

local function buffer_supports_lsp_status()
  return vim.bo.buftype == ""
end

local function prune_progress_state()
  for client_id in pairs(lsp_state.progress) do
    if not vim.lsp.get_client_by_id(client_id) then
      lsp_state.progress[client_id] = nil
    end
  end
end

local function current_spinner(frames)
  local spinner = frames or SPINNER_FRAMES
  local interval_ms = 80
  local index = math.floor((uv.hrtime() / 1e6) / interval_ms) % #spinner + 1
  return spinner[index]
end

local function filtered_clients(opts)
  local ignored = {}
  for _, name in ipairs(opts.ignore or {}) do
    ignored[name] = true
  end

  local clients = vim.lsp.get_clients({ bufnr = 0 })
  table.sort(clients, function(a, b)
    return a.name < b.name
  end)

  local ret = {}
  local seen = {}
  for _, client in ipairs(clients) do
    if not ignored[client.name] and not seen[client.name] then
      seen[client.name] = true
      ret[#ret + 1] = client
    end
  end
  return ret
end

local function latest_progress(tokens)
  local latest = nil
  for _, token in pairs(tokens or {}) do
    if not latest or token.updated > latest.updated then
      latest = token
    end
  end
  return latest
end

local function active_progress(opts)
  prune_progress_state()

  local ret = {}
  for _, client in ipairs(filtered_clients(opts)) do
    local progress = lsp_state.progress[client.id]
    local item = progress and latest_progress(progress.tokens) or nil
    if item then
      ret[#ret + 1] = {
        client = client.name,
        item = item,
      }
    end
  end
  return ret
end

local function setup_lsp_tracking()
  if lsp_state.setup_ran then
    return
  end
  lsp_state.setup_ran = true

  local group = vim.api.nvim_create_augroup("config_lualine_lsp", { clear = true })

  vim.api.nvim_create_autocmd("LspProgress", {
    group = group,
    callback = function(event)
      local data = event.data or {}
      local params = data.params or {}
      local value = params.value or {}
      local client_id = data.client_id
      local token = params.token ~= nil and tostring(params.token) or nil
      local client = client_id and vim.lsp.get_client_by_id(client_id) or nil
      if not client or not token or token == "" then
        return
      end

      if value.kind == "end" then
        local progress = lsp_state.progress[client.id]
        if progress then
          progress.tokens[token] = nil
          if vim.tbl_isempty(progress.tokens) then
            lsp_state.progress[client.id] = nil
          end
        end
      else
        local progress = lsp_state.progress[client.id] or { tokens = {} }
        progress.tokens[token] = {
          kind = value.kind,
          title = value.title,
          message = value.message,
          percentage = value.percentage,
          updated = uv.hrtime(),
        }
        lsp_state.progress[client.id] = progress
      end

      refresh_statusline()
    end,
  })

  vim.api.nvim_create_autocmd({ "LspAttach", "LspDetach" }, {
    group = group,
    callback = refresh_statusline,
  })
end

function M.lsp_clients_text(opts)
  setup_lsp_tracking()
  opts = vim.tbl_extend("force", {
    ignore = {},
    icon = "",
    inactive_icon = "",
    always_visible = true,
  }, opts or {})

  if not buffer_supports_lsp_status() then
    return ""
  end

  local clients = filtered_clients(opts)
  if #clients == 0 then
    return opts.always_visible and sanitize_statusline(opts.inactive_icon) or ""
  end

  return sanitize_statusline(string.format("%s %d", opts.icon, #clients))
end

function M.lsp_progress_text(opts)
  setup_lsp_tracking()
  opts = vim.tbl_extend("force", {
    ignore = {},
    show_client = false,
    show_message = false,
    spinner = SPINNER_FRAMES,
    separator = " ",
    client_separator = " | ",
  }, opts or {})

  if not buffer_supports_lsp_status() then
    return ""
  end

  local entries = active_progress(opts)
  if #entries == 0 then
    return ""
  end

  local spinner = current_spinner(opts.spinner)
  local parts = {}
  for _, entry in ipairs(entries) do
    local item = entry.item
    local segment = {}
    if opts.show_client then
      segment[#segment + 1] = entry.client
    end

    local percentage = type(item.percentage) == "number" and math.floor(item.percentage + 0.5) or nil
    if percentage then
      segment[#segment + 1] = string.format("%3d%%", percentage)
    else
      segment[#segment + 1] = spinner
    end

    if opts.show_message then
      local label = item.title or item.message or "Working"
      if item.title and item.message and item.message ~= item.title then
        label = item.title .. ": " .. item.message
      end
      if label ~= "" then
        segment[#segment + 1] = label
      end
    end

    parts[#parts + 1] = table.concat(segment, opts.separator)
  end

  return sanitize_statusline(table.concat(parts, opts.client_separator))
end

function M.breadcrumbs_text(opts)
  opts = vim.tbl_extend("force", {
    prefix = "",
    highlight = true,
  }, opts or {})

  local ok, navic = pcall(require, "nvim-navic")
  if not ok or not navic.is_available() then
    return ""
  end

  local breadcrumb = navic.get_location({
    highlight = opts.highlight,
    safe_output = true,
  })
  if breadcrumb == "" then
    return ""
  end

  return (opts.prefix or "") .. breadcrumb
end

M.sanitize_statusline = sanitize_statusline

return M
