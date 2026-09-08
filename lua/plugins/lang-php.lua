---@type string[]
local ROOT_MARKERS = {
  "composer.json",
  ".phpantom.toml",
}

local php_standalone = {
  filetypes = { "php" },
  extensions = { "php", "phtml", "inc" },
}

local twig_standalone = {
  filetypes = { "twig" },
  extensions = { "twig" },
}

local function setup_php()
  require("config.scaffold.php").register()
end

return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = { ensure_installed = { "php", "twig" } },
  },
  {
    "neovim/nvim-lspconfig",
    init = setup_php,
    opts = {
      servers = {
        phpantom_lsp = {
          enabled = true,
          root_markers = ROOT_MARKERS,
          standalone = php_standalone,
        },
        twiggy_language_server = {
          root_markers = ROOT_MARKERS,
          standalone = twig_standalone,
        },
      },
    },
  },
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
        "phpantom_lsp",
        "phpcs",
        "php-cs-fixer",
        "twigcs",
        "twig-cs-fixer",
      },
    },
  },
  {
    "mfussenegger/nvim-dap",
    optional = true,
    opts = function()
      local dap = require("dap")
      dap.adapters.php = {
        type = "executable",
        command = "php-debug-adapter",
        args = {},
      }
    end,
  },
  {
    "mfussenegger/nvim-lint",
    optional = true,
    opts = {
      linters_by_ft = {
        php = { "phpcs" },
        twig = { "twigcs" },
      },
    },
  },
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      formatters_by_ft = {
        php = { "php_cs_fixer" },
        twig = { "twig-cs-fixer" },
      },
    },
  },
}
