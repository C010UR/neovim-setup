local icons = require("config.icons")
local lualine = require("config.lualine")
local root = require("config.root")

local M = {}

local blink_icon = true
local blink_timer = nil

local DISABLED_FT = {
  dashboard = true,
  alpha = true,
  ministarter = true,
  snacks_dashboard = true,
}

local MODE_SOURCES = {
  StModeNormal = "Type",
  StModeInsert = "String",
  StModeVisual = "DiagnosticWarn",
  StModeOther = "Comment",
}

local GIT_DIFF_SOURCES = {
  StGitAdd = { "GitSignsAdd", "DiffAdd" },
  StGitChange = { "GitSignsChange", "DiffChange" },
  StGitDelete = { "GitSignsDelete", "DiffDelete" },
}

local MODE_LABELS = {
  n = { "n", "StModeNormal" },
  i = { "i", "StModeInsert" },
  v = { "v", "StModeVisual" },
  V = { "v-line", "StModeVisual" },
  ["\22"] = { "v-block", "StModeVisual" },
  c = { "c", "StModeOther" },
  r = { "r", "StModeOther" },
  R = { "R", "StModeOther" },
  t = { "t", "StModeOther" },
}

local LSP_CLIENT_OPTS = { always_visible = false }
local LSP_PROGRESS_OPTS = { show_client = false, show_message = false }
local BREADCRUMB_OPTS = { highlight = true }

local has_devicons, devicons = pcall(require, "nvim-web-devicons")

local function hl(group, text)
  if text == nil or text == "" then
    return ""
  end
  return "%#" .. group .. "#" .. text .. "%#StBase#"
end

