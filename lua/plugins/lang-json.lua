return {
  {
    "b0o/SchemaStore.nvim",
    lazy = true,
    version = false,
  },
  {
    "nvim-treesitter/nvim-treesitter",
    opts = { ensure_installed = { "json5" } },
  },
  {
    "neovim/nvim-lspconfig",
    dependencies = { "b0o/SchemaStore.nvim" },
    opts = {
      servers = {
        jsonls = {
          before_init = function(_, new_config)
            new_config.settings.json.schemas = new_config.settings.json.schemas or {}
            vim.list_extend(new_config.settings.json.schemas, require("schemastore").json.schemas())
          end,
          settings = {
            json = {
              format = { enable = true },
              validate = { enable = true },
            },
          },
        },
      },
    },
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
