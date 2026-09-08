local finder = require("config.finder")
local root = require("config.root")

local dashboard_splash = "lights"
local fallback_splash = "fire"

local function resolve_splash()
  local ok, splash = pcall(require("milli").load, { splash = dashboard_splash })
  if ok and splash and splash.frames then
    return splash, dashboard_splash
  end
  vim.notify(
    ("milli.nvim: splash %q not found, falling back to %q (try :MilliInstall %s)"):format(
      dashboard_splash,
      fallback_splash,
      dashboard_splash
    ),
    vim.log.levels.WARN
  )
  return require("milli").load({ splash = fallback_splash }), fallback_splash
end

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

local function setup_milli_dashboard()
  local _, active_splash = resolve_splash()
  -- Use milli's built-in renderer and its own splash colors.
  require("milli").snacks({ splash = active_splash, loop = true })
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
      local splash = resolve_splash()

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
          -- Finder scope: fff-backed files/grep + everywhere, uniform with
          -- the built-in sources (see lua/config/finder/init.lua).
          sources = finder.sources(),
          win = {
            input = {
              keys = {
                ["<a-c>"] = { "toggle_cwd", mode = { "n", "i" }, desc = "Toggle Picker Root / CWD" },
                ["<a-s>"] = { "flash", mode = { "n", "i" }, desc = "Flash Picker Results" },
                ["<c-q>"] = { "results_open", mode = { "n", "i" }, desc = "Results to Quickfix Buffer" },
                ["<a-t>"] = { "results_open", mode = { "n", "i" }, desc = "Results to Quickfix Buffer" },
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
            -- <c-q> / <a-t>: send results to the quickfix buffer. Also tear
            -- down the dashboard (it is a *floating* window — left alone it
            -- stays on top and every quickfix jump looks like a new split),
            -- then attach the first result to the main window when it is
            -- transient (dashboard background / empty buffer).
            results_open = function(picker_instance)
              require("snacks.picker.actions").qflist(picker_instance)

              vim.schedule(function()
                for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
                  local cfg = vim.api.nvim_win_get_config(w)
                  if cfg.relative ~= "" then
                    local ft = vim.bo[vim.api.nvim_win_get_buf(w)].filetype
                    if ft == "snacks_dashboard" or ft == "snacks_win_backdrop" then
                      pcall(vim.api.nvim_win_close, w, true)
                    end
                  end
                end

                local main_win
                for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
                  if vim.api.nvim_win_get_config(w).relative == "" then
                    local b = vim.api.nvim_win_get_buf(w)
                    if vim.bo[b].buftype ~= "quickfix" then
                      main_win = w
                      break
                    end
                  end
                end

                if main_win then
                  local b = vim.api.nvim_win_get_buf(main_win)
                  local transient = vim.bo[b].buftype ~= ""
                    or vim.bo[b].filetype == "snacks_dashboard"
                    or (vim.api.nvim_buf_get_name(b) == "" and not vim.bo[b].modified)
                  if transient then
                    vim.api.nvim_win_call(main_win, function()
                      pcall(vim.cmd, "cfirst")
                    end)
                  end
                end
              end)
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
              { icon = " ", key = "f", desc = "Find Files", action = ":lua require('config.finder').open('files')" },
              { icon = " ", key = "n", desc = "Create New File", action = ":ene | startinsert" },
              {
                icon = " ",
                key = "g",
                desc = "Grep",
                action = ":lua require('config.finder').open('grep')",
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
        "<leader><space>",
        finder.wrap("grep"),
        desc = "Grep (Project)",
      },
      {
        "<leader>:",
        function()
          Snacks.picker.command_history()
        end,
        desc = "Command History",
      },
      { "<leader>/", finder.wrap("files"), desc = "Find Files (Root Dir)" },
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
        "<leader>a",
        function()
          Snacks.picker.commands()
        end,
        desc = "Commands & Actions",
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
        "<leader>U",
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
