local icons = require("config.icons")
local root = require("config.root")

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

  local ok, utils = pcall(require, "lualine.utils.utils")
  if ok and type(utils.stl_escape) == "function" then
    return utils.stl_escape(text)
  end
  return text:gsub("%%", "%%%%")
end

local function truncate(text, max_length)
  if type(text) ~= "string" or text == "" or not max_length or max_length <= 0 then
    return text or ""
  end
  if vim.fn.strchars(text) <= max_length then
    return text
  end
  return vim.fn.strcharpart(text, 0, math.max(max_length - 1, 0)) .. "…"
end

local function refresh_statusline()
  local ok, lualine = pcall(require, "lualine")
  if ok then
    lualine.refresh({ place = { "statusline" } })
  else
    vim.cmd.redrawstatus()
  end
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

local function progress_bar(percentage, width)
  local size = math.max(width or 5, 1)
  local percent = math.max(0, math.min(100, percentage or 0))
  local filled = math.floor(((percent / 100) * size) + 0.5)
  return string.rep("█", filled) .. string.rep("░", size - filled)
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

      vim.schedule(refresh_statusline)
    end,
  })

  vim.api.nvim_create_autocmd({ "LspAttach", "LspDetach" }, {
    group = group,
    callback = function()
      vim.schedule(refresh_statusline)
    end,
  })
end

function M.status(icon, status)
  local colors = {
    ok = "Special",
    error = "DiagnosticError",
    pending = "DiagnosticWarn",
  }
  return {
    function()
      return icon
    end,
    cond = function()
      return status() ~= nil
    end,
    color = function()
      return { fg = Snacks.util.color(colors[status()] or colors.ok) }
    end,
  }
end

function M.format(component, text, hl_group)
  text = sanitize_statusline(text)
  if not hl_group or hl_group == "" then
    return text
  end
  component.hl_cache = component.hl_cache or {}
  local lualine_hl_group = component.hl_cache[hl_group]
  if not lualine_hl_group then
    local utils = require("lualine.utils.utils")
    local gui = vim.tbl_filter(function(x)
      return x
    end, {
      utils.extract_highlight_colors(hl_group, "bold") and "bold",
      utils.extract_highlight_colors(hl_group, "italic") and "italic",
    })

    lualine_hl_group = component:create_hl({
      fg = utils.extract_highlight_colors(hl_group, "fg"),
      gui = #gui > 0 and table.concat(gui, ",") or nil,
    }, "CFG_" .. hl_group)
    component.hl_cache[hl_group] = lualine_hl_group
  end
  return component:format_hl(lualine_hl_group) .. text .. component:get_default_hl()
end

