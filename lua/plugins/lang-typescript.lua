local lsp = require("config.lsp")
local uri_util = require("config.uri")

return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        tsserver = {
          enabled = false,
        },
        ts_ls = {
          enabled = false,
        },
        eslint = {
          settings = {
            workingDirectories = { mode = "auto" },
            format = false,
          },
        },
        biome = {},
        vtsls = {
          filetypes = {
            "javascript",
            "javascriptreact",
            "javascript.jsx",
            "typescript",
            "typescriptreact",
            "typescript.tsx",
          },
          settings = {
            complete_function_calls = true,
            vtsls = {
              enableMoveToFileCodeAction = true,
              autoUseWorkspaceTsdk = true,
              experimental = {
                maxInlayHintLength = 30,
                completion = {
                  enableServerSideFuzzyMatch = true,
                },
              },
            },
            typescript = {
              updateImportsOnFileMove = { enabled = "always" },
              suggest = {
                completeFunctionCalls = true,
              },
              inlayHints = {
                enumMemberValues = { enabled = true },
                functionLikeReturnTypes = { enabled = true },
                parameterNames = { enabled = "literals" },
                parameterTypes = { enabled = true },
                propertyDeclarationTypes = { enabled = true },
                variableTypes = { enabled = false },
              },
            },
          },
          keys = {
            {
              "gD",
              function()
                local win = vim.api.nvim_get_current_win()
                local params = vim.lsp.util.make_position_params(win, "utf-16")
                lsp.execute({
                  command = "typescript.goToSourceDefinition",
                  arguments = { params.textDocument.uri, params.position },
                  open = true,
                })
              end,
              desc = "Goto Source Definition",
            },
            {
              "gR",
              function()
                lsp.execute({
                  command = "typescript.findAllFileReferences",
                  arguments = { uri_util.from_bufnr(0) },
                  open = true,
                })
              end,
              desc = "File References",
            },
            { "<leader>co", lsp.action["source.organizeImports"], desc = "Organize Imports" },
            { "<leader>cM", lsp.action["source.addMissingImports.ts"], desc = "Add missing imports" },
            { "<leader>cu", lsp.action["source.removeUnused.ts"], desc = "Remove unused imports" },
            { "<leader>cD", lsp.action["source.fixAll.ts"], desc = "Fix all diagnostics" },
            {
              "<leader>cV",
              function()
                lsp.execute({ command = "typescript.selectTypeScriptVersion" })
              end,
              desc = "Select TS workspace version",
            },
          },
        },
      },
      setup = {
        tsserver = function()
          return true
        end,
        ts_ls = function()
          return true
        end,
        eslint = function()
          lsp.register_lsp_formatter("eslint", {
            name = "eslint: lsp",
            primary = false,
            priority = 200,
          })
        end,
        vtsls = function(_, opts)
          if vim.lsp.config.denols and vim.lsp.config.vtsls then
            local function resolve(server)
              local markers = vim.lsp.config[server].root_markers
              local root_dir = vim.lsp.config[server].root_dir
              vim.lsp.config(server, {
                root_dir = function(bufnr, on_dir)
                  local is_deno = vim.fs.root(bufnr, { "deno.json", "deno.jsonc" }) ~= nil
                  if is_deno == (server == "denols") then
                    if root_dir then
                      return root_dir(bufnr, on_dir)
                    elseif type(markers) == "table" then
                      local root = vim.fs.root(bufnr, markers)
                      return root and on_dir(root)
                    end
                  end
                end,
              })
            end
            resolve("denols")
            resolve("vtsls")
          end

          vim.api.nvim_create_autocmd("LspAttach", {
            group = vim.api.nvim_create_augroup("config_vtsls_commands", { clear = true }),
            callback = function(event)
              local client = vim.lsp.get_client_by_id(event.data.client_id)
              if not client or client.name ~= "vtsls" then
                return
              end
              client.commands["_typescript.moveToFileRefactoring"] = function(command)
                local action, uri, range = unpack(command.arguments)
                local function move(newf)
                  client:request("workspace/executeCommand", {
                    command = command.command,
                    arguments = { action, uri, range, newf },
                  })
                end
                local fname = uri_util.to_fname(uri)
                client:request("workspace/executeCommand", {
                  command = "typescript.tsserverRequest",
                  arguments = {
                    "getMoveToRefactoringFileSuggestions",
                    {
                      file = fname,
                      startLine = range.start.line + 1,
                      startOffset = range.start.character + 1,
                      endLine = range["end"].line + 1,
                      endOffset = range["end"].character + 1,
                    },
                  },
                }, function(_, result)
                  local files = result.body.files
                  table.insert(files, 1, "Enter new path...")
                  vim.ui.select(files, {
                    prompt = "Select move destination:",
                    format_item = function(f)
                      return vim.fn.fnamemodify(f, ":~:.")
                    end,
                  }, function(f)
                    if f and f:find("^Enter new path") then
                      vim.ui.input({
                        prompt = "Enter move destination:",
                        default = vim.fn.fnamemodify(fname, ":h") .. "/",
                        completion = "file",
                      }, function(newf)
                        if newf then
                          move(newf)
                        end
                      end)
                    elseif f then
                      move(f)
                    end
                  end)
                end)
              end
            end,
          })
          opts.settings.javascript = vim.tbl_deep_extend("force", {}, opts.settings.typescript, opts.settings.javascript or {})
        end,
      },
    },
  },
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = function(_, opts)
      local supported = {
        "astro",
        "css",
        "scss",
        "graphql",
        "javascript",
        "javascriptreact",
        "json",
        "jsonc",
        "svelte",
        "typescript",
        "typescriptreact",
        "vue",
      }
      opts.formatters_by_ft = opts.formatters_by_ft or {}
      for _, ft in ipairs(supported) do
        opts.formatters_by_ft[ft] = opts.formatters_by_ft[ft] or {}
        table.insert(opts.formatters_by_ft[ft], "biome-check")
      end
      opts.formatters = opts.formatters or {}
      opts.formatters["biome-check"] = { require_cwd = true }
    end,
  },
  {
    "mfussenegger/nvim-dap",
    optional = true,
    dependencies = {
      {
        "mason-org/mason.nvim",
        opts = function(_, opts)
          opts.ensure_installed = opts.ensure_installed or {}
          table.insert(opts.ensure_installed, "js-debug-adapter")
        end,
      },
    },
    opts = function()
      local dap = require("dap")
      for _, adapter_type in ipairs({ "node", "chrome", "msedge" }) do
        local pwa_type = "pwa-" .. adapter_type
        if not dap.adapters[pwa_type] then
          dap.adapters[pwa_type] = {
            type = "server",
            host = "localhost",
            port = "${port}",
            executable = {
              command = "js-debug-adapter",
              args = { "${port}" },
            },
          }
        end
        if not dap.adapters[adapter_type] then
          dap.adapters[adapter_type] = function(cb, config)
            local native_adapter = dap.adapters[pwa_type]
            config.type = pwa_type
            if type(native_adapter) == "function" then
              native_adapter(cb, config)
            else
              cb(native_adapter)
            end
          end
        end
      end

      local js_filetypes = { "typescript", "javascript", "typescriptreact", "javascriptreact" }
      local vscode = require("dap.ext.vscode")
      vscode.type_to_filetypes["node"] = js_filetypes
      vscode.type_to_filetypes["pwa-node"] = js_filetypes

      for _, language in ipairs(js_filetypes) do
        if not dap.configurations[language] then
          local runtime_executable = nil
          if language:find("typescript") then
            runtime_executable = vim.fn.executable("tsx") == 1 and "tsx" or "ts-node"
          end
          dap.configurations[language] = {
            {
              type = "pwa-node",
              request = "launch",
              name = "Launch file",
              program = "${file}",
              cwd = "${workspaceFolder}",
              sourceMaps = true,
              runtimeExecutable = runtime_executable,
              skipFiles = { "<node_internals>/**", "node_modules/**" },
              resolveSourceMapLocations = { "${workspaceFolder}/**", "!**/node_modules/**" },
            },
            {
              type = "pwa-node",
              request = "attach",
              name = "Attach",
              processId = require("dap.utils").pick_process,
              cwd = "${workspaceFolder}",
              sourceMaps = true,
              runtimeExecutable = runtime_executable,
              skipFiles = { "<node_internals>/**", "node_modules/**" },
              resolveSourceMapLocations = { "${workspaceFolder}/**", "!**/node_modules/**" },
            },
          }
        end
      end
    end,
  },
  {
    "jay-babu/mason-nvim-dap.nvim",
    optional = true,
    opts = {
      automatic_installation = { exclude = { "chrome" } },
    },
  },
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
        "vtsls",
        "eslint-lsp",
        "biome",
      },
    },
  },
  {
    "nvim-mini/mini.icons",
    opts = {
      file = {
        [".eslintrc.js"] = { glyph = "󰱺", hl = "MiniIconsYellow" },
        [".node-version"] = { glyph = "", hl = "MiniIconsGreen" },
        [".prettierrc"] = { glyph = "", hl = "MiniIconsPurple" },
        [".yarnrc.yml"] = { glyph = "", hl = "MiniIconsBlue" },
        ["eslint.config.js"] = { glyph = "󰱺", hl = "MiniIconsYellow" },
        ["package.json"] = { glyph = "", hl = "MiniIconsGreen" },
        ["tsconfig.json"] = { glyph = "", hl = "MiniIconsAzure" },
        ["tsconfig.build.json"] = { glyph = "", hl = "MiniIconsAzure" },
        ["yarn.lock"] = { glyph = "", hl = "MiniIconsBlue" },
      },
    },
  },
}
