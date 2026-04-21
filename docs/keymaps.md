# Keymap inventory

_Audited against the explicit repo-defined mappings on April 21, 2026._

## Scope and conventions

- Leader keys come from `lua/config/options.lua`:
  - `<leader>` = `Space`
  - `<localleader>` = `\`
- Source of truth:
  - direct `vim.keymap.set(...)` / local `map(...)`
  - normalized plugin-spec `keys = { ... }` entries loaded through `lua/config/pack.lua`
  - `Snacks.toggle(...):map(...)`
  - LSP key specs registered through `config.lsp.register_keys()` and attached in `config.lsp.enable_keymaps()`
  - repo-customized plugin-local key tables such as Snacks terminal/picker/dashboard keys
- This doc includes **explicit repo-defined mappings and repo-customized plugin-local key tables**.
- Unchanged upstream defaults are intentionally omitted. That includes most defaults from `mini.comment`, `mini.surround`, and `mini.move` that the repo does not override.
- Scope labels used below: `global`, `buffer-local`, `filetype-local`, `terminal-local`, `picker-local`, `dashboard-local`, and `conditional`.

## Core editing and movement

### Core remaps from `lua/config/keymaps.lua`

- `j`, `<Down>` — modes `n,x`; scope `global` — Move by display line when no count is given, otherwise use real line movement.
- `k`, `<Up>` — modes `n,x`; scope `global` — Move up by display line when no count is given, otherwise use real line movement.
- `<A-j>` — modes `n,i,v`; scope `global` — Move the current line or selection down and reindent.
- `<A-k>` — modes `n,i,v`; scope `global` — Move the current line or selection up and reindent.
- `<Esc>` — modes `i,n,s`; scope `global` — Clear search highlight, stop an active snippet if needed, then send a real Escape.
- `n` — modes `n,x,o`; scope `global` — Repeat search forward/backward according to the current search direction; normal mode also opens folds with `zv`.
- `N` — modes `n,x,o`; scope `global` — Repeat search in the opposite direction; normal mode also opens folds with `zv`.
- `,`, `.`, `;` — mode `i`; scope `global` — Insert punctuation and create an undo breakpoint.
- `<C-s>` — modes `i,n,x,s`; scope `global` — Save the current file.
- `<Tab>` — modes `i,s`; scope `global` — Accept the current popup completion item (selecting the first item when needed), otherwise accept inline completion, jump to the next snippet tabstop, or insert a literal tab.
- `<C-Space>` — mode `i`; scope `global` — Trigger native LSP completion manually.
- `<` — mode `x`; scope `global` — Indent left and keep the selection active.
- `>` — mode `x`; scope `global` — Indent right and keep the selection active.
- `gco` — mode `n`; scope `global` — Insert a commented line below.
- `gcO` — mode `n`; scope `global` — Insert a commented line above.

### Flash maps from `lua/plugins/editor.lua`

- `s` — modes `n,x,o`; scope `global` — Flash jump.
- `S` — modes `n,x,o`; scope `global` — Flash Treesitter jump.
- `r` — mode `o`; scope `global` — Remote Flash.
- `R` — modes `o,x`; scope `global` — Treesitter search.
- `<C-s>` — mode `c`; scope `global` — Toggle Flash search in command-line mode.
- `<C-Space>` — modes `n,o,x`; scope `global` — Start Flash Treesitter incremental selection. Inside that transient Flash session, the repo also maps `<C-Space>` to next and `<BS>` to previous.

### Which-key helpers from `lua/plugins/editor.lua`

- `<leader>?` — mode `n`; scope `global` — Show buffer-local keymaps in which-key.
- `<C-w><Space>` — mode `n`; scope `global` — Open a window-command which-key loop (“window hydra”).

## Buffers / tabs / windows

### Window and buffer management from `lua/config/keymaps.lua`

- `<C-h>` — mode `n`; scope `global` — Go to the left window.
- `<C-j>` — mode `n`; scope `global` — Go to the lower window.
- `<C-k>` — mode `n`; scope `global` — Go to the upper window.
- `<C-l>` — mode `n`; scope `global` — Go to the right window.
- `<C-Up>` — mode `n`; scope `global` — Increase window height.
- `<C-Down>` — mode `n`; scope `global` — Decrease window height.
- `<C-Left>` — mode `n`; scope `global` — Decrease window width.
- `<C-Right>` — mode `n`; scope `global` — Increase window width.
- `<S-h>` — mode `n`; scope `global` — Previous buffer.
- `<S-l>` — mode `n`; scope `global` — Next buffer.
- `[b` — mode `n`; scope `global` — Previous buffer.
- `]b` — mode `n`; scope `global` — Next buffer.
- `<leader>\`` — mode `n`; scope `global` — Switch to the alternate buffer.
- `<leader>bb` — mode `n`; scope `global` — Reload the current buffer from disk.
- `<leader>bd` — mode `n`; scope `global` — Delete the current buffer via `Snacks.bufdelete()`.
- `<leader>bo` — mode `n`; scope `global` — Delete all other buffers.
- `<leader>bD` — mode `n`; scope `global` — Delete the current buffer and window.
- `<leader>bc` — mode `n`; scope `global` — Copy the current buffer's relative path to the clipboard.
- `<leader>bC` — mode `n`; scope `global` — Copy the current buffer's relative path plus line number.
- `<leader>bn` — mode `n`; scope `global` — Open a `path[:line[:col]]` value from the clipboard.
- `<leader>wd` — mode `n`; scope `global` — Close the current window.
- `<leader>wm` — mode `n`; scope `global` — Toggle window zoom.
- `<leader>uZ` — mode `n`; scope `global` — Alias for the same window zoom toggle.

