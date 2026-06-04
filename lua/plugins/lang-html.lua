local function setup_html()
  require("config.scaffold.html").register()
end

return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = { ensure_installed = { "html", "css" } },
  },
  {
    "neovim/nvim-lspconfig",
    init = setup_html,
    opts = {
      servers = {
        html = {
          settings = {
            html = {
              format = {
                templating = true,
                wrapLineLength = 120,
                wrapAttributes = "auto",
              },
              hover = {
                documentation = true,
                references = true,
              },
              completion = {
                attributeDefaultValue = "doublequotes",
              },
            },
          },
        },
        cssls = {
          settings = {
            css = { validate = true },
            scss = { validate = true },
            less = { validate = true },
          },
        },
        emmet_language_server = {
          filetypes = {
            "css",
            "html",
            "javascriptreact",
            "less",
            "sass",
            "scss",
            "typescriptreact",
            "htmlangular",
          },
        },
      },
    },
  },
  {
    "windwp/nvim-ts-autotag",
    main = "nvim-ts-autotag",
    opts = {
      opts = {
        enable_rename = true,
        enable_close = true,
        enable_close_on_slash = true,
      },
    },
  },
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
        "html-lsp",
        "css-lsp",
        "emmet-language-server",
      },
    },
  },
}
