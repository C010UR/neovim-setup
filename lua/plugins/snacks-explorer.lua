local root = require("config.root")

return {
  "folke/snacks.nvim",
  opts = {
    explorer = {},
    picker = {
      hidden = true,
      ignored = true,
      files = {
        hidden = true,
        ignored = true,
        exclude = {
          "**/.git/*",
        },
      },
      sources = {
        explorer = {
          on_show = function(picker)
            local gap = 1
            local function clamp_width(value)
              return math.max(20, math.min(100, value))
            end
            local position = picker.resolved_layout.layout.position
            local rel = picker.layout.root
            local function update(win)
              local border = win:border_size().left + win:border_size().right
              win.opts.row = vim.api.nvim_win_get_position(rel.win)[1]
              win.opts.height = 0.8
              if position == "left" then
                win.opts.col = vim.api.nvim_win_get_width(rel.win) + gap
                win.opts.width = clamp_width(vim.o.columns - border - win.opts.col)
              elseif position == "right" then
                win.opts.col = -vim.api.nvim_win_get_width(rel.win) - gap
                win.opts.width = clamp_width(vim.o.columns - border + win.opts.col)
              end
              win:update()
            end
            local preview_win = Snacks.win.new({
              relative = "editor",
              external = false,
              focusable = false,
              border = "rounded",
              backdrop = false,
              show = false,
              bo = {
                filetype = "snacks_float_preview",
                buftype = "nofile",
                buflisted = false,
                swapfile = false,
                undofile = false,
              },
              on_win = function(win)
                update(win)
                picker:show_preview()
              end,
            })
            rel:on("WinLeave", function()
              vim.schedule(function()
                if not picker:is_focused() then
                  picker.preview.win:close()
                end
              end)
            end)
            rel:on("WinResized", function()
              update(preview_win)
            end)
            picker.preview.win = preview_win
            picker.main = preview_win.win
          end,
          on_close = function(picker)
            picker.preview.win:close()
          end,
          layout = {
            preset = "sidebar",
            preview = false,
          },
          actions = {
            toggle_preview = function(picker)
              picker.preview.win:toggle()
            end,
          },
        },
      },
    },
  },
  init = function()
    local started = false
    vim.api.nvim_create_autocmd("VimEnter", {
      callback = function()
        started = true
      end,
    })
    vim.api.nvim_create_autocmd("BufEnter", {
      nested = true,
      callback = function()
        if not started then
          return
        end
        local real_wins = {}
        for _, win in ipairs(vim.api.nvim_list_wins()) do
          if vim.api.nvim_win_get_config(win).relative == "" then
            table.insert(real_wins, win)
          end
        end
        if #real_wins == 1 then
          local buf = vim.api.nvim_win_get_buf(real_wins[1])
          local ft = vim.bo[buf].filetype
          if ft == "snacks_picker_list" or ft:match("^snacks") then
            vim.cmd("quit")
          end
        end
      end,
    })
  end,
  keys = {
    {
      "<leader>fe",
      function()
        Snacks.explorer({ cwd = root() })
      end,
      desc = "Open Explorer (Root Dir)",
    },
    {
      "<leader>fE",
      function()
        Snacks.explorer()
      end,
      desc = "Open Explorer (CWD)",
    },
    { "<leader>e", "<leader>fe", desc = "Open Explorer (Root Dir)", remap = true },
    { "<leader>E", "<leader>fE", desc = "Open Explorer (CWD)", remap = true },
    {
      "<C-p>",
      function()
        local explorer = Snacks.explorer() or Snacks.explorer()
        vim.defer_fn(function()
          explorer:focus("input", { show = true })
          vim.cmd.startinsert()
        end, 20)
      end,
      desc = "Open Explorer and Focus Search",
    },
    {
      "<leader>/",
      mode = "x",
      desc = "Live Grep Selection",
      function()
        local start_pos = vim.api.nvim_buf_get_mark(0, "<")
        local end_pos = vim.api.nvim_buf_get_mark(0, ">")
        local lines = vim.api.nvim_buf_get_text(0, start_pos[1] - 1, start_pos[2], end_pos[1] - 1, end_pos[2] + 1, {})
        local text = table.concat(lines, " "):gsub("%s+", " "):gsub("^%s*(.-)%s*$", "%1")
        if text ~= "" then
          Snacks.picker.grep({ search = text })
        end
      end,
    },
  },
}
