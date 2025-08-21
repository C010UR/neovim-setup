return {
  {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    dependencies = {
      { "nvim-telescope/telescope.nvim" },
    },
    opts = {
      menu = {
        width = vim.api.nvim_win_get_width(0) - 4,
      },
      settings = {
        save_on_toggle = true,
      },
    },
    keys = function()
      local harpoon = require("harpoon")

      local keys = {
        {
          "<leader>ha",
          function()
            harpoon:list():add()
          end,
          desc = "Harpoon File",
        },
        {
          "<C-S-P>",
          function()
            harpoon:list():prev()
          end,
        },
        {
          "<C-S-N>",
          function()
            harpoon:list():next()
          end,
        },
      }

      for i = 1, 5 do
        table.insert(keys, {
          "<leader>" .. i,
          function()
            harpoon:list():select(i)
          end,
          desc = "Harpoon to File " .. i,
        })
      end

      -- basic telescope configuration
      local conf = require("telescope.config").values
      local function toggle_telescope(harpoon_files)
        local file_paths = {}
        for _, item in ipairs(harpoon_files.items) do
          table.insert(file_paths, item.value)
        end

        require("telescope.pickers")
          .new({}, {
            prompt_title = "Harpoon",
            finder = require("telescope.finders").new_table({
              results = file_paths,
            }),
            previewer = conf.file_previewer({}),
            sorter = conf.generic_sorter({}),
          })
          :find()
      end

      table.insert(keys, {
        "<leader>hl",
        function()
          toggle_telescope(harpoon:list())
        end,
        desc = "Harpoon Quick View",
      })

      return keys
    end,
  },
  {
    "folke/which-key.nvim",
    opts = {
      spec = {
        { "<leader>h", group = "harpoon", icon = { icon = "󱡀 ", color = "cyan" } },
      },
    },
  },
}
