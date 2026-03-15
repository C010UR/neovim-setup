return {
  "nvim-telescope/telescope.nvim",
  keys = {
    {
      "<leader>/",
      mode = "x",
      desc = "Live Grep Selection",
      function()
        vim.cmd('normal! "zy')
        local text = vim.fn.getreg("z"):gsub("\n", " ")
        require("telescope.builtin").live_grep({
          default_text = text,
        })
      end,
    },
  },
}
