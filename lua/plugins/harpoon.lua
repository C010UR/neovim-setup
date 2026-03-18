return {
  {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    dependencies = {
      { "folke/snacks.nvim" },
    },
    keys = function()
      local harpoon = require("harpoon")

      local keys = {
        {
          "<leader>ha",
          function()
            harpoon:list():prepend()
          end,
          desc = "Harpoon File",
        },
        {
          "<C-p>",
          function()
            harpoon:list():prev()
          end,
          desc = "Harpoon Prev",
        },
        {
          "<C-n>",
          function()
            harpoon:list():next()
          end,
          desc = "Harpoon Next",
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
        table.insert(keys, {
          "<leader>h" .. i,
          function()
            harpoon:list():replace_at(i)
          end,
          desc = "Harpoon File At " .. i,
        })
      end

      local function open_harpoon_picker(harpoon_files)
        local items = {}

        for index, item in ipairs(harpoon_files.items) do
          if item.value and item.value ~= "" then
            local selected = index
            items[#items + 1] = {
              text = string.format("%d %s", index, item.value),
              file = item.value,
              idx = index,
              action = function()
                harpoon:list():select(selected)
              end,
            }
          end
        end

        if #items == 0 then
          vim.notify("Harpoon list is empty", vim.log.levels.WARN)
          return
        end

        Snacks.picker.pick({
          title = "Harpoon",
          items = items,
          format = "file",
          preview = "file",
          confirm = "item_action",
        })
      end

      table.insert(keys, {
        "<leader>hl",
        function()
          open_harpoon_picker(harpoon:list())
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
