--- Off-main-loop fff.nvim search workers.
---
--- fff's search API is a blocking FFI call: the Rust side fans out to its own
--- worker threads, but the calling Lua thread waits for the full result.
--- Running that on the main loop per keystroke stutters the UI — grep alone
--- can block for its whole `grep.time_budget_ms` (150ms by default).
---
--- `M.search` runs the call inside a `vim.uv.new_thread` worker instead:
---
--- - The thread loads `libfff_nvim` directly via `package.loadlib`. Safe to
---   re-open from a second Lua state: `luaopen_fff_nvim` only registers
---   exports, and every piece of shared Rust state (file picker, frecency,
---   query tracker) lives behind `RwLock`/`OnceLock` statics.
--- - The thread runs one search and ships the result back as JSON through a
---   `vim.uv.new_async` handle (search results are plain data).
--- - The calling snacks finder coroutine suspends on `ctx.async:sleep` while
---   the worker runs, so the main loop stays responsive. When snacks aborts
---   the finder (new keystroke), the sleep raises "aborted" and the coroutine
---   unwinds; the late worker result lands in a dead closure and is ignored.
---
--- If the library can't be located or the worker fails, `M.search` falls back
--- to `fallback(params)` — the classic synchronous call — and warns once.
---
--- NOTE: the worker calls `fuzzy_search_files` / `live_grep` with positional
--- args pinned to the fff.nvim rev in nvim-pack-lock.json. Re-check the
--- signatures in `crates/fff-nvim/src/lib.rs` after upgrading fff.

local uv = vim.uv

local M = {}

