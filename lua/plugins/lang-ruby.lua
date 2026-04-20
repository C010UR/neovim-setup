local ruby_lsp = vim.g.ruby_lsp or "ruby_lsp"
local formatter = vim.g.ruby_formatter or "rubocop"

return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = { ensure_installed = { "ruby" } },
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        ruby_lsp = {
          enabled = ruby_lsp == "ruby_lsp",
        },
        solargraph = {
          enabled = ruby_lsp == "solargraph",
        },
        rubocop = {
          enabled = formatter == "rubocop" and ruby_lsp ~= "solargraph",
          cmd = { "bundle", "exec", "rubocop", "--lsp" },
        },
        standardrb = {
          enabled = formatter == "standardrb",
        },
      },
    },
  },
  {
    "mason-org/mason.nvim",
    opts = { ensure_installed = { "erb-formatter" } },
  },
  {
    "mfussenegger/nvim-dap",
    optional = true,
    dependencies = {
      "suketa/nvim-dap-ruby",
      config = function()
        require("dap-ruby").setup()
      end,
    },
  },
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      formatters_by_ft = {
        ruby = { formatter },
        eruby = { "erb_format" },
      },
    },
  },
}
