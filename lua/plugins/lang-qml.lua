local qml_ft = { "qml" }

return {
  -- Treesitter
  {
    "nvim-treesitter/nvim-treesitter",
    optional = true,
    opts = { ensure_installed = { "qml" } },
  },
  -- LSP Config
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        qmlls = {
          enabled = true,
        },
      },
    },
  },
}
