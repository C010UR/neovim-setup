--- The "finder" scope: a small, uniform registry for every search entry point.
---
--- - Files / Grep / Everywhere are backed by fff.nvim's Rust engine
---   (fuzzy matching + frecency) but rendered inside snacks.picker, so every
---   finder shares the same window, preview, actions and scoping keys.
---   Searches run off the main loop in `vim.uv` worker threads (see
---   `config.finder.fff_search`) and results carry fff's match ranges, which
---   are highlighted like fff's native picker does.
--- - Symbols / Commands / Diagnostics reuse snacks.picker built-ins.
--- - Global find & replace lives in grug-far.nvim (see plugins/editor.lua).
---
--- Entry points:
---   <leader><space>  Files
---   <leader>/        Grep (project)
---   <leader>s        Symbols (workspace, namu.nvim / LSP)
---   <leader>R        Replace in files (grug-far, project-scoped)
---   <leader>a        Commands & actions
---   <leader>xx       Diagnostics
---   <a-t> (in picker) Send results to the Trouble sidebar
---   :Finder <id>     Same finders by id (everywhere, files, grep, symbols, ...)
---
--- Uniform picker keys: <c-q> quickfix, <c-t> Trouble sidebar,
--- <C-s>/<C-v>/<C-t> splits, <a-c> toggle project root / cwd scoping.

local root = require("config.root")
local search = require("config.finder.fff_search")

local M = {}

--- Source ids exposed through snacks.picker.
local SOURCES = {
  everywhere = "fff_everywhere",
  files = "fff_files",
  grep = "fff_grep",
  symbols = "lsp_workspace_symbols",
  commands = "commands",
  diagnostics = "diagnostics",
}

--- Resolve the search root: explicit `opts.cwd`, else cwd when
--- `opts.root == false`, else the detected project root.
---@param opts? { cwd?: string, root?: boolean, buf?: number }
---@return string
function M.root(opts)
  opts = opts or {}
  if opts.cwd then
    return vim.fs.normalize(vim.fn.expand(opts.cwd)) --[[@as string]]
  end
  if opts.root == false then
    return vim.fs.normalize(vim.uv.cwd() or ".")
  end
  return root.get({ buf = opts.buf, normalize = true })
end

--- fff's canonical index root, so relative results resolve to absolute paths.
---@return string
local function fff_base_path()
  local ok, conf = pcall(require, "fff.conf")
  if ok then
    local base = conf.get().base_path
    if base and base ~= "" then
      return vim.fs.normalize(base)
    end
  end
  return vim.fs.normalize(vim.uv.cwd() or ".")
end

--- Build an absolute path from an fff relative result. fff returns
--- project-relative paths; on failure fall back to the relative path itself.
local function absolute(base, rel)
  local ok, path = pcall(vim.fs.joinpath, base, rel)
  if not ok or not path then
    return rel
  end
  local real = vim.uv.fs_realpath(path)
  return real and vim.fs.normalize(real) or path
end

--- Ensure the fff index exists at `base` and is not mid-scan. fff's own
--- `wait_for_initial_scan` is unreliable (it checks a field the Rust side
--- never fills), so we poll `get_scan_progress` directly with a bounded
--- deadline. The scan itself runs on background threads; when it's done this
--- returns immediately, and the live source re-queries on every keystroke.
---
--- Uses `vim.wait` / `vim.fn` internally, so callers must invoke it on the
--- main loop — the finders run it via `ctx.async:schedule` (snacks async
--- finder bodies resume in fast-event context, where `vim.fn` is forbidden).
---@param base string
local function ensure_fff_ready(base)
  local ok_core, core = pcall(require, "fff.core")
  if not ok_core then
    return
  end
  core.ensure_initialized()

  -- Switch the indexed root if needed (scoping).
  local conf = require("fff.conf").get()
  local current = vim.fs.normalize(conf.base_path or "")
  if base and base ~= "" and current ~= base then
    require("fff").change_indexing_directory(base)
  end

  local ok_fuzzy, fuzzy = pcall(require, "fff.fuzzy")
  if not ok_fuzzy then
    return
  end
  local deadline = vim.uv.hrtime() + 2e9 -- 2s max
  local first = true
  while true do
    local ok_prog, prog = pcall(fuzzy.get_scan_progress)
    local scanning = ok_prog and prog and prog.is_scanning
    if not scanning then
      -- Guard against the race where the initial scan hasn't been reported
      -- as started yet: re-check once after a short yield.
      if first and prog and prog.scanned_files_count == 0 then
        first = false
        vim.wait(60)
      else
        return
      end
    else
      first = false
    end
    if vim.uv.hrtime() > deadline then
      return
    end
    vim.wait(60)
  end
