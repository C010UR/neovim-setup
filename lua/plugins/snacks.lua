local pick = require("config.pick")
local root = require("config.root")

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
    priority = 1000,
    opts = {
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
      explorer = {
        enabled = true,
        replace_netrw = true,
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
        preset = {
          pick = function(cmd, opts)
            return pick(cmd, opts)()
          end,
          header = [[
███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗
████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║
██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║
██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║
██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║
╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝]],
          keys = {
            { icon = " ", key = "f", desc = "Find Files", action = ":lua Snacks.dashboard.pick('files')" },
            { icon = " ", key = "n", desc = "Create New File", action = ":ene | startinsert" },
            { icon = " ", key = "g", desc = "Find Text", action = ":lua Snacks.dashboard.pick('live_grep')" },
            { icon = " ", key = "r", desc = "Open Recent Files", action = ":lua Snacks.dashboard.pick('oldfiles')" },
            { icon = " ", key = "c", desc = "Open Config", action = ":lua Snacks.dashboard.pick('files', { cwd = vim.fn.stdpath('config') })" },
            { icon = " ", key = "p", desc = "Open Projects", action = ":lua Snacks.picker.projects()" },
            { icon = " ", key = "s", desc = "Restore Session", section = "session" },
            { icon = "󰒲 ", key = "l", desc = "Open Plugins", action = ":Pack" },
            { icon = " ", key = "q", desc = "Quit Neovim", action = ":qa" },
          },
        },
      },
    },
    keys = {
      { "<leader>.", function() Snacks.scratch() end, desc = "Toggle Scratch Buffer" },
      { "<leader>S", function() Snacks.scratch.select() end, desc = "Select Scratch Buffer" },
      { "<leader>dps", function() Snacks.profiler.scratch() end, desc = "Open Profiler Scratch Buffer" },
      { "<leader>,", function() Snacks.picker.buffers() end, desc = "Open Buffers" },
      { "<leader>/", pick("live_grep"), desc = "Live Grep (Root Dir)" },
      { "<leader>:", function() Snacks.picker.command_history() end, desc = "Open Command History" },
      { "<leader><space>", pick("files"), desc = "Find Files (Root Dir)" },
      { "<leader>n", function() Snacks.picker.notifications() end, desc = "Open Notification History" },
      { "<leader>un", function() Snacks.notifier.hide() end, desc = "Dismiss All Notifications" },
      { "<leader>fb", function() Snacks.picker.buffers() end, desc = "Open Buffers" },
      { "<leader>fB", function() Snacks.picker.buffers({ hidden = true, nofile = true }) end, desc = "Open All Buffers" },
      { "<leader>fc", pick.config_files(), desc = "Find Config Files" },
      { "<leader>ff", pick("files"), desc = "Find Files (Root Dir)" },
      { "<leader>fF", pick("files", { root = false }), desc = "Find Files (CWD)" },
      { "<leader>fg", function() Snacks.picker.git_files() end, desc = "Find Git Files" },
      { "<leader>fr", pick("oldfiles"), desc = "Open Recent Files" },
      { "<leader>fR", function() Snacks.picker.recent({ filter = { cwd = true } }) end, desc = "Open Recent Files (CWD)" },
      { "<leader>fp", function() Snacks.picker.projects() end, desc = "Open Projects" },
      { "<leader>gd", function() Snacks.picker.git_diff() end, desc = "Open Git Diff Hunks" },
      { "<leader>gD", function() Snacks.picker.git_diff({ base = "origin", group = true }) end, desc = "Open Git Diff vs Origin" },
      { "<leader>gs", function() Snacks.picker.git_status() end, desc = "Open Git Status" },
      { "<leader>gS", function() Snacks.picker.git_stash() end, desc = "Open Git Stash" },
      { "<leader>sb", function() Snacks.picker.lines() end, desc = "Search Buffer Lines" },
      { "<leader>sB", function() Snacks.picker.grep_buffers() end, desc = "Search Open Buffers" },
      { "<leader>sg", pick("live_grep"), desc = "Live Grep (Root Dir)" },
      { "<leader>sG", pick("live_grep", { root = false }), desc = "Live Grep (CWD)" },
      { "<leader>sp", function() require("config.pack").open() end, desc = "Open Plugin Manager" },
      { "<leader>sw", pick("grep_word"), desc = "Grep Selection or Word (Root Dir)", mode = { "n", "x" } },
      { "<leader>sW", pick("grep_word", { root = false }), desc = "Grep Selection or Word (CWD)", mode = { "n", "x" } },
      { '<leader>s"', function() Snacks.picker.registers() end, desc = "Open Registers" },
      { '<leader>s/', function() Snacks.picker.search_history() end, desc = "Open Search History" },
      { "<leader>sa", function() Snacks.picker.autocmds() end, desc = "Open Autocmds" },
      { "<leader>sc", function() Snacks.picker.command_history() end, desc = "Open Command History" },
      { "<leader>sC", function() Snacks.picker.commands() end, desc = "Open Commands" },
      { "<leader>sd", function() Snacks.picker.diagnostics() end, desc = "Open Diagnostics" },
      { "<leader>sD", function() Snacks.picker.diagnostics_buffer() end, desc = "Open Buffer Diagnostics" },
      { "<leader>sh", function() Snacks.picker.help() end, desc = "Open Help Pages" },
      { "<leader>sH", function() Snacks.picker.highlights() end, desc = "Open Highlights" },
      { "<leader>si", function() Snacks.picker.icons() end, desc = "Open Icons" },
      { "<leader>sj", function() Snacks.picker.jumps() end, desc = "Open Jumps" },
      { "<leader>sk", function() Snacks.picker.keymaps() end, desc = "Open Keymaps" },
      { "<leader>sl", function() Snacks.picker.loclist() end, desc = "Open Location List" },
      { "<leader>sM", function() Snacks.picker.man() end, desc = "Open Man Pages" },
      { "<leader>sm", function() Snacks.picker.marks() end, desc = "Open Marks" },
      { "<leader>sR", function() Snacks.picker.resume() end, desc = "Resume Last Picker" },
      { "<leader>sq", function() Snacks.picker.qflist() end, desc = "Open Quickfix List" },
      { "<leader>su", function() require("config.pack").open_undotree() end, desc = "Open Undo Tree" },
      { "<leader>uC", function() Snacks.picker.colorschemes() end, desc = "Browse Colorschemes" },
    },
    config = function(_, opts)
      local snacks = require("snacks")
      _G.Snacks = snacks
      snacks.setup(opts)
    end,
  },
  {
    "folke/persistence.nvim",
    opts = {},
    keys = {
      { "<leader>qs", function() require("persistence").load() end, desc = "Restore Session" },
      { "<leader>qS", function() require("persistence").select() end, desc = "Select Session" },
      { "<leader>ql", function() require("persistence").load({ last = true }) end, desc = "Restore Last Session" },
      { "<leader>qd", function() require("persistence").stop() end, desc = "Stop Saving Session" },
    },
  },
  { "nvim-lua/plenary.nvim" },
}
