local lsp = require("config.lsp")
local mini = require("config.mini")

-- Core editing primitives and completion behavior shared across languages.

return {
  {
    "nvim-mini/mini.pairs",
    opts = {
      modes = { insert = true, command = true, terminal = false },
      skip_next = [=[[%w%%%'%[%"%.%`%$]]=],
      skip_ts = { "string" },
      skip_unbalanced = true,
      markdown = true,
    },
    config = function(_, opts)
      mini.pairs(opts)
    end,
  },
  {
    "folke/ts-comments.nvim",
    opts = {},
  },
  {
    "nvim-mini/mini.ai",
    opts = function()
      local ai = require("mini.ai")
      return {
        n_lines = 500,
        custom_textobjects = {
          o = ai.gen_spec.treesitter({
            a = { "@block.outer", "@conditional.outer", "@loop.outer" },
            i = { "@block.inner", "@conditional.inner", "@loop.inner" },
          }),
          f = ai.gen_spec.treesitter({ a = "@function.outer", i = "@function.inner" }),
          c = ai.gen_spec.treesitter({ a = "@class.outer", i = "@class.inner" }),
          t = { "<([%p%w]-)%f[^<%w][^<>]->.-</%1>", "^<.->().*()</[^/]->$" },
          d = { "%f[%d]%d+" },
          e = {
            { "%u[%l%d]+%f[^%l%d]", "%f[%S][%l%d]+%f[^%l%d]", "%f[%P][%l%d]+%f[^%l%d]", "^[%l%d]+%f[^%l%d]" },
            "^().*()$",
          },
          g = mini.ai_buffer,
          u = ai.gen_spec.function_call(),
          U = ai.gen_spec.function_call({ name_pattern = "[%w_]" }),
        },
      }
    end,
    config = function(_, opts)
      require("mini.ai").setup(opts)
      vim.schedule(function()
        if package.loaded["which-key"] then
          mini.ai_whichkey(opts)
        end
      end)
    end,
  },
  {
    "nvim-mini/mini.comment",
    version = false,
    opts = {},
  },
  {
    "nvim-mini/mini.surround",
    version = false,
    opts = {},
  },
  {
    "danymat/neogen",
    keys = {
      {
        "<leader>cn",
        function()
          require("neogen").generate()
        end,
        desc = "Generate Annotations",
      },
    },
    opts = {
      snippet_engine = "nvim",
    },
  },
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      {
        "SmiteshP/nvim-navic",
        main = "nvim-navic",
        opts = function()
          local icons = require("config.icons")
          return {
            icons = vim.tbl_extend("force", vim.deepcopy(icons.kinds), {
              enabled = true,
            }),
            highlight = true,
            separator = icons.misc.dots,
            safe_output = true,
            lsp = {
              auto_attach = false,
            },
          }
        end,
      },
    },
    opts = {
      servers = {
        ["*"] = {
          capabilities = {
            workspace = {
              fileOperations = {
                didRename = true,
                willRename = true,
              },
            },
          },
          keys = {
            {
              "<leader>cl",
              function()
                Snacks.picker.lsp_config()
              end,
              desc = "Open LSP Information",
            },
            {
              "gd",
              function()
                Snacks.picker.lsp_definitions()
              end,
              desc = "Go to Definition",
              has = "definition",
            },
            {
              "gr",
              function()
                Snacks.picker.lsp_references()
              end,
              nowait = true,
              desc = "Open References",
            },
            {
              "gI",
              function()
                Snacks.picker.lsp_implementations()
              end,
              desc = "Go to Implementation",
              has = "implementation",
            },
            {
              "gy",
              function()
                Snacks.picker.lsp_type_definitions()
              end,
              desc = "Go to Type Definition",
              has = "typeDefinition",
            },
            {
              "gD",
              vim.lsp.buf.declaration,
              desc = "Go to Declaration",
              has = "declaration",
            },
            {
              "K",
              vim.lsp.buf.hover,
              desc = "Show Hover Documentation",
              has = "hover",
            },
            {
              "gK",
              vim.lsp.buf.signature_help,
              desc = "Show Signature Help",
              has = "signatureHelp",
            },
            {
              "<c-k>",
              vim.lsp.buf.signature_help,
              mode = "i",
              desc = "Show Signature Help",
              has = "signatureHelp",
            },
            {
              "<leader>ca",
              vim.lsp.buf.code_action,
              desc = "Open Code Actions",
              mode = { "n", "x" },
              has = "codeAction",
            },
            {
              "<leader>cc",
              vim.lsp.codelens.run,
              desc = "Run CodeLens",
              mode = { "n", "x" },
              has = "codeLens",
            },
            {
              "<leader>cC",
              vim.lsp.codelens.refresh,
              desc = "Refresh CodeLens",
              mode = { "n" },
              has = "codeLens",
            },
            {
              "<leader>cR",
              function()
                Snacks.rename.rename_file()
              end,
              desc = "Rename File",
              has = { "workspace/didRenameFiles", "workspace/willRenameFiles" },
            },
            { "<leader>cr", vim.lsp.buf.rename, desc = "Rename Symbol", has = "rename" },
            { "<leader>cA", lsp.action.source, desc = "Run Source Action", has = "codeAction" },
            {
              "]]",
              function()
                Snacks.words.jump(vim.v.count1)
              end,
              has = "documentHighlight",
              desc = "Next Highlighted Reference",
              enabled = function()
                return Snacks.words.is_enabled()
              end,
            },
            {
              "[[",
              function()
                Snacks.words.jump(-vim.v.count1)
              end,
              has = "documentHighlight",
              desc = "Previous Highlighted Reference",
              enabled = function()
                return Snacks.words.is_enabled()
              end,
            },
            {
              "<a-n>",
              function()
                Snacks.words.jump(vim.v.count1, true)
              end,
              has = "documentHighlight",
              desc = "Next Highlighted Reference",
              enabled = function()
                return Snacks.words.is_enabled()
              end,
            },
            {
              "<a-p>",
              function()
                Snacks.words.jump(-vim.v.count1, true)
              end,
              has = "documentHighlight",
              desc = "Previous Highlighted Reference",
              enabled = function()
                return Snacks.words.is_enabled()
              end,
            },
            {
              "<leader>co",
              lsp.action["source.organizeImports"],
              desc = "Organize Imports",
              has = "codeAction",
              enabled = function(buf)
                local actions = vim.tbl_filter(function(action)
                  return action:find("^source%.organizeImports%.?$")
                end, lsp.code_actions({ bufnr = buf }))
                return #actions > 0
              end,
            },
            {
              "<leader>ss",
              function()
                Snacks.picker.lsp_symbols({ filter = lsp.kind_filter })
              end,
              desc = "Open Document Symbols",
              has = "documentSymbol",
            },
            {
              "<leader>sS",
              function()
                Snacks.picker.lsp_workspace_symbols({ filter = lsp.kind_filter })
              end,
              desc = "Open Workspace Symbols",
              has = "workspace/symbol",
            },
            {
              "gai",
              function()
                Snacks.picker.lsp_incoming_calls()
              end,
              desc = "Open Incoming Calls",
              has = "callHierarchy/incomingCalls",
            },
            {
              "gao",
              function()
                Snacks.picker.lsp_outgoing_calls()
              end,
              desc = "Open Outgoing Calls",
              has = "callHierarchy/outgoingCalls",
            },
          },
        },
      },
    },
  },
}
