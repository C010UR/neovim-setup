local pick = require("config.pick")
local root = require("config.root")

local dashboard_splash = "lights"

local function startup_directory_arg()
  if vim.fn.argc(-1) ~= 1 then
    return nil
  end

  local arg = vim.fn.argv(0)
  if arg == "" or vim.fn.isdirectory(arg) == 0 then
    return nil
  end

  return arg
end

local function is_directory_buffer(buf)
  local name = vim.api.nvim_buf_get_name(buf)
  return vim.bo[buf].filetype == "netrw" or (name ~= "" and vim.fn.isdirectory(name) == 1)
end

local function prepare_directory_buffer_for_dashboard(buf)
  if not vim.api.nvim_buf_is_valid(buf) then
    return false
  end

  vim.bo[buf].modifiable = true
  vim.bo[buf].readonly = false
  vim.bo[buf].buflisted = false
  vim.bo[buf].buftype = ""
  vim.bo[buf].filetype = ""
  pcall(vim.api.nvim_buf_set_name, buf, "")
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "" })
  vim.bo[buf].modified = false
  return true
end

-- When Neovim starts with a single directory argument, reuse the initial directory
-- buffer so Snacks can still open its startup dashboard in buffer 1 instead of
-- leaving netrw visible.
local function schedule_directory_dashboard()
  if not startup_directory_arg() then
    return
  end

  vim.api.nvim_create_autocmd("VimEnter", {
    group = vim.api.nvim_create_augroup("config_directory_dashboard", { clear = true }),
    once = true,
    callback = function()
      if not startup_directory_arg() then
        return
      end

      local buf = vim.api.nvim_get_current_buf()
      if not is_directory_buffer(buf) or not prepare_directory_buffer_for_dashboard(buf) then
        return
      end

      require("snacks.dashboard").setup()
    end,
  })
end

local milli_ns = vim.api.nvim_create_namespace("config_milli_dashboard")

