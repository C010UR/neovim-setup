--- Per-mode keymap cheatsheet.
---
--- One read-only scratch buffer per mode (plus a dedicated motions/text-object
--- page), rendered in an NVChad-style grid. The config's own global keymaps are
--- merged in at runtime (see `config.cheatsheet.collect`); curated tables cover
--- stock Neovim defaults and keymaps that are not globally visible.
---
---   :Cheatsheet [sheet]   open a sheet (a mode, motions, or a special context
---                         like pickers / explorer / lsp / trouble / debug)
---   <leader>k             Normal sheet
---   <leader>km            Motions sheet
---   q / <Esc>             close every sheet
---   <Tab> / <S-Tab>       next / previous mode sheet
---   ] / [                 next / previous special-context sheet
---   1-9                   jump within the current sheet group
local collect = require("config.cheatsheet.collect")
local context_tables = require("config.cheatsheet.tables.contexts")
local glyphs = require("config.cheatsheet.glyphs")
local render = require("config.cheatsheet.render")

local M = {}

local SHEETS = {
  {
    id = "n",
    title = "Normal Mode",
    subtitle = "Move around and run commands. Press i to start typing, " .. glyphs.esc .. " to come back.",
    modes = { "n" },
  },
  {
    id = "i",
    title = "Insert Mode",
    subtitle = "Typing here writes text into the file. Press " .. glyphs.esc .. " to return to Normal mode.",
    modes = { "i" },
  },
  {
    id = "v",
    title = "Visual Mode",
    subtitle = "Select text first, then act on it. Start with v, V or " .. glyphs.ctrl .. "v.",
    modes = { "x", "v", "s" },
  },
  {
    id = "o",
    title = "Operator-pending Mode",
    subtitle = "The pause after d, c or y while Neovim waits for a motion or text object.",
    modes = { "o" },
  },
  {
    id = "c",
    title = "Command-line Mode",
    subtitle = "The : and / prompt at the bottom of the screen.",
    modes = { "c" },
  },
  {
    id = "t",
    title = "Terminal Mode",
    subtitle = "Your keys go to the running program. "
      .. glyphs.ctrl
      .. "\\ then "
      .. glyphs.ctrl
      .. "n returns to Neovim.",
    modes = { "t" },
  },
  {
    id = "motions",
    title = "Motions & Text Objects",
    subtitle = "Motions move the cursor. Combine with d, c or y: d + w deletes a word.",
    modes = nil,
  },

  -- Special buffers and transient contexts. These are curated because the keys
  -- live in plugin windows that only exist while that UI is open.
  {
    id = "pickers",
    kind = "context",
    title = "Pickers (Snacks & fff)",
    subtitle = "Fuzzy finders for files, text and actions. Opened from the leader key menu.",
  },
  {
    id = "explorer",
    kind = "context",
    title = "File Explorer",
    subtitle = "The file tree. Open it with " .. glyphs.space .. " then e.",
  },
  {
    id = "lsp",
    kind = "context",
    title = "LSP & Code Actions",
    subtitle = "Code intelligence from language servers. Available once a server attaches.",
  },
  {
    id = "trouble",
    kind = "context",
    title = "Diagnostics & Trouble",
    subtitle = "The results sidebar. Toggle with " .. glyphs.space .. " then xq (or xl).",
  },
  {
    id = "debug",
    kind = "context",
    title = "Debugger (DAP)",
    subtitle = "The debugger. Start a session with " .. glyphs.space .. " then dc.",
  },
}

local ALIASES = {
  n = "n",
  normal = "n",
  i = "i",
  insert = "i",
  v = "v",
  x = "v",
  visual = "v",
  o = "o",
  op = "o",
  operator = "o",
  c = "c",
  cmd = "c",
  command = "c",
  t = "t",
  term = "t",
  terminal = "t",
  m = "motions",
  motion = "motions",
  motions = "motions",
  pick = "pickers",
  picker = "pickers",
  pickers = "pickers",
  fff = "pickers",
  finder = "pickers",
  explorer = "explorer",
  tree = "explorer",
  files = "explorer",
  lsp = "lsp",
  code = "lsp",
  diagnostics = "trouble",
  diag = "trouble",
  trouble = "trouble",
  debug = "debug",
  dap = "debug",
}

local LEGEND = {
  glyphs.ctrl
    .. " = Ctrl    "
    .. glyphs.shift
    .. " = Shift    "
    .. glyphs.alt
    .. " = Alt    "
    .. glyphs.space
    .. " = leader key (Space)    "
    .. glyphs.tab
    .. " = Tab",
  "{count} = a number you choose, e.g. 3dd deletes three lines",
  "[m] = waits for a motion or text object, e.g. d then w deletes a word",
  "q close    " .. glyphs.tab .. " next mode    ] / [ next special sheet    1-9 jump",
}

-- Window options we temporarily override so the grid is not distorted by the
-- user's global list/number settings. Values are saved and restored per window.
local WIN_OPTS = { "list", "number", "relativenumber", "cursorline", "wrap", "signcolumn", "foldcolumn", "spell" }

local bufs = {}
local origin_buf = nil

local function is_cheatsheet(buf)
  return buf ~= nil and vim.api.nvim_buf_is_valid(buf) and vim.b[buf].config_cheatsheet_id ~= nil
end

local function sheet_by_id(id)
  for _, sheet in ipairs(SHEETS) do
    if sheet.id == id then
      return sheet
    end
  end
end

local function sheet_index(id)
  for index, sheet in ipairs(SHEETS) do
    if sheet.id == id then
      return index
    end
  end
end

--- Sheets are split into two rings: `mode` sheets (Tab / <S-Tab>) and special
--- `context` sheets (] / [). Number keys jump within the current ring.
local function ring_sheets(kind)
  local list = {}
  for _, sheet in ipairs(SHEETS) do
    if (sheet.kind or "mode") == kind then
      list[#list + 1] = sheet
    end
  end
  return list
end

--- Data files use positional `{ "<key>", "<desc>", motion = true }` rows for
--- terseness; the renderer and collector want `{ key, desc, motion }`.
local function append_sections(doc, sections)
  for _, section in ipairs(sections or {}) do
    local entries = {}
    for _, entry in ipairs(section.entries or {}) do
      entries[#entries + 1] = {
        key = entry.key or entry[1],
        desc = entry.desc or entry[2],
        motion = entry.motion,
      }
    end
    doc.sections[#doc.sections + 1] = { name = section.name, entries = entries, fixed = section.fixed }
  end
end

local function build_doc(id)
  local sheet = sheet_by_id(id)
  local doc = { id = id, title = sheet.title, subtitle = sheet.subtitle, legend = LEGEND, sections = {} }

  local base
  if id == "motions" then
    base = require("config.cheatsheet.tables.motions")
  elseif context_tables[id] then
    base = context_tables[id]
  else
    base = require("config.cheatsheet.tables.defaults")[id] or {}
  end
  append_sections(doc, base)
  if not context_tables[id] then
    append_sections(doc, require("config.cheatsheet.tables.extras")[id])
  end

  if sheet.modes then
    local live = collect.gather(sheet.modes)
    collect.overlay(doc.sections, live)
    vim.list_extend(doc.sections, collect.remaining_sections(live))
  end

  return doc
end

local function render_buffer(buf, id, win)
  local doc = build_doc(id)
  local width = vim.api.nvim_win_get_width(win or 0)
  render.render(buf, doc, width)
end

local function apply_win_opts(buf)
  local win = vim.api.nvim_get_current_win()
  if is_cheatsheet(buf) then
    local saved = vim.w[win].config_cheatsheet_saved
    if not saved then
      saved = {}
      for _, name in ipairs(WIN_OPTS) do
        saved[name] = vim.wo[win][name]
      end
      vim.w[win].config_cheatsheet_saved = saved
    end
    vim.wo[win].list = false
    vim.wo[win].number = false
    vim.wo[win].relativenumber = false
    vim.wo[win].cursorline = false
    vim.wo[win].wrap = false
    vim.wo[win].signcolumn = "no"
    vim.wo[win].foldcolumn = "0"
    vim.wo[win].spell = false
    return
  end

  local saved = vim.w[win].config_cheatsheet_saved
  if saved then
    for _, name in ipairs(WIN_OPTS) do
      vim.wo[win][name] = saved[name]
    end
    vim.w[win].config_cheatsheet_saved = nil
  end
end

local function setup_buffer(buf, sheet)
  local function bmap(lhs, rhs, desc)
    vim.keymap.set("n", lhs, rhs, { buffer = buf, silent = true, nowait = true, desc = "Cheatsheet: " .. desc })
  end
  bmap("q", function()
    M.close()
  end, "Close")
  bmap("<Esc>", function()
    M.close()
  end, "Close")
  bmap("<Tab>", function()
    M.cycle("mode", 1)
  end, "Next Mode Sheet")
  bmap("<S-Tab>", function()
    M.cycle("mode", -1)
  end, "Previous Mode Sheet")
  bmap("]", function()
    M.cycle("context", 1)
  end, "Next Special Sheet")
  bmap("[", function()
    M.cycle("context", -1)
  end, "Previous Special Sheet")

  -- 1-9 jump within the ring this sheet belongs to.
  local ring = ring_sheets(sheet.kind or "mode")
  for index, item in ipairs(ring) do
    if index > 9 then
      break
    end
    bmap(tostring(index), function()
      M.open(item.id)
    end, item.title)
  end
end

--- Resolve a user supplied sheet name to a sheet id.
function M.resolve(name)
  if not name or name == "" then
    return "n"
  end
  return ALIASES[name:lower()] or (sheet_by_id(name) and name or nil)
end

--- Open (or focus) the sheet named `name` in the current window.
function M.open(name)
  local id = M.resolve(name)
  if not id then
    vim.notify("Cheatsheet: unknown sheet '" .. tostring(name) .. "'", vim.log.levels.WARN, { title = "Cheatsheet" })
    return
  end

  local win = vim.api.nvim_get_current_win()
  local current = vim.api.nvim_win_get_buf(win)
  if not is_cheatsheet(current) then
    origin_buf = current
  end

  local buf = bufs[id]
  if not (buf and vim.api.nvim_buf_is_valid(buf)) then
    buf = vim.api.nvim_create_buf(false, true)
    bufs[id] = buf
    vim.bo[buf].buftype = "nofile"
    vim.bo[buf].bufhidden = "hide"
    vim.bo[buf].swapfile = false
    vim.bo[buf].buflisted = false
    vim.bo[buf].modifiable = true
    vim.bo[buf].filetype = "cheatsheet"
    pcall(vim.api.nvim_buf_set_name, buf, "cheatsheet://" .. id)
    vim.b[buf].config_cheatsheet_id = id
    setup_buffer(buf, sheet_by_id(id))
  end

  vim.api.nvim_win_set_buf(win, buf)
  render_buffer(buf, id, win)
  apply_win_opts(buf)
end

--- Cycle through one ring of sheets by `dir` (+1 / -1).
--- `ring` is "mode" or "context"; see `ring_sheets`.
function M.cycle(ring, dir)
  dir = dir or 1
  local list = ring_sheets(ring)
  if #list == 0 then
    return
  end
  local buf = vim.api.nvim_get_current_buf()
  local id = vim.b[buf].config_cheatsheet_id
  local index
  for i, sheet in ipairs(list) do
    if sheet.id == id then
      index = i
      break
    end
  end
  -- Not on this ring: entering forward starts at the first sheet, backwards at
  -- the last.
  if not index then
    index = dir > 0 and 0 or 1
  end
  M.open(list[((index - 1 + dir) % #list) + 1].id)
end

--- Wipe every sheet buffer and return to where the cheatsheet was opened from.
function M.close()
  local win = vim.api.nvim_get_current_win()
  local target = origin_buf

  for id, buf in pairs(bufs) do
    if vim.api.nvim_buf_is_valid(buf) then
      pcall(vim.api.nvim_buf_delete, buf, { force = true })
    end
    bufs[id] = nil
  end
  origin_buf = nil

  local current = vim.api.nvim_win_get_buf(win)
  if is_cheatsheet(current) or not vim.api.nvim_buf_is_valid(current) then
    if target and vim.api.nvim_buf_is_valid(target) then
      vim.api.nvim_win_set_buf(win, target)
    else
      vim.cmd("enew")
    end
  end
end

function M.setup()
  if M._did_setup then
    return
  end
  M._did_setup = true

  render.setup_highlights()

  vim.api.nvim_create_user_command("Cheatsheet", function(opts)
    M.open(opts.args)
  end, {
    nargs = "?",
    desc = "Open the keymap cheatsheet",
    complete = function(arg)
      local names = {
        "normal",
        "insert",
        "visual",
        "operator",
        "command",
        "terminal",
        "motions",
        "pickers",
        "explorer",
        "lsp",
        "trouble",
        "debug",
      }
      for _, sheet in ipairs(SHEETS) do
        names[#names + 1] = sheet.id
      end
      return vim.tbl_filter(function(name)
        return name:sub(1, #arg) == arg
      end, names)
    end,
  })

  vim.keymap.set("n", "<leader>k", function()
    M.open("n")
  end, { desc = "Cheatsheet" })
  vim.keymap.set("n", "<leader>km", function()
    M.open("motions")
  end, { desc = "Motions Cheatsheet" })

  local group = vim.api.nvim_create_augroup("config_cheatsheet", { clear = true })
  vim.api.nvim_create_autocmd("BufWinEnter", {
    group = group,
    callback = function(event)
      apply_win_opts(event.buf)
    end,
  })
  vim.api.nvim_create_autocmd("VimResized", {
    group = group,
    callback = function()
      local win = vim.api.nvim_get_current_win()
      local buf = vim.api.nvim_win_get_buf(win)
      local id = vim.b[buf].config_cheatsheet_id
      if id then
        render_buffer(buf, id, win)
      end
    end,
  })
end

return M
