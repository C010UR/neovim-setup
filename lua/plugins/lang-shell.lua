local shell_standalone = {
  filetypes = { "sh", "bash", "zsh", "ksh" },
  extensions = { "sh", "bash", "zsh", "ksh" },
  filenames = { ".bashrc", ".bash_profile", ".profile", ".zshrc", ".zprofile", ".zshenv", ".kshrc" },
}

return {
  -- Shared support for shell scripting and shell-adjacent files.
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      local function add(lang)
        if type(opts.ensure_installed) == "table" and not vim.tbl_contains(opts.ensure_installed, lang) then
          table.insert(opts.ensure_installed, lang)
        end
      end

      vim.filetype.add({
        pattern = {
          ["%.env%.[%w_.-]+"] = "sh",
        },
      })

      add("bash")

      local xdg_config = vim.env.XDG_CONFIG_HOME or vim.env.HOME .. "/.config"
      if vim.uv.fs_stat(xdg_config .. "/fish") ~= nil then
        add("fish")
      end
    end,
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        bashls = {
          standalone = shell_standalone,
        },
      },
    },
  },
}
