---@class ConfigScaffoldPhpSymfony
local M = {}

---@param root string
---@return boolean
function M.is_project(root)
  if vim.uv.fs_stat(root .. "/symfony.lock") then
    return true
  end
  if vim.uv.fs_stat(root .. "/vendor/symfony") then
    return true
  end
  local composer = root .. "/composer.json"
  if vim.uv.fs_stat(composer) then
    local lines = vim.fn.readfile(composer)
    if lines then
      local content = table.concat(lines, "\n")
      if content:find('"symfony/framework-bundle"', 1, true) or content:find('"symfony/symfony"', 1, true) then
        return true
      end
    end
  end
  return false
end

---@param stem string
---@return string|nil
function M.scaffold_type(stem)
  if stem:match("^Abstract") then
    return nil
  end
  if stem:match("Command$") then
    return "command"
  end
  if stem:match("Controller$") then
    return "controller"
  end
  if stem:match("Type$") then
    return "form_type"
  end
  if stem:match("Handler$") then
    return "message_handler"
  end
  if stem:match("Listener$") then
    return "event_listener"
  end
  if stem:match("Voter$") then
    return "voter"
  end
  if stem:match("Extension$") then
    return "twig_extension"
  end
  if stem:match("Transformer$") then
    return "data_transformer"
  end
  if stem:match("Normalizer$") then
    return "normalizer"
  end
  if stem:match("Validator$") then
    return "constraint_validator"
  end
  if stem:match("Constraint$") then
    return "constraint"
  end
  if stem:match("Message$") then
    return "message"
  end
  return nil
end

return M
