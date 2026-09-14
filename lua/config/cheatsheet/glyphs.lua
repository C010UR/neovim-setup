--- Nerd Font glyphs used to present key notation.
---
--- Keys are stored in Neovim's `<C-x>` / `<leader>` notation; `M.pretty`
--- rewrites those tokens into their icons for display, e.g.:
---
---   <C-d>          -> ctrl d
---   <S-Tab>        -> shift tab
---   <C-S-Space>    -> ctrl shift space
---   <leader>bd     -> space bd
---
--- Codepoints come from Material Design Icons (nerd-fonts glyphnames.json).
local M = {}

M.ctrl = "\u{f0634}" -- nf-md-apple_keyboard_control
M.shift = "\u{f0636}" -- nf-md-apple_keyboard_shift
M.alt = "\u{f0635}" -- nf-md-apple_keyboard_option
M.cmd = "\u{f0633}" -- nf-md-apple_keyboard_command
M.tab = "\u{f0312}" -- nf-md-keyboard_tab
M.space = "\u{f1050}" -- nf-md-keyboard_space
M.enter = "\u{f0311}" -- nf-md-keyboard_return
M.backspace = "\u{f030d}" -- nf-md-keyboard_backspace
M.esc = "\u{f12b7}" -- nf-md-keyboard_esc

local KEY_TOKENS = {
  leader = M.space,
  localleader = "\\",
  space = M.space,
  tab = M.tab,
  cr = M.enter,
  enter = M.enter,
  ["return"] = M.enter,
  bs = M.backspace,
  backspace = M.backspace,
  esc = M.esc,
  escape = M.esc,
}

local MODIFIERS = {
  c = M.ctrl,
  control = M.ctrl,
  s = M.shift,
  shift = M.shift,
  a = M.alt,
  alt = M.alt,
  m = M.alt,
  meta = M.alt,
  d = M.cmd,
  super = M.cmd,
  cmd = M.cmd,
  command = M.cmd,
}

--- Rewrite every `<...>` token in `key` into its glyph form.
function M.pretty(key)
  return (key:gsub("<([^>]+)>", function(token)
    local lower = token:lower()
    if KEY_TOKENS[lower] then
      return KEY_TOKENS[lower]
    end

    local parts = vim.split(token, "-", { plain = true })
    local out = {}
    for index, part in ipairs(parts) do
      if index < #parts then
        out[#out + 1] = MODIFIERS[part:lower()] or part
      else
        out[#out + 1] = KEY_TOKENS[part:lower()] or part
      end
    end
    return table.concat(out)
  end))
end

return M
