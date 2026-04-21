local format = require("config.format")
local icons = require("config.icons")
local lsp = require("config.lsp")

return {
  {
    "folke/lazydev.nvim",
    opts = {
      library = {
        { path = "${3rd}/luv/library", words = { "vim%.uv" } },
      },
      enabled = function(root_dir)
        return not vim.uv.fs_stat(root_dir .. "/.luarc.json")
      end,
    },
  },
  -- Base LSP and Mason integration shared by language-specific specs.
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "mason-org/mason.nvim",
      { "mason-org/mason-lspconfig.nvim", config = function() end },
    },
    opts_extend = { "servers.*.keys" },
    opts = {
      diagnostics = {
        underline = true,
        update_in_insert = false,
        virtual_text = {
          spacing = 4,
          source = "if_many",
          prefix = "●",
        },
        severity_sort = true,
        signs = {
          text = {
            [vim.diagnostic.severity.ERROR] = icons.diagnostics.Error,
            [vim.diagnostic.severity.WARN] = icons.diagnostics.Warn,
            [vim.diagnostic.severity.HINT] = icons.diagnostics.Hint,
            [vim.diagnostic.severity.INFO] = icons.diagnostics.Info,
          },
        },
      },
      inlay_hints = {
        enabled = true,
        exclude = { "vue" },
      },
      codelens = {
        enabled = false,
      },
      folds = {
        enabled = true,
      },
      format = {
        formatting_options = nil,
        timeout_ms = nil,
      },
      completion = {
        autotrigger = true,
      },
      servers = {
        stylua = { enabled = false },
        lua_ls = {
          settings = {
            Lua = {
              workspace = {
                checkThirdParty = false,
              },
              codeLens = {
                enable = true,
              },
              completion = {
                callSnippet = "Replace",
              },
              doc = {
                privateName = { "^_" },
              },
              hint = {
                enable = true,
                setType = false,
                paramType = true,
                paramName = "Disable",
                semicolon = "Disable",
                arrayIndex = "Disable",
              },
            },
          },
        },
      },
      setup = {},
    },
    config = function(_, opts)
      format.register(lsp.formatter())

      for server, server_opts in pairs(opts.servers) do
        if type(server_opts) == "table" and server_opts.keys then
          lsp.register_keys(server, server_opts.keys)
        end
      end
      lsp.enable_keymaps()

      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("config_lsp_features", { clear = true }),
        callback = function(event)
          local client = vim.lsp.get_client_by_id(event.data.client_id)
          if not client then
            return
          end
          local buf = event.buf

          if
            opts.completion.autotrigger
            and vim.lsp.completion
            and client:supports_method("textDocument/completion")
          then
            vim.lsp.completion.enable(true, client.id, buf, {
              autotrigger = true,
            })
          end

          if opts.inlay_hints.enabled and vim.lsp.inlay_hint then
            if
              not vim.tbl_contains(opts.inlay_hints.exclude, vim.bo[buf].filetype)
              and client:supports_method("textDocument/inlayHint")
            then
              vim.lsp.inlay_hint.enable(true, { bufnr = buf })
            end
          end

          if opts.folds.enabled and client:supports_method("textDocument/foldingRange") then
            if vim.o.foldmethod == "indent" then
              vim.opt_local.foldmethod = "expr"
            end
            if vim.o.foldexpr == "" or vim.o.foldexpr == "0" then
              vim.opt_local.foldexpr = "v:lua.vim.lsp.foldexpr()"
            end
          end

          if opts.codelens.enabled and vim.lsp.codelens and client:supports_method("textDocument/codeLens") then
            vim.lsp.codelens.refresh()
            vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold", "InsertLeave" }, {
              buffer = buf,
              callback = vim.lsp.codelens.refresh,
            })
          end
        end,
      })

      vim.diagnostic.config(vim.deepcopy(opts.diagnostics))
      if opts.servers["*"] then
        local default_server_opts = vim.tbl_deep_extend("force", {}, opts.servers["*"])
        default_server_opts.keys = nil
        default_server_opts.enabled = nil
        default_server_opts.mason = nil
        vim.lsp.config("*", default_server_opts)
      end

      local pack = require("config.pack")
      local have_mason = pack.is_registered("mason-lspconfig.nvim")
      local mason_exclude = {}

      local function configure(server)
        if server == "*" then
          return false
        end

        local raw = opts.servers[server]
        local server_opts = raw == true and {} or (not raw and { enabled = false } or vim.deepcopy(raw))
        if server_opts.enabled == false then
          mason_exclude[#mason_exclude + 1] = server
          return false
        end

        server_opts.enabled = nil
        server_opts.keys = nil
        local use_mason = have_mason and server_opts.mason ~= false
        server_opts.mason = nil

        local setup = opts.setup[server] or opts.setup["*"]
        if setup and setup(server, server_opts) then
          mason_exclude[#mason_exclude + 1] = server
          return false
        end

        vim.lsp.config(server, server_opts)
        if not use_mason then
          vim.lsp.enable(server)
        end
        return use_mason
      end

      local install = vim.tbl_filter(configure, vim.tbl_keys(opts.servers))
      if have_mason then
        local ensure =
          vim.deepcopy(vim.tbl_get(pack.plugin_opts("mason-lspconfig.nvim") or {}, "ensure_installed") or {})
        local install_set = {}
        local ensure_installed = {}
        for _, server in ipairs(vim.list_extend(install, ensure)) do
          if not install_set[server] then
            install_set[server] = true
            ensure_installed[#ensure_installed + 1] = server
          end
        end
        local ok, err = pcall(function()
          require("mason-lspconfig").setup({
            ensure_installed = ensure_installed,
            automatic_enable = { exclude = mason_exclude },
          })
        end)
        if not ok then
          vim.notify(err, vim.log.levels.WARN, { title = "mason-lspconfig" })
        end
      end
    end,
  },
  {
    "mason-org/mason.nvim",
    keys = { { "<leader>cm", "<cmd>Mason<cr>", desc = "Open Mason" } },
    opts_extend = { "ensure_installed" },
    opts = {
      ensure_installed = {
        "stylua",
        "shfmt",
      },
    },
    config = function(_, opts)
      require("mason").setup(opts)
      local registry = require("mason-registry")
      local interactive = #vim.api.nvim_list_uis() > 0
      if interactive then
        registry:on("package:install:success", function()
          vim.defer_fn(function()
            vim.api.nvim_exec_autocmds("FileType", {
              buffer = vim.api.nvim_get_current_buf(),
              modeline = false,
            })
          end, 100)
        end)
        registry.refresh(function()
          for _, tool in ipairs(opts.ensure_installed) do
            local ok, pkg = pcall(registry.get_package, tool)
            if ok and pkg and not pkg:is_installed() then
              pkg:install()
            end
          end
        end)
      end
    end,
  },
}