### Bufferline maps from `lua/plugins/ui.lua`

- `<leader>bp` — mode `n`; scope `global` — Toggle pin on the current buffer.
- `<leader>bP` — mode `n`; scope `global` — Close all non-pinned buffers.
- `<leader>br` — mode `n`; scope `global` — Close buffers to the right.
- `<leader>bl` — mode `n`; scope `global` — Close buffers to the left.
- `[B` — mode `n`; scope `global` — Move the current buffer one slot left in Bufferline.
- `]B` — mode `n`; scope `global` — Move the current buffer one slot right in Bufferline.
- `<leader>bj` — mode `n`; scope `global` — Pick a buffer from Bufferline.
- `<S-h>`, `<S-l>`, `[b`, `]b` — mode `n`; scope `global` — Bufferline also defines these as previous/next buffer cycling. See the notes on duplicates below.

### Tab maps from `lua/config/keymaps.lua`

- `<leader><tab>l` — mode `n`; scope `global` — Go to the last tab.
- `<leader><tab>o` — mode `n`; scope `global` — Close all other tabs.
- `<leader><tab>f` — mode `n`; scope `global` — Go to the first tab.
- `<leader><tab><tab>` — mode `n`; scope `global` — Open a new tab.
- `<leader><tab>]` — mode `n`; scope `global` — Go to the next tab.
- `<leader><tab>d` — mode `n`; scope `global` — Close the current tab.
- `<leader><tab>[` — mode `n`; scope `global` — Go to the previous tab.

## File / find / explorer / search

### File and picker entry points

- `<leader>fn` — mode `n`; scope `global` — Create a new empty buffer. Defined in `lua/config/keymaps.lua`.
- `<leader>,` — mode `n`; scope `global` — Open the buffers picker.
- `<leader>:` — mode `n`; scope `global` — Open command history.
- `<leader><space>` — mode `n`; scope `global` — Find files from the detected project root.
- `<leader>fb` — mode `n`; scope `global` — Open the buffers picker.
- `<leader>fB` — mode `n`; scope `global` — Open the buffers picker including hidden and `nofile` buffers.
- `<leader>fc` — mode `n`; scope `global` — Find config files.
- `<leader>ff` — mode `n`; scope `global` — Find files from the detected project root.
- `<leader>fF` — mode `n`; scope `global` — Find files from the current working directory.
- `<leader>fg` — mode `n`; scope `global` — Find Git-tracked files.
- `<leader>fr` — mode `n`; scope `global` — Open recent files.
- `<leader>fR` — mode `n`; scope `global` — Open recent files limited to the current working directory.
- `<leader>fp` — mode `n`; scope `global` — Open the projects picker.
- `<leader>uC` — mode `n`; scope `global` — Open the colorscheme picker.

### Explorer maps from `lua/plugins/snacks-explorer.lua`

