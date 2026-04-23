local root = require("config.root")

---@class ConfigTmp
local M = {}

local TEMP_MARKER = "~ "

local function augroup(name)
  return vim.api.nvim_create_augroup("config_" .. name, { clear = true })
end

local function notify(msg, level, opts)
  vim.notify(msg, level or vim.log.levels.INFO, vim.tbl_extend("force", { title = "Tmp" }, opts or {}))
end

local function current_buf(buf)
  if buf == nil or buf == 0 then
    return vim.api.nvim_get_current_buf()
  end
  return buf
end

local function normalize(path)
  if not path or path == "" then
    return nil
  end
  return vim.fs.normalize(path)
end

local function build_temp_path(original_path)
  local basename = vim.fs.basename(original_path)
  return normalize(vim.fn.tempname() .. "-" .. basename)
end

local function ensure_parent_dir(path)
  vim.fn.mkdir(vim.fn.fnamemodify(path, ":p:h"), "p")
end

local function path_stat(path)
  if not path then
    return nil
  end
  return vim.uv.fs_stat(path)
end

local function set_metadata(buf, meta)
  local stat = meta.original_stat
  vim.b[buf].config_tmp_original_path = meta.original_path
  vim.b[buf].config_tmp_original_bufnr = meta.original_bufnr
  vim.b[buf].config_tmp_original_changedtick = meta.original_changedtick
  vim.b[buf].config_tmp_original_existed = stat ~= nil
  vim.b[buf].config_tmp_original_mtime_sec = stat and stat.mtime and stat.mtime.sec or nil
  vim.b[buf].config_tmp_original_mtime_nsec = stat and stat.mtime and stat.mtime.nsec or nil
  vim.b[buf].config_tmp_original_size = stat and stat.size or nil
  vim.b[buf].config_tmp_path = meta.temp_path
end

local function get_metadata(buf)
  buf = current_buf(buf)
  local original_path = normalize(vim.b[buf].config_tmp_original_path)
  if not original_path then
    return nil
  end

  return {
    original_path = original_path,
    original_bufnr = tonumber(vim.b[buf].config_tmp_original_bufnr),
    original_changedtick = tonumber(vim.b[buf].config_tmp_original_changedtick),
    original_existed = not not vim.b[buf].config_tmp_original_existed,
    original_mtime_sec = tonumber(vim.b[buf].config_tmp_original_mtime_sec),
    original_mtime_nsec = tonumber(vim.b[buf].config_tmp_original_mtime_nsec),
    original_size = tonumber(vim.b[buf].config_tmp_original_size),
    temp_path = normalize(vim.b[buf].config_tmp_path) or normalize(vim.api.nvim_buf_get_name(buf)),
  }
end

local function refresh_bufferline()
  vim.schedule(function()
    if type(_G.nvim_bufferline) == "function" then
      pcall(_G.nvim_bufferline)
    else
      vim.cmd.redrawtabline()
    end
  end)
end

local function normalize_buffer_path(buf)
  return root.bufpath(buf) or normalize(vim.api.nvim_buf_get_name(buf))
end

local function find_original_buffer(meta)
  if meta.original_bufnr and vim.api.nvim_buf_is_valid(meta.original_bufnr) then
    local name = normalize_buffer_path(meta.original_bufnr)
    if name == meta.original_path then
      return meta.original_bufnr
    end
  end

  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if normalize_buffer_path(buf) == meta.original_path then
      return buf
    end
  end
end

local function original_disk_changed(meta)
  local stat = path_stat(meta.original_path)
  if not stat then
    return meta.original_existed
  end
  if not meta.original_existed then
    return true
  end
  return stat.size ~= meta.original_size
    or stat.mtime.sec ~= meta.original_mtime_sec
    or stat.mtime.nsec ~= meta.original_mtime_nsec
end

