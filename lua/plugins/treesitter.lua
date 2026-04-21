return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    version = false,
    build = ":TSUpdate",
    dependencies = { "neovim-treesitter/treesitter-parser-registry" },
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
      highlight = true,
      indent = true,
      folds = true,
    },
    config = function(_, opts)
      local ts = require("nvim-treesitter")
      local interactive = #vim.api.nvim_list_uis() > 0
      if interactive then
        ts.install(opts.ensure_installed)
      end

      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("config_treesitter_features", { clear = true }),
        callback = function(event)
          local ok = true
          if opts.highlight then
            ok = pcall(vim.treesitter.start, event.buf)
          end
          if not ok then
            return
          end

          if opts.folds then
            local win = vim.fn.bufwinid(event.buf)
            if win ~= -1 and vim.wo[win].foldmethod == "indent" then
              vim.wo[win].foldmethod = "expr"
              vim.wo[win].foldexpr = "v:lua.vim.treesitter.foldexpr()"
            end
          end

          if opts.indent then
            vim.bo[event.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
          end
        end,
      })
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    branch = "main",
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