- `<leader>fe` — mode `n`; scope `global` — Open the Snacks explorer at the detected project root.
- `<leader>fE` — mode `n`; scope `global` — Open the Snacks explorer at the current working directory.
- `<leader>e` — mode `n`; scope `global` — Remap to `<leader>fe`.
- `<leader>E` — mode `n`; scope `global` — Remap to `<leader>fE`.
- `<C-p>` — mode `n`; scope `global` — Open Snacks explorer and focus its input field.
- `<leader>/` — mode `x`; scope `global` — Grep the current visual selection.

### Search maps from `lua/plugins/snacks.lua`

- `<leader>/` — mode `n`; scope `global` — Live grep from the detected project root.
- `<leader>sb` — mode `n`; scope `global` — Search lines in the current buffer.
- `<leader>sB` — mode `n`; scope `global` — Grep across open buffers.
- `<leader>sg` — mode `n`; scope `global` — Live grep from the detected project root.
- `<leader>sG` — mode `n`; scope `global` — Live grep from the current working directory.
- `<leader>sp` — mode `n`; scope `global` — Open the floating `vim.pack` plugin manager UI.
- `<leader>sw` — modes `n,x`; scope `global` — Grep the current word or visual selection from the project root.
- `<leader>sW` — modes `n,x`; scope `global` — Grep the current word or visual selection from the current working directory.
- `<leader>s"` — mode `n`; scope `global` — Open the registers picker.
- `<leader>s/` — mode `n`; scope `global` — Open search history.
- `<leader>sa` — mode `n`; scope `global` — Open autocmds.
- `<leader>sc` — mode `n`; scope `global` — Open command history.
- `<leader>sC` — mode `n`; scope `global` — Open commands.
- `<leader>sh` — mode `n`; scope `global` — Open help pages.
- `<leader>sH` — mode `n`; scope `global` — Open highlights.
- `<leader>si` — mode `n`; scope `global` — Open icons.
- `<leader>sj` — mode `n`; scope `global` — Open jumps.
- `<leader>sk` — mode `n`; scope `global` — Open keymaps.
- `<leader>sM` — mode `n`; scope `global` — Open man pages.
- `<leader>sm` — mode `n`; scope `global` — Open marks.
- `<leader>sR` — mode `n`; scope `global` — Resume the last picker.
- `<leader>su` — mode `n`; scope `global` — Open Neovim's built-in undo tree.

### Search and replace / TODO helpers

From `lua/plugins/editor.lua`:

- `<leader>sr` — modes `n,x`; scope `global` — Open GrugFar search/replace, prefilling the current file extension when possible.
- `[t` — mode `n`; scope `global` — Jump to the previous TODO comment.
- `]t` — mode `n`; scope `global` — Jump to the next TODO comment.
- `<leader>st` — mode `n`; scope `global` — Open the todo comments picker.
- `<leader>sT` — mode `n`; scope `global` — Open the todo comments picker filtered to TODO/FIX/FIXME.

## Code / LSP / formatting

### General code actions

From `lua/config/keymaps.lua`, `lua/plugins/formatting.lua`, `lua/plugins/guess-indent.lua`, `lua/plugins/coding.lua`, and `lua/plugins/lsp.lua`:

- `<leader>cf` — modes `n,x`; scope `global` — Format through the repo's `config.format` dispatcher.
- `<leader>cF` — modes `n,x`; scope `global` — Format injected languages only via Conform.
- `<leader>cg` — mode `n`; scope `global` — Run `GuessIndent`.
- `<leader>cn` — mode `n`; scope `global` — Generate annotations/docblocks with Neogen.
- `<leader>cm` — mode `n`; scope `global` — Open Mason.
- `<leader>cs` — mode `n`; scope `global` — Open the document symbols picker.
- `<leader>cS` — mode `n`; scope `global` — Open the LSP references picker.

### Generic LSP maps from `lua/plugins/coding.lua`, attached through `lua/config/lsp.lua`

These are `buffer-local` and only attach when the connected LSP client supports the required method or capability.