local function restore_cursor(cursor)
  local row = math.min(cursor[1], vim.api.nvim_buf_line_count(0))
  local line = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1] or ""
  local col = math.min(cursor[2], #line)
  pcall(vim.api.nvim_win_set_cursor, 0, { row, col })
end

function M.is_temp(buf)
  return get_metadata(buf) ~= nil
end

function M.bufferline_name(buf)
  local meta = get_metadata(buf.bufnr)
  if not meta then
    return buf.name
  end

  local original_name = vim.fs.basename(meta.original_path)
  return TEMP_MARKER .. (original_name ~= "" and original_name or buf.name)
end

function M.tmp()
  local source_buf = vim.api.nvim_get_current_buf()
  if M.is_temp(source_buf) then
    notify("Already editing a temporary buffer", vim.log.levels.ERROR)
    return
  end

  if vim.bo[source_buf].buftype ~= "" then
    notify("Tmp only works for normal file buffers", vim.log.levels.ERROR)
    return
  end

  local original_path = root.bufpath(source_buf)
  if not original_path then
    notify("Tmp needs a named file buffer", vim.log.levels.ERROR)
    return
  end

  local cursor = vim.api.nvim_win_get_cursor(0)
  local temp_path = build_temp_path(original_path)
  local filetype = vim.bo[source_buf].filetype

  ensure_parent_dir(temp_path)
  local ok, err = pcall(function()
    vim.cmd(("keepalt silent noautocmd write! %s"):format(vim.fn.fnameescape(temp_path)))
    vim.cmd(("hide edit %s"):format(vim.fn.fnameescape(temp_path)))
  end)

  if not ok then
    notify(err, vim.log.levels.ERROR)
    return
  end

  local temp_buf = vim.api.nvim_get_current_buf()
  vim.bo[temp_buf].readonly = false
  vim.bo[temp_buf].modifiable = true
  if filetype ~= "" then
    vim.bo[temp_buf].filetype = filetype
  end

  set_metadata(temp_buf, {
    original_path = original_path,
    original_bufnr = source_buf,
    original_changedtick = vim.api.nvim_buf_get_changedtick(source_buf),
    original_stat = path_stat(original_path),
    temp_path = temp_path,
  })

  restore_cursor(cursor)
  refresh_bufferline()
  notify(("Created temporary buffer for %s"):format(original_path))
end

function M.untmp()
  local temp_buf = vim.api.nvim_get_current_buf()
  local meta = get_metadata(temp_buf)
  if not meta then
    notify("Current buffer is not a temporary buffer", vim.log.levels.ERROR)
    return
  end

  local original_buf = find_original_buffer(meta)
  if original_buf and vim.api.nvim_buf_is_loaded(original_buf) then
    local current_tick = vim.api.nvim_buf_get_changedtick(original_buf)
    if current_tick ~= meta.original_changedtick then
      notify("Original buffer changed since :tmp; recreate the temporary copy first", vim.log.levels.ERROR)
      return
    end
  end

  if original_disk_changed(meta) then
    notify("Original file changed on disk since :tmp; refusing to overwrite it", vim.log.levels.ERROR)
    return
  end

  local cursor = vim.api.nvim_win_get_cursor(0)
  ensure_parent_dir(meta.temp_path)
  ensure_parent_dir(meta.original_path)

  local ok, err = pcall(function()
    vim.cmd("silent noautocmd write")
    vim.cmd(("keepalt silent noautocmd write! %s"):format(vim.fn.fnameescape(meta.original_path)))
  end)

  if not ok then
    notify(err, vim.log.levels.ERROR)
    return
  end

  local switched = false
  if original_buf and vim.api.nvim_buf_is_valid(original_buf) then
    local original_name = normalize_buffer_path(original_buf)
    if original_name == meta.original_path then
      ok, err = pcall(function()
        vim.fn.bufload(original_buf)
        vim.cmd(("buffer %d"):format(original_buf))
        vim.cmd("silent noautocmd edit!")
      end)
      switched = ok
    end
  end

  if not switched then
    ok, err = pcall(function()
      vim.cmd(("edit %s"):format(vim.fn.fnameescape(meta.original_path)))
    end)
    if not ok then
      notify(err, vim.log.levels.ERROR)
      return
    end
  end

  restore_cursor(cursor)
  vim.api.nvim_buf_delete(temp_buf, { force = true })
  refresh_bufferline()
  notify(("Replaced %s with the temporary buffer"):format(meta.original_path))
end

local function create_command_alias(from, to)
  vim.cmd(
    ("cnoreabbrev <expr> %s getcmdtype() ==# ':' && getcmdline() ==# '%s' ? '%s' : '%s'"):format(from, from, to, from)
  )
end

function M.setup()
  vim.api.nvim_create_user_command("Tmp", function()
    M.tmp()
  end, { desc = "Create a writable temporary copy of the current buffer" })

  vim.api.nvim_create_user_command("Untmp", function()
    M.untmp()
  end, { desc = "Write a temporary buffer back to its original file" })

  create_command_alias("tmp", "Tmp")
  create_command_alias("untmp", "Untmp")

  vim.api.nvim_create_autocmd("BufDelete", {
    group = augroup("tmp_cleanup"),
    callback = function(event)
      local meta = get_metadata(event.buf)
      if not meta or not meta.temp_path then
        return
      end
      if normalize(meta.temp_path) == normalize(meta.original_path) then
        return
      end
      pcall(vim.uv.fs_unlink, meta.temp_path)
    end,
  })
end

return M
