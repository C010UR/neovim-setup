--- The "finder" scope: a small, uniform registry for every search entry point.
---
--- - Files / Grep open fff.nvim's native picker (Rust engine: fuzzy + frecency,
---   live grep, preview, git signs, quickfix). fff owns its own window, so
---   there is no snacks bridge here anymore.
--- - Symbols / Commands / Diagnostics reuse snacks.picker built-ins.
--- - Global find & replace lives in grug-far.nvim (see plugins/editor.lua).
---
--- Entry points:
---   <leader><space>  Files (fff)
---   <leader>/        Grep (fff, project; visual mode greps the selection)
---   <leader>s        Symbols (workspace, namu.nvim / LSP)
---   <leader>R        Replace in files (grug-far, project-scoped)
---   <leader>a        Commands & actions (snacks)
---   <leader>xx       Diagnostics (snacks)
---   :Finder <id>     Same finders by id (files, grep, symbols, commands, diagnostics)

local root = require("config.root")

local M = {}

--- Source ids exposed through `:Finder`. `files` / `grep` are handled by
--- `M.open` directly (native fff); the rest map to snacks.picker sources.
local SOURCES = {
  files = "fff",
  grep = "fff",
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

--- Open a finder by id (see `SOURCES`).
---@param id string
---@param opts? { cwd?: string, root?: boolean, buf?: number, search?: string }
function M.open(id, opts)
  opts = vim.deepcopy(opts or {})

  if id == "files" then
    return require("fff").find_files({ cwd = M.root(opts), query = opts.search })
  end
  if id == "grep" then
    return require("fff").live_grep({ cwd = M.root(opts), query = opts.search })
  end

  local source = SOURCES[id] or id
  return Snacks.picker.pick(source, opts)
end

--- Grep the visual selection with fff's native picker, scoped to the project
--- root. `live_grep_under_cursor` resolves the selection without clobbering
--- registers and falls back to `<cword>` in normal mode.
---@param opts? { cwd?: string, root?: boolean, buf?: number }
function M.grep_visual(opts)
  opts = vim.deepcopy(opts or {})
  return require("fff").live_grep_under_cursor({ cwd = M.root(opts) })
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
    local id = o.args ~= "" and o.args or "files"
    local ok, err = pcall(M.open, id)
    if not ok then
      vim.notify(("Finder %q: %s"):format(id, err), vim.log.levels.ERROR, { title = "Finder" })
    end
  end, {
    nargs = "?",
    desc = "Open a finder",
    complete = function()
      local ids = vim.tbl_keys(SOURCES)
      table.sort(ids)
      return ids
    end,
  })
end

return M
