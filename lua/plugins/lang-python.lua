local lsp = require("config.lsp")

local python_lsp = vim.g.python_lsp or "pyright"
local ruff = vim.g.python_ruff or "ruff"

return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = { ensure_installed = { "ninja", "rst" } },
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        ruff = {
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
        ruff_lsp = {
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
        [ruff] = function()
          vim.api.nvim_create_autocmd("LspAttach", {
            group = vim.api.nvim_create_augroup("config_python_ruff_hover", { clear = true }),
            callback = function(event)
              local client = vim.lsp.get_client_by_id(event.data.client_id)
              if client and client.name == ruff then
                client.server_capabilities.hoverProvider = false
              end
            end,
          })
        end,
      },
    },
  },
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      local servers = { "pyright", "basedpyright", "ruff", "ruff_lsp", ruff, python_lsp }
      for _, server in ipairs(servers) do
        opts.servers[server] = opts.servers[server] or {}
        opts.servers[server].enabled = server == python_lsp or server == ruff
      end
    end,
  },
  {
    "nvim-neotest/neotest",
    optional = true,
    dependencies = { "nvim-neotest/neotest-python" },
    opts = {
      adapters = {
        ["neotest-python"] = {},
      },
    },
  },
  {
    "mfussenegger/nvim-dap",
    optional = true,
    dependencies = {
      "mfussenegger/nvim-dap-python",
      keys = {
        { "<leader>dPt", function() require("dap-python").test_method() end, desc = "Debug Method", ft = "python" },
        { "<leader>dPc", function() require("dap-python").test_class() end, desc = "Debug Class", ft = "python" },
      },
      config = function()
        require("dap-python").setup("debugpy-adapter")
      end,
    },
  },
  {
    "linux-cultist/venv-selector.nvim",
    cmd = "VenvSelect",
    ft = "python",
    keys = { { "<leader>cv", "<cmd>:VenvSelect<cr>", desc = "Select VirtualEnv", ft = "python" } },
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
