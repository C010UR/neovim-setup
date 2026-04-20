return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        tailwindcss = {
          filetypes_exclude = { "markdown" },
          filetypes_include = {},
          settings = {
            tailwindCSS = {
              includeLanguages = {
                elixir = "html-eex",
                eelixir = "html-eex",
                heex = "html-eex",
              },
            },
          },
        },
      },
      setup = {
        tailwindcss = function(_, opts)
          opts.filetypes = opts.filetypes or {}
          vim.list_extend(opts.filetypes, vim.lsp.config.tailwindcss.filetypes)
          opts.filetypes = vim.tbl_filter(function(ft)
            return not vim.tbl_contains(opts.filetypes_exclude or {}, ft)
          end, opts.filetypes)
          vim.list_extend(opts.filetypes, opts.filetypes_include or {})
        end,
      },
    },
  },
  {
    "saghen/blink.cmp",
    optional = true,
    dependencies = { { "brenoprata10/nvim-highlight-colors", opts = {} } },
    opts = {
      appearance = {
        use_nvim_cmp_as_default = false,
      },
      completion = {
        menu = {
          draw = {
            components = {
              kind_icon = {
                text = function(ctx)
                  local icon = ctx.kind_icon
                  if ctx.item.source_name == "LSP" then
                    local color_item = require("nvim-highlight-colors").format
                      and require("nvim-highlight-colors").format(ctx.item.documentation, { kind = ctx.kind })
                    if color_item and color_item.icon then
                      icon = color_item.icon .. " "
                    end
                  end
                  return icon .. ctx.icon_gap
                end,
              },
            },
          },
        },
      },
    },
  },
}
