return {
  {
    "nickkadutskyi/jb.nvim",
    priority = 2000,
    lazy = false,
    config = function()
      -- jb paints FloatBorder with its notification background (#323438),
      -- which doesn't match float interiors (NormalFloat bg #2b2d30), so every
      -- float gets visible border slabs; its border fg (#43454a) is also
      -- near-invisible in terminals. Match the border slab to each float's own
      -- background and use a readable fg. Resolved at runtime so it tracks jb.
      local function fix_borders()
        local hl = vim.api.nvim_set_hl
        local function bg_of(name)
          local ok, d = pcall(vim.api.nvim_get_hl, 0, { name = name, link = false })
          return (ok and d and d.bg) and string.format("#%06x", d.bg) or nil
        end
        -- Picker/list/preview floats use NormalFloat as their background.
        hl(0, "FloatBorder", { fg = "#5A5D6B", bg = bg_of("NormalFloat") })
        -- Snacks input windows use Normal (editor bg) instead of NormalFloat.
        local input_bg = bg_of("SnacksInputNormal") or bg_of("Normal")
        hl(0, "SnacksInputBorder", { fg = "#6F737A", bg = input_bg })
        hl(0, "SnacksInputTitle", { fg = "#6F737A", bg = input_bg })
        -- jb's picker/explorer integration deliberately hides borders for a
        -- "tool window" look: SnacksPickerBorder fg = editor bg, the input
        -- border fg = bg = panel bg, prompt fg = panel bg. That reads as
        -- broken/missing borders in a terminal, so restore them.
        local panel_bg = bg_of("SnacksPickerInput") or float_bg
        hl(0, "SnacksPickerBorder", { fg = "#5A5D6B", bg = panel_bg })
        hl(0, "SnacksPickerInputBorder", { fg = "#6F737A", bg = panel_bg })
        hl(0, "SnacksPickerPrompt", { fg = "#6F737A" })
        -- Picker rows show "file:line:col"; snacks links these to String (jb's
        -- saturated green) / LineNr / Delimiter. Mute them JetBrains-style.
        local subtle = "#7A7E87"
        hl(0, "SnacksPickerRow", { fg = subtle })
        hl(0, "SnacksPickerCol", { fg = subtle })
        hl(0, "SnacksPickerDelim", { fg = subtle })
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
