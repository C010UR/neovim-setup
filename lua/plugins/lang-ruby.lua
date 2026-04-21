local ruby_lsp = vim.g.ruby_lsp or "ruby_lsp"
local formatter = vim.g.ruby_formatter or "rubocop"

local ruby_root_markers = {
  "Gemfile",
  "gems.rb",
  ".ruby-version",
  "Rakefile",
}

local ruby_standalone = {
  filetypes = { "ruby" },
  extensions = { "rb", "rake", "gemspec", "ru" },
  filenames = { "Gemfile", "Rakefile", "Guardfile", "Capfile", "Podfile", "Fastfile", "Brewfile" },
}

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
          root_markers = ruby_root_markers,
          standalone = ruby_standalone,
        },
        solargraph = {
          enabled = ruby_lsp == "solargraph",
          root_markers = ruby_root_markers,
          standalone = ruby_standalone,
        },
        rubocop = {
          enabled = formatter == "rubocop" and ruby_lsp ~= "solargraph",
          root_markers = ruby_root_markers,
          standalone = ruby_standalone,
          cmd = { "bundle", "exec", "rubocop", "--lsp" },
        },
        standardrb = {
          enabled = formatter == "standardrb",
          root_markers = ruby_root_markers,
          standalone = ruby_standalone,
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
