local M = {}

local function source_path(level)
  local info = debug.getinfo(level or 1, "S")
  if not info or type(info.source) ~= "string" then
    return nil
  end
  return info.source:sub(1, 1) == "@" and info.source:sub(2) or nil
end

local CONFIG_ROOT = vim.fs.normalize(vim.fs.joinpath(vim.fs.dirname(assert(source_path(1), "missing module source")), "..", ".."))

local state = {
  plugins = {},
  order = {},
  raw = {},
  configured = {},
  setup_ran = false,
}

-- This loader preserves the repo's declaration shape (merged specs, opts,
-- dependencies, and keys), but otherwise follows native vim.pack behavior.

local DISABLED_BUILTINS = {
  "gzip",
  "tarPlugin",
  "tohtml",
  "tutor",
  "zipPlugin",
}

local function notify(msg, level, opts)
  vim.notify(msg, level or vim.log.levels.INFO, opts or { title = "config.pack" })
end

local function listify(value)
  if value == nil then
    return {}
  end
  if type(value) == "table" and not vim.islist(value) then
    return { value }
  end
  if type(value) == "table" then
    return vim.deepcopy(value)
  end
  return { value }
end

local function looks_like_source(value)
  if type(value) ~= "string" then
    return false
  end
  return value:find("^[%w.+-]+://") ~= nil
    or value:find("^git@") ~= nil
    or value:find("^ssh://") ~= nil
    or value:find("^[%w_.-]+/[%w_.-]+$") ~= nil
end

local function normalize_source(src)
  if not src then
    return nil
  end
  if src:find("^[%w.+-]+://") ~= nil or src:find("^git@") ~= nil or src:find("^ssh://") ~= nil then
    return src
  end
  if src:find("^[%w_.-]+/[%w_.-]+$") ~= nil then
    return ("https://github.com/%s"):format(src)
  end
  return src
end

local function derive_name(src)
  local tail = src:gsub("/+$", ""):match("([^/]+)$") or src
  return tail:gsub("%.git$", "")
end

local function is_single_spec(spec)
  if type(spec) ~= "table" then
    return false
  end
  return spec.src ~= nil
    or type(spec[1]) == "string"
    or spec.name ~= nil
    or spec.opts ~= nil
    or spec.config ~= nil
    or spec.init ~= nil
    or spec.keys ~= nil
    or spec.dependencies ~= nil
    or spec.optional ~= nil
end

