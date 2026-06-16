---@type string[]
local ROOT_MARKERS = {
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

local indexing_tokens = {}

---@param value table
---@return boolean
local function is_indexing_progress(value)
  local title = type(value.title) == "string" and value.title:lower() or ""
  local message = type(value.message) == "string" and value.message:lower() or ""
  return title:find("index", 1, true) ~= nil or message:find("index", 1, true) ~= nil
end

---@param client vim.lsp.Client
---@param token string
---@param value table
local function notify_indexing_progress(client, token, value)
  local key = ("%d:%s"):format(client.id, token)
  if value.kind == "end" then
    if indexing_tokens[key] then
      indexing_tokens[key] = nil
      vim.notify("Intelephense indexing finished", vim.log.levels.INFO, { title = "PHP LSP" })
    end
    return
  end

  if not is_indexing_progress(value) then
    return
  end

  if indexing_tokens[key] then
    return
  end
  indexing_tokens[key] = true
  vim.notify("Intelephense indexing started", vim.log.levels.INFO, { title = "PHP LSP" })
end

---@param cmd string
---@return boolean
local function is_git_branch_change(cmd)
  if not cmd:match("^git%s+") then
    return false
  end
  return cmd:match("%f[%w]checkout%f[%W]") ~= nil or cmd:match("%f[%w]switch%f[%W]") ~= nil
end

local function setup_php()
  require("config.scaffold.php").register()

  local phpactor = require("config.phpactor")
  local group = vim.api.nvim_create_augroup("config_php_lsp", { clear = true })

  vim.api.nvim_create_autocmd("LspProgress", {
    group = group,
    callback = function(event)
      local data = event.data or {}
      local params = data.params or {}
      local value = params.value or {}
      local token = params.token ~= nil and tostring(params.token) or nil
      local client = data.client_id and vim.lsp.get_client_by_id(data.client_id) or nil
      if not client or client.name ~= "intelephense" or not token or type(value.kind) ~= "string" then
        return
      end
      notify_indexing_progress(client, token, value)
    end,
  })

  vim.api.nvim_create_autocmd("LspDetach", {
    group = group,
    callback = function(event)
      local client = vim.lsp.get_client_by_id(event.data.client_id)
      if not client then
        return
      end
      local prefix = client.id .. ":"
      for key in pairs(indexing_tokens) do
        if key:find("^" .. prefix, 1, true) then
          indexing_tokens[key] = nil
        end
      end
    end,
  })

  vim.api.nvim_create_autocmd("ShellCmdPost", {
    group = group,
    callback = function(event)
      if not is_git_branch_change(event.match or "") then
        return
      end
      phpactor.handle_branch_change()
    end,
  })

  if vim.g.config_php_lsp_cmds then
    return
  end
  vim.g.config_php_lsp_cmds = true

  vim.api.nvim_create_user_command("IntelephenseTraceToggle", function()
    vim.g.intelephense_trace = vim.g.intelephense_trace == "messages" and "off" or "messages"
    vim.notify(
      ("Intelephense trace: %s — run :lsp restart intelephense, then :LspLog"):format(vim.g.intelephense_trace),
      vim.log.levels.INFO,
      { title = "PHP LSP" }
    )
  end, { desc = "Toggle Intelephense LSP trace (requires restart)" })

  vim.api.nvim_create_user_command("IntelephenseIndexWorkspace", function()
    local client = vim.lsp.get_clients({ bufnr = 0, name = "intelephense" })[1]
    if not client then
      vim.notify("Intelephense is not attached", vim.log.levels.WARN, { title = "PHP LSP" })
      return
    end
    client:exec_cmd({
      command = "intelephense.index.workspace",
      title = "Intelephense: Index workspace",
    })
  end, { desc = "Re-index PHP workspace (clears Intelephense cache)" })

  vim.api.nvim_create_user_command("PhpactorReindex", function()
    phpactor.reindex()
  end, { desc = "Re-index PHP workspace (phpactor)" })

  vim.api.nvim_create_user_command("PhpactorRestart", function()
    vim.cmd("lsp restart phpactor")
  end, { desc = "Restart phpactor (e.g. after external git branch switch)" })

  vim.api.nvim_create_user_command("PhpactorBranchIndexClean", function(opts)
    phpactor.clean_branch_caches(opts.bang)
  end, {
    desc = "Remove phpactor branch index caches (! = keep current branch only)",
    bang = true,
  })
end

local node_runtime = vim.fn.exepath("node")

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
        intelephense = {
          enabled = false,
          root_markers = ROOT_MARKERS,
          standalone = php_standalone,
          settings = {
            intelephense = {
              maxMemory = 16384,
              runtime = node_runtime ~= "" and node_runtime or nil,
              trace = {
                server = type(vim.g.intelephense_trace) == "string" and vim.g.intelephense_trace or "off",
              },
              compatibility = {
                preferPsalmPhpstanPrefixedAnnotations = true,
                correctForArrayAccessArrayAndTraversableArrayUnionTypes = true,
              },
              files = {
                maxSize = 10000000,
                exclude = {
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
                  "**/var/**",
                  "**/migrations/**",
                  "**/web/**",
                  "**/Model/**/Map/**",
                  "**/Model/**/om/**",
                },
              },
              diagnostics = {
                enable = true,
                embeddedLanguages = true,
                undefinedTypes = true,
                undefinedFunctions = true,
                undefinedConstants = true,
                undefinedClassConstants = true,
                undefinedMethods = true,
                undefinedProperties = true,
                undefinedVariables = true,
                unusedSymbols = true,
                typeErrors = true,
                argumentCount = "on",
                languageConstraints = true,
                implementationErrors = true,
                unreachableCode = true,
                suspectCode = true,
                duplicateSymbols = true,
                unexpectedTokens = true,
                memberAccess = true,
                deprecated = true,
                suppressUndefinedMembersWhenMagicMethodDeclared = false,
                exclude = {
                  ["**/vendor/**"] = { "*" },
                  ["**/Model/**/Base/**"] = { "*" },
                  ["**/Model/**/Map/**"] = { "*" },
                  ["**/Model/**/om/**"] = { "*" },
                },
              },
              format = {
                enable = true,
                braces = "per",
              },
              completion = {
                insertUseDeclaration = true,
                triggerParameterHints = true,
                maxItems = 100,
              },
              references = {
                enable = true,
                exclude = {
                  "**/Model/**/Base/**",
                  "**/Model/**/Map/**",
                  "**/Model/**/om/**",
                  "**/vendor/**",
                },
              },
              rename = {
                enable = true,
                namespaceMode = "single",
                exclude = {
                  "**/Model/**/Base/**",
                  "**/Model/**/Map/**",
                  "**/Model/**/om/**",
                  "**/vendor/**",
                },
              },
              telemetry = {
                enabled = false,
              },
              stubs = {
                "apache",
                "bcmath",
                "Core",
                "ctype",
                "curl",
                "date",
                "dom",
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
                "intl",
                "json",
                "ldap",
                "libxml",
                "mbstring",
                "mysqli",
                "openssl",
                "pcntl",
                "pcre",
                "PDO",
                "pgsql",
                "Phar",
                "posix",
                "random",
                "readline",
                "Reflection",
                "redis",
                "session",
                "SimpleXML",
                "soap",
                "sockets",
                "sodium",
                "SPL",
                "sqlite3",
                "standard",
                "superglobals",
                "tokenizer",
                "xml",
                "xmlreader",
                "xmlwriter",
                "xdebug",
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
            clearCache = false,
          },
        },
        phpactor = {
          enabled = true,
          root_markers = ROOT_MARKERS,
          standalone = php_standalone,
          before_init = function(params, config)
            require("config.phpactor").before_init(params, config)
          end,
          cmd = function(dispatchers, config)
            return require("config.phpactor").start_rpc(dispatchers, config)
          end,
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
        "intelephense",
        "phpactor",
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
