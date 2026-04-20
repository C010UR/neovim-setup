return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    commit = vim.fn.has("nvim-0.12") == 0 and "7caec274fd19c12b55902a5b795100d21531391f" or nil,
    version = false,
    build = ":TSUpdate",
    event = { "LazyFile", "VeryLazy" },
    cmd = { "TSUpdate", "TSInstall", "TSLog", "TSUninstall" },
    opts_extend = { "ensure_installed" },
    opts = {
      ensure_installed = {
        "bash",
        "c",
        "diff",
        "html",
        "javascript",
        "jsdoc",
        "json",
        "lua",
        "luadoc",
        "luap",
        "markdown",
        "markdown_inline",
        "printf",
        "python",
        "query",
        "regex",
        "toml",
        "tsx",
        "typescript",
        "vim",
        "vimdoc",
        "xml",
        "yaml",
      },
      auto_install = true,
      highlight = { enable = true },
      indent = { enable = true },
    },
    config = function(_, opts)
      local ok, ts = pcall(require, "nvim-treesitter")
      if ok and ts.setup then
        ts.setup(opts)
      else
        require("nvim-treesitter.configs").setup(opts)
      end
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    branch = "main",
    event = "VeryLazy",
    opts = {
      move = {
        enable = true,
        set_jumps = true,
        goto_next_start = { ["]f"] = "@function.outer", ["]c"] = "@class.outer", ["]a"] = "@parameter.inner" },
        goto_next_end = { ["]F"] = "@function.outer", ["]C"] = "@class.outer", ["]A"] = "@parameter.inner" },
        goto_previous_start = { ["[f"] = "@function.outer", ["[c"] = "@class.outer", ["[a"] = "@parameter.inner" },
        goto_previous_end = { ["[F"] = "@function.outer", ["[C"] = "@class.outer", ["[A"] = "@parameter.inner" },
      },
    },
    config = function(_, opts)
      local ok, textobjects = pcall(require, "nvim-treesitter-textobjects")
      if ok and textobjects.setup then
        textobjects.setup(opts)
      else
        require("nvim-treesitter.configs").setup({ textobjects = opts })
      end
    end,
  },
  {
    "windwp/nvim-ts-autotag",
    event = "LazyFile",
    opts = {},
  },
  {
    "nvim-treesitter/nvim-treesitter-context",
    opts = {
      enabled = true,
      max_lines = 6,
      trim_scope = "outer",
      mode = "cursor",
      line_numbers = true,
    },
  },
}