- `<leader>cl` — mode `n`; scope `buffer-local` — Open the LSP config/info picker.
- `gd` — mode `n`; scope `buffer-local` — Go to definition.
- `gr` — mode `n`; scope `buffer-local` — Show references.
- `gI` — mode `n`; scope `buffer-local` — Go to implementation.
- `gy` — mode `n`; scope `buffer-local` — Go to type definition.
- `gD` — mode `n`; scope `buffer-local` — Go to declaration.
- `K` — mode `n`; scope `buffer-local` — Hover.
- `gK` — mode `n`; scope `buffer-local` — Signature help.
- `<C-k>` — mode `i`; scope `buffer-local` — Signature help.
- `<leader>ca` — modes `n,x`; scope `buffer-local` — Code action.
- `<leader>cc` — modes `n,x`; scope `buffer-local` — Run codelens.
- `<leader>cC` — mode `n`; scope `buffer-local` — Refresh and display codelens.
- `<leader>cR` — mode `n`; scope `buffer-local` — Rename the current file when the LSP server supports workspace file-rename operations.
- `<leader>cr` — mode `n`; scope `buffer-local` — Rename symbol.
- `<leader>cA` — mode `n`; scope `buffer-local` — Run a source action.
- `<leader>co` — mode `n`; scope `buffer-local` — Organize imports when that action kind is available.
- `]]` — mode `n`; scope `buffer-local` — Jump to the next highlighted reference via Snacks words.
- `[[` — mode `n`; scope `buffer-local` — Jump to the previous highlighted reference via Snacks words.
- `<A-n>` — mode `n`; scope `buffer-local` — Alternate jump to the next highlighted reference.
- `<A-p>` — mode `n`; scope `buffer-local` — Alternate jump to the previous highlighted reference.
- `<leader>ss` — mode `n`; scope `buffer-local` — Open document symbols.
- `<leader>sS` — mode `n`; scope `buffer-local` — Open workspace symbols.
- `gai` — mode `n`; scope `buffer-local` — Show incoming call hierarchy.
- `gao` — mode `n`; scope `buffer-local` — Show outgoing call hierarchy.

### Textobjects and code motions

#### `mini.ai` custom textobjects from `lua/plugins/coding.lua` and `lua/config/mini.lua`

These objects are available under the usual `mini.ai` prefixes (`a`, `i`, `an`, `in`, `al`, `il`) in modes `o,x`.

- `f` — scope `global` — Function.
- `c` — scope `global` — Class.
- `o` — scope `global` — Block / conditional / loop.
- `t` — scope `global` — Tag.
- `d` — scope `global` — Digit run.
- `e` — scope `global` — CamelCase / snake_case segment.
- `g` — scope `global` — Entire buffer (`ig` trims outer blank lines).
- `u` — scope `global` — Function call / use.
- `U` — scope `global` — Function call / use without dot.

#### Treesitter motions from `lua/plugins/treesitter.lua`

- `]f` — mode `n`; scope `global` — Next function start.
- `[f` — mode `n`; scope `global` — Previous function start.
- `]F` — mode `n`; scope `global` — Next function end.
- `[F` — mode `n`; scope `global` — Previous function end.
- `]c` — mode `n`; scope `global` — Next class start.
- `[c` — mode `n`; scope `global` — Previous class start.
- `]C` — mode `n`; scope `global` — Next class end.
- `[C` — mode `n`; scope `global` — Previous class end.
- `]a` — mode `n`; scope `global` — Next parameter start.
- `[a` — mode `n`; scope `global` — Previous parameter start.
- `]A` — mode `n`; scope `global` — Next parameter end.
- `[A` — mode `n`; scope `global` — Previous parameter end.

## Git

### Git maps from `lua/config/keymaps.lua`

- `<leader>gg` — mode `n`; scope `conditional` — Open LazyGit at the detected Git root. Only defined when the `lazygit` executable is available.
- `<leader>gG` — mode `n`; scope `conditional` — Open LazyGit in the current working directory. Only defined when the `lazygit` executable is available.
- `<leader>gL` — mode `n`; scope `global` — Show Git log in the current working directory.
- `<leader>gb` — mode `n`; scope `global` — Show blame for the current line.
- `<leader>gf` — mode `n`; scope `global` — Show history for the current file.
- `<leader>gl` — mode `n`; scope `global` — Show Git log at the repo root.
- `<leader>gB` — modes `n,x`; scope `global` — Open the Git browse URL.
- `<leader>gY` — modes `n,x`; scope `global` — Copy the Git browse URL.

### Snacks Git pickers from `lua/plugins/snacks.lua`

- `<leader>gd` — mode `n`; scope `global` — Open Git diff hunks.
- `<leader>gD` — mode `n`; scope `global` — Open grouped Git diff against `origin`.
- `<leader>gs` — mode `n`; scope `global` — Open Git status.
- `<leader>gS` — mode `n`; scope `global` — Open Git stash.

### Diff note

- No inline diff mappings are defined; use LazyGit or the Snacks Git pickers above.

