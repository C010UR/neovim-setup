local api = vim.api
local ns = api.nvim_create_namespace("pack_ui")

local M = {}

local MAX_COMMITS_PREVIEW = 10

local state = {
  bufnr = nil,
  winid = nil,
  win_autocmd_id = nil,
  line_to_plugin = {},
  plugin_lines = {},
  expanded = {},
  show_help = false,
  updates = {},
  breaking = {},
  unreleased_breaking = {},
  show_all_commits = {},
  latest_ref = {},
  checking = false,
  check_id = 0,
}

local tag_cache = {}
local ref_cache = {}

local render
local open

local function complete_plugin_names()
  local plugins = vim.pack.get(nil, { info = false })
  table.sort(plugins, function(a, b)
    return a.spec.name < b.spec.name
  end)
  return vim.tbl_map(function(plugin)
    return plugin.spec.name
  end, plugins)
end

local function setup_highlights()
  local links = {
    PackUiHeader = "Title",
    PackUiButton = "Function",
    PackUiPluginLoaded = "String",
    PackUiPluginNotLoaded = "Comment",
    PackUiPluginMissing = "ErrorMsg",
    PackUiUpdateAvailable = "DiagnosticInfo",
    PackUiBreaking = "DiagnosticWarn",
    PackUiVersion = "Number",
    PackUiSectionHeader = "Label",
    PackUiSeparator = "FloatBorder",
    PackUiDetail = "Comment",
    PackUiHelp = "SpecialComment",
  }

  for group, target in pairs(links) do
    api.nvim_set_hl(0, group, { link = target, default = true })
  end
end

local function get_installed_tag(path)
  if not path then
    return nil
  end
  if tag_cache[path] ~= nil then
    return tag_cache[path] or nil
  end

  local result = vim.system({ "git", "-C", path, "describe", "--tags", "--exact-match", "HEAD" }, { text = true }):wait()
  if result.code == 0 then
    local tag = vim.trim(result.stdout)
    tag_cache[path] = tag
    return tag
  end

  tag_cache[path] = false
  return nil
end

local function get_version_str(plugin)
  local version = plugin.spec.version
  if version == nil then
    return ""
  end
  if type(version) == "string" then
    return version
  end
  return tostring(version)
end

local function parse_semver(tag)
  if not tag then
    return nil
  end
  local major, minor, patch = tag:match("^v?(%d+)%.(%d+)%.(%d+)")
  if major then
    return { tonumber(major), tonumber(minor), tonumber(patch) }
  end
  return nil
end

local function semver_gt(a, b)
  if not a or not b then
    return false
  end
  if a[1] ~= b[1] then
    return a[1] > b[1]
  end
  if a[2] ~= b[2] then
    return a[2] > b[2]
  end
  return a[3] > b[3]
end

