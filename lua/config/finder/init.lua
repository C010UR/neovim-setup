--- The "finder" scope: a small, uniform registry for every search entry point.
---
--- - Files / Grep / Everywhere are backed by fff.nvim's Rust engine
---   (fuzzy matching + frecency) but rendered inside snacks.picker, so every
---   finder shares the same window, preview, actions and scoping keys.
--- - Symbols / Commands / Diagnostics reuse snacks.picker built-ins.
--- - Global find & replace lives in grug-far.nvim (see plugins/editor.lua).
---
--- Entry points:
---   <leader><space>  Grep (project)
---   <leader>/        Files
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

--- Finder: fff file search (fuzzy + frecency ranked). Returned in fff's own
--- ranking order; the source sorts by `idx` to preserve it.
---@type snacks.picker.finder
local function file_finder(opts, ctx)
  local base = M.root(opts)
  ensure_fff_ready(base)
  local ok, res = pcall(require("fff").file_search, ctx.filter.search, {
    wait_for_index_ms = 0,
    max_results = 200,
  })
  if not ok or not res then
    return {}
  end
  local items = {}
  for _, f in ipairs(res.items or {}) do
    local rel = f.relative_path or f.name or ""
    items[#items + 1] = {
      file = absolute(base, rel),
      text = rel,
      fff_file = f,
    }
  end
  return items
end

--- Finder: fff content search (plain/regex/fuzzy with smart case).
---@type snacks.picker.finder
local function grep_finder(opts, ctx)
  local query = ctx.filter.search
  if query == "" then
    return {}
  end
  local base = M.root(opts)
  ensure_fff_ready(base)
  local ok, res = pcall(require("fff").content_search, query, {
    wait_for_index_ms = 0,
    page_size = 200,
  })
  if not ok or not res then
    return {}
  end
  local items = {}
  for _, m in ipairs(res.items or {}) do
    local rel = m.relative_path or ""
    items[#items + 1] = {
      file = absolute(base, rel),
      text = ("%s:%d:%s"):format(rel, m.line_number or 0, m.line_content or ""),
      pos = { m.line_number or 1, m.col or 0 },
      line = m.line_content,
      fff_match = m,
    }
  end
  return items
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
      format = "file",
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
      format = "file",
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
