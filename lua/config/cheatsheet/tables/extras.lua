--- Keymaps that are not visible to global introspection, so they are curated
--- here instead: LSP buffer-local maps, picker/explorer window keys, and
--- filetype-specific mappings.
---
--- Live global maps with the same `lhs` are merged over these at runtime, so
--- descriptions stay accurate and nothing is listed twice.

local M = {}

M.n = {
  {
    name = "LSP (buffer-local)",
    entries = {
      { "gd", "Go to definition" },
      { "gD", "Go to declaration" },
      { "gy", "Go to type definition" },
      { "gI", "Go to implementation" },
      { "gr", "References" },
      { "gK", "Signature help" },
      { "K", "Hover" },
      { "gai", "Incoming calls" },
      { "gao", "Outgoing calls" },
      { "]]", "Next highlighted reference" },
      { "[[", "Previous highlighted reference" },
      { "<A-n>", "Next highlighted reference" },
      { "<A-p>", "Previous highlighted reference" },
      { "<leader>cl", "LSP info" },
      { "<leader>ca", "Code actions" },
      { "<leader>cc", "Run code lens" },
      { "<leader>cC", "Refresh code lens" },
      { "<leader>cr", "Rename symbol" },
      { "<leader>cR", "Rename file" },
      { "<leader>cA", "Run source action" },
      { "<leader>co", "Organize imports" },
      { "<leader>cn", "Generate annotations" },
    },
  },
  {
    name = "TypeScript (buffer-local)",
    entries = {
      { "gD", "Go to source definition" },
      { "gR", "File references" },
      { "<leader>cM", "Add missing imports" },
      { "<leader>cu", "Remove unused imports" },
      { "<leader>cD", "Fix all diagnostics" },
      { "<leader>cV", "Select workspace TypeScript version" },
    },
  },
  {
    name = "Picker Sources",
    entries = {
      { "<leader><space>", "Find files (root dir)" },
      { "<leader>/", "Grep (project)" },
      { "<leader>s", "Symbols (workspace)" },
      { "<leader>R", "Replace in files" },
      { "<leader>a", "Commands & actions" },
      { "<leader>xx", "Find diagnostics" },
      { "<leader>xX", "Find buffer diagnostics" },
      { "<leader>cs", "Document symbols" },
      { "<leader>xT", "TODO / FIXME list" },
      { "<leader>gd", "Find git diff hunks" },
      { "<leader>gD", "Git diff vs origin" },
      { "<leader>gs", "Find git status" },
      { "<leader>gS", "Find git stash" },
      { "<leader>uC", "Browse colorschemes" },
      { "<leader>:", "Command history" },
      { "<leader>n", "Notification history" },
      { "<leader>U", "Undo tree" },
    },
  },
  {
    name = "Picker Window",
    entries = {
      { "<A-c>", "Toggle picker root / CWD" },
      { "<A-s>", "Flash picker results" },
      { "s", "Flash picker results" },
      { "<C-q>", "Results to quickfix buffer" },
      { "<A-t>", "Results to quickfix buffer" },
      { "<Tab>", "Select entry and move down" },
    },
  },
  {
    name = "Terminal & Explorer",
    entries = {
      { "<leader>t", "Terminal (root dir)" },
      { "<leader>T", "Terminal (CWD)" },
      { "<C-/>", "Focus terminal (root dir)" },
      { "<leader>e", "Explorer (root dir)" },
      { "<leader>E", "Explorer (CWD)" },
    },
  },
}

M.i = {
  {
    name = "LSP & Filetype",
    entries = {
      { "<C-k>", "Signature help" },
      { "<leader>cv", "Select virtualenv (python)" },
      { "<leader>dPt", "Debug test method (python)" },
      { "<leader>dPc", "Debug test class (python)" },
    },
  },
}

M.v = {
  {
    name = "LSP (buffer-local)",
    entries = {
      { "<leader>ca", "Code actions" },
      { "<leader>cc", "Run code lens" },
      { "<leader>cf", "Format selection" },
      { "<leader>de", "Evaluate expression" },
    },
  },
  {
    name = "Config Helpers",
    entries = {
      { "<leader>R", "Replace in files" },
      { "<leader>/", "Grep visual selection" },
      { "<leader>gB", "Git browse URL" },
      { "<leader>gY", "Copy git browse URL" },
      { "<leader>99", "99: work on selection" },
    },
  },
}

return M