end

--- Convert fff's `match_ranges` (byte ranges `{start0, end0}` pairs, end
--- exclusive) into a flat list of 1-based byte indices — the shape
--- `snacks.picker.finder.Item.positions` expects for match highlighting.
---@param ranges any?
---@return number[]? positions nil when there is nothing to highlight
local function positions_from_ranges(ranges)
  if type(ranges) ~= "table" then
    return nil
  end
  local positions = {}
  for _, range in ipairs(ranges) do
    local start0, end0 = range[1], range[2]
    if type(start0) == "number" and type(end0) == "number" and end0 > start0 then
      for i = start0 + 1, end0 do
        positions[#positions + 1] = i
      end
    end
  end
  return #positions > 0 and positions or nil
end

--- `SnacksPickerMatch` extmarks for one resolved path render. Positions are
--- byte indices into the fff result's relative path (`item.text`); the
--- displayed path may differ (snacks' `truncpath` can shorten directories or
--- prefix `~/` / `⋮root/`). Mapping mirrors fff's own renderer
--- (`fff.picker_ui.file_name_renderer.fuzzy_segments`): match against the
--- full path when it's intact, otherwise only the basename (which truncpath
--- always keeps) — elided directory characters can't be mapped.
---
--- Extmarks use negative cols: `Snacks.picker.highlight.to_text` resolves
--- those relative to the end of the preceding text segments (the path), so
--- the marks don't depend on how much prefix snacks rendered before them.
---@param item snacks.picker.finder.Item
---@param resolved snacks.picker.Highlight[] resolved path segments
---@return snacks.picker.Extmark[]
local function path_match_extmarks(item, resolved)
  local positions, rel = item.fff_positions, item.text
  if not (positions and rel and rel ~= "") then
    return {}
  end
  local parts = {}
  for _, part in ipairs(resolved) do
    if type(part[1]) == "string" and #part[1] > 0 then
      parts[#parts + 1] = part[1]
    end
  end
  local displayed = table.concat(parts)
  if displayed == "" then
    return {}
  end

  local offset ---@type number displayed_idx = offset + position
  local from = displayed:find(rel, 1, true)
  if from then
    offset = from - 1
  else
    local base = vim.fs.basename(rel)
    if base == "" or #base > #displayed or displayed:sub(-#base) ~= base then
      return {}
    end
    offset = #displayed - #base + 1 - (#rel - #base + 1)
  end

  local marks = {}
  for _, p in ipairs(positions) do
    local idx = offset + p
    if idx >= 1 and idx <= #displayed then
      marks[#marks + 1] = {
        col = (idx - 1) - #displayed,
        end_col = idx - #displayed,
        hl_group = "SnacksPickerMatch",
      }
    end
  end
  return marks
end

--- snacks `file` formatter with fff query-match highlighting: wraps the path
--- segment's `resolve` callback so matched characters get extmarked on
--- whatever path (truncated or not) ends up displayed. Items without
--- `fff_positions` (buffers/recent in the everywhere source, fff results with
--- no match ranges) pass through untouched.
---@type snacks.picker.format
local function file_format(item, picker)
  local ret = Snacks.picker.format.file(item, picker)
  if not (item.fff_positions and #item.fff_positions > 0) then
    return ret
  end
  for _, seg in ipairs(ret) do
    if type(seg) == "table" and seg.resolve then
      local inner = seg.resolve
      seg.resolve = function(max_width)
        local resolved = inner(max_width)
        vim.list_extend(resolved, path_match_extmarks(item, resolved))
        return resolved
      end
      break
    end
  end
  return ret
end

--- Synchronous fallbacks (used when the worker thread can't run).
---@param params table
local function fallback_files(params)
  local ok, res = pcall(require("fff").file_search, params.query, {
    wait_for_index_ms = 0,
    max_results = params.page_size,
  })
  return ok and res or nil
end

---@param params table
local function fallback_grep(params)
  local ok, res = pcall(require("fff").content_search, params.query, {
    wait_for_index_ms = 0,
    page_size = params.page_size,
  })
  return ok and res or nil
end

--- Finder: fff file search (fuzzy + frecency ranked). The search itself runs
--- in a worker thread (see `config.finder.fff_search`); items are emitted in
--- fff's ranking order — the source sorts by `idx` to preserve it.
---@type snacks.picker.finder
local function file_finder(opts, ctx)
  return function(cb)
    -- Finder coroutines resume in fast-event context (`:h fast-event`),
    -- where `vim.fn` is off-limits — hop to the main loop for the setup.
    local base = ctx.async:schedule(function()
      local b = M.root(opts)
      ensure_fff_ready(b)
      return b
    end)
    local params = search.file_params(ctx.filter.search, { max_results = 200 })
    local res = search.search(ctx, "files", params, fallback_files)
    if not res then
      return
    end
    for _, f in ipairs(res.items or {}) do
      local rel = f.relative_path or f.name or ""
      cb({
        file = absolute(base, rel),
        text = rel,
        fff_file = f,
        fff_positions = positions_from_ranges(f.match_ranges),
      })
    end
  end
end

--- Finder: fff content search (plain/regex/fuzzy with smart case). Matched
--- characters are highlighted via `item.positions` (indices into
--- `item.line`), which the `file` formatter renders as match extmarks.
---@type snacks.picker.finder
local function grep_finder(opts, ctx)
  return function(cb)
    local query = ctx.filter.search
    if query == "" then
      return
    end
    local base = ctx.async:schedule(function()
      local b = M.root(opts)
      ensure_fff_ready(b)
      return b
    end)
    local params = search.grep_params(query, { page_size = 200 })
    local res = search.search(ctx, "grep", params, fallback_grep)
    if not res then
      return
    end
    for _, m in ipairs(res.items or {}) do
      local rel = m.relative_path or ""
      cb({
        file = absolute(base, rel),
        text = ("%s:%d:%s"):format(rel, m.line_number or 0, m.line_content or ""),
        pos = { m.line_number or 1, m.col or 0 },
        line = m.line_content,
        fff_match = m,
        positions = positions_from_ranges(m.match_ranges),
      })
    end
  end
end

--- Shared snacks source definitions. `sort = { fields = { "idx" } }` keeps
--- fff's ranking instead of re-ranking through the snacks matcher.
---@return table<string, snacks.picker.Config>
function M.sources()
  return {
    fff_files = {
      title = " Find Files",
      live = true,
      supports_live = true,
      finder = file_finder,
      format = file_format,
      sort = { fields = { "idx" } },
      show_empty = true,
    },
    fff_grep = {
      title = " Grep",
      live = true,
      supports_live = true,
      finder = grep_finder,
      format = "file",
      sort = { fields = { "idx" } },
    },
    fff_everywhere = {
      title = " Search Everywhere",
      multi = { "fff_files", "buffers", "recent" },
      format = file_format,
      matcher = {
        cwd_bonus = true,
        frecency = true,
        sort_empty = true,
      },
      transform = "unique_file",
    },
  }
end

--- Open a finder by id (see `SOURCES`), with uniform scoping.
---@param id string
---@param opts? { cwd?: string, root?: boolean, buf?: number, search?: string }
function M.open(id, opts)
  opts = vim.deepcopy(opts or {})
  local source = SOURCES[id] or id

  -- fff-backed finders get the resolved root passed down explicitly.
  if source == SOURCES.files or source == SOURCES.grep then
    opts.cwd = M.root(opts)
  end
  return Snacks.picker.pick(source, opts)
end

--- Same as `open` but as a callable for keymaps.
---@param id string
---@param opts? { cwd?: string, root?: boolean, buf?: number, search?: string }
function M.wrap(id, opts)
  return function()
    M.open(id, opts)
  end
end

--- Open grug-far scoped to the project root; in visual mode the selection
--- prefills the search.
---@param opts? { cwd?: string, root?: boolean }
function M.replace(opts)
  opts = opts or {}
  local grug = require("grug-far")
  local visual = vim.fn.mode():lower():find("v")
  if visual then
    vim.cmd([[normal! v]])
  end

  local base = M.root(opts)
  local prefills = {}
  -- Only pin the scope when it differs from grug-far's cwd default.
  if base ~= vim.fs.normalize(vim.uv.cwd() or ".") then
    prefills.paths = base
  end
  local open = visual and grug.with_visual_selection or grug.open
  open(vim.tbl_extend("force", opts, {
    transient = true,
    prefills = prefills,
  }))
end

--- `:Finder <id>` command + completion.
function M.setup()
  vim.api.nvim_create_user_command("Finder", function(o)
    local id = o.args ~= "" and o.args or "everywhere"
    local ok, err = pcall(M.open, id)
    if not ok then
      vim.notify(("Finder %q: %s"):format(id, err), vim.log.levels.ERROR, { title = "Finder" })
    end
  end, {
    nargs = "?",
    desc = "Open a finder",
    complete = function()
      return vim.tbl_keys(SOURCES)
    end,
  })
end

return M
