return {
  "folke/which-key.nvim",
  opts_extend = { "spec" },
  opts = {
    preset = "helix",
    delay = 200,
    sort = { "local", "group", "alphanum" },
    spec = {
      {
        mode = { "n", "x" },
        { "<leader><tab>", group = "tabs",     icon = { icon = "󰓩", color = "blue"   } },
        { "<leader>c",      group = "code",     icon = { icon = "󰅱", color = "cyan"   } },
        { "<leader>d",      group = "debug",    icon = { icon = "", color = "red"    } },
        { "<leader>dp",     group = "profiler", icon = { icon = "󰙨", color = "orange" } },
        { "<leader>f",      group = "file",     icon = { icon = "󰈔", color = "green"  } },
        { "<leader>g",      group = "git",      icon = { icon = "󰊢", color = "orange" } },
        { "<leader>gh",     group = "hunks",    icon = { icon = "󰊢", color = "yellow" } },
        { "<leader>q",      group = "session",  icon = { icon = "󰿅", color = "red"    } },
        { "<leader>s",      group = "search",   icon = { icon = "󰍉", color = "blue"   } },
        { "<leader>u",      group = "ui",       icon = { icon = "󰙵", color = "purple" } },
        { "<leader>x",      group = "diagnostics", icon = { icon = "󱖫", color = "red" } },
        { "<leader>9",      group = "ai",       icon = { icon = "󰧑", color = "green"  } },
        { "[",              group = "prev",     icon = { icon = "󰒮", color = "blue"   } },
        { "]",              group = "next",     icon = { icon = "󰒭", color = "blue"   } },
        { "g",              group = "goto",     icon = { icon = "󰁔", color = "cyan"   } },
        { "z",              group = "fold",     icon = { icon = "󰐕", color = "purple" } },
        {
          "<leader>b",
          group = "buffer",
          icon = { icon = "󰓩", color = "blue" },
          expand = function()
            return require("which-key.extras").expand.buf()
          end,
        },
        {
          "<leader>w",
          group = "windows",
          icon = { icon = "󰖯", color = "blue" },
          proxy = "<c-w>",
          expand = function()
            return require("which-key.extras").expand.win()
          end,
        },
        { "gx", desc = "Open URL", icon = { icon = "󰌷", color = "cyan" } },
      },
      {
        mode = { "n", "x", "o" },
        { "s", group = "surround", icon = { icon = "󰐅", color = "yellow" } },
        { "<space>", group = "leader", icon = { icon = "󰘳", color = "purple" } },
      },
    },
    icons = {
      group = "+",
      separator = "➜",
      breadcrumb = "»",
      rules = {
        -- Search / Find / Grep  (single consistent icon)
        { pattern = "live grep", icon = "󰍉", color = "blue" },
        { pattern = "grep", icon = "󰍉", color = "blue" },
        { pattern = "search", icon = "󰍉", color = "blue" },
        { pattern = "find files", icon = "󰍉", color = "blue" },
        { pattern = "find buffer", icon = "󰍉", color = "blue" },
        { pattern = "find", icon = "󰍉", color = "blue" },

        -- Git
        { pattern = "git diff", icon = "󰊢", color = "orange" },
        { pattern = "git stash", icon = "󰊢", color = "orange" },
        { pattern = "git status", icon = "󰊢", color = "orange" },
        { pattern = "git log", icon = "󰊢", color = "orange" },
        { pattern = "git browse", icon = "󰊢", color = "orange" },
        { pattern = "git blame", icon = "󰊢", color = "orange" },
        { pattern = "git file", icon = "󰊢", color = "orange" },
        { pattern = "git", icon = "󰊢", color = "orange" },

        -- Files / Buffers / Explorer / Scratch
        { pattern = "scratch", icon = "󰓂", color = "grey" },
        { pattern = "explore", icon = "󰙅", color = "green" },
        { pattern = "buffer", icon = "󰓩", color = "blue" },
        { pattern = "file", icon = "󰈔", color = "cyan" },

        -- Picker helpers
        { pattern = "resume", icon = "󰦖", color = "green" },
        { pattern = "project", icon = "󰉿", color = "green" },
        { pattern = "recent", icon = "󰋚", color = "grey" },
        { pattern = "config", icon = "󰒓", color = "grey" },

        -- Code / LSP
        { pattern = "code action", icon = "󰅱", color = "cyan" },
        { pattern = "organize", icon = "󰉢", color = "green" },
        { pattern = "rename", icon = "󰑕", color = "yellow" },
        { pattern = "hover", icon = "󰙵", color = "cyan" },
        { pattern = "signature", icon = "󰷉", color = "yellow" },
        { pattern = "incoming", icon = "󰈀", color = "green" },
        { pattern = "outgoing", icon = "󰈂", color = "green" },
        { pattern = "implement", icon = "󰆧", color = "green" },
        { pattern = "reference", icon = "󰈇", color = "blue" },
        { pattern = "declar", icon = "󰙕", color = "cyan" },
        { pattern = "defin", icon = "󰙕", color = "cyan" },
        { pattern = "type", icon = "󰉿", color = "yellow" },
        { pattern = "symbol", icon = "󰒕", color = "purple" },
        { pattern = "lsp", icon = "󰒍", color = "green" },
        { pattern = "code", icon = "󰅱", color = "cyan" },

        -- Format
        { pattern = "format", icon = "󰉢", color = "green" },

        -- Diagnostics / Lists
        { pattern = "diagnostic", icon = "󱖫", color = "red" },
        { pattern = "quickfix", icon = "󰁨", color = "yellow" },
        { pattern = "location", icon = "󰁦", color = "yellow" },

        -- Terminal
        { pattern = "terminal", icon = "󰆍", color = "grey" },

        -- Tabs
        { pattern = "tab", icon = "󰓩", color = "purple" },

        -- Session / Quit
        { pattern = "session", icon = "󰿅", color = "red" },
        { pattern = "restore", icon = "󰦔", color = "green" },
        { pattern = "quit", icon = "󰿅", color = "red" },

        -- UI / Theme
        { pattern = "colorscheme", icon = "󰏘", color = "purple" },
        { pattern = "theme", icon = "󰏘", color = "purple" },
        { pattern = "zoom", icon = "󰁌", color = "purple" },
        { pattern = "zen", icon = "󰖲", color = "purple" },
        { pattern = "conceal", icon = "󰈈", color = "yellow" },
        { pattern = "spell", icon = "󰓆", color = "green" },
        { pattern = "wrap", icon = "󰖶", color = "blue" },
        { pattern = "relative", icon = "󰉼", color = "blue" },
        { pattern = "number", icon = "󰎠", color = "blue" },
        { pattern = "inlay", icon = "󰅱", color = "cyan" },
        { pattern = "inline", icon = "󰅱", color = "cyan" },
        { pattern = "dim", icon = "󰛐", color = "grey" },
        { pattern = "animate", icon = "󰔡", color = "purple" },
        { pattern = "indent", icon = "󰉿", color = "green" },
        { pattern = "scroll", icon = "󰘣", color = "blue" },
        { pattern = "profiler", icon = "󰙨", color = "orange" },
        { pattern = "dark", icon = "󰆍", color = "grey" },
        { pattern = "ui", icon = "󰙵", color = "cyan" },

        -- Debug
        { pattern = "breakpoint", icon = "󰯯", color = "red" },
        { pattern = "step", icon = "󰆏", color = "blue" },
        { pattern = "eval", icon = "󰅱", color = "cyan" },
        { pattern = "debug", icon = "", color = "red" },

        -- AI
        { pattern = "ai", icon = "󰧑", color = "green" },

        -- Toggle
        { pattern = "toggle", icon = "󰔡", color = "purple" },

        -- Navigation / Lists
        { pattern = "register", icon = "󰅇", color = "yellow" },
        { pattern = "mark", icon = "󰃀", color = "yellow" },
        { pattern = "history", icon = "󰋚", color = "grey" },
        { pattern = "jump", icon = "󰁛", color = "blue" },
        { pattern = "undo", icon = "󰕌", color = "blue" },

        -- Help / Info
        { pattern = "help", icon = "󰋖", color = "blue" },
        { pattern = "man", icon = "󰋖", color = "blue" },
        { pattern = "highlight", icon = "󰉿", color = "yellow" },
        { pattern = "icon", icon = "󰀿", color = "yellow" },
        { pattern = "keymap", icon = "󰌌", color = "blue" },
        { pattern = "autocmd", icon = "󰌌", color = "blue" },
        { pattern = "command", icon = "󰘳", color = "grey" },

        -- Notifications
        { pattern = "notify", icon = "󰂚", color = "yellow" },
        { pattern = "dismiss", icon = "󰂛", color = "yellow" },

        -- Misc
        { pattern = "url", icon = "󰌷", color = "cyan" },
        { pattern = "clipboard", icon = "󰆐", color = "yellow" },
        { pattern = "run", icon = "󰜎", color = "green" },
        { pattern = "plugin", icon = "󰒲", color = "green" },
        { pattern = "new file", icon = "󰈔", color = "green" },
        { pattern = "save", icon = "󰆓", color = "green" },
      },
    },
    disable = {
      ft = { "TelescopePrompt", "neo-tree" },
    },
  },
  keys = {
    {
      "<leader>?",
      function()
        require("which-key").show({})
      end,
      mode = "n",
      desc = "All Keymaps",
    },
    {
      "<leader>?",
      function()
        require("which-key").show({})
      end,
      mode = { "x", "o" },
      desc = "Motion Keymaps",
    },
    {
      "<c-w><space>",
      function()
        require("which-key").show({ keys = "<c-w>", loop = true })
      end,
      desc = "Window Hydra Mode",
    },
  },
  config = function(_, opts)
    require("which-key").setup(opts)
    vim.schedule(function()
      require("which-key").add({
        {
          mode = { "n", "x", "o" },
          { "sa", desc = "Add Surrounding",    icon = { icon = "󰐅", color = "yellow" } },
          { "sd", desc = "Delete Surrounding", icon = { icon = "󰐅", color = "yellow" } },
          { "sr", desc = "Replace Surrounding",icon = { icon = "󰐅", color = "yellow" } },
          { "sf", desc = "Find Surrounding →", icon = { icon = "󰁔", color = "cyan"   } },
          { "sF", desc = "Find Surrounding ←", icon = { icon = "󰒮", color = "cyan"   } },
          { "sh", desc = "Highlight Surrounding",icon = { icon = "󰉿", color = "yellow" } },
          { "sn", desc = "Update n Lines",     icon = { icon = "󰇀", color = "green"  } },
        },
      }, { notify = false })
    end)
  end,
}