local function parse_commits(stdout)
  local commits = {}
  if stdout and stdout ~= "" then
    for line in stdout:gmatch("[^\n]+") do
      commits[#commits + 1] = line
    end
  end
  return commits
end

local function git_log(path, range, callback)
  vim.system({ "git", "-C", path, "log", "--oneline", range }, { text = true }, function(result)
    callback(parse_commits(result.code == 0 and result.stdout or ""))
  end)
end

local function is_breaking_commit(commit)
  return commit:match("%x+ %w+!:") or commit:match("%x+ %w+%b()!:")
end

local function has_breaking_commit(commits)
  return vim.iter(commits):any(is_breaking_commit)
end

local function filter_breaking(commits)
  return vim.iter(commits):filter(is_breaking_commit):totable()
end

local function resolve_remote_ref(path, callback)
  if ref_cache[path] ~= nil then
    callback(ref_cache[path] or nil)
    return
  end

  vim.system({ "git", "-C", path, "symbolic-ref", "refs/remotes/origin/HEAD" }, { text = true }, function(result)
    if result.code == 0 then
      local ref = vim.trim(result.stdout)
      ref_cache[path] = ref
      callback(ref)
      return
    end

    vim.system({ "git", "-C", path, "rev-parse", "--verify", "origin/main" }, { text = true }, function(main_result)
      if main_result.code == 0 then
        ref_cache[path] = "origin/main"
        callback("origin/main")
        return
      end

      vim.system({ "git", "-C", path, "rev-parse", "--verify", "origin/master" }, { text = true }, function(master_result)
        if master_result.code == 0 then
          ref_cache[path] = "origin/master"
          callback("origin/master")
        else
          ref_cache[path] = false
          callback(nil)
        end
      end)
    end)
  end)
end

local function reset_state()
  state.winid = nil
  state.bufnr = nil
  state.expanded = {}
  state.show_help = false
  state.updates = {}
  state.breaking = {}
  state.unreleased_breaking = {}
  state.show_all_commits = {}
  state.latest_ref = {}
  state.checking = false
  state.line_to_plugin = {}
  state.plugin_lines = {}
  state.check_id = state.check_id + 1
end

local function close()
  if state.win_autocmd_id then
    pcall(api.nvim_del_autocmd, state.win_autocmd_id)
    state.win_autocmd_id = nil
  end

  if state.winid and api.nvim_win_is_valid(state.winid) then
    api.nvim_win_close(state.winid, true)
  end

  reset_state()
end

local function plugin_at_cursor()
  if not state.winid or not api.nvim_win_is_valid(state.winid) then
    return nil
  end
  local row = api.nvim_win_get_cursor(state.winid)[1]
  return state.line_to_plugin[row]
end

local function jump_plugin(direction)
  if not state.winid or not api.nvim_win_is_valid(state.winid) then
    return
  end

  local row = api.nvim_win_get_cursor(state.winid)[1]
  local plugin_lines = vim.tbl_keys(state.line_to_plugin)
  table.sort(plugin_lines)

  if direction > 0 then
    for _, line in ipairs(plugin_lines) do
      if line > row then
        api.nvim_win_set_cursor(state.winid, { line, 0 })
        return
      end
    end
    if #plugin_lines > 0 then
      api.nvim_win_set_cursor(state.winid, { plugin_lines[1], 0 })
    end
    return
  end

  for index = #plugin_lines, 1, -1 do
    if plugin_lines[index] < row then
      api.nvim_win_set_cursor(state.winid, { plugin_lines[index], 0 })
      return
    end
  end
  if #plugin_lines > 0 then
    api.nvim_win_set_cursor(state.winid, { plugin_lines[#plugin_lines], 0 })
  end
end

local function check_updates()
  if state.checking then
    return
  end

  local plugins = vim.pack.get(nil, { info = false })
  if #plugins == 0 then
    return
  end

  state.check_id = state.check_id + 1
  local my_check_id = state.check_id
  state.checking = true
  state.updates = {}
  state.breaking = {}
  state.unreleased_breaking = {}
  state.latest_ref = {}
  render()

  local remaining = #plugins

  local function finish_one(result)
    vim.schedule(function()
      if state.check_id ~= my_check_id then
        return
      end

      if result then
        if result.updates ~= nil then
          state.updates[result.name] = result.updates
        end
        if result.breaking then
          state.breaking[result.name] = true
        end
        if result.unreleased_breaking then
          state.unreleased_breaking[result.name] = result.unreleased_breaking
        end
        if result.latest_ref then
          state.latest_ref[result.name] = result.latest_ref
        end
      end

      remaining = remaining - 1
      if remaining == 0 then
        state.checking = false
        render()
      end
    end)
  end

  for _, plugin in ipairs(plugins) do
    local path = plugin.path
    local name = plugin.spec.name
    local current_tag = plugin.spec.version and get_installed_tag(path) or nil

    vim.system({ "git", "-C", path, "fetch", "--quiet", "--tags" }, {}, function(fetch_result)
      if fetch_result.code ~= 0 then
        finish_one(nil)
        return
      end

      if current_tag then
        vim.system({ "git", "-C", path, "tag", "--list", "--sort=-version:refname" }, { text = true }, function(tag_result)
          local current_version = parse_semver(current_tag)
          local latest_tag
          local latest_version

          if tag_result.code == 0 then
            for tag in tag_result.stdout:gmatch("[^\n]+") do
              local version = parse_semver(tag)
              if version and (not latest_version or semver_gt(version, latest_version)) then
                latest_tag = tag
                latest_version = version
              end
            end
          end

          local result = { name = name }
          if current_version and latest_version and latest_version[1] > current_version[1] then
            result.breaking = true
          end

          local function after_released()
            resolve_remote_ref(path, function(ref)
              if not ref then
                finish_one(result)
                return
              end

              local compare_from = latest_tag or current_tag
              git_log(path, compare_from .. ".." .. ref, function(unreleased)
                local breaking_lines = filter_breaking(unreleased)
                if #breaking_lines > 0 then
                  result.unreleased_breaking = breaking_lines
                end
                finish_one(result)
              end)
            end)
          end

          local is_newer = current_version and latest_version and semver_gt(latest_version, current_version)
          if is_newer and latest_tag then
            result.latest_ref = latest_tag
            git_log(path, "HEAD.." .. latest_tag, function(commits)
              result.updates = commits
              if has_breaking_commit(commits) then
                result.breaking = true
              end
              after_released()
            end)
          else
            result.updates = {}
            after_released()
          end
        end)
      else
        resolve_remote_ref(path, function(ref)
          if not ref then
            finish_one(nil)
            return
          end

          git_log(path, "HEAD.." .. ref, function(commits)
            local result = { name = name, updates = commits }
            if has_breaking_commit(commits) then
              result.breaking = true
            end
            if #commits > 0 then
              local latest_hash = commits[1]:match("^(%x+)")
              if latest_hash then
                result.latest_ref = latest_hash
              end
            end
            finish_one(result)
          end)
        end)
      end
    end)
  end
end

local function build_content()
  local plugins = vim.pack.get(nil, { info = false })
  local loaded = {}
  local not_loaded = {}

  for _, plugin in ipairs(plugins) do
    if plugin.active then
      loaded[#loaded + 1] = plugin
    else
      not_loaded[#not_loaded + 1] = plugin
    end
  end

  table.sort(loaded, function(a, b)
    return a.spec.name < b.spec.name
  end)
  table.sort(not_loaded, function(a, b)
    return a.spec.name < b.spec.name
  end)

  local lines = {}
  local highlights = {}
  local line_to_plugin = {}
  local plugin_lines = {}

  local function add(text, highlight)
    local line = #lines
    lines[#lines + 1] = text
    if highlight then
      highlights[#highlights + 1] = { line, 0, #text, highlight }
    end
  end

  local function add_highlight(line, start_col, end_col, highlight)
    highlights[#highlights + 1] = { line, start_col, end_col, highlight }
  end

  local status = state.checking and "  (checking...)" or ""
  add((" vim.pack -- %d plugins | %d loaded%s"):format(#plugins, #loaded, status), "PackUiHeader")

  local win_width = state.winid and api.nvim_win_get_width(state.winid) or 80
  add(" " .. string.rep("─", win_width - 1), "PackUiSeparator")

  local bar = " [U]pdate All  [u] Update  [C]heck  [X] Clean  [D]elete  [L] Log  [?] Help"
  add(bar)
  local bar_line = #lines - 1
  for start_col, end_col in bar:gmatch("()%[.-%]()") do
    add_highlight(bar_line, start_col - 1, end_col - 1, "PackUiButton")
  end

  if state.show_help then
    add("")
    add(" Keymaps:", "PackUiHelp")
    add("   U       Update all plugins", "PackUiHelp")
    add("   u       Update plugin under cursor", "PackUiHelp")
    add("   C       Check remote for new commits", "PackUiHelp")
    add("   X       Clean non-active plugins", "PackUiHelp")
    add("   D       Delete plugin under cursor (non-active only)", "PackUiHelp")
    add("   L       Open update log file", "PackUiHelp")
    add("   <CR>    Toggle plugin details", "PackUiHelp")
    add("   ]]      Jump to next plugin", "PackUiHelp")
    add("   [[      Jump to previous plugin", "PackUiHelp")
    add("   q/Esc   Close window", "PackUiHelp")
  end

  local max_name = 0
  for _, plugin in ipairs(plugins) do
    max_name = math.max(max_name, #plugin.spec.name)
  end

  local function render_plugin(plugin, icon, highlight)
    local name = plugin.spec.name
    local pad = string.rep(" ", max_name - #name + 2)
    local version = get_version_str(plugin)
    local tag = plugin.spec.version and get_installed_tag(plugin.path) or nil
    local rev_short = plugin.rev and plugin.rev:sub(1, 7) or ""
    local version_display = tag or (rev_short ~= "" and rev_short or version)
    local latest = state.latest_ref[name]

    if latest then
      local current_has_v = version_display:match("^v") ~= nil
      local latest_has_v = latest:match("^v") ~= nil
      local latest_display = latest
      if current_has_v and not latest_has_v then
        latest_display = "v" .. latest
      elseif not current_has_v and latest_has_v then
        latest_display = latest:sub(2)
      end
      if latest_display ~= version_display then
        version_display = version_display .. " → " .. latest_display
      end
    end

    local update_count = state.updates[name] and #state.updates[name] or 0
    local update_display = update_count > 0 and ("  ↑%d"):format(update_count) or ""
    local unreleased = state.unreleased_breaking[name]
    local unreleased_display = unreleased and #unreleased > 0 and ("  ⚠ %d breaking unreleased"):format(#unreleased) or ""
    local line = ("   %s %s%s%s%s%s"):format(icon, name, pad, version_display, update_display, unreleased_display)
    local current_line = #lines
    add(line)

    local icon_bytes = #icon
    local icon_start = 3
    local name_start = icon_start + icon_bytes + 1
    add_highlight(current_line, icon_start, icon_start + icon_bytes, highlight)
    add_highlight(current_line, name_start, name_start + #name, highlight)

    if #version_display > 0 then
      local version_start = name_start + #name + #pad
      local version_highlight = state.breaking[name] and "PackUiBreaking" or "PackUiVersion"
      add_highlight(current_line, version_start, version_start + #version_display, version_highlight)
    end

    if update_count > 0 then
      local update_start = name_start + #name + #pad + #version_display
      local update_highlight = state.breaking[name] and "PackUiBreaking" or "PackUiUpdateAvailable"
      add_highlight(current_line, update_start, update_start + #update_display, update_highlight)
    end

    if #unreleased_display > 0 then
      local unreleased_start = name_start + #name + #pad + #version_display + #update_display
      add_highlight(current_line, unreleased_start, unreleased_start + #unreleased_display, "PackUiBreaking")
    end

    line_to_plugin[current_line + 1] = name
    plugin_lines[name] = current_line + 1

    if state.expanded[name] then
      local details = {
        ("     Path:    %s"):format(plugin.path),
        ("     Source:  %s"):format(plugin.spec.src),
      }
      if plugin.rev then
        details[#details + 1] = ("     Rev:     %s"):format(plugin.rev)
      end

      for _, detail in ipairs(details) do
        add(detail, "PackUiDetail")
        line_to_plugin[#lines] = name
      end

      local commits = state.updates[name]
      if commits and #commits > 0 then
        local max_commits = state.show_all_commits[name] and #commits or MAX_COMMITS_PREVIEW
        for index, commit in ipairs(commits) do
          if index > max_commits then
            add(("     ... and %d more (Enter to expand)"):format(#commits - max_commits), "PackUiDetail")
            line_to_plugin[#lines] = name
            break
          end
          add("     " .. commit, is_breaking_commit(commit) and "PackUiBreaking" or nil)
          line_to_plugin[#lines] = name
        end
        add("")
      end

      local unreleased_commits = state.unreleased_breaking[name]
      if unreleased_commits and #unreleased_commits > 0 then
        add(("     ⚠ %d breaking change(s) unreleased on main:"):format(#unreleased_commits), "PackUiBreaking")
        line_to_plugin[#lines] = name
        for _, commit in ipairs(unreleased_commits) do
          add("       " .. commit, "PackUiBreaking")
          line_to_plugin[#lines] = name
        end
        add("")
      end
    end
  end

  add("")
  add((" Loaded (%d)"):format(#loaded), "PackUiSectionHeader")
  for _, plugin in ipairs(loaded) do
    render_plugin(plugin, "●", "PackUiPluginLoaded")
  end

  if #not_loaded > 0 then
    add("")
    add((" Not Loaded (%d)"):format(#not_loaded), "PackUiSectionHeader")
    for _, plugin in ipairs(not_loaded) do
      render_plugin(plugin, "○", "PackUiPluginNotLoaded")
    end
  end

  state.line_to_plugin = line_to_plugin
  state.plugin_lines = plugin_lines

  return lines, highlights
end

render = function()
  if not state.bufnr or not api.nvim_buf_is_valid(state.bufnr) then
    return
  end

  local lines, highlights = build_content()

  vim.bo[state.bufnr].modifiable = true
  api.nvim_buf_set_lines(state.bufnr, 0, -1, false, lines)
  vim.bo[state.bufnr].modifiable = false
  vim.bo[state.bufnr].modified = false

  api.nvim_buf_clear_namespace(state.bufnr, ns, 0, -1)
  for _, highlight in ipairs(highlights) do
    api.nvim_buf_set_extmark(state.bufnr, ns, highlight[1], highlight[2], {
      end_col = highlight[3],
      hl_group = highlight[4],
    })
  end
end

local function setup_keymaps()
  local opts = { buffer = state.bufnr, silent = true, nowait = true }

  vim.keymap.set("n", "q", close, opts)
  vim.keymap.set("n", "<Esc>", close, opts)

  vim.keymap.set("n", "U", function()
    close()
    vim.pack.update()
  end, opts)

  vim.keymap.set("n", "u", function()
    local name = plugin_at_cursor()
    if not name then
      return
    end
    close()
    vim.pack.update({ name })
  end, opts)

  vim.keymap.set("n", "X", function()
    local names = vim.iter(vim.pack.get(nil, { info = false }))
      :filter(function(plugin)
        return not plugin.active
      end)
      :map(function(plugin)
        return plugin.spec.name
      end)
      :totable()

    if #names == 0 then
      vim.notify("vim.pack: nothing to clean", vim.log.levels.INFO)
      return
    end

    local prompt = ("Remove %d non-active plugin(s)?\n\n%s"):format(#names, table.concat(names, "\n"))
    if vim.fn.confirm(prompt, "&Yes\n&No", 2, "Question") == 1 then
      close()
      local ok, err = pcall(vim.pack.del, names)
      if ok then
        vim.notify(("vim.pack: removed %d plugin(s)"):format(#names), vim.log.levels.INFO)
      else
        vim.notify("vim.pack: " .. tostring(err), vim.log.levels.ERROR)
      end
    end
  end, opts)

  vim.keymap.set("n", "D", function()
    local name = plugin_at_cursor()
    if not name then
      return
    end

    local ok, plugins = pcall(vim.pack.get, { name }, { info = false })
    if not ok then
      vim.notify(("vim.pack: %s is not installed"):format(name), vim.log.levels.WARN)
      return
    end

    if #plugins > 0 and plugins[1].active then
      vim.notify(("vim.pack: %s is active, remove from config first"):format(name), vim.log.levels.WARN)
      return
    end

    if vim.fn.confirm(("Delete plugin %s?"):format(name), "&Yes\n&No", 2, "Question") == 1 then
      close()
      local deleted, err = pcall(vim.pack.del, { name })
      if deleted then
        vim.notify(("vim.pack: removed %s"):format(name), vim.log.levels.INFO)
      else
        vim.notify("vim.pack: " .. tostring(err), vim.log.levels.ERROR)
      end
    end
  end, opts)

  vim.keymap.set("n", "L", function()
    close()
    local log_path = vim.fs.joinpath(vim.fn.stdpath("log"), "nvim-pack.log")
    if vim.uv.fs_stat(log_path) then
      vim.cmd.edit(log_path)
    else
      vim.notify("vim.pack: no log file yet", vim.log.levels.INFO)
    end
  end, opts)

  vim.keymap.set("n", "<CR>", function()
    local name = plugin_at_cursor()
    if not name then
      return
    end

    local commits = state.updates[name]
    local truncated = commits and #commits > MAX_COMMITS_PREVIEW
    if not state.expanded[name] then
      state.expanded[name] = true
    elseif truncated and not state.show_all_commits[name] then
      state.show_all_commits[name] = true
    else
      state.expanded[name] = false
      state.show_all_commits[name] = nil
    end

    render()
    if state.plugin_lines[name] then
      api.nvim_win_set_cursor(state.winid, { state.plugin_lines[name], 0 })
    end
  end, opts)

  vim.keymap.set("n", "]]", function()
    jump_plugin(1)
  end, opts)
  vim.keymap.set("n", "[[", function()
    jump_plugin(-1)
  end, opts)
  vim.keymap.set("n", "C", check_updates, opts)
  vim.keymap.set("n", "?", function()
    state.show_help = not state.show_help
    render()
  end, opts)
end

open = function()
  if state.winid and api.nvim_win_is_valid(state.winid) then
    api.nvim_set_current_win(state.winid)
    return
  end

  setup_highlights()

  state.bufnr = api.nvim_create_buf(false, true)
  vim.bo[state.bufnr].buftype = "nofile"
  vim.bo[state.bufnr].bufhidden = "wipe"
  vim.bo[state.bufnr].swapfile = false
  vim.bo[state.bufnr].filetype = "pack-ui"

  local cols = vim.o.columns
  local lines = vim.o.lines
  local width = math.min(cols - 4, math.max(math.floor(cols * 0.8), 60))
  local height = math.min(lines - 4, math.max(math.floor(lines * 0.7), 20))
  local row = math.floor((lines - height) / 2)
  local col = math.floor((cols - width) / 2)

  state.winid = api.nvim_open_win(state.bufnr, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
    title = " vim.pack ",
    title_pos = "center",
  })

  vim.wo[state.winid].cursorline = true
  vim.wo[state.winid].wrap = false

  render()
  setup_keymaps()

  local captured_winid = state.winid
  state.win_autocmd_id = api.nvim_create_autocmd("WinClosed", {
    pattern = tostring(captured_winid),
    once = true,
    callback = function()
      state.win_autocmd_id = nil
      reset_state()
    end,
  })
end

function M.open()
  open()
end

function M.setup()
  if M._did_setup then
    return
  end
  M._did_setup = true

  api.nvim_create_user_command("Pack", function(opts)
    open()
    if opts.args == "check" then
      check_updates()
    elseif opts.args == "update" or opts.args == "update-all" then
      close()
      vim.pack.update()
    end
  end, {
    nargs = "?",
    complete = function()
      return { "check", "update", "update-all" }
    end,
    desc = "Open vim.pack plugin manager UI",
  })

  api.nvim_create_user_command("PackUpdate", function(opts)
    vim.pack.update(#opts.fargs > 0 and opts.fargs or nil)
  end, {
    nargs = "*",
    complete = complete_plugin_names,
    desc = "Check for vim.pack plugin updates",
  })
end

M[1] = {
  name = "pack-ui",
  config = function()
    M.setup()
  end,
}

return M
