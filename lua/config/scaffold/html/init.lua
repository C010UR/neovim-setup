---@class ConfigScaffoldHtml
local M = {}

---@param ctx ScaffoldContext
---@return ScaffoldResult
function M.build(ctx)
  local lines = {
    "<!DOCTYPE html>",
    '<html lang="en">',
    "  <head>",
    '    <meta charset="UTF-8">',
    '    <meta name="viewport" content="width=device-width, initial-scale=1.0">',
    '    <meta name="description" content="">',
    "    <title>Index</title>",
    '    <script defer src="script.js"></script>',
    "  </head>",
    "  <body>",
    "  </body>",
    "</html>",
  }

  return {
    lines = lines,
    cursor = { line = 11, col = 4 },
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
  return path:match("%.html$") ~= nil or path:match("%.htm$") ~= nil
end

function M.register()
  require("config.scaffold.registry").register("html", {
    filetypes = { "html" },
    extensions = { "html", "htm" },
    should_scaffold = M.should_scaffold,
    build = M.build,
  })
end

return M