--- How long to wait for a worker before giving up (the searches themselves
--- are bounded by fff's grep time budget; 5s covers pathological cases).
local WORKER_TIMEOUT_NS = 5e9

---@type string?
local lib_path
local lib_checked = false

--- Locate the fff Rust library the same way `fff.rust` does (plugin
--- `target/release`, honoring `CARGO_TARGET_DIR`), cached. Only fast-event
--- safe calls (Lua + `vim.uv` + `vim.api`): this runs from inside snacks
--- async finder coroutines, where `vim.fn`/`vim.env` are forbidden.
---@return string?
local function resolve_lib_path()
  if lib_checked then
    return lib_path
  end
  lib_checked = true

  local ext = ({ mac = "dylib", windows = "dll" })[jit.os:lower()] or "so"
  local candidates = {}

  local ok, files = pcall(vim.api.nvim_get_runtime_file, "lua/fff/download.lua", false)
  if ok and files and files[1] then
    -- download.lua resolves its own plugin root as `<root>/lua` and appends
    -- `/../target/release`, i.e. the repo's target dir.
    local plugin_root = files[1]:match("^(.*)/lua/fff/download%.lua$") or vim.fs.dirname(vim.fs.dirname(files[1]))
    candidates[#candidates + 1] =
      vim.fs.normalize(vim.fs.joinpath(plugin_root, "target", "release", ("libfff_nvim.%s"):format(ext)))
  end

  local cargo_target_dir = uv.os_getenv("CARGO_TARGET_DIR")
  if cargo_target_dir and cargo_target_dir ~= "" then
    candidates[#candidates + 1] =
      vim.fs.normalize(vim.fs.joinpath(vim.fs.normalize(cargo_target_dir), "release", ("libfff_nvim.%s"):format(ext)))
  end

  for _, path in ipairs(candidates) do
    local stat = uv.fs_stat(path)
    if stat and stat.type == "file" then
      lib_path = path
      break
    end
  end
  return lib_path
end

local warned = false

local function warn_once(msg)
  if warned then
    return
  end
  warned = true
  vim.notify(
    ("Finder: fff search worker failed (%s), using synchronous search."):format(msg),
    vim.log.levels.WARN,
    { title = "Finder" }
  )
end

--- Worker entry. Runs in the thread's own Lua state, which provides
--- `vim.json`, `package` and its own `vim.uv` loop (see `:h lua-loop-threads`).
--- Everything it needs is passed in as arguments: luv dumps the entry
--- function's bytecode without preserving upvalues. Sends the result as JSON
--- via `cb:send(...)` exactly once.
---@param cb uv.uv_async_t
---@param lib string path to libfff_nvim
---@param kind string "files" | "grep"
---@param params_json string
local function worker_entry(cb, lib, kind, params_json)
  local params = vim.json.decode(params_json) or {}

  ---@param res any
  local function reply(res)
    pcall(function()
      cb:send(vim.json.encode(res or {}))
    end)
  end

  local ok, loader = pcall(package.loadlib, lib, "luaopen_fff_nvim")
  if not ok or type(loader) ~= "function" then
    return reply({ error = "loadlib failed: " .. tostring(loader) })
  end
  local ok_open, ffn = pcall(loader)
  if not ok_open or type(ffn) ~= "table" then
    return reply({ error = "luaopen_fff_nvim failed: " .. tostring(ffn) })
  end

  if kind == "files" then
    local ok_search, res = pcall(
      ffn.fuzzy_search_files,
      params.query,
      params.max_threads,
      params.current_file,
      params.combo_boost,
      params.min_combo,
      params.page,
      params.page_size
    )
    if ok_search then
      return reply(res)
    end
    return reply({ error = "fuzzy_search_files: " .. tostring(res) })
  elseif kind == "grep" then
    local ok_search, res = pcall(
      ffn.live_grep,
      params.query,
      params.file_offset,
      params.page_size,
      params.max_file_size,
      params.max_matches_per_file,
      params.smart_case,
      params.mode,
      params.time_budget_ms,
      params.trim_whitespace
    )
    if ok_search then
      return reply(res)
    end
    return reply({ error = "live_grep: " .. tostring(res) })
  end

  return reply({ error = ("unknown search kind %q"):format(tostring(kind)) })
end

--- File search params, mirroring `fff.file_search`'s own config merging
--- (`lua/fff/main.lua`) so the worker can call the FFI function directly.
---@param query string
---@param opts? { max_results?: integer, max_threads?: integer, current_file?: string }
---@return table
function M.file_params(query, opts)
  opts = opts or {}
  local ok, conf = pcall(require, "fff.conf")
  local config = ok and conf.get() or {}
  local history = config.history or {}
  return {
    query = query,
    max_threads = opts.max_threads or config.max_threads or 4,
    current_file = opts.current_file,
    combo_boost = history.combo_boost_score_multiplier or 100,
    min_combo = history.min_combo_count or 3,
    page = 0,
    page_size = opts.max_results or config.max_results or 100,
  }
end

--- Grep search params, mirroring `fff.content_search`'s config merging
--- (`lua/fff/main.lua` + `fff.picker_ui.grep_renderer.search`).
---@param query string
---@param opts? { page_size?: integer, mode?: string }
---@return table
function M.grep_params(query, opts)
  opts = opts or {}
  local ok, conf = pcall(require, "fff.conf")
  local grep = (ok and conf.get() or {}).grep or {}
  return {
    query = query,
    file_offset = 0,
    page_size = opts.page_size or 50,
    max_file_size = grep.max_file_size,
    max_matches_per_file = grep.max_matches_per_file,
    smart_case = grep.smart_case == nil and true or grep.smart_case,
    mode = opts.mode or "plain",
    time_budget_ms = grep.time_budget_ms,
    trim_whitespace = grep.trim_whitespace == nil and true or grep.trim_whitespace,
  }
end

--- Run one fff search off the main loop. Must be called from inside a snacks
--- async finder (i.e. from the function the finder returns), where
--- `ctx.async:sleep` suspends the finder coroutine instead of blocking.
---@param ctx snacks.picker.finder.ctx
---@param kind string "files" | "grep"
---@param params table from `M.file_params` / `M.grep_params`
---@param fallback fun(params: table): table? synchronous fallback
---@return table? result fff search result, or nil on failure/abort
function M.search(ctx, kind, params, fallback)
  local lib = resolve_lib_path()
  if not lib then
    warn_once("libfff_nvim not found")
    return fallback(params)
  end

  local ok_json, params_json = pcall(vim.json.encode, params)
  if not ok_json then
    warn_once("params not serializable")
    return fallback(params)
  end

  local result ---@type table?
  local done = false
  local send = uv.new_async(function(encoded)
    local ok_decode, decoded = pcall(vim.json.decode, encoded)
    result = ok_decode and decoded or nil
    done = true
    pcall(function()
      send:close()
    end)
  end)

  local ok_thread, thread = pcall(uv.new_thread, worker_entry, send, lib, kind, params_json)
  if not ok_thread or not thread then
    warn_once("could not spawn worker thread")
    return fallback(params)
  end

  local deadline = uv.hrtime() + WORKER_TIMEOUT_NS
  while not done do
    if uv.hrtime() > deadline then
      warn_once("worker timed out")
      return nil
    end
    ctx.async:sleep(2)
  end
  if type(result) == "table" and result.error then
    warn_once(tostring(result.error))
    return fallback(params)
  end
  return result
end

return M
