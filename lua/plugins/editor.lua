return {
  {
    "MagicDuck/grug-far.nvim",
    opts = { headerMaxWidth = 80 },
    keys = {
      {
        "<leader>R",
        function()
          require("config.finder").replace()
        end,
        mode = { "n", "x" },
        desc = "Replace in Files (Project)",
      },
    },
  },
  {
    "folke/flash.nvim",
    opts = {},
    keys = {
      {
        "\\",
        mode = { "n", "x", "o" },
        function()
          require("flash").jump()
        end,
        desc = "Flash Jump",
      },
      {
        "|",
        mode = { "n", "o", "x" },
        function()
          require("flash").treesitter()
        end,
        desc = "Flash Treesitter Jump",
      },
      {
        "r",
        mode = "o",
        function()
          require("flash").remote()
        end,
        desc = "Flash Remote",
      },
      {
        "R",
        mode = { "o", "x" },
        function()
          require("flash").treesitter_search()
        end,
        desc = "Flash Treesitter Search",
      },
      {
        "<c-s>",
        mode = { "c" },
        function()
          require("flash").toggle()
        end,
        desc = "Toggle Flash Search",
      },
      {
        "<c-space>",
        mode = { "n", "o", "x" },
        function()
          require("flash").treesitter({ actions = { ["<c-space>"] = "next", ["<BS>"] = "prev" } })
        end,
        desc = "Flash Treesitter Selection",
      },
    },
  },
  {
    "folke/snacks.nvim",
    optional = true,
    keys = {
      {
        "<leader>xx",
        function()
          Snacks.picker.diagnostics()
        end,
        desc = "Find Diagnostics",
      },
      {
        "<leader>xX",
        function()
          Snacks.picker.diagnostics_buffer()
        end,
        desc = "Find Buffer Diagnostics",
      },
      {
        "<leader>cs",
        function()
          Snacks.picker.lsp_symbols({ filter = require("config.lsp").kind_filter })
        end,
        desc = "Document Symbols",
      },
      {
        "[q",
        function()
          local ok, err = pcall(vim.cmd.cprev)
          if not ok then
            vim.notify(err, vim.log.levels.ERROR)
          end
        end,
        desc = "Prev Quickfix Item",
      },
      {
        "]q",
        function()
          local ok, err = pcall(vim.cmd.cnext)
          if not ok then
            vim.notify(err, vim.log.levels.ERROR)
          end
        end,
        desc = "Next Quickfix Item",
      },
    },
  },
  {
    "folke/todo-comments.nvim",
    opts = {},
    keys = {
      {
        "]t",
        function()
          require("todo-comments").jump_next()
        end,
        desc = "Next Todo Comment",
      },
      {
        "[t",
        function()
          require("todo-comments").jump_prev()
        end,
        desc = "Prev Todo Comment",
      },
      {
        "<leader>xT",
        function()
          Snacks.picker.todo_comments({ keywords = { "TODO", "FIX", "FIXME" } })
        end,
        desc = "TODO / FIXME List",
      },
    },
  },
  {
    "nvim-mini/mini.move",
    opts = {},
  },
}
