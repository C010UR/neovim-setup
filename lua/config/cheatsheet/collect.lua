--- Runtime harvesting of the config's own keymaps.
---
--- `nvim_get_keymap(mode)` only ever returns user/plugin defined maps (never
--- Vim's built-in defaults), which is exactly what we want here: the curated
--- default tables cover stock Neovim, this fills in everything the config and
--- its plugins register globally.
local M = {}

--- Leader-prefixed groups, in the order they should appear on the page.
--- Longest / most specific prefixes must come first.
local RULES = {
  { "<leader><tab>", "Tabs" },
  { "<leader>dp", "Profiler" },
  { "<leader>d", "Debug" },
  { "<leader>b", "Buffer" },
  { "<leader>c", "Code" },
  { "<leader>g", "Git" },
  { "<leader>q", "Session" },
  { "<leader>u", "UI" },
  { "<leader>x", "Results" },
  { "<leader>9", "AI" },
  { "<leader>w", "Windows" },
  { "<leader>e", "Explorer" },
  { "<leader>", "Leader" },
  { "[", "Prev" },
  { "]", "Next" },
  { "g", "Goto" },
  { "z", "Fold" },
  { "s", "Surround" },
}

--- `nvim_get_keymap` expands the leader to its literal character. Put the
--- friendly names back so the sheet reads like the config source.
local function normalize(lhs)
  lhs = lhs or ""
  if lhs:sub(1, 1) == " " then
    return "<leader>" .. lhs:sub(2)
  end
  if lhs:sub(1, 1) == "\\" then
    return "<localleader>" .. lhs:sub(2)
  end
  return lhs
end

--- Gather global maps for `modes` into a `lhs -> { desc }` map.
function M.gather(modes)
  local map = {}
  for _, mode in ipairs(modes or {}) do
    local ok, maps = pcall(vim.api.nvim_get_keymap, mode)
    if ok then
      for _, entry in ipairs(maps) do
        local desc = entry.desc
        if type(desc) == "string" and desc ~= "" and desc ~= "which_key_ignore" then
          local lhs = normalize(entry.lhs)
          if lhs ~= "" and not lhs:find("<Plug>", 1, true) then
            map[lhs] = { desc = desc }
          end
        end
      end
    end
  end
  return map
end

--- Fold live maps into existing curated sections. When a curated entry shares
--- an lhs with a live map the live description wins (it reflects what the key
--- actually does now) and the live entry is consumed so it is not repeated.
---
--- Sections marked `fixed = true` keep their curated wording (used for the
--- beginner-facing "Start Here" section) but still consume the live entry.
function M.overlay(sections, map)
  for _, section in ipairs(sections or {}) do
    for _, entry in ipairs(section.entries or {}) do
      local live = map[entry.key]
      if live then
        if not section.fixed then
          entry.desc = live.desc
          entry.customized = true
        end
        map[entry.key] = nil
      end
    end
  end
end

--- Turn whatever is left in `map` into grouped sections.
function M.remaining_sections(map)
  local buckets = {}
  local others = {}
  for lhs, item in pairs(map) do
    local name
    for _, rule in ipairs(RULES) do
      if lhs:sub(1, #rule[1]) == rule[1] then
        name = rule[2]
        break
      end
    end
    if name then
      buckets[name] = buckets[name] or {}
      buckets[name][#buckets[name] + 1] = { key = lhs, desc = item.desc }
    else
      others[#others + 1] = { key = lhs, desc = item.desc }
    end
  end

  local sections = {}
  for _, rule in ipairs(RULES) do
    local list = buckets[rule[2]]
    if list and #list > 0 then
      table.sort(list, function(a, b)
        return a.key < b.key
      end)
      sections[#sections + 1] = { name = rule[2] .. " Keymaps", entries = list }
    end
  end
  if #others > 0 then
    table.sort(others, function(a, b)
      return a.key < b.key
    end)
    sections[#sections + 1] = { name = "Other Keymaps", entries = others }
  end
  return sections
end

return M
