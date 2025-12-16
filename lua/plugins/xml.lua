return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = { ensure_installed = { "xml" } },
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        lemminx = {
          enabled = true,
        },
      },
    },
  },
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
        "lemminx",
        "xmlformatter",
      },
    },
  },
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      formatters_by_ft = {
        xml = { "xmlformatter" },
        svg = { "xmlformatter" },
      },
    },
  },
}
