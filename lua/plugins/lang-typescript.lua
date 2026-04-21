local lsp = require("config.lsp")
local uri_util = require("config.uri")

local biome_root_markers = { "biome.json", "biome.jsonc" }
local eslint_root_markers = {
  "eslint.config.js",
  "eslint.config.mjs",
  "eslint.config.cjs",
  "eslint.config.ts",
  "eslint.config.mts",
  "eslint.config.cts",
  ".eslintrc",
  ".eslintrc.js",
  ".eslintrc.cjs",
  ".eslintrc.json",
  ".eslintrc.yaml",
  ".eslintrc.yml",
}
local ts_root_markers = { "tsconfig.json", "tsconfig.base.json", "jsconfig.json" }

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
          root_markers = eslint_root_markers,
          workspace_required = true,
          settings = {
            workingDirectories = { mode = "auto" },
            format = false,
          },
        },
        biome = {
          root_markers = biome_root_markers,
          workspace_required = true,
        },
        vtsls = {
          root_markers = ts_root_markers,
          workspace_required = true,
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
              desc = "Go to Source Definition",
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
              desc = "Show File References",
            },
            { "<leader>co", lsp.action["source.organizeImports"], desc = "Organize Imports" },
            { "<leader>cM", lsp.action["source.addMissingImports.ts"], desc = "Add Missing Imports" },
            { "<leader>cu", lsp.action["source.removeUnused.ts"], desc = "Remove Unused Imports" },
            { "<leader>cD", lsp.action["source.fixAll.ts"], desc = "Fix All Diagnostics" },
            {
              "<leader>cV",
              function()
                lsp.execute({ command = "typescript.selectTypeScriptVersion" })
              end,
              desc = "Select Workspace TypeScript Version",
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
              local root_dir_fn = vim.lsp.config[server].root_dir
              vim.lsp.config(server, {
                root_dir = function(bufnr, on_dir)
                  local is_deno = vim.fs.root(bufnr, { "deno.json", "deno.jsonc" }) ~= nil
                  if is_deno == (server == "denols") then
                    if root_dir_fn then
                      return root_dir_fn(bufnr, on_dir)
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
      opts.formatters["biome-check"] = vim.tbl_deep_extend("force", opts.formatters["biome-check"] or {}, {
        require_cwd = true,
        condition = function(_, ctx)
          return vim.fs.root(ctx.filename, biome_root_markers) ~= nil
        end,
      })
    end,
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