function M.pretty_path(opts)
  opts = vim.tbl_extend("force", {
    relative = "cwd",
    modified_hl = "MatchParen",
    directory_hl = "",
    filename_hl = "Bold",
    modified_sign = "",
    readonly_icon = " 󰌾 ",
    length = 3,
  }, opts or {})

  return function(self)
    local path = vim.fn.expand("%:p")
    if path == "" then
      return ""
    end

    local normalized = vim.fs.normalize(path)
    local project_root = root.get({ normalize = true })
    local cwd = root.cwd()
    local compare = normalized
    local compare_root = project_root
    local compare_cwd = cwd

    if vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1 then
      compare = compare:lower()
      compare_root = compare_root:lower()
      compare_cwd = compare_cwd:lower()
    end

    if opts.relative == "cwd" and compare:find(compare_cwd, 1, true) == 1 then
      path = path:sub(#cwd + 2)
    elseif compare:find(compare_root, 1, true) == 1 then
      path = path:sub(#project_root + 2)
    end

    local sep = package.config:sub(1, 1)
    local parts = vim.split(path, "[\\/]")
    if opts.length > 0 and #parts > opts.length then
      parts = { parts[1], "…", unpack(parts, #parts - opts.length + 2, #parts) }
    end

    if opts.modified_hl and vim.bo.modified then
      parts[#parts] = M.format(self, parts[#parts] .. opts.modified_sign, opts.modified_hl)
    else
      parts[#parts] = M.format(self, parts[#parts], opts.filename_hl)
    end

    local dir = ""
    if #parts > 1 then
      dir = table.concat({ unpack(parts, 1, #parts - 1) }, sep)
      dir = M.format(self, dir .. sep, opts.directory_hl)
    end

    local readonly = ""
    if vim.bo.readonly then
      readonly = M.format(self, opts.readonly_icon, opts.modified_hl)
    end

    return dir .. parts[#parts] .. readonly
  end
end

function M.root_dir(opts)
  opts = vim.tbl_extend("force", {
    cwd = false,
    subdirectory = true,
    parent = true,
    other = true,
    icon = "󱉭 ",
    color = function()
      return { fg = Snacks.util.color("Special") }
    end,
  }, opts or {})

  local function get_name()
    local cwd = root.cwd()
    local project_root = root.get({ normalize = true })
    local name = vim.fs.basename(project_root)
    if project_root == cwd then
      return opts.cwd and name or nil
    elseif project_root:find(cwd, 1, true) == 1 then
      return opts.subdirectory and name or nil
    elseif cwd:find(project_root, 1, true) == 1 then
      return opts.parent and name or nil
    end
    return opts.other and name or nil
  end

  return {
    function()
      local name = get_name()
      return name and sanitize_statusline(((opts.icon and opts.icon .. " ") or "") .. name) or ""
    end,
    cond = function()
      return type(get_name()) == "string"
    end,
    color = opts.color,
  }
end

function M.lsp_clients(opts)
  setup_lsp_tracking()
  opts = vim.tbl_extend("force", {
    ignore = {},
    icon = "",
    inactive_icon = "",
    always_visible = true,
  }, opts or {})

  local function text()
    if not buffer_supports_lsp_status() then
      return ""
    end

    local clients = filtered_clients(opts)
    if #clients == 0 then
      return opts.always_visible and opts.inactive_icon or ""
    end

    return sanitize_statusline(string.format("%s %d", opts.icon, #clients))
  end

  return {
    text,
    cond = function()
      return text() ~= ""
    end,
    color = function()
      return { fg = Snacks.util.color(#filtered_clients(opts) > 0 and "Special" or "Comment") }
    end,
  }
end

function M.lsp_progress(opts)
  setup_lsp_tracking()
  opts = vim.tbl_extend("force", {
    ignore = {},
    bar_width = 6,
    show_client = true,
    show_message = true,
    message_length = 32,
    spinner = SPINNER_FRAMES,
    separator = " ",
    client_separator = " | ",
    color = function()
      return { fg = Snacks.util.color("Special") }
    end,
  }, opts or {})

  local function text()
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
        segment[#segment + 1] = progress_bar(percentage, opts.bar_width)
        segment[#segment + 1] = string.format("%3d%%", percentage)
      else
        segment[#segment + 1] = spinner
      end

      if opts.show_message then
        local label = item.title or item.message or "Working"
        if item.title and item.message and item.message ~= item.title then
          label = item.title .. ": " .. item.message
        end
        label = truncate(label, opts.message_length)
        if label ~= "" then
          segment[#segment + 1] = label
        end
      end

      parts[#parts + 1] = table.concat(segment, opts.separator)
    end

    return sanitize_statusline(table.concat(parts, opts.client_separator))
  end

  return {
    text,
    cond = function()
      return text() ~= ""
    end,
    color = opts.color,
  }
end

function M.breadcrumbs(opts)
  opts = vim.tbl_extend("force", {
    prefix = "",
    length = 48,
    highlight = true,
  }, opts or {})

  local function location()
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

    local prefix = opts.prefix or ""
    if opts.highlight then
      return prefix .. breadcrumb
    end
    return sanitize_statusline(prefix .. truncate(breadcrumb, opts.length))
  end

  return {
    location,
    cond = function()
      return location() ~= ""
    end,
    color = opts.highlight and nil or opts.color,
  }
end

local function sanitize_component_output(component)
  if type(component) == "table" and type(component[1]) == "function" then
    local text = component[1]
    component[1] = function(...)
      return sanitize_statusline(text(...))
    end
  end
  return component
end

function M.profiler_status()
  return sanitize_component_output(Snacks.profiler.status())
end

function M.dap_status()
  return {
    function()
      return sanitize_statusline("  " .. require("dap").status())
    end,
    cond = function()
      return package.loaded["dap"] and require("dap").status() ~= ""
    end,
    color = function()
      return { fg = Snacks.util.color("Debug") }
    end,
  }
end

function M.opts()
  return {
    options = {
      theme = "auto",
      component_separators = { left = "|", right = "|" },
      section_separators = { left = "", right = "" },
      globalstatus = vim.o.laststatus == 3,
      disabled_filetypes = { statusline = { "dashboard", "alpha", "ministarter", "snacks_dashboard" } },
    },
    sections = {
      lualine_a = { "mode" },
      lualine_b = { "branch" },
      lualine_c = {
        M.root_dir(),
        {
          "diagnostics",
          separator = "",
          symbols = {
            error = icons.diagnostics.Error,
            warn = icons.diagnostics.Warn,
            info = icons.diagnostics.Info,
            hint = icons.diagnostics.Hint,
          },
        },
        M.lsp_clients({ always_visible = false }),
        { "filetype", icon_only = true, separator = "", padding = { left = 1, right = 0 } },
        { M.pretty_path() },
        M.breadcrumbs({ color = function() return { fg = Snacks.util.color("Comment") } end }),
      },
      lualine_x = {
        M.profiler_status(),
        M.lsp_progress(),
        M.dap_status(),
      },
      lualine_y = {
        { "progress", separator = " ", padding = { left = 1, right = 0 } },
        { "location", padding = { left = 0, right = 1 } },
      },
      lualine_z = {
        function()
          return ""
        end,
      },
    },
    extensions = { "neo-tree", "fzf" },
  }
end

M.sanitize_statusline = sanitize_statusline

M.icons = icons

return M