local function setup_milli_dashboard()
  local milli_opts = { splash = dashboard_splash, loop = true }

  -- Accent color (tokyonight purple)
  local function set_hl()
    vim.api.nvim_set_hl(0, "MilliDashboardAccent", { fg = "#bb9af7" })
  end
  set_hl()
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = vim.api.nvim_create_augroup("config_milli_dashboard_hl", { clear = true }),
    callback = set_hl,
  })

  -- Patch milli.play so it re-locates the anchor every frame and tints with accent.
  local runtime = require("milli.runtime")
  local _load = runtime.load

  local accent = "#bb9af7"
  local blend = 0.55

  local function hex_to_rgb(hex)
    hex = hex:gsub("#", "")
    return tonumber(hex:sub(1, 2), 16), tonumber(hex:sub(3, 4), 16), tonumber(hex:sub(5, 6), 16)
  end

  local function rgb_to_hex(r, g, b)
    return string.format("#%02x%02x%02x", r, g, b)
  end

  local function blend_hex(c1, c2, factor)
    local r1, g1, b1 = hex_to_rgb(c1)
    local r2, g2, b2 = hex_to_rgb(c2)
    return rgb_to_hex(
      math.floor(r1 * (1 - factor) + r2 * factor),
      math.floor(g1 * (1 - factor) + g2 * factor),
      math.floor(b1 * (1 - factor) + b2 * factor)
    )
  end

  local blended_hl_cache = {}
  local function get_blended_hl(fg, bg)
    local orig_fg = fg
    fg = blend_hex(fg, accent, blend)
    local key = fg .. "_" .. bg
    if blended_hl_cache[key] then
      return blended_hl_cache[key]
    end
    local bg_suffix = bg == "NONE" and "NONE" or bg:sub(2)
    local name = "MilliBlend_" .. fg:sub(2) .. "_" .. bg_suffix
    local spec = { fg = fg }
    if bg ~= "NONE" then
      spec.bg = bg
    end
    vim.api.nvim_set_hl(0, name, spec)
    blended_hl_cache[key] = name
    return name
  end

  runtime.play = function(buf, opts)
    if not buf or not vim.api.nvim_buf_is_valid(buf) then
      return
    end
    local data = _load(opts)
    local loop = opts.loop == true

    -- Find anchor in frame 0
    local first = data.frames[1]
    if not first then
      return
    end
    local anchor_idx, anchor_line
    for i, line in ipairs(first) do
      if line:find("[^%s]") then
        anchor_idx = i
        anchor_line = line
        break
      end
    end
    if not anchor_line then
      return
    end
    local anchor_trim = (anchor_line:gsub("%s+$", ""))

    local generation = (vim.b[buf].milli_generation or 0) + 1
    vim.b[buf].milli_generation = generation

    local function paint(idx)
      if not vim.api.nvim_buf_is_valid(buf) or vim.b[buf].milli_generation ~= generation then
        return
      end
      local frame = data.frames[idx + 1]
      if not frame then
        return
      end

      -- Re-locate anchor each frame so splits/resizes don't drift
      local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
      local start_row, pad
      for i, l in ipairs(lines) do
        local pos = l:find(anchor_trim, 1, true)
        if pos then
          start_row = i - anchor_idx
          pad = l:sub(1, pos - 1)
          break
        end
      end
      if not start_row then
        return
      end

      local pad_bytes = #pad
      local padded = {}
      for i, line in ipairs(frame) do
        padded[i] = pad .. line
      end

      vim.bo[buf].modifiable = true
      pcall(vim.api.nvim_buf_set_lines, buf, start_row, start_row + #padded, false, padded)
      vim.bo[buf].modified = false
      vim.bo[buf].modifiable = false

      vim.api.nvim_buf_clear_namespace(buf, milli_ns, start_row, start_row + #padded)

      if data.colors then
        local colors = data.colors[idx + 1]
        if colors then
          for row_i, row_runs in ipairs(colors) do
            local buf_row = start_row + row_i - 1
            for _, run in ipairs(row_runs) do
              local sb, eb, fg, bg = run[1], run[2], run[3], run[4]
              local hl = get_blended_hl(fg, bg)
              pcall(vim.api.nvim_buf_set_extmark, buf, milli_ns, buf_row, pad_bytes + sb, {
                end_col = pad_bytes + eb,
                hl_group = hl,
                priority = 200,
              })
            end
          end
        end
      else
        -- fallback: no color data -> single accent overlay
        for i, line in ipairs(frame) do
          if line ~= "" then
            pcall(vim.api.nvim_buf_set_extmark, buf, milli_ns, start_row + i - 1, pad_bytes, {
              end_col = pad_bytes + #line,
              hl_group = "MilliDashboardAccent",
              priority = 200,
            })
          end
        end
      end
    end

    paint(0)
    local idx = 1
    local function step()
      if not vim.api.nvim_buf_is_valid(buf) or vim.b[buf].milli_generation ~= generation then
        return
      end
      if idx >= #data.frames and not loop then
        return
      end
      local fi = idx % #data.frames
      paint(fi)
      idx = idx + 1
      vim.defer_fn(step, data.delays[fi + 1] or 100)
    end
    vim.defer_fn(step, data.delays[1] or 100)
  end

  -- Let milli handle the SnacksDashboardOpened / UpdatePost wiring.
  require("milli").snacks(milli_opts)
end

local function term_nav(dir)
  -- Reuse normal window navigation keys when a terminal is not floating.
  return function(self)
    return self:is_floating() and ("<c-" .. dir .. ">") or vim.schedule(function()
      vim.cmd.wincmd(dir)
    end)
  end
end

return {
  -- Core UI, picker, explorer, notification, and utility primitives.
  {
    "folke/snacks.nvim",
    dependencies = {
      "amansingh-afk/milli.nvim",
    },
    priority = 1000,
    opts = function()
      local splash = require("milli").load({ splash = dashboard_splash })

      return {
        bigfile = { enabled = true },
        quickfile = { enabled = true },
        terminal = {
          win = {
            keys = {
              nav_h = { "<C-h>", term_nav("h"), desc = "Go to Left Window", expr = true, mode = "t" },
              nav_j = { "<C-j>", term_nav("j"), desc = "Go to Lower Window", expr = true, mode = "t" },
              nav_k = { "<C-k>", term_nav("k"), desc = "Go to Upper Window", expr = true, mode = "t" },
              nav_l = { "<C-l>", term_nav("l"), desc = "Go to Right Window", expr = true, mode = "t" },
              hide_slash = { "<C-/>", "hide", desc = "Hide Terminal", mode = "t" },
              hide_underscore = { "<c-_>", "hide", desc = "which_key_ignore", mode = "t" },
            },
          },
        },
        indent = { enabled = true },
        input = { enabled = true },
        notifier = { enabled = true },
        scope = { enabled = true },
        scroll = { enabled = true },
        statuscolumn = { enabled = false },
        words = { enabled = true },
        image = {
          enabled = true,
          doc = {
            conceal = true,
          },
        },
        explorer = {
          enabled = true,
          replace_netrw = false,
        },
        picker = {
          enabled = true,
          hidden = true,
          ignored = true,
          win = {
            input = {
              keys = {
                ["<a-c>"] = { "toggle_cwd", mode = { "n", "i" }, desc = "Toggle Picker Root / CWD" },
                ["<a-s>"] = { "flash", mode = { "n", "i" }, desc = "Flash Picker Results" },
                ["s"] = { "flash", desc = "Flash Picker Results" },
              },
            },
          },
          actions = {
            toggle_cwd = function(picker_instance)
              local project_root = root.get({ buf = picker_instance.input.filter.current_buf, normalize = true })
              local cwd = vim.fs.normalize(vim.uv.cwd() or ".")
              local current = picker_instance:cwd()
              picker_instance:set_cwd(current == project_root and cwd or project_root)
              picker_instance:find()
            end,
            flash = function(picker_instance)
              if not package.loaded["flash"] then
                return
              end
              require("flash").jump({
                pattern = "^",
                label = { after = { 0, 0 } },
                search = {
                  mode = "search",
                  exclude = {
                    function(win)
                      return vim.bo[vim.api.nvim_win_get_buf(win)].filetype ~= "snacks_picker_list"
                    end,
                  },
                },
                action = function(match)
                  local idx = picker_instance.list:row2idx(match.pos[1])
                  picker_instance.list:_move(idx, true, true)
                end,
              })
            end,
          },
        },
        toggle = {
          map = function(mode, lhs, rhs, opts)
            vim.keymap.set(mode, lhs, rhs, opts)
          end,
        },
        dashboard = {
          enabled = true,
          sections = {
            { section = "header" },
            { section = "keys", gap = 1, padding = 1 },
          },
          preset = {
            header = table.concat(splash.frames[1], "\n"),
            keys = {
              { icon = " ", key = "f", desc = "Find Files", action = ":lua require('config.pick').open('files')" },
              { icon = " ", key = "n", desc = "Create New File", action = ":ene | startinsert" },
              {
                icon = " ",
                key = "g",
                desc = "Find Text",
                action = ":lua require('config.pick').open('live_grep')",
              },
              {
                icon = " ",
                key = "r",
                desc = "Find Recent Files",
                action = ":lua require('config.pick').open('oldfiles')",
              },
              {
                icon = " ",
                key = "c",
                desc = "Config Files",
                action = ":lua require('config.pick').open('files', { cwd = vim.fn.stdpath('config') })",
              },
              { icon = " ", key = "p", desc = "Projects", action = ":lua Snacks.picker.projects()" },
              {
                icon = " ",
                key = "s",
                desc = "Restore Session",
                action = ":lua require('persistence').load({ last = true })",
              },
              { icon = "󰒲 ", key = "l", desc = "Plugins", action = ":Pack" },
              { icon = " ", key = "q", desc = "Quit Neovim", action = ":qa" },
            },
          },
        },
      }
    end,
    keys = {
      {
        "<leader>.",
        function()
          Snacks.scratch()
        end,
        desc = "Toggle Scratch Buffer",
      },
      {
        "<leader>S",
        function()
          Snacks.scratch.select()
        end,
        desc = "Select Scratch Buffer",
      },
      {
        "<leader>dps",
        function()
          Snacks.profiler.scratch()
        end,
        desc = "Profiler Scratch",
      },
      {
        "<leader>,",
        function()
          Snacks.picker.buffers()
        end,
        desc = "Find Buffers",
      },
      { "<leader>/", pick("live_grep"), desc = "Live Grep (Root Dir)" },
      {
        "<leader>:",
        function()
          Snacks.picker.command_history()
        end,
        desc = "Command History",
      },
      { "<leader><space>", pick("files"), desc = "Find Files (Root Dir)" },
      {
        "<leader>n",
        function()
          Snacks.picker.notifications()
        end,
        desc = "Notification History",
      },
      {
        "<leader>un",
        function()
          Snacks.notifier.hide()
        end,
        desc = "Dismiss All Notifications",
      },
      {
        "<leader>fb",
        function()
          Snacks.picker.buffers()
        end,
        desc = "Find Buffers",
      },
      {
        "<leader>fB",
        function()
          Snacks.picker.buffers({ hidden = true, nofile = true })
        end,
        desc = "Find All Buffers",
      },
      { "<leader>fc", pick.config_files(), desc = "Find Config Files" },
      { "<leader>ff", pick("files"), desc = "Find Files (Root Dir)" },
      { "<leader>fF", pick("files", { root = false }), desc = "Find Files (CWD)" },
      {
        "<leader>fg",
        function()
          Snacks.picker.git_files()
        end,
        desc = "Find Git Files",
      },
      { "<leader>fr", pick("oldfiles"), desc = "Find Recent Files" },
      {
        "<leader>fR",
        function()
          Snacks.picker.recent({ filter = { cwd = true } })
        end,
        desc = "Find Recent Files (CWD)",
      },
      {
        "<leader>fp",
        function()
          Snacks.picker.projects()
        end,
        desc = "Find Projects",
      },
      {
        "<leader>gd",
        function()
          Snacks.picker.git_diff()
        end,
        desc = "Find Git Diff Hunks",
      },
      {
        "<leader>gD",
        function()
          Snacks.picker.git_diff({ base = "origin", group = true })
        end,
        desc = "Find Git Diff vs Origin",
      },
      {
        "<leader>gs",
        function()
          Snacks.picker.git_status()
        end,
        desc = "Find Git Status",
      },
      {
        "<leader>gS",
        function()
          Snacks.picker.git_stash()
        end,
        desc = "Find Git Stash",
      },
      {
        "<leader>sb",
        function()
          Snacks.picker.lines()
        end,
        desc = "Search Buffer Lines",
      },
      {
        "<leader>sB",
        function()
          Snacks.picker.grep_buffers()
        end,
        desc = "Search Open Buffers",
      },
      { "<leader>sg", pick("live_grep"), desc = "Live Grep (Root Dir)" },
      { "<leader>sG", pick("live_grep", { root = false }), desc = "Live Grep (CWD)" },
      {
        "<leader>sp",
        function()
          require("plugins.pack-ui").open()
        end,
        desc = "Plugin Manager",
      },
      { "<leader>sw", pick("grep_word"), desc = "Grep Selection or Word (Root Dir)", mode = { "n", "x" } },
      { "<leader>sW", pick("grep_word", { root = false }), desc = "Grep Selection or Word (CWD)", mode = { "n", "x" } },
      {
        '<leader>s"',
        function()
          Snacks.picker.registers()
        end,
        desc = "Registers",
      },
      {
        "<leader>s/",
        function()
          Snacks.picker.search_history()
        end,
        desc = "Search History",
      },
      {
        "<leader>sa",
        function()
          Snacks.picker.autocmds()
        end,
        desc = "Autocmds",
      },
      {
        "<leader>sc",
        function()
          Snacks.picker.command_history()
        end,
        desc = "Command History",
      },
      {
        "<leader>sC",
        function()
          Snacks.picker.commands()
        end,
        desc = "Commands",
      },
      {
        "<leader>sd",
        function()
          Snacks.picker.diagnostics()
        end,
        desc = "Find Diagnostics",
      },
      {
        "<leader>sD",
        function()
          Snacks.picker.diagnostics_buffer()
        end,
        desc = "Find Buffer Diagnostics",
      },
      {
        "<leader>sh",
        function()
          Snacks.picker.help()
        end,
        desc = "Help Pages",
      },
      {
        "<leader>sH",
        function()
          Snacks.picker.highlights()
        end,
        desc = "Highlights",
      },
      {
        "<leader>si",
        function()
          Snacks.picker.icons()
        end,
        desc = "Icons",
      },
      {
        "<leader>sj",
        function()
          Snacks.picker.jumps()
        end,
        desc = "Jumps",
      },
      {
        "<leader>sk",
        function()
          Snacks.picker.keymaps()
        end,
        desc = "Keymaps",
      },
      {
        "<leader>sl",
        function()
          Snacks.picker.loclist()
        end,
        desc = "Location List",
      },
      {
        "<leader>sM",
        function()
          Snacks.picker.man()
        end,
        desc = "Man Pages",
      },
      {
        "<leader>sm",
        function()
          Snacks.picker.marks()
        end,
        desc = "Marks",
      },
      {
        "<leader>sR",
        function()
          Snacks.picker.resume()
        end,
        desc = "Resume Last Picker",
      },
      {
        "<leader>sq",
        function()
          Snacks.picker.qflist()
        end,
        desc = "Quickfix List",
      },
      {
        "<leader>su",
        function()
          require("config.pack").open_undotree()
        end,
        desc = "Undo Tree",
      },
      {
        "<leader>uC",
        function()
          Snacks.picker.colorschemes()
        end,
        desc = "Browse Colorschemes",
      },
    },
    config = function(_, opts)
      local snacks = require("snacks")
      _G.Snacks = snacks
      snacks.setup(opts)
      schedule_directory_dashboard()
      setup_milli_dashboard()
    end,
  },
  {
    "folke/persistence.nvim",
    opts = {},
    keys = {
      {
        "<leader>qs",
        function()
          require("persistence").load()
        end,
        desc = "Restore Session",
      },
      {
        "<leader>qS",
        function()
          require("persistence").select()
        end,
        desc = "Select Session",
      },
      {
        "<leader>ql",
        function()
          require("persistence").load({ last = true })
        end,
        desc = "Restore Last Session",
      },
      {
        "<leader>qd",
        function()
          require("persistence").stop()
        end,
        desc = "Stop Saving Session",
      },
    },
  },
  { "nvim-lua/plenary.nvim" },
}
