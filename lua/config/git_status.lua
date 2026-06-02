local M = {}

local state = {
  setup_ran = false,
  pending = {},
  callbacks = {},
}

M.labels = {
  staged_new = "staged (new)",
  staged_modified = "staged",
  staged_deleted = "staged (del)",
  untracked = "untracked",
  modified = "modified",
  deleted = "deleted",
  renamed = "renamed",
  ignored = "ignored",
}

M.highlights = {
  staged_new = "FFFGitStaged",
  staged_modified = "FFFGitStaged",
  staged_deleted = "FFFGitStaged",
  modified = "FFFGitModified",
  deleted = "FFFGitDeleted",
  renamed = "FFFGitRenamed",
  untracked = "FFFGitUntracked",
  ignored = "FFFGitIgnored",
}

M.sign_highlights = {
  untracked = "FFFGitSignUntracked",
  ignored = "FFFGitSignIgnored",
  unknown = "FFFGitSignUntracked",
  modified = "FFFGitSignModified",
  deleted = "FFFGitSignDeleted",
  renamed = "FFFGitSignRenamed",
  staged_new = "FFFGitSignStaged",
  staged_modified = "FFFGitSignStaged",
  staged_deleted = "FFFGitSignStaged",
}

local function ensure_highlights()
  local defaults = {
    FFFGitStaged = "#10B981",
    FFFGitModified = "#F59E0B",
    FFFGitDeleted = "#EF4444",
    FFFGitRenamed = "#8B5CF6",
    FFFGitUntracked = "#10B981",
    FFFGitIgnored = "#4B5563",
    FFFGitSignStaged = "#10B981",
    FFFGitSignModified = "#F59E0B",
    FFFGitSignDeleted = "#EF4444",
    FFFGitSignRenamed = "#8B5CF6",
    FFFGitSignUntracked = "#10B981",
    FFFGitSignIgnored = "#4B5563",
  }

  for group, fg in pairs(defaults) do
    if vim.api.nvim_get_hl(0, { name = group, link = false }).fg == nil then
      vim.api.nvim_set_hl(0, group, { fg = fg, default = true })
    end
  end
end

function M.ensure_highlights()
  ensure_highlights()
end

local function parse_git_porcelain(line)
  if line == "" then
    return "clean"
  end
  if line:sub(1, 2) == "??" then
    return "untracked"
  end
  if line:sub(1, 2) == "!!" then
    return "ignored"
  end

  local index = line:sub(1, 1)
  local wt = line:sub(2, 2)

  if wt == "M" then
    return "modified"
  end
  if wt == "D" then
    return "deleted"
  end
  if wt == "R" then
    return "renamed"
  end
  if index == "A" then
    return "staged_new"
  end
  if index == "M" then
    return "staged_modified"
  end
  if index == "D" then
    return "staged_deleted"
  end
  if index == "R" then
    return "renamed"
  end

  return "unknown"
end

local function buffer_supports_git_status(bufnr)
  bufnr = bufnr or 0
  return vim.api.nvim_buf_is_valid(bufnr) and vim.bo[bufnr].buftype == ""
end

local function notify_update(bufnr)
  if bufnr ~= vim.api.nvim_get_current_buf() then
    return
  end

  vim.schedule(function()
    for _, callback in ipairs(state.callbacks) do
      callback()
    end
  end)
end

local function refresh_display()
  vim.cmd.redrawstatus()
end

function M.on_update(callback)
  state.callbacks[#state.callbacks + 1] = callback
end

function M.get(bufnr)
  bufnr = bufnr or 0
  return vim.b[bufnr].git_status_line
end

function M.label(status)
  return M.labels[status] or status
end

function M.highlight(status)
  return M.highlights[status]
end

function M.should_show(status)
  return status ~= nil and status ~= "clean" and status ~= "clear"
end

function M.gitsign(text, hl)
  return { text = text, show_count = false, texthl = hl }
end

function M.update(bufnr)
  bufnr = bufnr or 0
  if not buffer_supports_git_status(bufnr) then
    vim.b[bufnr].git_status_line = nil
    notify_update(bufnr)
    return
  end

  local path = vim.api.nvim_buf_get_name(bufnr)
  if path == "" then
    vim.b[bufnr].git_status_line = nil
    notify_update(bufnr)
    return
  end

  local path_norm = vim.fs.normalize(path)
  if vim.fn.isdirectory(path_norm) == 1 then
    vim.b[bufnr].git_status_line = nil
    notify_update(bufnr)
    return
  end

  local pending = state.pending[bufnr]
  if pending and pending.path == path_norm then
    return
  end
  if pending and pending.job then
    pending.job:kill()
  end

  local job = vim.system(
    { "git", "-C", vim.fs.dirname(path_norm), "rev-parse", "--show-toplevel" },
    { text = true },
    function(root_result)
      vim.schedule(function()
        state.pending[bufnr] = nil
        if not vim.api.nvim_buf_is_valid(bufnr) then
          return
        end
        if root_result.code ~= 0 then
          vim.b[bufnr].git_status_line = nil
          notify_update(bufnr)
          return
        end

        local root = vim.trim(root_result.stdout)
        state.pending[bufnr] = { path = path_norm }
        state.pending[bufnr].job = vim.system({
          "git",
          "-C",
          root,
          "status",
          "--porcelain",
          "--ignored=matching",
          "--",
          path_norm,
        }, { text = true }, function(status_result)
          vim.schedule(function()
            state.pending[bufnr] = nil
            if not vim.api.nvim_buf_is_valid(bufnr) then
              return
            end

            if status_result.code ~= 0 then
              vim.b[bufnr].git_status_line = nil
            else
              local line = vim.split(vim.trim(status_result.stdout), "\n", { plain = true })[1] or ""
              vim.b[bufnr].git_status_line = parse_git_porcelain(line)
            end

            notify_update(bufnr)
          end)
        end)
      end)
    end
  )

  state.pending[bufnr] = { path = path_norm, job = job }
end

function M.setup()
  if state.setup_ran then
    return
  end
  state.setup_ran = true

  ensure_highlights()
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = vim.api.nvim_create_augroup("config_git_status_hl", { clear = true }),
    callback = ensure_highlights,
  })

  M.on_update(refresh_display)

  local group = vim.api.nvim_create_augroup("config_git_status", { clear = true })
  local events = {
    "BufEnter",
    "BufReadPost",
    "BufWritePost",
    "FocusGained",
    "DirChanged",
    "VimResume",
    "FileChangedShellPost",
  }

  vim.api.nvim_create_autocmd(events, {
    group = group,
    callback = function(event)
      M.update(event.buf)
    end,
  })

  vim.api.nvim_create_autocmd("BufDelete", {
    group = group,
    callback = function(event)
      local pending = state.pending[event.buf]
      if pending and pending.job then
        pending.job:kill()
      end
      state.pending[event.buf] = nil
    end,
  })

  M.update(0)
end

return M
