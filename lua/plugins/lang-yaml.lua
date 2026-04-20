return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = { ensure_installed = { "yaml" } },
  },
  {
    "b0o/SchemaStore.nvim",
    lazy = true,
    version = false,
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        yamlls = {
          capabilities = {
            textDocument = {
              foldingRange = {
                dynamicRegistration = false,
                lineFoldingOnly = true,
              },
            },
          },
          before_init = function(_, new_config)
            new_config.settings.yaml.schemas = vim.tbl_deep_extend(
              "force",
              new_config.settings.yaml.schemas or {},
              require("schemastore").yaml.schemas()
            )
          end,
          settings = {
            redhat = { telemetry = { enabled = false } },
            yaml = {
              keyOrdering = false,
              format = { enable = true },
              validate = true,
              schemaStore = {
                enable = false,
                url = "",
              },
            },
          },
        },
      },
    },
  },
  {
    "https://tangled.org/cuducos.me/yaml.nvim",
    ft = { "yaml" },
    dependencies = { "folke/snacks.nvim" },
    keys = {
      {
        "<leader>fy",
        function()
          require("yaml_nvim").snacks()
        end,
        desc = "YAML Key Find",
      },
    },
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