local function append_path(path, key)
  local new_path = vim.deepcopy(path)
  new_path[#new_path + 1] = key
  return new_path
end

local function split_pattern(pattern)
  return vim.split(pattern or "", ".", { plain = true, trimempty = true })
end

local function path_matches(path, pattern)
  local parts = split_pattern(pattern)
  if #parts ~= #path then
    return false
  end
  for index, part in ipairs(parts) do
    if part ~= "*" and tostring(path[index]) ~= part then
      return false
    end
  end
  return true
end

local function should_extend(path, patterns)
  for _, pattern in ipairs(patterns or {}) do
    if path_matches(path, pattern) then
      return true
    end
  end
  return false
end

local function merge_opts(dst, src, extend_patterns, path)
  if src == nil then
    return dst
  end
  if dst == nil then
    return vim.deepcopy(src)
  end

  if type(dst) ~= "table" or type(src) ~= "table" then
    return vim.deepcopy(src)
  end

  local dst_is_list = vim.islist(dst)
  local src_is_list = vim.islist(src)
  if dst_is_list or src_is_list then
    if dst_is_list and src_is_list and should_extend(path, extend_patterns) then
      local result = vim.deepcopy(dst)
      vim.list_extend(result, vim.deepcopy(src))
      return result
    end
    return vim.deepcopy(src)
  end

  local result = vim.deepcopy(dst)
  for key, value in pairs(src) do
    result[key] = merge_opts(result[key], value, extend_patterns, append_path(path, key))
  end
  return result
end

local function normalize_version(raw)
  if raw.commit then
    return raw.commit
  end
  if raw.branch then
    return raw.branch
  end
  if raw.version == false or raw.version == nil then
    return nil
  end
  if type(raw.version) == "string" and raw.version:find("[%*<>=~%^]") then
    local ok, range = pcall(vim.version.range, raw.version)
    if ok then
      return range
    end
  end
  return raw.version
end

local function compare_plugins(a, b)
  if a.priority == b.priority then
    return a.name < b.name
  end
  return a.priority > b.priority
end

local function register_raw(spec, meta)
  if type(spec) == "string" then
    spec = { spec }
  end
  if type(spec) ~= "table" then
    return nil
  end

  local raw = vim.deepcopy(spec)
  raw._origin = meta and meta.origin or ""
  raw._dependencies = {}
  state.raw[#state.raw + 1] = raw

  local nested = raw.specs
  raw.specs = nil
  for _, nested_spec in ipairs(listify(nested)) do
    register_raw(nested_spec, { origin = raw._origin })
  end

  local dependencies = raw.dependencies
  raw.dependencies = nil
  for _, dependency in ipairs(listify(dependencies)) do
    local dep_raw = register_raw(dependency, { origin = raw._origin })
    if dep_raw then
      raw._dependencies[#raw._dependencies + 1] = dep_raw
    end
  end

  return raw
end

local function collect_module_specs(value, origin)
  if is_single_spec(value) then
    register_raw(value, { origin = origin })
    return
  end

  for _, spec in ipairs(value or {}) do
    collect_module_specs(spec, origin)
  end
end

local function discover_specs()
  state.raw = {}
  local files = vim.fn.readdir(CONFIG_ROOT .. "/lua/plugins")
  table.sort(files)
  for _, file in ipairs(files) do
    if file:sub(-4) == ".lua" then
      collect_module_specs(require("plugins." .. file:gsub("%.lua$", "")), file)
    end
  end
end

local function resolve_specs()
  local alias_map = {}
  for _, raw in ipairs(state.raw) do
    local locator = raw.src or raw[1]
    if raw.src or looks_like_source(locator) then
      raw._source = normalize_source(raw.src or locator)
      raw._name = raw.name or derive_name(raw._source)
      alias_map[raw._name] = raw._name
      if type(locator) == "string" then
        alias_map[locator] = raw._name
      end
    elseif raw.name then
      raw._name = raw.name
      alias_map[raw._name] = raw._name
    end
  end

  for _, raw in ipairs(state.raw) do
    if not raw._name then
      raw._name = alias_map[raw.src or raw[1]]
    end
  end

  local groups = {}
  for _, raw in ipairs(state.raw) do
    if raw._name then
      groups[raw._name] = groups[raw._name] or { has_base = false }
      if not raw.optional then
        groups[raw._name].has_base = true
      end
    elseif not raw.optional then
      notify(("Skipping unresolved plugin reference from %s"):format(raw._origin), vim.log.levels.WARN)
    end
  end

  state.plugins = {}
  state.order = {}
  state.configured = {}
  local seen = {}

  for _, raw in ipairs(state.raw) do
    local name = raw._name
    local group = name and groups[name] or nil
    if name and group and not (raw.optional and not group.has_base) then
      local plugin = state.plugins[name]
      if not plugin then
        plugin = {
          name = name,
          src = nil,
          version = nil,
          priority = 0,
          opts_extend = {},
          opts_specs = {},
          config_specs = {},
          init_specs = {},
          build_specs = {},
          keys = {},
          dependencies = {},
          desc = nil,
          main = nil,
        }
        state.plugins[name] = plugin
      end

      plugin.priority = math.max(plugin.priority, raw.priority or 0)
      plugin.desc = plugin.desc or raw.desc
      plugin.main = plugin.main or raw.main

      if raw._source then
        plugin.src = plugin.src or raw._source
      end

      local version = normalize_version(raw)
      if version ~= nil then
        plugin.version = version
      end

      for _, pattern in ipairs(listify(raw.opts_extend)) do
        plugin.opts_extend[#plugin.opts_extend + 1] = pattern
      end
      if raw.opts ~= nil then
        plugin.opts_specs[#plugin.opts_specs + 1] = raw.opts
      end
      if raw.config ~= nil then
        plugin.config_specs[#plugin.config_specs + 1] = raw.config
      end
      if raw.init ~= nil then
        plugin.init_specs[#plugin.init_specs + 1] = raw.init
      end
      if raw.build ~= nil then
        plugin.build_specs[#plugin.build_specs + 1] = raw.build
      end
      for _, key_spec in ipairs(listify(raw.keys)) do
        plugin.keys[#plugin.keys + 1] = key_spec
      end
      for _, dep_raw in ipairs(raw._dependencies) do
        local dep_name = dep_raw._name
        local dep_group = dep_name and groups[dep_name] or nil
        if dep_name and dep_group and dep_group.has_base and not vim.tbl_contains(plugin.dependencies, dep_name) then
          plugin.dependencies[#plugin.dependencies + 1] = dep_name
        end
      end

      if not seen[name] then
        seen[name] = true
        state.order[#state.order + 1] = plugin
      end
    end
  end
  table.sort(state.order, compare_plugins)
end

local function ensure_packpath()
  local site = vim.fs.normalize(vim.fn.stdpath("data") .. "/site")
  local packpath = vim.opt.packpath:get()
  if not vim.tbl_contains(packpath, site) then
    vim.opt.packpath:append(site)
  end
end

local function guess_main(plugin)
  if plugin.main then
    return plugin.main
  end
  if plugin.name:match("^mini%.") then
    return plugin.name
  end
  local guess = plugin.name:gsub("%.nvim$", "")
  guess = guess:gsub("^nvim%-", "")
  return guess ~= "" and guess or nil
end

function M.is_registered(name)
  return state.plugins[name] ~= nil
end

function M.plugin_opts(name)
  local plugin = state.plugins[name]
  if not plugin then
    return nil
  end
  if plugin._opts_resolved then
    return plugin._opts
  end

  local opts = {}
  local have_opts = false
  for _, spec in ipairs(plugin.opts_specs) do
    have_opts = true
    if type(spec) == "function" then
      local result = spec(plugin, opts)
      if result ~= nil then
        opts = result
      end
    else
      opts = merge_opts(opts, spec, plugin.opts_extend, {})
    end
  end

  plugin._opts = have_opts and opts or nil
  plugin._opts_resolved = true
  return plugin._opts
end

local function default_config(plugin, opts)
  if opts == nil then
    return
  end

  local main = guess_main(plugin)
  if not main then
    return
  end

  local ok, module = pcall(require, main)
  if not ok then
    notify(("Failed to load %s for %s: %s"):format(main, plugin.name, module), vim.log.levels.ERROR)
    return
  end

  if type(module.setup) == "function" then
    module.setup(opts)
  end
end

local function configure_plugin(plugin, visiting)
  if state.configured[plugin.name] then
    return
  end
  visiting = visiting or {}
  if visiting[plugin.name] then
    return
  end
  visiting[plugin.name] = true

  local deps = {}
  for _, dep_name in ipairs(plugin.dependencies) do
    local dep = state.plugins[dep_name]
    if dep then
      deps[#deps + 1] = dep
    end
  end
  table.sort(deps, compare_plugins)
  for _, dep in ipairs(deps) do
    configure_plugin(dep, visiting)
  end

  local opts = M.plugin_opts(plugin.name)
  if #plugin.config_specs > 0 then
    for _, config in ipairs(plugin.config_specs) do
      config(plugin, opts)
    end
  else
    default_config(plugin, opts)
  end

  state.configured[plugin.name] = true
  visiting[plugin.name] = nil
end

local function register_keymap(key_spec)
  local lhs = key_spec[1]
  local rhs = key_spec[2]
  if type(lhs) ~= "string" or (type(rhs) ~= "function" and type(rhs) ~= "string") then
    return
  end

  local mode = key_spec.mode or "n"
  local map_opts = {
    desc = key_spec.desc,
    expr = key_spec.expr,
    nowait = key_spec.nowait,
    remap = key_spec.remap,
    silent = key_spec.silent ~= false,
  }

  if key_spec.ft then
    vim.api.nvim_create_autocmd("FileType", {
      group = state.keymap_group,
      pattern = key_spec.ft,
      callback = function(event)
        vim.keymap.set(mode, lhs, rhs, vim.tbl_extend("force", map_opts, { buffer = event.buf }))
      end,
    })
    return
  end

  vim.keymap.set(mode, lhs, rhs, map_opts)
end

local function register_build_hooks()
  vim.api.nvim_create_autocmd("PackChanged", {
    group = state.build_group,
    callback = function(event)
      local data = event.data or {}
      local spec = data.spec or {}
      local plugin = state.plugins[spec.name]
      if not plugin or (data.kind ~= "install" and data.kind ~= "update") then
        return
      end

      if not data.active then
        pcall(vim.cmd.packadd, spec.name)
      end
      for _, build in ipairs(plugin.build_specs) do
        if type(build) == "string" then
          vim.cmd(build:match("^:") and build:sub(2) or build)
        elseif type(build) == "function" then
          build(plugin)
        end
      end
    end,
  })
end

local function bootstrap_plugins()
  discover_specs()
  resolve_specs()

  state.build_group = vim.api.nvim_create_augroup("config_pack_builds", { clear = true })
  state.keymap_group = vim.api.nvim_create_augroup("config_pack_keymaps", { clear = true })

  register_build_hooks()

  for _, plugin in ipairs(state.order) do
    for _, init in ipairs(plugin.init_specs) do
      init(plugin)
    end
  end

  local specs = {}
  for _, plugin in ipairs(state.order) do
    if plugin.src then
      specs[#specs + 1] = {
        src = plugin.src,
        name = plugin.name,
        version = plugin.version,
        data = { desc = plugin.desc },
      }
    end
  end

  vim.pack.add(specs, {
    load = true,
    confirm = false,
  })

  for _, plugin in ipairs(state.order) do
    configure_plugin(plugin)
  end
  for _, plugin in ipairs(state.order) do
    for _, key_spec in ipairs(plugin.keys) do
      register_keymap(key_spec)
    end
  end
end

function M.open_undotree()
  vim.cmd.packadd("nvim.undotree")
  vim.cmd.Undotree()
end

function M.setup()
  if state.setup_ran then
    return
  end
  state.setup_ran = true

  local ok, pack = pcall(function()
    return vim.pack
  end)
  if (not ok or not pack) and package.loaded["vim.pack"] == nil then
    ok, pack = pcall(require, "vim.pack")
  end
  if not ok or not pack then
    error("This config requires Neovim 0.12 with the bundled vim.pack runtime")
  end
  vim.pack = pack

  ensure_packpath()
  for _, plugin in ipairs(DISABLED_BUILTINS) do
    vim.g["loaded_" .. plugin] = 1
  end

  require("config.options")
  require("config.root").setup()
  require("config.util")

  bootstrap_plugins()

  require("config.format").setup()
  require("config.autocmds")
  require("config.keymaps")
end

return M
