local psr4 = require("config.scaffold.php.psr4")

---@class ConfigScaffoldPhpSync
local M = {}

local KIND_KEYWORDS =
  { class = "class", interface = "interface", enum = "enum", trait = "trait", abstract_class = "class" }

---@param stem string
---@return string kind, string name
function M.kind_from_stem(stem)
  if stem:match("Interface$") then
    return "interface", stem
  end
  if stem:match("Trait$") then
    return "trait", stem
  end
  if stem:match("Enum$") then
    return "enum", stem
  end
  if stem:match("^Abstract") then
    return "abstract_class", stem
  end
  return "class", stem
end

---@param path string
---@return boolean
function M.is_vendor_path(path)
  return path:find("/vendor/", 1, true) ~= nil or path:find("\\vendor\\", 1, true) ~= nil
end

---@param ctx ScaffoldFileMoveContext
---@return boolean
function M.should_handle_relocate(ctx)
  return ctx.to:match("%.php$") ~= nil and not M.is_vendor_path(ctx.to)
end

---@param ctx ScaffoldFileMoveContext
---@return ScaffoldFileMoveExpected|nil
function M.file_move_expected(ctx)
  local kind, symbol = M.kind_from_stem(ctx.new_stem)
  return {
    namespace = psr4.namespace_for(ctx.to, psr4.project_root(ctx.to)),
    symbol = symbol,
    kind = kind,
  }
end

---@param line string
---@param expected ScaffoldFileMoveExpected
---@return string|nil
local function replace_declaration_line(line, expected)
  if line:match("^%s*//") or line:match("^%s*#") or line:match("/%*") or line:match("%*/") then
    return nil
  end

  local indent = line:match("^(%s*)") or ""
  local tokens = {}
  for token in line:gmatch("%S+") do
    tokens[#tokens + 1] = token
  end

  local kind_idx = nil
  for i, token in ipairs(tokens) do
    if KIND_KEYWORDS[token] then
      kind_idx = i
      break
    end
  end

  if not kind_idx then
    return nil
  end

  local name_idx = kind_idx + 1
  if not tokens[name_idx] then
    return nil
  end

  local name, trailing = tokens[name_idx]:match("^([%w_]+)(.*)$")
  if not name then
    return nil
  end

  local new_name = expected.symbol .. trailing
  if new_name == tokens[name_idx] then
    return nil
  end

  tokens[name_idx] = new_name
  return indent .. table.concat(tokens, " ")
end

---@param lines string[]
---@param expected ScaffoldFileMoveExpected
---@return string[] lines
---@return boolean changed
function M.apply_expected_to_lines(lines, expected)
  local changed = false
  for i, line in ipairs(lines) do
    if line:match("^namespace%s+") then
      if expected.namespace ~= "" then
        local new_line = ("namespace %s;"):format(expected.namespace)
        if line ~= new_line then
          lines[i] = new_line
          changed = true
        end
      end
    else
      local new_line = replace_declaration_line(line, expected)
      if new_line then
        lines[i] = new_line
        changed = true
      end
    end
  end
  return lines, changed
end

---@param path string
---@param expected ScaffoldFileMoveExpected
---@return boolean
function M.sync_path(path, expected)
  path = vim.fs.normalize(path)
  if vim.fn.filereadable(path) ~= 1 then
    return false
  end

  local lines = vim.fn.readfile(path)
  local changed
  lines, changed = M.apply_expected_to_lines(lines, expected)
  if not changed then
    return false
  end

  vim.fn.writefile(lines, path)

  local buf = vim.fn.bufnr(path, true)
  if buf >= 0 and vim.api.nvim_buf_is_valid(buf) then
    local modifiable = vim.bo[buf].modifiable
    if not modifiable then
      vim.bo[buf].modifiable = true
    end
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.bo[buf].modified = false
    if not modifiable then
      vim.bo[buf].modifiable = false
    end
  end

  return true
end

---@param ctx ScaffoldFileMoveContext
---@param expected ScaffoldFileMoveExpected
---@return boolean
function M.sync_buffer(ctx, expected)
  return M.sync_path(ctx.to, expected)
end

return M
