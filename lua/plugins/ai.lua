return {
  {
    "ThePrimeagen/99",
    keys = {
      {
        "<leader>99",
        function()
          require("99").visual()
        end,
        mode = "v",
        desc = "Work on Selection with 99",
      },
      {
        "<leader>9x",
        function()
          require("99").stop_all_requests()
        end,
        desc = "Stop All 99 Requests",
      },
      {
        "<leader>9s",
        function()
          require("99").search()
        end,
        desc = "Search with 99",
      },
    },
    config = function()
      local _99 = require("99")
      local cwd = vim.uv.cwd()
      local basename = vim.fs.basename(cwd)

      _99.setup({
        provider = _99.Providers.OpenCodeProvider,
        model = "opencode-go/qwen3.7-max",
        logger = {
          level = _99.DEBUG,
          path = "/tmp/99/" .. basename .. ".debug",
          print_on_error = true,
        },
        tmp_dir = "./tmp/99",
        completion = {
          custom_rules = { ".opencode/skills" },
          files = {},
          source = "native",
        },
        md_files = { "AGENT.md" },
      })
    end,
  },
}
