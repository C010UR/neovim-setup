return {
  { "b0o/schemastore.nvim", lazy = true },
  {
    "nvim-treesitter/nvim-treesitter",
    opts = { ensure_installed = { "yaml" } },
  },
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "b0o/schemastore.nvim",
    },
    opts = function(_, opts)
      opts.servers = opts.servers or {}
      opts.servers.yamlls = {
        settings = {
          yaml = {
            schemaStore = {
              -- You must disable built-in schemaStore support if you want to use
              -- this plugin and its advanced options like `ignore`.
              enable = false,
              -- Avoid TypeError: Cannot read properties of undefined (reading 'length')
              url = "",
            },
            schemas = require("schemastore").yaml.schemas(),
          },
        },
      }
    end,
  },
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
        "yaml-language-server",
        "yamlfmt",
      },
    },
  },
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      formatters_by_ft = {
        yaml = { "yamlfmt" },
      },
    },
  },
}
