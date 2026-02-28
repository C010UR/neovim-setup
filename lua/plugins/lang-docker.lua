return {
  recommended = function()
    return LazyVim.extras.wants({
      ft = "dockerfile",
      root = {
        "Dockerfile",
        "Containerfile",
        "docker-compose.yml",
        "compose.yml",
        "docker-compose.yaml",
        "compose.yaml",
      },
    })
  end,
  {
    "nvim-treesitter/nvim-treesitter",
    opts = { ensure_installed = { "dockerfile" } },
  },
  {
    "mason.nvim",
    opts = { ensure_installed = { "hadolint" } },
  },
  {
    "mfussenegger/nvim-lint",
    optional = true,
    opts = {
      linters_by_ft = {
        dockerfile = { "hadolint" },
      },
    },
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        dockerls = {},
        docker_compose_language_service = {},
      },
    },
  },
}
