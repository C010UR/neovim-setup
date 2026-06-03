require("config.scaffold.types")

local psr4 = require("config.scaffold.php.psr4")
local php_rename = require("config.scaffold.php.rename")
local sync = require("config.scaffold.php.sync")

---@class ConfigScaffoldPhp
local M = {}

M.namespace_for = psr4.namespace_for
M.project_root = psr4.project_root
M.apply_expected_to_lines = sync.apply_expected_to_lines
M.sync_path = sync.sync_path
M.symbol_at_cursor = php_rename.symbol_at_cursor
M.kind_from_stem = sync.kind_from_stem

--- LSP client priority for workspace rename operations (caller-driven).
--- Clients earlier in this list are tried first.
M.lsp_client_priority = { "phpactor" }

---@param ctx ScaffoldContext
---@return ScaffoldResult
function M.build(ctx)
  local namespace = psr4.namespace_for(ctx.path, psr4.project_root(ctx.path))
  local kind, name = sync.kind_from_stem(ctx.stem)

  local lines = {
    "<?php",
    "",
    "declare(strict_types=1);",
    "",
  }

  if namespace ~= "" then
    lines[#lines + 1] = ("namespace %s;"):format(namespace)
    lines[#lines + 1] = ""
  end

  local prefix = kind:gsub("_", " ")
  lines[#lines + 1] = ("%s %s"):format(prefix, name)
  lines[#lines + 1] = "{"
  lines[#lines + 1] = ""
  lines[#lines + 1] = "}"

  return {
    lines = lines,
    cursor = { line = #lines - 1, col = 0 },
  }
end

---@param buf integer
---@return boolean
function M.should_scaffold(buf)
  local path = vim.api.nvim_buf_get_name(buf)
  if path == "" then
    return false
  end
  path = vim.fs.normalize(path)
  return path:match("%.php$") ~= nil and not sync.is_vendor_path(path)
end

function M.register()
  require("config.scaffold.registry").register("php", {
    filetypes = { "php" },
    extensions = { "php" },
    should_scaffold = M.should_scaffold,
    build = M.build,
    lsp_client_priority = M.lsp_client_priority,
    rename = {
      symbol_at_cursor = php_rename.symbol_at_cursor,
      should_rename_file = php_rename.should_rename_file,
      new_path = php_rename.new_path,
    },
    file_move = {
      should_handle = sync.should_handle_relocate,
      expected = sync.file_move_expected,
      sync_buffer = sync.sync_buffer,
    },
  })

  psr4.setup_cache_autocmd()
end

return M
