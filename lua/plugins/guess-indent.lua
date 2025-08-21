return {
  {
    "NMAC427/guess-indent.nvim",
    cmd = "GuessIndent",
    event = "LazyFile",
    keys = {
      { "<leader>cg", "<cmd>GuessIndent<cr>", desc = "Guess Indent" },
    },
    config = function(_, opts)
      require("guess-indent").setup(opts)
    end,
  },
}
