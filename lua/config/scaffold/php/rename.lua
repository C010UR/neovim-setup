---@class ConfigScaffoldPhpRename
local M = {}

local TS_QUERY = [[
  (class_declaration name: (name) @name)
  (interface_declaration name: (name) @name)
  (enum_declaration name: (name) @name)
  (trait_declaration name: (name) @name)
]]

local function win_for_buf(buf)
  local win = vim.fn.bufwinid(buf)
  if win ~= -1 then
    return win
  end
  return vim.api.nvim_get_current_win()
end

---@param buf integer
---@return string|nil
local function symbol_on_line(buf, row)
  local line = vim.api.nvim_buf_get_lines(buf, row, row + 1, false)[1] or ""
  return line:match("^(?:abstract%s+)?(?:final%s+)?class%s+(%w+)")
    or line:match("^interface%s+(%w+)")
    or line:match("^enum%s+(%w+)")
    or line:match("^trait%s+(%w+)")
end

---@param buf integer
---@return string|nil
function M.symbol_at_cursor(buf)
  local win = win_for_buf(buf)
  local row = vim.api.nvim_win_get_cursor(win)[1] - 1
  local col = vim.api.nvim_win_get_cursor(win)[2]

  if vim.treesitter then
    local ok, parser = pcall(vim.treesitter.get_parser, buf, "php")
    if ok and parser then
      local tree = parser:parse()[1]
      if tree then
        local query = vim.treesitter.query.parse("php", TS_QUERY)
        local fallback = nil
        for id, node in query:iter_captures(tree:root(), buf, row, row + 1) do
          if query.captures[id] == "name" then
            local start_row, start_col, end_row, end_col = node:range()
            if row >= start_row and row <= end_row and col >= start_col and col <= end_col then
              return vim.treesitter.get_node_text(node, buf)
            end
            fallback = vim.treesitter.get_node_text(node, buf)
          end
        end
        if fallback then
          return fallback
        end
      end
    end
  end

  return symbol_on_line(buf, row)
end

---@param ctx ScaffoldRenameContext
---@return boolean
function M.should_rename_file(ctx)
  if not ctx.old_symbol or ctx.old_symbol == "" then
    return false
  end
  return ctx.old_stem == ctx.old_symbol and ctx.new_symbol ~= ctx.old_stem
end

---@param ctx ScaffoldRenameContext
---@return string
function M.new_path(ctx)
  return vim.fs.normalize(vim.fs.joinpath(vim.fs.dirname(ctx.path), ctx.new_symbol .. ".php"))
end

return M
