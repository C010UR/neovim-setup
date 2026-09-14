--- Keymaps for "special buffers" and transient contexts: pickers, the file
--- explorer, LSP prompts/floats, the Trouble sidebar and the debugger.
---
--- These are curated (not introspected) because the keys live in plugin-managed
--- windows that only exist while that UI is open. Entries are the same
--- `{ "<key>", "<description>" }` rows used everywhere else, and `<...>` tokens
--- are turned into Nerd Font glyphs at render time.

return {
  pickers = {
    {
      name = "Open & Close",
      entries = {
        { "<CR>", "Confirm / open the selection" },
        { "<Esc>", "Close the picker" },
        { "q", "Close (normal mode)" },
        { "<C-c>", "Cancel (insert mode)" },
        { "/", "Move focus between input and list" },
      },
    },
    {
      name = "Open a Result",
      entries = {
        { "<CR>", "Open in the current window" },
        { "<C-s>", "Open in a horizontal split" },
        { "<C-v>", "Open in a vertical split" },
        { "<C-t>", "Open in a new tab" },
        { "<S-CR>", "Pick a window and jump to it" },
      },
    },
    {
      name = "Move in the List",
      entries = {
        { "<C-n>", "Next item" },
        { "<C-p>", "Previous item" },
        { "<Down>", "Next item" },
        { "<Up>", "Previous item" },
        { "j", "Next item (list focused)" },
        { "k", "Previous item (list focused)" },
        { "gg", "Jump to the first item" },
        { "G", "Jump to the last item" },
        { "<C-d>", "Scroll the list down" },
        { "<C-u>", "Scroll the list up" },
        { "zz", "Center the current item" },
        { "zt", "Current item to the top" },
        { "zb", "Current item to the bottom" },
      },
    },
    {
      name = "Select & Send",
      entries = {
        { "<Tab>", "Select item and move down" },
        { "<S-Tab>", "Select item and move up" },
        { "<C-a>", "Select all items" },
        { "<C-q>", "Send results to the quickfix list" },
        { "<A-t>", "Send results to quickfix (config)" },
      },
    },
    {
      name = "Search & Filter",
      entries = {
        { "<A-c>", "Toggle picker root / CWD (config)" },
        { "<A-s>", "Flash picker results (config)" },
        { "s", "Flash picker results (config)" },
        { "<A-f>", "Toggle follow current file" },
        { "<A-h>", "Toggle hidden files" },
        { "<A-i>", "Toggle ignored files" },
        { "<A-r>", "Toggle regex search" },
        { "<A-d>", "Inspect the current item" },
        { "<C-g>", "Toggle live search" },
      },
    },
    {
      name = "Window & Preview",
      entries = {
        { "<A-p>", "Toggle the preview pane" },
        { "<A-m>", "Maximize the picker" },
        { "<A-w>", "Cycle between the windows" },
        { "<C-b>", "Scroll the preview up" },
        { "<C-f>", "Scroll the preview down" },
        { "<C-w>H", "Move layout to the left" },
        { "<C-w>J", "Move layout to the bottom" },
        { "<C-w>K", "Move layout to the top" },
        { "<C-w>L", "Move layout to the right" },
      },
    },
    {
      name = "Files & Grep (fff)",
      entries = {
        { "<Esc>", "Close the fff picker" },
        { "q", "Close (normal mode)" },
        { "<CR>", "Open file / jump to match" },
        { "<C-s>", "Open in a horizontal split" },
        { "<C-v>", "Open in a vertical split" },
        { "<C-t>", "Open in a new tab" },
        { "<Tab>", "Select / add to multi-select" },
        { "<C-q>", "Send selection to quickfix" },
        { "<A-t>", "Send selection to quickfix (config)" },
        { "<C-p>", "Move up" },
        { "<C-n>", "Move down" },
        { "<C-u>", "Scroll the preview up" },
        { "<C-d>", "Scroll the preview down" },
      },
    },
    {
      name = "Grep Mode (fff)",
      entries = {
        { "<S-Tab>", "Cycle grep modes: text / regex / fuzzy" },
        { "<C-CR>", "Insert a newline into the query" },
        { "<C-A-n>", "Jump to the next file group" },
        { "<A-Down>", "Jump to the next file group" },
        { "<C-A-p>", "Jump to the previous file group" },
        { "<A-Up>", "Jump to the previous file group" },
        { "<C-Up>", "Previous query from history" },
        { "<C-Down>", "Next query from history" },
        { "<leader>l", "Focus the result list" },
        { "<leader>p", "Focus the preview" },
      },
    },
  },

  explorer = {
    {
      name = "Navigation",
      entries = {
        { "<Tab>", "Select entry and move down" },
        { "<CR>", "Open file / expand directory" },
        { "l", "Open the current entry" },
        { "h", "Close the current directory" },
        { "<BS>", "Go to the parent directory" },
        { "j", "Next entry" },
        { "k", "Previous entry" },
        { "gg", "First entry" },
        { "G", "Last entry" },
        { ".", "Reveal the current file" },
        { "<Esc>", "Close the explorer" },
      },
    },
    {
      name = "File Actions",
      entries = {
        { "a", "Add a file or directory" },
        { "d", "Delete the selection" },
        { "r", "Rename the selection" },
        { "c", "Copy the selection" },
        { "m", "Move the selection" },
        { "y", "Yank the path" },
        { "p", "Paste (after copy or move)" },
        { "o", "Open with the system application" },
        { "u", "Update / refresh the tree" },
        { "Z", "Close all directories" },
      },
    },
    {
      name = "View & Filters",
      entries = {
        { "P", "Toggle the preview" },
        { "I", "Toggle ignored files" },
        { "H", "Toggle hidden files" },
        { "<leader>cf", "Format the selected files (config)" },
        { "<leader>/", "Grep from the tree" },
        { "<C-c>", "Change directory to the tree root" },
        { "<C-t>", "Open a terminal in the tree" },
        { "?", "Show explorer keymaps (help)" },
        { "]g", "Next git change" },
        { "[g", "Previous git change" },
        { "]d", "Next diagnostic" },
        { "[d", "Previous diagnostic" },
      },
    },
  },

  lsp = {
    {
      name = "Go To",
      entries = {
        { "gd", "Definition" },
        { "gD", "Declaration" },
        { "gy", "Type definition" },
        { "gI", "Implementation" },
        { "gr", "References" },
        { "gai", "Incoming calls" },
        { "gao", "Outgoing calls" },
      },
    },
    {
      name = "Info",
      entries = {
        { "K", "Hover documentation" },
        { "gK", "Signature help" },
        { "<C-k>", "Signature help (insert mode)" },
        { "<leader>cd", "Line diagnostics (float)" },
        { "<leader>cl", "LSP information" },
        { "<leader>cm", "Mason (install servers)" },
      },
    },
    {
      name = "Actions",
      entries = {
        { "<leader>ca", "Code actions" },
        { "<leader>cr", "Rename symbol" },
        { "<leader>cR", "Rename file" },
        { "<leader>cA", "Run source action" },
        { "<leader>co", "Organize imports" },
        { "<leader>cf", "Format buffer or selection" },
        { "<leader>cF", "Format injected languages" },
        { "<leader>cn", "Generate annotations" },
      },
    },
    {
      name = "In the Prompt",
      entries = {
        { "j", "Move to the next choice" },
        { "k", "Move to the previous choice" },
        { "<C-n>", "Next choice" },
        { "<C-p>", "Previous choice" },
        { "<CR>", "Apply the selected choice" },
        { "<Esc>", "Cancel without applying" },
      },
    },
    {
      name = "Highlights & Symbols",
      entries = {
        { "]]", "Next highlighted reference" },
        { "[[", "Previous highlighted reference" },
        { "<A-n>", "Next highlighted reference" },
        { "<A-p>", "Previous highlighted reference" },
        { "<leader>cs", "Document symbols" },
        { "<leader>s", "Workspace symbols" },
      },
    },
    {
      name = "Diagnostics",
      entries = {
        { "]d", "Next diagnostic" },
        { "[d", "Previous diagnostic" },
        { "]e", "Next error" },
        { "[e", "Previous error" },
        { "]w", "Next warning" },
        { "[w", "Previous warning" },
        { "<leader>xx", "Find diagnostics" },
        { "<leader>xX", "Find buffer diagnostics" },
      },
    },
    {
      name = "Floating Windows",
      entries = {
        { "<C-f>", "Scroll down" },
        { "<C-b>", "Scroll up" },
        { "<C-d>", "Scroll down (half page)" },
        { "<C-u>", "Scroll up (half page)" },
        { "q", "Close the float" },
        { "<Esc>", "Close the float" },
      },
    },
  },

  trouble = {
    {
      name = "Open & Close",
      entries = {
        { "<leader>xq", "Toggle quickfix sidebar" },
        { "<leader>xl", "Toggle location sidebar" },
        { "?", "Show help" },
        { "q", "Close the sidebar" },
        { "<Esc>", "Cancel" },
      },
    },
    {
      name = "Jump",
      entries = {
        { "<CR>", "Jump to the item" },
        { "o", "Jump and close" },
        { "<C-s>", "Jump in a horizontal split" },
        { "<C-v>", "Jump in a vertical split" },
        { "]]", "Next item" },
        { "[[", "Previous item" },
        { "}", "Next item" },
        { "{", "Previous item" },
      },
    },
    {
      name = "Preview & Inspect",
      entries = {
        { "p", "Preview the item" },
        { "P", "Toggle the preview" },
        { "i", "Inspect the item" },
      },
    },
    {
      name = "Manage",
      entries = {
        { "r", "Refresh the list" },
        { "R", "Toggle auto refresh" },
        { "dd", "Delete the item" },
        { "d", "Delete (visual mode)" },
        { "s", "Toggle the severity filter" },
        { "gb", "Toggle current buffer filter" },
      },
    },
    {
      name = "Folds",
      entries = {
        { "zo", "Open fold" },
        { "zc", "Close fold" },
        { "za", "Toggle fold" },
        { "zR", "Open all folds" },
        { "zM", "Close all folds" },
        { "zr", "Reduce folds" },
        { "zm", "Fold more" },
        { "zx", "Update folds" },
        { "zn", "Disable folding" },
        { "zi", "Toggle folding" },
      },
    },
    {
      name = "Diagnostics (global)",
      entries = {
        { "]d", "Next diagnostic" },
        { "[d", "Previous diagnostic" },
        { "]e", "Next error" },
        { "[e", "Previous error" },
        { "]w", "Next warning" },
        { "[w", "Previous warning" },
        { "<leader>cd", "Line diagnostics (float)" },
      },
    },
  },

  debug = {
    {
      name = "Start & Control",
      entries = {
        { "<leader>dc", "Continue / start debugging" },
        { "<leader>da", "Run with arguments" },
        { "<leader>dC", "Run to the cursor" },
        { "<leader>dl", "Run the last session" },
        { "<leader>dg", "Go to a line (no execute)" },
        { "<leader>dP", "Pause" },
        { "<leader>dt", "Terminate" },
      },
    },
    {
      name = "Breakpoints",
      entries = {
        { "<leader>db", "Toggle a breakpoint" },
        { "<leader>dB", "Set a conditional breakpoint" },
      },
    },
    {
      name = "Stepping",
      entries = {
        { "<leader>di", "Step into" },
        { "<leader>dO", "Step over" },
        { "<leader>do", "Step out" },
        { "<leader>dj", "Go down a stack frame" },
        { "<leader>dk", "Go up a stack frame" },
      },
    },
    {
      name = "UI & Inspect",
      entries = {
        { "<leader>du", "Toggle the debug UI" },
        { "<leader>de", "Evaluate an expression" },
        { "<leader>dr", "Toggle the debug REPL" },
        { "<leader>dw", "Debug widgets (hover)" },
        { "<leader>ds", "Show the debug session" },
      },
    },
    {
      name = "Python Tests",
      entries = {
        { "<leader>dPt", "Debug the test method" },
        { "<leader>dPc", "Debug the test class" },
      },
    },
  },
}
