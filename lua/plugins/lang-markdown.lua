vim.filetype.add({
  extension = { mdx = "markdown.mdx" },
})

return {
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      formatters = {
        ["markdown-toc"] = {
          condition = function(_, ctx)
            for _, line in ipairs(vim.api.nvim_buf_get_lines(ctx.buf, 0, -1, false)) do
              if line:find("<!%-%- toc %-%->") then
                return true
              end
            end
          end,
        },
        ["markdownlint-cli2"] = {
          condition = function(_, ctx)
            local diag = vim.tbl_filter(function(d)
              return d.source == "markdownlint"
            end, vim.diagnostic.get(ctx.buf))
            return #diag > 0
          end,
        },
      },
      formatters_by_ft = {
        markdown = { "prettier", "markdownlint-cli2", "markdown-toc" },
        ["markdown.mdx"] = { "prettier", "markdownlint-cli2", "markdown-toc" },
      },
    },
  },
  {
    "mason-org/mason.nvim",
    opts = { ensure_installed = { "markdownlint-cli2", "markdown-toc" } },
  },
  {
    "mfussenegger/nvim-lint",
    optional = true,
    opts = {
      linters_by_ft = {
        markdown = {},
      },
    },
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        marksman = {
          enabled = false,
        },
      },
    },
  },
  {
    "noisesfromspace/touchup.nvim",
    ft = { "markdown", "markdown.mdx" },
    opts = {
      filetypes = { "markdown", "markdown.mdx" },
    },
  },
  {
    "Necrom4/calcium.nvim",
    ft = { "markdown", "markdown.mdx" },
    cmd = { "Calcium" },
    opts = {
      notifications = false,
      default_mode = "append",
    },
    keys = {
      {
        "<leader>c=",
        function()
          require("calcium").calculate({ mode = "append" })
        end,
        desc = "Calculate Expression",
        mode = { "n", "x" },
        ft = { "markdown", "markdown.mdx" },
      },
    },
  },
}