local function join(...)
  local out = {}
  for i = 1, select("#", ...) do
    local part = select(i, ...)
    if part and part ~= "" then
      out[#out + 1] = part
    end
  end
  return table.concat(out, " ")
end

local function set_inverted_hl(target, source)
  local src = vim.api.nvim_get_hl(0, { name = source, link = false })
  local st = vim.api.nvim_get_hl(0, { name = "StatusLine", link = false })
  local mode_color = src.fg or src.foreground
  local text_color = st.bg or st.background or st.fg or st.foreground
  if not mode_color or not text_color then
    return
  end
  vim.api.nvim_set_hl(0, target, {
    fg = text_color,
    bg = mode_color,
    bold = true,
    default = true,
  })
end

local function set_theme_fg_hl(target, sources)
  for _, source in ipairs(sources) do
    local src = vim.api.nvim_get_hl(0, { name = source, link = false })
    local fg = src.fg or src.foreground
    if fg then
      vim.api.nvim_set_hl(0, target, {
        fg = fg,
        bg = "NONE",
        sp = "NONE",
        default = true,
      })
      return
    end
  end
end

local function setup_highlights()
  local links = {
    StBase = "StatusLine",
    StGitBranch = "Special",
    FileModifiedIcon = "WarningMsg",
    RecordingHl = "DiagnosticError",
    LazyCheckHl = "WarningMsg",
    ErrorHl = "DiagnosticError",
    WarningHl = "DiagnosticWarn",
    HintsHl = "DiagnosticHint",
    InfoHl = "DiagnosticInfo",
    StLsp = "Special",
  }

  for group, link in pairs(links) do
    vim.api.nvim_set_hl(0, group, { link = link, default = true })
  end

  for group, source in pairs(MODE_SOURCES) do
    set_inverted_hl(group, source)
  end

  for group, sources in pairs(GIT_DIFF_SOURCES) do
    set_theme_fg_hl(group, sources)
  end
end

local function mode_part(group, label)
  return "%#StBase#%#" .. group .. "# " .. label .. " %#StBase#"
end

local function get_lazy_updates()
  local ok, lazy_status = pcall(require, "lazy.status")
  if not ok or lazy_status.has_updates() == false then
    return nil
  end

  local updates = lazy_status.updates()
  if updates == nil or updates == "" then
    return nil
  end

  return hl("LazyCheckHl", lualine.sanitize_statusline(updates))
end

local function get_mode()
  local mode = vim.api.nvim_get_mode().mode
  local m = MODE_LABELS[mode] or { mode, "StModeOther" }
  return mode_part(m[2], m[1])
end

local function get_git()
  local dict = vim.b.gitsigns_status_dict
  if not dict then
    return nil
  end

  local parts = {}
  if dict.added and dict.added > 0 then
    parts[#parts + 1] = hl("StGitAdd", "+" .. dict.added)
  end
  if dict.changed and dict.changed > 0 then
    parts[#parts + 1] = hl("StGitChange", "~" .. dict.changed)
  end
  if dict.removed and dict.removed > 0 then
    parts[#parts + 1] = hl("StGitDelete", "-" .. dict.removed)
  end
  if dict.head then
    parts[#parts + 1] = hl("StGitBranch", " " .. dict.head)
  end

  if #parts == 0 then
    return nil
  end
  return table.concat(parts, " ")
end

local function get_lsp_diagnostic_count()
  local counts = vim.diagnostic.count(0)

  local errors = counts[vim.diagnostic.severity.ERROR] or 0
  local warnings = counts[vim.diagnostic.severity.WARN] or 0
  local hints = counts[vim.diagnostic.severity.HINT] or 0
  local info = counts[vim.diagnostic.severity.INFO] or 0

  local parts = {}
  if errors > 0 then
    parts[#parts + 1] = hl("ErrorHl", icons.diagnostics.Error .. errors)
  end
  if warnings > 0 then
    parts[#parts + 1] = hl("WarningHl", icons.diagnostics.Warn .. warnings)
  end
  if hints > 0 then
    parts[#parts + 1] = hl("HintsHl", icons.diagnostics.Hint .. hints)
  end
  if info > 0 then
    parts[#parts + 1] = hl("InfoHl", icons.diagnostics.Info .. info)
  end

  if #parts == 0 then
    return nil
  end
  return table.concat(parts, " ")
end

local function get_filetype()
  local bufname = vim.api.nvim_buf_get_name(0)
  if has_devicons and bufname ~= "" then
    local icon, icon_hl = devicons.get_icon(vim.fn.fnamemodify(bufname, ":t"), vim.fn.fnamemodify(bufname, ":e"))
    if icon then
      return hl(icon_hl, icon)
    end
  end

  local ft = vim.bo.filetype
  if ft ~= "" then
    return hl("StBase", ft)
  end
  return nil
end

local function get_filename()
  local path = root.statusline_path(0)
  if not path then
    return nil
  end
  return hl("StBase", lualine.sanitize_statusline(path))
end

local function get_macro_reading()
  local is_rec = vim.fn.reg_recording()
  if is_rec == "" then
    if blink_timer then
      blink_timer:stop()
      blink_timer:close()
      blink_timer = nil
    end
    return ""
  end

  if not blink_timer then
    blink_timer = vim.uv.new_timer()
    blink_timer:start(
      0,
      500,
      vim.schedule_wrap(function()
        blink_icon = not blink_icon
        vim.cmd.redrawstatus()
      end)
    )
  end

  local icon = blink_icon and "" or " "
  return "%#RecordingHl#" .. icon .. "%#StBase#" .. " Rec @"
end

local function get_lsp_clients()
  local text = lualine.lsp_clients_text(LSP_CLIENT_OPTS)
  if text == "" then
    return nil
  end
  return hl("StLsp", text)
end

local function get_lsp_progress()
  local text = lualine.lsp_progress_text(LSP_PROGRESS_OPTS)
  if text == "" then
    return nil
  end
  return hl("StLsp", text)
end

local function get_breadcrumbs()
  local text = lualine.breadcrumbs_text(BREADCRUMB_OPTS)
  if text == "" then
    return nil
  end
  return text
end

function M.render()
  if DISABLED_FT[vim.bo.filetype] then
    return ""
  end

  local left = join(get_filetype(), get_filename(), "%l:%c", get_lsp_diagnostic_count(), get_breadcrumbs())

  if vim.o.laststatus ~= 3 then
    local winid = vim.g.statusline_winid
    if winid and winid ~= vim.fn.win_getid() then
      return left .. "%="
    end
  end

  return left
    .. "%#StBase#%="
    .. join(get_lsp_progress(), get_lazy_updates(), get_lsp_clients(), get_git(), get_macro_reading(), get_mode())
end

function M.setup()
  setup_highlights()

  vim.api.nvim_create_autocmd("ColorScheme", {
    group = vim.api.nvim_create_augroup("config_statusline_hl", { clear = true }),
    callback = setup_highlights,
  })

  _G.CustomStatusLine = M.render
  vim.o.statusline = "%!v:lua.CustomStatusLine()"

  vim.api.nvim_create_autocmd({ "InsertEnter", "InsertLeave", "CmdlineLeave" }, {
    group = vim.api.nvim_create_augroup("config_statusline_mode", { clear = true }),
    callback = function()
      vim.schedule(function()
        vim.cmd.redrawstatus()
      end)
    end,
  })

  vim.api.nvim_create_autocmd("User", {
    group = vim.api.nvim_create_augroup("config_statusline_user", { clear = true }),
    pattern = { "GitSignsUpdate", "LazyCheck" },
    callback = function()
      vim.cmd.redrawstatus()
    end,
  })
end

return M
