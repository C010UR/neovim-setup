require("config.scaffold.types")

local buffer = require("config.scaffold.buffer")
local registry = require("config.scaffold.registry")
local relocate = require("config.scaffold.relocate")
local symbol_rename = require("config.scaffold.symbol_rename")

---@class ConfigScaffold : ConfigScaffoldRegistry, ConfigScaffoldRelocate
---@field maybe_scaffold fun(buf: integer)
---@field rename_file fun(opts?: table): boolean|nil
local M = vim.tbl_extend("force", {}, registry, relocate)

M.maybe_scaffold = buffer.maybe_scaffold

---@param buf integer
function M.rename_symbol(buf)
  symbol_rename.rename_symbol(buf, M.rename_file)
end

local _did_setup = false

function M.setup()
  if _did_setup then
    return
  end
  _did_setup = true

  vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
    group = vim.api.nvim_create_augroup("config_scaffold_buffer", { clear = true }),
    callback = function(ev)
      vim.schedule(function()
        if vim.api.nvim_buf_is_valid(ev.buf) then
          M.maybe_scaffold(ev.buf)
        end
      end)
    end,
  })

  symbol_rename.setup(M.rename_file)
end

return M
