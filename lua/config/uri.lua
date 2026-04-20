local M = {}

local function decode(str)
  return (str:gsub("%%(%x%x)", function(hex)
    return string.char(tonumber(hex, 16))
  end))
end

local function encode(str)
  return (str:gsub("[^%w%-%._~!$&'()*+,;=/:@]", function(char)
    return string.format("%%%02X", string.byte(char))
  end))
end

function M.to_fname(uri)
  if not uri or uri == "" then
    return uri
  end
  if not uri:match("^file://") then
    return uri
  end
  local path = decode(uri:gsub("^file://", ""))
  if path:match("^/[A-Za-z]:") then
    path = path:sub(2)
  end
  return vim.fs.normalize(path)
end

function M.from_fname(fname)
  local path = vim.fs.normalize(fname)
  if path:match("^%a:[/\\]") then
    path = "/" .. path:gsub("\\", "/")
  end
  return "file://" .. encode(path)
end

function M.from_bufnr(buf)
  return M.from_fname(vim.api.nvim_buf_get_name(buf))
end

return M
