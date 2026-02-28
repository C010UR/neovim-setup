return {
  recommended = function()
    return LazyVim.extras.wants({
      ft = "twig",
    })
  end,
  {
    "nvim-treesitter/nvim-treesitter",
    opts = { ensure_installed = { "twig" } },
  },
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
        "twigcs",
        "twig-cs-fixer",
      },
    },
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        twiggy_language_server = {
          enabled = true,
        },
      },
    },
  },
  {
    "mfussenegger/nvim-lint",
    optional = true,
    opts = {
      linters_by_ft = {
        twig = { "twigcs" },
      },
    },
  },
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      formatters_by_ft = {
        twig = { "twig-cs-fixer" },
      },
    },
  },
}
