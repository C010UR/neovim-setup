return {
  src = "https://github.com/dmtrKovalenko/fff.nvim",
  build = function()
    require("fff.download").download_or_build_binary()
  end,
  config = function(_, opts)
    require("fff").setup(opts)

    local function setup_fff_highlights()
      local nf = vim.api.nvim_get_hl(0, { name = "NormalFloat", link = false })
      local float_bg = nf.bg

      local function with_float_bg(name, source, extras)
        local hl = vim.api.nvim_get_hl(0, { name = source, link = false })
        local def = { fg = hl.fg, bg = float_bg }
        if hl.bold then
          def.bold = true
        end
        if hl.italic then
          def.italic = true
        end
        if hl.underline then
          def.underline = true
        end
        vim.api.nvim_set_hl(0, name, vim.tbl_extend("force", def, extras or {}))
      end

      with_float_bg("FffTitle", "Title")
      with_float_bg("FffFileInfoSection", "Title")

      local cl = vim.api.nvim_get_hl(0, { name = "CursorLine", link = false })
      local cursor_bg = cl.bg
      if not cursor_bg then
        local psel_fallback = vim.api.nvim_get_hl(0, { name = "PmenuSel", link = false })
        cursor_bg = psel_fallback.bg
      end
      vim.api.nvim_set_hl(0, "FffCursor", {
        fg = cl.fg,
        bg = cursor_bg,
        bold = cl.bold,
        italic = cl.italic,
        underline = cl.underline,
      })

      local psel = vim.api.nvim_get_hl(0, { name = "PmenuSel", link = false })
      vim.api.nvim_set_hl(0, "FffSelectedActive", {
        fg = psel.fg,
        bg = psel.bg,
        bold = true,
        italic = psel.italic,
        underline = psel.underline,
      })

      local comment = vim.api.nvim_get_hl(0, { name = "Comment", link = false })
      vim.api.nvim_set_hl(0, "FffComment", {
        fg = comment.fg,
        bg = "NONE",
        bold = comment.bold,
        italic = comment.italic,
        underline = comment.underline,
      })

      local git_signs = {
        { "FffGitSignStaged", "FFFGitSignStaged" },
        { "FffGitSignModified", "FFFGitSignModified" },
        { "FffGitSignDeleted", "FFFGitSignDeleted" },
        { "FffGitSignRenamed", "FFFGitSignRenamed" },
        { "FffGitSignUntracked", "FFFGitSignUntracked" },
        { "FffGitSignIgnored", "FFFGitSignIgnored" },
      }
      for _, pair in ipairs(git_signs) do
        local new_name, orig_name = pair[1], pair[2]
        local hl = vim.api.nvim_get_hl(0, { name = orig_name, link = false })
        vim.api.nvim_set_hl(0, new_name, { fg = hl.fg, bg = float_bg })
      end

      local git_selected = {
        { "FffGitSignStagedSelected", "FFFGitSignStagedSelected" },
        { "FffGitSignModifiedSelected", "FFFGitSignModifiedSelected" },
        { "FffGitSignDeletedSelected", "FFFGitSignDeletedSelected" },
        { "FffGitSignRenamedSelected", "FFFGitSignRenamedSelected" },
        { "FffGitSignUntrackedSelected", "FFFGitSignUntrackedSelected" },
        { "FffGitSignIgnoredSelected", "FFFGitSignIgnoredSelected" },
      }
      for _, pair in ipairs(git_selected) do
        local new_name, orig_name = pair[1], pair[2]
        local hl = vim.api.nvim_get_hl(0, { name = orig_name, link = false })
        vim.api.nvim_set_hl(0, new_name, { fg = hl.fg, bg = cursor_bg })
      end
    end

    setup_fff_highlights()
    vim.api.nvim_create_autocmd("ColorScheme", {
      callback = setup_fff_highlights,
    })
  end,
  opts = {
    max_results = 100,
    max_threads = 16,
    layout = {
      height = 0.8,
      width = 0.8,
      prompt_position = "top",
      preview_position = "right",
      preview_size = 0.5,
      anchor = "center",
    },
    preview = {
      enabled = true,
      line_numbers = true,
    },
    hl = {
      title = "FffTitle",
      cursor = "FffCursor",
      selected_active = "FffSelectedActive",
      grep_line_number = "FffComment",
      file_info_section = "FffFileInfoSection",
      file_info_separator = "FloatBorder",
      file_info_label = "FffComment",
      winhl = "Normal:NormalFloat,NormalNC:NormalFloat,FloatBorder:FloatBorder,FloatTitle:FffTitle,SignColumn:NormalFloat",
      git_sign_staged = "FffGitSignStaged",
      git_sign_modified = "FffGitSignModified",
      git_sign_deleted = "FffGitSignDeleted",
      git_sign_renamed = "FffGitSignRenamed",
      git_sign_untracked = "FffGitSignUntracked",
      git_sign_ignored = "FffGitSignIgnored",
      git_sign_staged_selected = "FffGitSignStagedSelected",
      git_sign_modified_selected = "FffGitSignModifiedSelected",
      git_sign_deleted_selected = "FffGitSignDeletedSelected",
      git_sign_renamed_selected = "FffGitSignRenamedSelected",
      git_sign_untracked_selected = "FffGitSignUntrackedSelected",
      git_sign_ignored_selected = "FffGitSignIgnoredSelected",
    },
    grep = {
      smart_case = true,
    },
    frecency = {
      enabled = true,
    },
    history = {
      enabled = true,
    },
  },
}
