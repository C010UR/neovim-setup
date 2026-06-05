local M = {}

local function decode(str)
  return (str:gsub("%%(%x%x)", function(hex)
    return string.char(tonumber(hex, 16))
  end))
end

local function encode(str)
  return (
    str:gsub("[^%w%-%._~!$&'()*+,;=/:@]", function(char)
      return string.format("%%%02X", string.byte(char))
    end)
  )
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

function M.open(url)
  if not url or url == "" then
    vim.notify("No URL provided", vim.log.levels.WARN)
    return
  end

  local ok, obj, err = pcall(vim.ui.open, url)
  if not ok then
    vim.notify("Failed to open URL: " .. (err or obj or "unknown error"), vim.log.levels.ERROR)
    return
  end

  if err then
    vim.notify("Failed to open URL: " .. err, vim.log.levels.ERROR)
    return
  end

  if obj then
    vim.defer_fn(function()
      local res = obj:wait(10000)
      if res and res.code ~= 0 and res.code ~= nil then
        vim.notify("Failed to open URL: " .. (res.stderr or ("exit code " .. res.code)), vim.log.levels.ERROR)
      end
    end, 0)
  end
end

function M.get_url_under_cursor()
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2] + 1

  -- Check markdown links first: [text](url)
  local md_pos = 1
  while true do
    local s, e, _, url = line:find("%[([^%]]*)%]%(([^%)]+)%)", md_pos)
    if not s then
      break
    end
    if col >= s and col <= e then
      return url
    end
    md_pos = e + 1
  end

  -- Check bare URLs
  local url_pattern = "https?://[^%s%\"'<>%[%]{}|`]+"
  local url_pos = 1
  while true do
    local s, e, url = line:find("()(" .. url_pattern .. ")", url_pos)
    if not s then
      break
    end
    if col >= s and col <= e then
      return url
    end
    url_pos = e + 1
  end
  return nil
end

function M.get_visual_selection()
  local mode = vim.fn.mode()
  if mode ~= "v" and mode ~= "V" and mode ~= "\22" then
    return nil
  end

  local region = vim.fn.getregion(vim.fn.getpos("v"), vim.fn.getpos("."), { type = mode })
  return table.concat(region, "\n")
end

return M