## Diagnostics / quickfix / location lists

### Core maps from `lua/config/keymaps.lua`

- `<leader>cd` — mode `n`; scope `global` — Open line diagnostics in a float.
- `]d` — mode `n`; scope `global` — Jump to the next diagnostic.
- `[d` — mode `n`; scope `global` — Jump to the previous diagnostic.
- `]e` — mode `n`; scope `global` — Jump to the next error.
- `[e` — mode `n`; scope `global` — Jump to the previous error.
- `]w` — mode `n`; scope `global` — Jump to the next warning.
- `[w` — mode `n`; scope `global` — Jump to the previous warning.
- `<leader>xl` — mode `n`; scope `global` — Toggle the location list window.
- `<leader>xq` — mode `n`; scope `global` — Toggle the quickfix window.
- `[q` — mode `n`; scope `global` — Jump to the previous quickfix item.
- `]q` — mode `n`; scope `global` — Jump to the next quickfix item.

### Snacks list pickers from `lua/plugins/snacks.lua` and `lua/plugins/editor.lua`

- `<leader>xx` — mode `n`; scope `global` — Open diagnostics.
- `<leader>xX` — mode `n`; scope `global` — Open buffer diagnostics.
- `<leader>xL` — mode `n`; scope `global` — Open the location list picker.
- `<leader>xQ` — mode `n`; scope `global` — Open the quickfix list picker.
- `<leader>sd` — mode `n`; scope `global` — Open diagnostics.
- `<leader>sD` — mode `n`; scope `global` — Open buffer diagnostics.
- `<leader>sl` — mode `n`; scope `global` — Open the location list picker.
- `<leader>sq` — mode `n`; scope `global` — Open the quickfix list picker.
- `[q`, `]q` — mode `n`; scope `global` — The optional Snacks augment also defines wrapped quickfix navigation using `pcall`; see the notes on duplicates below.

## Debugging

### Core DAP maps from `lua/plugins/dap.lua`

- `<leader>dB` — mode `n`; scope `global` — Set a conditional breakpoint.
- `<leader>db` — mode `n`; scope `global` — Toggle a breakpoint.
- `<leader>dc` — mode `n`; scope `global` — Continue.
- `<leader>da` — mode `n`; scope `global` — Continue / run with prompted arguments.
- `<leader>dC` — mode `n`; scope `global` — Run to cursor.
- `<leader>dg` — mode `n`; scope `global` — Go to line without executing.
- `<leader>di` — mode `n`; scope `global` — Step into.
- `<leader>dj` — mode `n`; scope `global` — Move down the stack / frame list.
- `<leader>dk` — mode `n`; scope `global` — Move up the stack / frame list.
- `<leader>dl` — mode `n`; scope `global` — Run the last debug session again.
- `<leader>do` — mode `n`; scope `global` — Step out.
- `<leader>dO` — mode `n`; scope `global` — Step over.
- `<leader>dP` — mode `n`; scope `global` — Pause.
- `<leader>dr` — mode `n`; scope `global` — Toggle the DAP REPL.
- `<leader>ds` — mode `n`; scope `global` — Show the current DAP session.
- `<leader>dt` — mode `n`; scope `global` — Terminate the current debug session.
- `<leader>dw` — mode `n`; scope `global` — Open DAP widget hover.
- `<leader>du` — mode `n`; scope `global` — Toggle the DAP UI.
- `<leader>de` — modes `n,x`; scope `global` — Evaluate the expression under the cursor or the current selection.

### Profiler maps

From `lua/config/keymaps.lua` and `lua/plugins/snacks.lua`:

- `<leader>dpp` — mode `n`; scope `global` — Toggle the Snacks profiler.
- `<leader>dph` — mode `n`; scope `global` — Toggle profiler highlights.
- `<leader>dps` — mode `n`; scope `global` — Open the profiler scratch buffer.

## UI / toggles / sessions / terminal

### Scratch, notifications, sessions, quit, and inspect

From `lua/plugins/snacks.lua` and `lua/config/keymaps.lua`:

