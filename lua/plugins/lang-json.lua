return {
  { "b0o/schemastore.nvim", lazy = true },
  {
    "nvim-treesitter/nvim-treesitter",
    opts = { ensure_installed = { "json", "jsonc" } },
  },
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "b0o/schemastore.nvim",
    },
    opts = function(_, opts)
      opts.servers = opts.servers or {}
      opts.servers.jsonls = {
        settings = {
          json = {
            schemas = require("schemastore").json.schemas(),
            validate = { enable = true },
          },
        },
      }
    end,
  },
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
        "json-lsp",
        "jq",
        "biome",
        "prettier",
      },
    },
  },
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      formatters_by_ft = {
        json = { "jq" },
        jsonc = { "biome", "prettier" },
      },
    },
  },
}
