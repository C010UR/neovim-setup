local php_root_markers = {
  "composer.json",
  ".phpactor.json",
  ".phpactor.yml",
  "phpactor.json",
  "phpactor.yml",
}

local php_standalone = {
  filetypes = { "php" },
  extensions = { "php", "phtml", "inc" },
}

local twig_standalone = {
  filetypes = { "twig" },
  extensions = { "twig" },
}

return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = { ensure_installed = { "php", "twig" } },
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        intelephense = {
          enabled = false,
          root_markers = php_root_markers,
          standalone = php_standalone,
          settings = {
            intelephense = {
              maxMemory = 16384,
              files = {
                maxSize = 10000000,
                excude = {
                  "**/.idea/**",
                  "**/.git/**",
                  "**/.svn/**",
                  "**/.hg/**",
                  "**/CVS/**",
                  "**/.DS_Store/**",
                  "**/node_modules/**",
                  "**/bower_components/**",
                  "**/vendor/**/{Tests,tests}/**",
                  "**/.history/**",
                  "**/vendor/**/vendor/**",
                  "**/var/**/",
                  "**/migrations/**",
                  "**/web/**",
                },
              },
              environment = {
                phpVersion = "8.4",
              },
              format = {
                enable = true,
                braces = "psr12",
              },
              stubs = {
                "apache",
                "bcmath",
                "bz2",
                "calendar",
                "com_dotnet",
                "Core",
                "ctype",
                "curl",
                "date",
                "dba",
                "dom",
                "enchant",
                "exif",
                "FFI",
                "fileinfo",
                "filter",
                "fpm",
                "ftp",
                "gd",
                "gettext",
                "gmp",
                "hash",
                "iconv",
                "imap",
                "intl",
                "json",
                "ldap",
                "libxml",
                "mbstring",
                "meta",
                "mysqli",
                "oci8",
                "odbc",
                "openssl",
                "pcntl",
                "pcre",
                "PDO",
                "pgsql",
                "Phar",
                "posix",
                "pspell",
                "random",
                "readline",
                "Reflection",
                "redis",
                "session",
                "shmop",
                "SimpleXML",
                "snmp",
                "soap",
                "sockets",
                "sodium",
                "SPL",
                "sqlite3",
                "standard",
                "superglobals",
                "sysvmsg",
                "sysvsem",
                "sysvshm",
                "tidy",
                "tokenizer",
                "xml",
                "xmlreader",
                "xmlrpc",
                "xmlwriter",
                "xsl",
                "Zend OPcache",
                "zip",
                "zlib",
              },
            },
          },
          init_options = {
            storagePath = vim.fn.expand("~/.cache/intelephense-local"),
            globalStoragePath = vim.fn.expand("~/.cache/intelephense-global"),
            licenseKey = vim.fn.expand("~/intelephense/licence.txt"),
          },
        },
        phpactor = {
          enabled = true,
          root_markers = php_root_markers,
          standalone = php_standalone,
        },
        twiggy_language_server = {
          root_markers = php_root_markers,
          standalone = twig_standalone,
        },
      },
    },
  },
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
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