- `<leader>.` — mode `n`; scope `global` — Toggle the scratch buffer.
- `<leader>S` — mode `n`; scope `global` — Select a scratch buffer.
- `<leader>n` — mode `n`; scope `global` — Open notification history.
- `<leader>un` — mode `n`; scope `global` — Dismiss all notifications.
- `<leader>qs` — mode `n`; scope `global` — Restore the current session.
- `<leader>qS` — mode `n`; scope `global` — Select a saved session.
- `<leader>ql` — mode `n`; scope `global` — Restore the last session.
- `<leader>qd` — mode `n`; scope `global` — Stop saving the current session.
- `<leader>qq` — mode `n`; scope `global` — Quit all windows.
- `<leader>ur` — mode `n`; scope `global` — Redraw, clear search highlighting, and update diffs.
- `<leader>ui` — mode `n`; scope `global` — Inspect the current cursor position.
- `<leader>uI` — mode `n`; scope `global` — Inspect the current Treesitter tree.

### Toggle maps from `lua/config/keymaps.lua`, `lua/config/mini.lua`, and `lua/plugins/ui.lua`

- `<leader>uf` — mode `n`; scope `global` — Toggle global auto-format.
- `<leader>uF` — mode `n`; scope `global` — Toggle buffer-local auto-format.
- `<leader>us` — mode `n`; scope `global` — Toggle spelling.
- `<leader>uw` — mode `n`; scope `global` — Toggle wrap.
- `<leader>uL` — mode `n`; scope `global` — Toggle relative numbers.
- `<leader>ud` — mode `n`; scope `global` — Toggle diagnostics.
- `<leader>ue` — mode `n`; scope `global` — Toggle LSP inline completion when Neovim's built-in inline completion API is available.
- `<leader>ul` — mode `n`; scope `global` — Toggle line numbers.
- `<leader>uc` — mode `n`; scope `global` — Toggle conceal level.
- `<leader>uA` — mode `n`; scope `global` — Toggle the tabline.
- `<leader>uT` — mode `n`; scope `global` — Toggle Treesitter highlighting.
- `<leader>ub` — mode `n`; scope `global` — Toggle dark background.
- `<leader>uD` — mode `n`; scope `global` — Toggle dim mode.
- `<leader>ua` — mode `n`; scope `global` — Toggle UI animation.
- `<leader>ug` — mode `n`; scope `global` — Toggle Snacks indent guides.
- `<leader>uS` — mode `n`; scope `global` — Toggle smooth scroll.
- `<leader>uh` — mode `n`; scope `conditional` — Toggle LSP inlay hints when `vim.lsp.inlay_hint` exists.
- `<leader>uz` — mode `n`; scope `global` — Toggle zen mode.
- `<leader>up` — mode `n`; scope `global` — Toggle Mini Pairs.

### Terminal entry points and terminal-local keys

Global mappings from `lua/config/keymaps.lua`:

- `<leader>fT` — mode `n`; scope `global` — Open a terminal in the current working directory.
- `<leader>ft` — mode `n`; scope `global` — Open a terminal at the detected project root.
- `<C-/>` — modes `n,t`; scope `global` — Focus or toggle the root terminal.
- `<C-_>` — modes `n,t`; scope `global` — Alias for `<C-/>`.

Terminal-local Snacks keys from `lua/plugins/snacks.lua`:

- `<C-h>` — mode `t`; scope `terminal-local` — Move to the left window when the terminal is not floating.
- `<C-j>` — mode `t`; scope `terminal-local` — Move to the lower window when the terminal is not floating.
- `<C-k>` — mode `t`; scope `terminal-local` — Move to the upper window when the terminal is not floating.
- `<C-l>` — mode `t`; scope `terminal-local` — Move to the right window when the terminal is not floating.
- `<C-/>` — mode `t`; scope `terminal-local` — Hide the current Snacks terminal.
- `<C-_>` — mode `t`; scope `terminal-local` — Alias for hiding the current Snacks terminal.

### Picker-local and dashboard-local key tables from `lua/plugins/snacks.lua`

Picker-local keys:

- `<A-c>` — modes `n,i`; scope `picker-local` — Toggle picker cwd between project root and current working directory.
- `<A-s>` — modes `n,i`; scope `picker-local` — Trigger Flash inside the picker.
- `s` — scope `picker-local` — Trigger Flash inside the picker from the input window.

Dashboard-local keys:

- `f` — scope `dashboard-local` — Find file.
- `n` — scope `dashboard-local` — New file.
- `g` — scope `dashboard-local` — Find text.
- `r` — scope `dashboard-local` — Recent files.
- `c` — scope `dashboard-local` — Find config files.
- `p` — scope `dashboard-local` — Projects.
- `s` — scope `dashboard-local` — Restore session.
- `l` — scope `dashboard-local` — Open the floating `vim.pack` plugin manager UI.
- `q` — scope `dashboard-local` — Quit.

