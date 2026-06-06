local root = require("config.root")

--- Build a Snacks explorer action that runs `cb(bufnr)` for every file in the
--- current selection (directories are expanded recursively).  Aggregates
--- results and shows a summary notification.
---
--- @param title  string          Label used in notifications, e.g. "Format"
--- @param cb     fun(bufnr: integer): boolean|nil
---               Return true (or nothing falsy) on success, false/nil on skip.
---               Raise an error to mark the file as failed.
--- @return fun(picker: snacks.Picker)
local function explorer_buf_action(title, cb)
  return function(picker)
    local selected = picker:selected({ fallback = true }) or {}
    if #selected == 0 then
      vim.notify("No entries selected", vim.log.levels.WARN, { title = title })
      return
    end

    -- Expand selection: files directly, directories recursively.
    local files = {}
    local seen = {}
    for _, item in ipairs(selected) do
      local path = item.file
      if path then
        local stat = vim.uv.fs_stat(path)
        if stat and stat.type == "file" then
          if not seen[path] then
            seen[path] = true
            files[#files + 1] = path
          end
        elseif stat and stat.type == "directory" then
          for name, kind in vim.fs.dir(path, { depth = math.huge }) do
            if kind == "file" then
              local child = path .. "/" .. name
              if not seen[child] then
                seen[child] = true
                files[#files + 1] = child
              end
            end
          end
        end
      end
    end

    if #files == 0 then
      vim.notify("No files found in selection", vim.log.levels.WARN, { title = title })
      return
    end

    local ok_count = 0
    local failed = {}
    for _, file in ipairs(files) do
      local bufnr = vim.fn.bufadd(file)
      vim.fn.bufload(bufnr)
      local ok, err = pcall(cb, bufnr)
      if ok then
        ok_count = ok_count + 1
      else
        failed[#failed + 1] = { file = file, err = tostring(err) }
      end
    end

    local level = #failed == 0 and vim.log.levels.INFO or vim.log.levels.WARN
    vim.notify(("%s: %d/%d files"):format(title, ok_count, #files), level, { title = title })
    for _, item in ipairs(failed) do
      vim.notify(("%s: %s"):format(item.file, item.err), vim.log.levels.ERROR, { title = title .. " Failed" })
    end
  end
end

local format_explorer_selection = explorer_buf_action("Format", function(bufnr)
  local conform = require("conform")
  conform.format({ bufnr = bufnr, async = false, lsp_format = "fallback" })
  vim.api.nvim_buf_call(bufnr, vim.cmd.write)
end)

local scaffold_explorer = require("config.scaffold.explorer")

vim.api.nvim_create_autocmd("FileType", {
  pattern = "snacks_picker_list",
  group = vim.api.nvim_create_augroup("config_explorer_keymaps", { clear = true }),
  callback = function(ev)
    vim.schedule(function()
      local picker = Snacks.picker.get({ source = "explorer" })[1]
      if not picker then
        return
      end
      local buf = ev.buf
      local wk = require("which-key")

      vim.keymap.set("n", "<leader>cf", function()
        format_explorer_selection(picker)
      end, { buffer = buf, nowait = true, desc = "Format Selected" })

      vim.keymap.set("n", "?", function()
        wk.show({ global = false })
      end, { buffer = buf, nowait = true, desc = "Explorer Keymaps" })

      wk.add({
        { "<leader>cf", desc = "Format Selected", buffer = buf },
        { "<tab>", desc = "Select Entry", buffer = buf },
        { "?", desc = "Explorer Keymaps", buffer = buf },
      }, { notify = false })
    end)
  end,
})

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
              border = true,
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
          focus = "list",
          layout = {
            preset = "sidebar",
            preview = false,
          },
          actions = {
            toggle_preview = function(picker)
              picker.preview.win:toggle()
            end,
            format_selection = format_explorer_selection,
            explorer_rename = scaffold_explorer.rename,
            explorer_copy = scaffold_explorer.copy,
            explorer_paste = scaffold_explorer.paste,
            explorer_move = scaffold_explorer.move,
          },
          win = {
            list = {
              keys = {
                -- <Tab> is already bound to select_and_next by Snacks default;
                -- re-declaring here makes it explicit and discoverable.
                ["<tab>"] = { "select_and_next", mode = { "n", "x" }, desc = "Select Entry and Move Down" },
              },
            },
          },
        },
      },
    },
  },
  keys = {
    {
      "<leader>fe",
      function()
        Snacks.explorer({ cwd = root.get() })
      end,
      desc = "Explorer (Root Dir)",
    },
    {
      "<leader>fE",
      function()
        Snacks.explorer()
      end,
      desc = "Explorer (CWD)",
    },
    { "<leader>e", "<leader>fe", desc = "Explorer (Root Dir)", remap = true },
    { "<leader>E", "<leader>fE", desc = "Explorer (CWD)", remap = true },
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
          local cwd = root.get({ normalize = true, spec = { "startup", { ".git", "lua" }, "cwd" } })
          require("fff").live_grep({ query = text, cwd = cwd })
        end
      end,
    },
  },
}
