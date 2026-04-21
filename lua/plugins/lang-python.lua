local lsp = require("config.lsp")

local python_root_markers = {
  "pyproject.toml",
  "ruff.toml",
  ".ruff.toml",
  "setup.py",
  "setup.cfg",
  "requirements.txt",
  "Pipfile",
  "pyrightconfig.json",
}

local python_standalone = {
  filetypes = { "python" },
  extensions = { "py", "pyi", "pyw" },
}

return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = { ensure_installed = { "ninja", "rst" } },
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        pyright = {
          root_markers = python_root_markers,
          standalone = python_standalone,
        },
        ruff = {
          root_markers = python_root_markers,
          standalone = python_standalone,
          cmd_env = { RUFF_TRACE = "messages" },
          init_options = {
            settings = {
              logLevel = "error",
            },
          },
          keys = {
            {
              "<leader>co",
              lsp.action["source.organizeImports"],
              desc = "Organize Imports",
            },
          },
        },
      },
      setup = {
        ruff = function()
          vim.api.nvim_create_autocmd("LspAttach", {
            group = vim.api.nvim_create_augroup("config_python_ruff_hover", { clear = true }),
            callback = function(event)
              local client = vim.lsp.get_client_by_id(event.data.client_id)
              if client and client.name == "ruff" then
                client.server_capabilities.hoverProvider = false
              end
            end,
          })
        end,
      },
    },
  },
  {
    "mfussenegger/nvim-dap",
    optional = true,
    dependencies = {
      "mfussenegger/nvim-dap-python",
      keys = {
        {
          "<leader>dPt",
          function()
            require("dap-python").test_method()
          end,
          desc = "Debug Test Method",
          ft = "python",
        },
        {
          "<leader>dPc",
          function()
            require("dap-python").test_class()
          end,
          desc = "Debug Test Class",
          ft = "python",
        },
      },
      config = function()
        require("dap-python").setup("debugpy-adapter")
      end,
    },
  },
  {
    "linux-cultist/venv-selector.nvim",
    keys = { { "<leader>cv", "<cmd>:VenvSelect<cr>", desc = "Select Virtualenv", ft = "python" } },
    opts = {
      options = {
        notify_user_on_venv_activation = true,
      },
    },
  },
  {
    "jay-babu/mason-nvim-dap.nvim",
    optional = true,
    opts = {
      handlers = {
        python = function() end,
      },
    },
  },
}