### Native completion notes

- `<C-y>` still accepts the currently selected completion item through Neovim's built-in popup menu.
- `<Tab>` accepts popup completion first (selecting the first item when needed), then falls back to inline completion, snippet jumping, or a literal tab.
- `<C-Space>` triggers native LSP completion manually.
- `<leader>ue` toggles Neovim's built-in LSP inline completion when supported by an attached server.
- In command-line mode, `<Tab>`, `<Left>`, and `<Right>` still use Neovim's native completion behavior.

## AI

From `lua/plugins/ai.lua`:

- `<leader>9v` — mode `v`; scope `global` — Send the current visual selection to `99`.
- `<leader>9x` — mode `n`; scope `global` — Stop all active `99` requests.
- `<leader>9s` — mode `n`; scope `global` — Run `99` search.

## Language-specific and filetype-local mappings

### Helper buffers and Lua files

- `q` — mode `n`; scope `buffer-local` — Close helper/ephemeral buffers for the filetypes listed in `lua/config/autocmds.lua` (`PlenaryTestPopup`, `checkhealth`, `dap-float`, `dbout`, `gitsigns-blame`, `grug-far`, `help`, `lspinfo`, `notify`, `qf`, `spectre_panel`, `startuptime`, `tsplayground`).
- `<localleader>r` — modes `n,x`; scope `filetype-local` — Run the current Lua file/selection with `Snacks.debug.run()`. Added on `FileType=lua` in `lua/config/keymaps.lua`.

### YAML and Markdown

- `<leader>fy` — mode `n`; scope `filetype-local` — YAML key finder via `yaml.nvim`. Defined for YAML buffers in `lua/plugins/lang-conffiles.lua`.
- `<leader>cp` — mode `n`; scope `filetype-local` — Toggle Markdown preview. Defined for Markdown buffers in `lua/plugins/lang-markdown.lua`.

### Python

From `lua/plugins/lang-python.lua`:

- `<leader>cv` — mode `n`; scope `filetype-local` — Select a Python virtualenv.
- `<leader>dPt` — mode `n`; scope `filetype-local` — Debug the current Python test method.
- `<leader>dPc` — mode `n`; scope `filetype-local` — Debug the current Python test class.

### Rust

From `lua/plugins/lang-rust.lua`:

- `<leader>cR` — mode `n`; scope `buffer-local` — Run `RustLsp codeAction`.
- `<leader>dr` — mode `n`; scope `buffer-local` — Open `RustLsp debuggables`.

### TypeScript / JavaScript via `vtsls`

From `lua/plugins/lang-typescript.lua`:

- `gR` — mode `n`; scope `buffer-local` — Show file references.
- `<leader>cM` — mode `n`; scope `buffer-local` — Add missing imports.
- `<leader>cu` — mode `n`; scope `buffer-local` — Remove unused imports.
- `<leader>cD` — mode `n`; scope `buffer-local` — Fix all diagnostics.
- `<leader>cV` — mode `n`; scope `buffer-local` — Select the workspace TypeScript version.
- `gD` — mode `n`; scope `buffer-local` — Intended by the `vtsls` module as “goto source definition”, but it competes with the generic LSP `gD`; see the notes below.
- `<leader>co` — mode `n`; scope `buffer-local` — The `vtsls` module also registers an organize-imports mapping on this lhs, but the generic LSP table claims it first; see the notes below.

## Notes on duplicates and precedence

- `<leader>,` / `<leader>fb`, `<leader><space>` / `<leader>ff`, `<leader>:` / `<leader>sc`, and the paired Snacks `s*` / `x*` pickers are intentional aliases.
- `<S-h>`, `<S-l>`, `[b`, `]b`, `[q`, and `]q` are defined in more than one source, but the effective behavior is the same.
- `lua/config/lsp.lua` attaches generic `"*"` mappings before per-server mappings and dedupes by `mode + lhs`, so generic keys like `<leader>co` can prevent server-specific duplicates such as `vtsls` `gD` or `<leader>co` from attaching.
- Rust sets fresh `buffer-local` mappings in `rustaceanvim`'s `on_attach`, so in Rust buffers `<leader>cR` and `<leader>dr` override the generic meanings.

