--- trouble.nvim: opt-in results sidebar, toggled manually via <leader>xq
--- (quickfix) / <leader>xl (loclist) — see lua/config/keymaps.lua.
--- The default result flows (<C-q> / <A-t> in pickers) spawn the plain
--- quickfix buffer instead of routing through here.
return {
  {
    src = "https://github.com/folke/trouble.nvim",
    opts = {},
  },
}
