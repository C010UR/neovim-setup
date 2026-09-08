return {
  {
    "nickkadutskyi/jb.nvim",
    priority = 2000,
    lazy = false,
    config = function()
      -- jb styles snacks floats as lighter "tool windows" (#2b2d30) with
      -- deliberately hidden borders. We want snacks windows to follow the
      -- editor background instead, with visible border chars.
      local function fix_borders()
        local hl = vim.api.nvim_set_hl
        local function bg_of(name)
          local ok, d = pcall(vim.api.nvim_get_hl, 0, { name = name, link = false })
          return (ok and d and d.bg) and string.format("#%06x", d.bg) or nil
        end
        local editor_bg = bg_of("Normal")
        -- Snacks picker/explorer/preview/input windows follow the buffer bg.
        for _, name in ipairs({
          "SnacksPicker",
          "SnacksPickerList",
          "SnacksPickerInput",
          "SnacksPickerPreview",
          "SnacksPickerBox",
        }) do
          hl(0, name, { link = "Normal" })
        end
        -- Visible border chars on the editor bg.
        hl(0, "FloatBorder", { fg = "#5A5D6B", bg = editor_bg })
        hl(0, "SnacksPickerBorder", { fg = "#5A5D6B", bg = editor_bg })
        hl(0, "SnacksPickerInputBorder", { fg = "#6F737A", bg = editor_bg })
        hl(0, "SnacksPickerPrompt", { fg = "#6F737A" })
        hl(0, "SnacksInputBorder", { fg = "#6F737A", bg = editor_bg })
        hl(0, "SnacksInputTitle", { fg = "#6F737A", bg = editor_bg })
      end
      vim.api.nvim_create_autocmd("ColorScheme", {
        group = vim.api.nvim_create_augroup("config_jb_float_borders", { clear = true }),
        callback = fix_borders,
      })
      vim.cmd.colorscheme("jb")
      fix_borders()
    end,
  },
  {
    "folke/tokyonight.nvim",
    opts = { style = "night" },
    config = function(_, opts)
      require("tokyonight").setup(opts)
    end,
  },
  { "ellisonleao/gruvbox.nvim" },
  {
    "catppuccin/nvim",
    name = "catppuccin",
    opts = {
      flavour = "frappe",
      lsp_styles = {
        underlines = {
          errors = { "undercurl" },
          hints = { "undercurl" },
          warnings = { "undercurl" },
          information = { "undercurl" },
        },
      },
      integrations = {
        aerial = true,
        alpha = true,
        dashboard = true,
        flash = true,
        fzf = true,
        grug_far = true,
        headlines = true,
        illuminate = true,
        indent_blankline = { enabled = true },
        leap = true,
        mason = true,
        mini = true,
        navic = { enabled = true, custom_bg = "lualine" },
        neotree = true,
        notify = true,
        snacks = true,
        treesitter_context = true,
        which_key = true,
      },
    },
    specs = {
      {
        "akinsho/bufferline.nvim",
        optional = true,
        opts = function(_, opts)
          if (vim.g.colors_name or ""):find("catppuccin") then
            opts.highlights = require("catppuccin.special.bufferline").get_theme()
          end
        end,
      },
    },
  },
}
