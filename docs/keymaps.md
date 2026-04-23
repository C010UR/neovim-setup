# Keymaps, motions, and useful commands

_Audited against the repo-defined mappings on April 23, 2026._

This document is written for complete beginners. It mixes:

- the **most important built-in Neovim keys** you should learn first,
- the **custom mappings from this repo**,
- the **plugin-local keys** that only work inside certain UIs, and
- the **commands** you will reach for most often.

> **Important:** this config disables Neovim's built-in `:Tutor` plugin, so this file is meant to serve as the local, tutor-style guide for this setup.

## 1. Read this first

### Leader keys

From `lua/config/options.lua`:

- `<leader>` = `Space`
- `<localleader>` = `\`

So when you see `<leader>` in a mapping like `<leader>ff`, read it as:

- press `Space`
- then `f`
- then `f`

And when you see `<localleader>` in a mapping like `<localleader>r`, press `\` first.

### Modes

| Mode | Name | What you usually do there |
| --- | --- | --- |
| `n` | Normal | move around, delete/change/yank, run commands |
| `i` | Insert | type text |
| `v` | Visual | select characters |
| `V` | Visual line | select whole lines |
| `<C-v>` | Visual block | select a column/block |
| `x` | Visual/select-style mapping scope | selections and operators |
| `o` | Operator-pending | after keys like `d`, `c`, `y`, waiting for a motion |
| `t` | Terminal | interact with terminal buffers |
| `c` | Command-line | after `:` or `/` |
| `s` | Select / snippet | active snippet fields and select-mode cases |

### How to read the notation

| Notation | Meaning |
| --- | --- |
| `<C-s>` | hold `Ctrl`, press `s` |
| `<A-j>` | hold `Alt`, press `j` |
| `<CR>` | `Enter` |
| `<Esc>` | `Escape` |
| `<BS>` | `Backspace` |
| `<Space>` | the space bar |
| `3w` | do `w` three times |
| `daw` | `d` operator + `aw` text object |

### Scope labels used in this guide

| Label | Meaning |
| --- | --- |
| `global` | works in normal buffers everywhere |
| `buffer-local` | only works in the current buffer, usually after LSP attaches |
| `filetype-local` | only works for a specific filetype |
| `terminal-local` | only inside a Snacks terminal |
| `picker-local` | only inside a Snacks picker window |
| `dashboard-local` | only on the startup dashboard |
| `plugin-manager-local` | only inside the `:Pack` window |
| `conditional` | only exists when a tool/capability is available |

### The fastest way to discover keys in this setup

- Press `<leader>` and pause for a moment: **which-key** will show the available groups.
- Press `<leader>?`: show **buffer-local** keymaps.
- Press `<C-w><Space>`: show **window** keymaps.
- Press `<leader>sk`: open the **keymaps picker**.
- Press `<leader>sh`: open **help pages**.

### The 12 keys to learn first

If you are brand new, start here:

- `i` — enter Insert mode before the cursor
- `<Esc>` — go back to Normal mode
- `h`, `j`, `k`, `l` — move left/down/up/right
- `w`, `b` — move by word
- `dd` — delete line
- `yy` — yank (copy) line
- `p` — paste after cursor
- `u` — undo
- `<C-r>` — redo
- `:w` — save
- `:q` — quit current window

### The editing grammar you should internalize

The real power of Neovim is not memorizing hundreds of unrelated shortcuts. It is learning this sentence:

- **count** + **operator** + **motion**
- **count** + **operator** + **text object**
- sometimes **register** + command

| Piece | What it means | Examples |
| --- | --- | --- |
| count | how many times / how far | `3w`, `2dd`, `5G` |
| operator | what action to perform | `d` delete, `c` change, `y` yank, `>` indent |
| motion | where the action goes | `w`, `$`, `f,`, `}` |
| text object | what shaped thing to target | `iw`, `ap`, `i"`, `a(` |
| register | where text goes or comes from | `"a`, `"+`, `"_` |

Examples:

- `d2w` — delete two words
- `ci"` — change inside double quotes
- `yap` — yank a paragraph
- `>ap` — indent a paragraph
- `"+yy` — yank the current line to the system clipboard
- `"_daw` — delete a word without overwriting what you last yanked

If you learn this grammar, you stop hunting for a separate shortcut for every task.

---

## 2. What this config changes from stock Neovim

These are the main differences you will notice right away.

| Key | Modes | Scope | What changed |
| --- | --- | --- | --- |
| `j`, `k` | `n,x` | global | Without a count, they move by **display line** (`gj`/`gk` behavior). With a count like `5j`, they still move by real lines. |
| `<Down>`, `<Up>` | `n,x` | global | Same idea as `j`/`k`: screen lines without a count, real lines with a count. |
| `s` | `n,x,o` | global | No longer does the stock substitute behavior here; it starts **Flash jump**. |
| `S` | `n,x,o` | global | No longer does the stock line substitute behavior here; it starts **Flash Treesitter jump**. |
| `<Esc>` | `i,n,s` | global | Still escapes, but also clears search highlighting and stops an active snippet when needed. |
| `<C-s>` | `i,n,x,s` | global | Saves the current file. |
| `<Tab>` | `i,s` | global | Accepts popup completion first, then inline completion, then jumps to the next snippet field, then falls back to a real tab. |
| `<C-Space>` | `i` | global | Manually triggers native LSP completion. |
| `<C-Space>` | `n,o,x` | global | Starts Flash Treesitter selection. |
| `n`, `N` | `n,x,o` | global | Respect the last search direction; in Normal mode they also open folds with `zv`. |

> **Tip:** Normal-mode `r` still replaces one character, and Normal-mode `R` still enters Replace mode. The Flash remaps only take over the modes listed above.

---

## 3. Core Neovim defaults you should learn first

This section covers the built-in keys that matter most in day-to-day editing.

### 3.1 Entering and leaving Insert mode

| Key | Mode | What it does |
| --- | --- | --- |
| `i` | `n` | insert before the cursor |
| `a` | `n` | insert after the cursor |
| `I` | `n` | insert at the first non-blank character of the line |
| `A` | `n` | insert at the end of the line |
| `o` | `n` | open a new line below and enter Insert mode |
| `O` | `n` | open a new line above and enter Insert mode |
| `<Esc>` | `i` | leave Insert mode and return to Normal mode |
| `<C-[>` | `i` | another way to escape Insert mode |

#### Practice

```text
first line
second line
third line
```

Try this:

1. Put the cursor on `second`.
2. Press `A` and type ` !!!`.
3. Press `<Esc>`.
4. Press `O` and type `inserted above`.
5. Press `<Esc>` again.

### 3.2 Basic movement

| Key | Mode | What it does |
| --- | --- | --- |
| `h` | `n,x,o` | move left |
| `l` | `n,x,o` | move right |
| `j` | `n,x,o` | move down one line; in this config, screen-line movement is preferred when no count is given |
| `k` | `n,x,o` | move up one line; same screen-line behavior as above |
| `0` | `n,x,o` | go to the start of the line |
| `^` | `n,x,o` | go to the first non-blank character of the line |
| `$` | `n,x,o` | go to the end of the line |
| `gg` | `n,x,o` | go to the first line of the file |
| `G` | `n,x,o` | go to the last line of the file |
| `H` | `n,x,o` | go to the top of the visible window |
| `M` | `n,x,o` | go to the middle of the visible window |
| `L` | `n,x,o` | go to the bottom of the visible window |
| `%` | `n,x,o` | jump to the matching bracket/brace/parenthesis |
| `{` | `n,x,o` | jump to previous paragraph |
| `}` | `n,x,o` | jump to next paragraph |
| `<C-u>` | `n` | scroll up half a page |
| `<C-d>` | `n` | scroll down half a page |
| `<C-b>` | `n` | scroll up one full page |
| `<C-f>` | `n` | scroll down one full page |

#### Practice

```text
alpha beta gamma
one two three
left (middle) right
last line here
```

Try this:

1. Put the cursor on `alpha`.
2. Press `w` twice.
3. Press `0`, then `$`.
4. Move to the line with parentheses and press `%`.
5. Press `gg`, then `G`.

### Counts, scrolling, and keeping context on screen

Counts work almost everywhere in Normal mode.

| Key | Mode | What it does |
| --- | --- | --- |
| `3w` | `n` | move forward three words |
| `2dd` | `n` | delete two lines |
| `5G` | `n` | go to line 5 |
| `99G` | `n` | go to line 99 |
| `zz` | `n` | center the current line in the window |
| `zt` | `n` | put the current line at the top of the window |
| `zb` | `n` | put the current line at the bottom of the window |
| `<C-e>` | `n` | scroll the window down one line |
| `<C-y>` | `n` | scroll the window up one line |

`zz` is one of the most useful quality-of-life keys in all of Neovim. Use it constantly after jumps, searches, `gd`, or `n`.

### 3.3 Word movement

| Key | Mode | What it does |
| --- | --- | --- |
| `w` | `n,x,o` | jump to the start of the next word |
| `W` | `n,x,o` | same, but treats punctuation as part of the word |
| `b` | `n,x,o` | jump to the start of the previous word |
| `B` | `n,x,o` | same, with punctuation treated as part of the word |
| `e` | `n,x,o` | jump to the end of the current/next word |
| `E` | `n,x,o` | same, with punctuation treated as part of the word |
| `ge` | `n,x,o` | jump to the end of the previous word |
| `gE` | `n,x,o` | same, with punctuation treated as part of the word |

### 3.4 Character-find motions inside a line

| Key | Mode | What it does |
| --- | --- | --- |
| `f{char}` | `n,x,o` | find the next `{char}` on the current line |
| `F{char}` | `n,x,o` | find the previous `{char}` on the current line |
| `t{char}` | `n,x,o` | move right **until before** `{char}` |
| `T{char}` | `n,x,o` | move left **until after** `{char}` |
| `;` | `n,x,o` | repeat the last `f`, `F`, `t`, or `T` search |
| `,` | `n,x,o` | repeat that same search in the opposite direction |

#### Practice

```text
name = value + other_value
```

Try this:

1. Put the cursor at the start of the line.
2. Press `f=`.
3. Press `;` to repeat the character search.
4. Press `,` to go back.
5. Press `t+` to stop just before the `+`.

### 3.5 Search inside the whole file

| Key | Mode | What it does |
| --- | --- | --- |
| `/pattern` | `n` | search forward |
| `?pattern` | `n` | search backward |
| `n` | `n,x,o` | repeat the search in the same logical direction |
| `N` | `n,x,o` | repeat in the opposite logical direction |
| `*` | `n` | search forward for the word under the cursor |
| `#` | `n` | search backward for the word under the cursor |
| `g*` | `n` | search forward for the text under the cursor, not just a whole word |
| `g#` | `n` | search backward for the text under the cursor, not just a whole word |
| `:noh` | command | clear the highlighted search matches |

In this config, `<Esc>` also clears search highlighting for you.

#### Practice

```text
apple banana apple
banana apple banana
```

Try this:

1. Put the cursor on `apple`.
2. Press `*`.
3. Press `n` a few times.
4. Press `N` to go back.
5. Press `<Esc>` to clear the highlight.

### 3.6 Editing, deletion, changing, and repeating

The most important Neovim idea is:

- **operator** + **motion/text object** = edit exactly what you mean

Examples:

- `dw` = delete to the next word
- `ciw` = change inner word
- `yap` = yank a paragraph
- `>}` = indent until the next paragraph

| Key | Mode | What it does |
| --- | --- | --- |
| `x` | `n` | delete the character under the cursor |
| `X` | `n` | delete the character before the cursor |
| `dd` | `n` | delete the current line |
| `D` | `n` | delete to the end of the line |
| `cc` | `n` | change the whole current line |
| `C` | `n` | change to the end of the line |
| `dw` | `n` | delete to the next word |
| `cw` | `n` | change to the next word |
| `yy` | `n` | yank the current line |
| `p` | `n` | paste after the cursor |
| `P` | `n` | paste before the cursor |
| `r{char}` | `n` | replace one character |
| `R` | `n` | enter Replace mode |
| `J` | `n` | join the next line onto the current line |
| `u` | `n` | undo |
| `<C-r>` | `n` | redo |
| `.` | `n` | repeat the last change |
| `>` / `<` | `n,x,o` | indent right / left |
| `=` | `n,x,o` | reindent |

#### Practice

```text
one two three
four five six
```

Try this:

1. Put the cursor on `two` and press `ciw`.
2. Type `TWO` and press `<Esc>`.
3. Move to `five` and press `.`.
4. Press `u`, then `<C-r>`.
5. Go to the first line and press `J`.

### Changing case quickly

| Key | Mode | What it does |
| --- | --- | --- |
| `~` | `n,x` | toggle case under the cursor or on the current visual selection |
| `guw` | `n` | lowercase from the cursor to the end of the word |
| `gUw` | `n` | uppercase from the cursor to the end of the word |
| `guiw` | `n` | lowercase the current word |
| `gUiw` | `n` | uppercase the current word |
| `guu` | `n` | lowercase the current line |
| `gUU` | `n` | uppercase the current line |

### 3.7 Visual mode

| Key | Mode | What it does |
| --- | --- | --- |
| `v` | `n` | start character-wise visual selection |
| `V` | `n` | start line-wise visual selection |
| `<C-v>` | `n` | start block-wise visual selection |
| `o` | `x` | jump to the other end of the selection |

Once text is selected, you can use the usual operators:

- `d` to delete the selection
- `y` to yank it
- `c` to change it
- `>` / `<` to indent it

This repo improves visual indenting:

- `<` in Visual mode indents left **and keeps the selection active**
- `>` in Visual mode indents right **and keeps the selection active**

### Visual block mode

Visual block mode is one of the features that makes Neovim feel "advanced" very quickly.

| Key | Mode | What it does |
| --- | --- | --- |
| `<C-v>` | `n` | start block selection |
| `I` | block visual | insert at the start of every selected line |
| `A` | block visual | append at the end of every selected line |
| `c` | block visual | change the block selection |
| `d` | block visual | delete the block selection |

#### Practice

```text
apple
banana
cherry
```

Try this:

1. Put the cursor on the first letter of `apple`.
2. Press `<C-v>` and select the first letter on all three lines.
3. Press `I`, type `- `, then press `<Esc>`.
4. Neovim applies the insertion to all selected lines.

This is great for adding comment prefixes, list markers, or quick aligned edits.

### 3.8 Registers, marks, jumps, and macros

#### Registers and clipboard

This config sets `clipboard=unnamedplus`, so regular yank/paste talks to your system clipboard.

| Key | Mode | What it does |
| --- | --- | --- |
| `""` | `n` | the unnamed default register; normal yanks, deletes, and pastes usually use this |
| `"0` | `n` | the yank register; it keeps the most recent yank |
| `"ayy` | `n` | yank the current line into register `a` |
| `"ap` | `n` | paste from register `a` |
| `"+y` | `n,x` | yank explicitly to the system clipboard |
| `"+p` | `n,x` | paste explicitly from the system clipboard |
| `"_daw` | `n` | delete a word into the black-hole register, leaving your previous yank untouched |
| `:registers` | command | inspect registers |

#### Local and global marks

| Key | Mode | What it does |
| --- | --- | --- |
| `ma` | `n` | set local mark `a` in the current file |
| `'a` | `n` | jump to mark `a` by line |
| `` `a `` | `n` | jump to mark `a` by exact position |
| `mA` | `n` | set global mark `A` that you can jump to from another file |
| `'A` | `n` | jump to global mark `A` by line |
| `` `A `` | `n` | jump to global mark `A` by exact position |
| `<C-o>` | `n` | jump backward in the jumplist |
| `<C-i>` | `n` | jump forward in the jumplist |
| `g;` | `n` | jump to an older change |
| `g,` | `n` | jump to a newer change |

#### Macros

| Key | Mode | What it does |
| --- | --- | --- |
| `qa` | `n` | start recording a macro into register `a` |
| `q` | `n` | stop recording |
| `@a` | `n` | play macro `a` |
| `@@` | `n` | play the last-used macro again |

> **Important:** in this setup, some helper windows remap plain `q` to close the window. In normal editing buffers, `q{register}` still records a macro as usual.

#### Practice

```text
item_1
item_2
item_3
```

Try this:

1. Put the cursor on the first line.
2. Press `qa` to start recording into register `a`.
3. Press `A`, type `;`, then press `<Esc>`.
4. Press `j` to go to the next line.
5. Press `q` to stop recording.
6. Press `@a`, then `@@`.

### 3.9 Folds

This config enables Treesitter/LSP-aware folding, so the classic fold keys are worth knowing.

| Key | Mode | What it does |
| --- | --- | --- |
| `za` | `n` | toggle the fold under the cursor |
| `zo` | `n` | open the fold under the cursor |
| `zc` | `n` | close the fold under the cursor |
| `zR` | `n` | open all folds |
| `zM` | `n` | close all folds |
| `zv` | `n` | open folds just enough to reveal the cursor |

This setup automatically uses `zv` when you press `n` or `N` in Normal mode, so search results hidden in folds are easier to see.

---

## 4. Text objects: the real superpower

Text objects let you target meaningful chunks of text.

### 4.1 Built-in text objects you should know early

These are usually used after an operator (`d`, `c`, `y`, `v`, `>` and so on).

| Key | Meaning | Example |
| --- | --- | --- |
| `iw` | inner word | `ciw` changes the current word |
| `aw` | a word | `daw` deletes the word and nearby space |
| `i"` | inside double quotes | `ci"` changes only the text inside `"..."` |
| `a"` | around double quotes | `da"` deletes the quotes too |
| `i'` / `a'` | inside / around single quotes | `yi'` yanks inside `'...'` |
| `i(` / `a(` | inside / around parentheses | `ci(` changes inside `( ... )` |
| `i[` / `a[` | inside / around brackets | `da[` deletes `[ ... ]` |
| `i{` / `a{` | inside / around braces | `vi{` selects inside `{ ... }` |
| `ip` / `ap` | inner / around paragraph | `yap` yanks a paragraph |
| `it` / `at` | inside / around HTML/XML tag | useful in markup files |

### 4.2 Repo-added `mini.ai` text objects

This config extends the usual text-object system.

These work with the normal `a...` / `i...` prefixes, and also the extra `an`, `in`, `al`, `il` variants from `mini.ai`.

| Object | Meaning | Example |
| --- | --- | --- |
| `f` | function | `vaf` selects a function |
| `c` | class | `dic` deletes inside a class |
| `o` | block / conditional / loop | `vao` selects a block |
| `t` | tag | `cit` changes inside a tag |
| `d` | digit run | `cid` changes a run of digits |
| `e` | CamelCase / snake_case segment | `cie` changes one segment |
| `g` | entire buffer (`ig` trims outer blank lines) | `yig` yanks the meaningful file body |
| `u` | function call / use | `dau` deletes a whole call |
| `U` | function call / use without dot | useful when you want the bare call target |

#### Practice

```text
function add(one, two) {
  return one + two
}
```

Try this:

1. Put the cursor anywhere inside the function body.
2. Press `vaf` to select the whole function.
3. Press `<Esc>`.
4. Put the cursor on `one` and press `ciw`.
5. Undo with `u`.
6. If Treesitter is active for the file, try `vaf` again in a code buffer.

### 4.3 Treesitter motions for code structure

These are repo-defined motions for code-aware jumping.

| Key | Mode | Scope | What it does |
| --- | --- | --- | --- |
| `]f` / `[f` | `n` | global | next / previous function start |
| `]F` / `[F` | `n` | global | next / previous function end |
| `]c` / `[c` | `n` | global | next / previous class start |
| `]C` / `[C` | `n` | global | next / previous class end |
| `]a` / `[a` | `n` | global | next / previous parameter start |
| `]A` / `[A` | `n` | global | next / previous parameter end |

---

## 5. Commenting, search/replace, and fast jumping

### 5.1 Commenting

This setup keeps the usual comment workflow and adds helpers.

| Key | Mode | Scope | What it does |
| --- | --- | --- | --- |
| `gcc` | `n` | global | comment/uncomment the current line |
| `gco` | `n` | global | add a commented line **below** |
| `gcO` | `n` | global | add a commented line **above** |

### 5.2 Search and replace

| Key / Command | Mode | Scope | What it does |
| --- | --- | --- | --- |
| `:s/old/new/` | command | built-in | replace the first match on the current line |
| `:s/old/new/g` | command | built-in | replace all matches on the current line |
| `:%s/old/new/g` | command | built-in | replace all matches in the whole file |
| `:%s/old/new/gc` | command | built-in | replace in the whole file, but confirm each match |
| `<leader>sr` | `n,x` | global | open GrugFar search/replace |

#### Practice

```text
cat dog cat dog
cat dog cat dog
```

Try this:

1. Press `:%s/cat/bird/gc`.
2. Answer `y` or `n` for each match.
3. Undo with `u` if you want to practice again.

### 5.3 Flash: faster-than-search jumping

Flash is one of the biggest movement upgrades in this config.

| Key | Mode | Scope | What it does |
| --- | --- | --- | --- |
| `s` | `n,x,o` | global | Flash jump |
| `S` | `n,x,o` | global | Flash Treesitter jump |
| `r` | `o` | global | remote Flash |
| `R` | `o,x` | global | Treesitter search |
| `<C-s>` | `c` | global | toggle Flash in command-line search |
| `<C-Space>` | `n,o,x` | global | start Flash Treesitter selection |
| `<C-Space>` / `<BS>` | inside Flash selection | transient | next / previous Treesitter target |

A simple way to think about `s`:

1. press `s`
2. type a small clue
3. jump directly where you want

This is especially good in large files where `/` search feels too broad.

### 5.4 TODO helpers

| Key | Mode | Scope | What it does |
| --- | --- | --- | --- |
| `]t` | `n` | global | next TODO-style comment |
| `[t` | `n` | global | previous TODO-style comment |
| `<leader>st` | `n` | global | open TODO comments picker |
| `<leader>sT` | `n` | global | open TODO/FIX/FIXME picker |

---

## 6. Repo keymaps by category

The sections below are the repo-specific mappings you will use most often.

### 6.1 Core editing and movement

| Key | Modes | Scope | What it does |
| --- | --- | --- | --- |
| `j`, `<Down>` | `n,x` | global | move by display line when no count is given; use real line movement when a count is given |
| `k`, `<Up>` | `n,x` | global | same idea, but upward |
| `<A-j>` | `n,i,v` | global | move the current line or selection down and reindent |
| `<A-k>` | `n,i,v` | global | move the current line or selection up and reindent |
| `<Esc>` | `i,n,s` | global | clear search highlight, stop snippet if needed, then send a real escape |
| `n` | `n,x,o` | global | repeat search according to current direction; Normal mode also opens folds |
| `N` | `n,x,o` | global | repeat search in the opposite direction; Normal mode also opens folds |
| `,`, `.`, `;` | `i` | global | insert punctuation and create an undo breakpoint |
| `<C-s>` | `i,n,x,s` | global | save the current file |
| `<Tab>` | `i,s` | global | accept popup completion, then inline completion, then snippet jump, then literal tab |
| `<C-Space>` | `i` | global | trigger native LSP completion |
| `<` | `x` | global | indent left and keep the selection active |
| `>` | `x` | global | indent right and keep the selection active |
| `gco` | `n` | global | add a commented line below |
| `gcO` | `n` | global | add a commented line above |

### 6.2 Discovery and help

| Key | Mode | Scope | What it does |
| --- | --- | --- | --- |
| `<leader>?` | `n` | global | show buffer-local keymaps in which-key |
| `<C-w><Space>` | `n` | global | show window-command keys in a which-key loop |
| `<leader>sk` | `n` | global | open keymaps picker |
| `<leader>sh` | `n` | global | open help pages picker |
| `<leader>sc` | `n` | global | open command history |
| `<leader>sC` | `n` | global | open available commands |

### 6.3 Windows, buffers, and tabs

#### Windows

| Key | Mode | Scope | What it does |
| --- | --- | --- | --- |
| `<C-h>` | `n` | global | go to the left window |
| `<C-j>` | `n` | global | go to the lower window |
| `<C-k>` | `n` | global | go to the upper window |
| `<C-l>` | `n` | global | go to the right window |
| `<C-Up>` | `n` | global | increase window height |
| `<C-Down>` | `n` | global | decrease window height |
| `<C-Left>` | `n` | global | decrease window width |
| `<C-Right>` | `n` | global | increase window width |
| `<leader>wd` | `n` | global | close the current window |
| `<leader>wm` | `n` | global | toggle zoom for the current window |
| `<leader>uZ` | `n` | global | same zoom toggle under the UI group |

Useful built-in window commands that still work:

- `<C-w>s` — horizontal split
- `<C-w>v` — vertical split
- `<C-w>c` — close current window
- `<C-w>=` — equalize split sizes
- `<C-w>o` — keep only the current window

#### Buffers

| Key | Mode | Scope | What it does |
| --- | --- | --- | --- |
| `<S-h>` / `[b` | `n` | global | previous buffer |
| `<S-l>` / `]b` | `n` | global | next buffer |
| `<leader>\`` | `n` | global | switch to the alternate buffer |
| `<leader>bb` | `n` | global | reload the current buffer from disk |
| `<leader>bd` | `n` | global | close the current buffer |
| `<leader>bo` | `n` | global | close all other buffers |
| `<leader>bD` | `n` | global | close the current buffer and window |
| `<leader>bc` | `n` | global | copy the current buffer's relative path |
| `<leader>bC` | `n` | global | copy the current buffer's relative path and line number |
| `<leader>bn` | `n` | global | open a `path[:line[:col]]` value from the clipboard |
| `<leader>bp` | `n` | global | pin/unpin current buffer in Bufferline |
| `<leader>bP` | `n` | global | close all non-pinned buffers |
| `<leader>br` | `n` | global | close buffers to the right |
| `<leader>bl` | `n` | global | close buffers to the left |
| `[B` | `n` | global | move current buffer left in Bufferline |
| `]B` | `n` | global | move current buffer right in Bufferline |
| `<leader>bj` | `n` | global | pick a buffer directly from Bufferline |

Useful built-in buffer commands that still work:

- `:ls` or `:buffers` — list buffers
- `:bnext` / `:bprevious` — next / previous buffer
- `:b {number}` — jump to a specific buffer number
- `gf` — open the file under the cursor (**different from** `<leader>gf`, which is Git file history)

#### Tabs

| Key | Mode | Scope | What it does |
| --- | --- | --- | --- |
| `<leader><tab><tab>` | `n` | global | open a new tab |
| `<leader><tab>d` | `n` | global | close the current tab |
| `<leader><tab>]` | `n` | global | next tab |
| `<leader><tab>[` | `n` | global | previous tab |
| `<leader><tab>f` | `n` | global | first tab |
| `<leader><tab>l` | `n` | global | last tab |
| `<leader><tab>o` | `n` | global | close all other tabs |

Useful built-in tab keys that still work:

- `gt` — next tab
- `gT` — previous tab
- `:tabnew` — open a new tab

#### Practice

Try this mini-workflow:

1. Open a file with `<leader>ff`.
2. Create a split with `<C-w>v`.
3. Move between windows with `<C-h>` and `<C-l>`.
4. Open another file with `<leader>ff`.
5. Switch buffers with `<S-h>` and `<S-l>`.

### 6.4 Files, explorer, pickers, and search

#### File and picker entry points

| Key | Mode | Scope | What it does |
| --- | --- | --- | --- |
| `<leader>fn` | `n` | global | create a new empty buffer |
| `<leader>,` | `n` | global | open buffer picker |
| `<leader>:` | `n` | global | open command history |
| `<leader><space>` | `n` | global | find files from the detected project root |
| `<leader>fb` | `n` | global | open buffer picker |
| `<leader>fB` | `n` | global | open buffer picker including hidden and nofile buffers |
| `<leader>fc` | `n` | global | find config files |
| `<leader>ff` | `n` | global | find files from the detected project root |
| `<leader>fF` | `n` | global | find files from the current working directory |
| `<leader>fg` | `n` | global | find Git-tracked files |
| `<leader>fr` | `n` | global | open recent files |
| `<leader>fR` | `n` | global | open recent files from the current working directory |
| `<leader>fp` | `n` | global | open projects picker |
| `<leader>uC` | `n` | global | browse colorschemes |

#### Explorer

| Key | Mode | Scope | What it does |
| --- | --- | --- | --- |
| `<leader>fe` | `n` | global | open Snacks explorer at the detected project root |
| `<leader>fE` | `n` | global | open Snacks explorer at the current working directory |
| `<leader>e` | `n` | global | alias for `<leader>fe` |
| `<leader>E` | `n` | global | alias for `<leader>fE` |

#### Search pickers

| Key | Mode | Scope | What it does |
| --- | --- | --- | --- |
| `<leader>/` | `n` | global | live grep from the detected project root |
| `<leader>/` | `x` | global | grep the current visual selection |
| `<leader>sb` | `n` | global | search lines in the current buffer |
| `<leader>sB` | `n` | global | grep across open buffers |
| `<leader>sg` | `n` | global | live grep from the detected project root |
| `<leader>sG` | `n` | global | live grep from the current working directory |
| `<leader>sw` | `n,x` | global | grep the current word or visual selection from the project root |
| `<leader>sW` | `n,x` | global | grep the current word or visual selection from the current working directory |
| `<leader>s"` | `n` | global | open registers picker |
| `<leader>s/` | `n` | global | open search history |
| `<leader>sa` | `n` | global | open autocmds |
| `<leader>sc` | `n` | global | open command history |
| `<leader>sC` | `n` | global | open commands |
| `<leader>sh` | `n` | global | open help pages |
| `<leader>sH` | `n` | global | open highlights |
| `<leader>si` | `n` | global | open icons |
| `<leader>sj` | `n` | global | open jumps |
| `<leader>sk` | `n` | global | open keymaps |
| `<leader>sM` | `n` | global | open man pages |
| `<leader>sm` | `n` | global | open marks |
| `<leader>sR` | `n` | global | resume the last picker |
| `<leader>su` | `n` | global | open the undo tree |
| `<leader>sp` | `n` | global | open the floating `vim.pack` plugin manager UI |

#### Practice

A beginner-friendly file workflow:

1. Press `<leader>ff` and open a file.
2. Press `<leader>/` and search for a word in the project.
3. Press `<leader>fr` to reopen a recent file.
4. Press `<leader>fe` to browse the project tree.

### 6.5 Insert mode, completion, and editing helpers

| Key | Modes | Scope | What it does |
| --- | --- | --- | --- |
| `<C-s>` | `i,n,x,s` | global | save file |
| `<Tab>` | `i,s` | global | accept completion / jump snippet / insert literal tab |
| `<C-y>` | `i` | global | accept the currently selected popup completion item when the popup menu is visible |
| `<C-Space>` | `i` | global | trigger native LSP completion |
| `<leader>ue` | `n` | global | toggle built-in LSP inline completion when supported |
| `<A-j>` / `<A-k>` | `n,i,v` | global | move line/selection down or up |
| `,`, `.`, `;` | `i` | global | create undo breakpoints after punctuation |
| `<leader>up` | `n` | global | toggle Mini Pairs |

### 6.6 Code, formatting, and LSP

#### General code actions

| Key | Modes | Scope | What it does |
| --- | --- | --- | --- |
| `<leader>cf` | `n,x` | global | format through the repo formatter dispatcher |
| `<leader>cF` | `n,x` | global | format injected languages only |
| `<leader>cg` | `n` | global | detect indentation with `GuessIndent` |
| `<leader>cn` | `n` | global | generate annotations/docblocks with Neogen |
| `<leader>cm` | `n` | global | open Mason |
| `<leader>cs` | `n` | global | open document symbols picker |
| `<leader>cS` | `n` | global | open references picker |

#### LSP maps

These are **buffer-local** and appear only when the attached LSP client supports them.

| Key | Modes | Scope | What it does |
| --- | --- | --- | --- |
| `<leader>cl` | `n` | buffer-local | open LSP information/config picker |
| `gd` | `n` | buffer-local | go to definition |
| `gr` | `n` | buffer-local | show references |
| `gI` | `n` | buffer-local | go to implementation |
| `gy` | `n` | buffer-local | go to type definition |
| `gD` | `n` | buffer-local | go to declaration |
| `K` | `n` | buffer-local | hover documentation |
| `gK` | `n` | buffer-local | signature help |
| `<C-k>` | `i` | buffer-local | signature help while typing |
| `<leader>ca` | `n,x` | buffer-local | code action |
| `<leader>cc` | `n,x` | buffer-local | run CodeLens |
| `<leader>cC` | `n` | buffer-local | refresh CodeLens |
| `<leader>cR` | `n` | buffer-local | rename current file when the server supports file-rename operations |
| `<leader>cr` | `n` | buffer-local | rename symbol |
| `<leader>cA` | `n` | buffer-local | run a source action |
| `<leader>co` | `n` | buffer-local | organize imports when available |
| `]]` / `[[` | `n` | buffer-local | next / previous highlighted reference |
| `<A-n>` / `<A-p>` | `n` | buffer-local | alternate next / previous highlighted reference |
| `<leader>ss` | `n` | buffer-local | open document symbols |
| `<leader>sS` | `n` | buffer-local | open workspace symbols |
| `gai` | `n` | buffer-local | incoming call hierarchy |
| `gao` | `n` | buffer-local | outgoing call hierarchy |

#### Good first LSP workflow

1. Put the cursor on a symbol.
2. Press `gd`.
3. Press `<C-o>` to jump back.
4. Press `K` for docs.
5. Press `<leader>ca` for code actions.
6. Press `<leader>cr` to rename the symbol.

### 6.7 Git

| Key | Modes | Scope | What it does |
| --- | --- | --- | --- |
| `<leader>gg` | `n` | conditional | open LazyGit at the detected Git root |
| `<leader>gG` | `n` | conditional | open LazyGit in the current working directory |
| `<leader>gL` | `n` | global | show Git log in the current working directory |
| `<leader>gb` | `n` | global | show blame for the current line |
| `<leader>gf` | `n` | global | show history for the current file |
| `<leader>gl` | `n` | global | show Git log at the repo root |
| `<leader>gB` | `n,x` | global | open the Git browse URL |
| `<leader>gY` | `n,x` | global | copy the Git browse URL |
| `<leader>gd` | `n` | global | open Git diff hunks picker |
| `<leader>gD` | `n` | global | open grouped Git diff against `origin` |
| `<leader>gs` | `n` | global | open Git status |
| `<leader>gS` | `n` | global | open Git stash |

### 6.8 Diagnostics, quickfix, and location lists

#### Diagnostics

| Key | Mode | Scope | What it does |
| --- | --- | --- | --- |
| `<leader>cd` | `n` | global | show diagnostics for the current line |
| `]d` / `[d` | `n` | global | next / previous diagnostic |
| `]e` / `[e` | `n` | global | next / previous error |
| `]w` / `[w` | `n` | global | next / previous warning |
| `<leader>xx` | `n` | global | open diagnostics picker |
| `<leader>xX` | `n` | global | open buffer diagnostics picker |
| `<leader>sd` | `n` | global | open diagnostics picker |
| `<leader>sD` | `n` | global | open buffer diagnostics picker |

#### Quickfix and location lists

| Key | Mode | Scope | What it does |
| --- | --- | --- | --- |
| `<leader>xl` | `n` | global | toggle the location list window |
| `<leader>xq` | `n` | global | toggle the quickfix window |
| `[q` / `]q` | `n` | global | previous / next quickfix item |
| `<leader>xL` | `n` | global | open location list picker |
| `<leader>xQ` | `n` | global | open quickfix list picker |
| `<leader>sl` | `n` | global | open location list picker |
| `<leader>sq` | `n` | global | open quickfix list picker |

Useful built-in commands that still matter here:

- `:copen`, `:cclose` — open/close quickfix
- `:lopen`, `:lclose` — open/close location list
- `:cnext`, `:cprev` — next/previous quickfix item

### 6.9 Debugging

| Key | Mode | Scope | What it does |
| --- | --- | --- | --- |
| `<leader>dB` | `n` | global | set a conditional breakpoint |
| `<leader>db` | `n` | global | toggle a breakpoint |
| `<leader>dc` | `n` | global | continue debugging |
| `<leader>da` | `n` | global | continue / run with prompted arguments |
| `<leader>dC` | `n` | global | run to cursor |
| `<leader>dg` | `n` | global | go to line without executing |
| `<leader>di` | `n` | global | step into |
| `<leader>dj` | `n` | global | move down the stack |
| `<leader>dk` | `n` | global | move up the stack |
| `<leader>dl` | `n` | global | run the last debug session again |
| `<leader>do` | `n` | global | step out |
| `<leader>dO` | `n` | global | step over |
| `<leader>dP` | `n` | global | pause |
| `<leader>dr` | `n` | global | toggle the DAP REPL |
| `<leader>ds` | `n` | global | show the current DAP session |
| `<leader>dt` | `n` | global | terminate the current debug session |
| `<leader>dw` | `n` | global | open DAP widget hover |
| `<leader>du` | `n` | global | toggle DAP UI |
| `<leader>de` | `n,x` | global | evaluate expression under cursor / selection |
| `<leader>dpp` | `n` | global | toggle the Snacks profiler |
| `<leader>dph` | `n` | global | toggle profiler highlights |
| `<leader>dps` | `n` | global | open profiler scratch buffer |

### 6.10 Terminal, scratch, notifications, sessions, and UI toggles

#### Terminal and scratch

| Key | Modes | Scope | What it does |
| --- | --- | --- | --- |
| `<leader>fT` | `n` | global | open a terminal in the current working directory |
| `<leader>ft` | `n` | global | open a terminal at the detected project root |
| `<C-/>` | `n,t` | global | focus or toggle the root terminal |
| `<C-_>` | `n,t` | global | same terminal focus/toggle alias |
| `<leader>.` | `n` | global | toggle scratch buffer |
| `<leader>S` | `n` | global | select a scratch buffer |

Useful built-in terminal key to remember:

- `<C-\\><C-n>` — leave Terminal mode and return to Normal mode inside the terminal window

#### Notifications and sessions

| Key | Mode | Scope | What it does |
| --- | --- | --- | --- |
| `<leader>n` | `n` | global | open notification history |
| `<leader>un` | `n` | global | dismiss all notifications |
| `<leader>qs` | `n` | global | restore the current session |
| `<leader>qS` | `n` | global | select a saved session |
| `<leader>ql` | `n` | global | restore the last session |
| `<leader>qd` | `n` | global | stop saving the current session |
| `<leader>qq` | `n` | global | quit all windows |

#### Inspect and utility

| Key | Mode | Scope | What it does |
| --- | --- | --- | --- |
| `<leader>ur` | `n` | global | redraw, clear search highlights, and update diffs |
| `<leader>ui` | `n` | global | inspect the current cursor position |
| `<leader>uI` | `n` | global | inspect the current Treesitter tree |
| `<leader>uz` | `n` | global | toggle zen mode |

#### Toggles

| Key | Mode | Scope | What it does |
| --- | --- | --- | --- |
| `<leader>uf` | `n` | global | toggle global auto-format |
| `<leader>uF` | `n` | global | toggle buffer-local auto-format |
| `<leader>us` | `n` | global | toggle spelling |
| `<leader>uw` | `n` | global | toggle wrap |
| `<leader>uL` | `n` | global | toggle relative numbers |
| `<leader>ud` | `n` | global | toggle diagnostics |
| `<leader>ue` | `n` | global | toggle LSP inline completion |
| `<leader>ul` | `n` | global | toggle line numbers |
| `<leader>uc` | `n` | global | toggle conceal level |
| `<leader>uA` | `n` | global | toggle the tabline |
| `<leader>uT` | `n` | global | toggle Treesitter highlighting |
| `<leader>ub` | `n` | global | toggle dark background |
| `<leader>uD` | `n` | global | toggle dim mode |
| `<leader>ua` | `n` | global | toggle UI animation |
| `<leader>ug` | `n` | global | toggle Snacks indent guides |
| `<leader>uS` | `n` | global | toggle smooth scroll |
| `<leader>uh` | `n` | conditional | toggle LSP inlay hints |
| `<leader>up` | `n` | global | toggle Mini Pairs |

### 6.11 AI

| Key | Mode | Scope | What it does |
| --- | --- | --- | --- |
| `<leader>9v` | `v` | global | send the current visual selection to `99` |
| `<leader>9x` | `n` | global | stop all active `99` requests |
| `<leader>9s` | `n` | global | run `99` search |

---

## 7. Filetype-local and conditional mappings

### Helper windows and Lua files

| Key | Modes | Scope | What it does |
| --- | --- | --- | --- |
| `q` | `n` | buffer-local | close helper/ephemeral buffers such as `help`, `qf`, `notify`, `grug-far`, `checkhealth`, `lspinfo`, and several plugin popups |
| `<localleader>r` | `n,x` | filetype-local (`lua`) | run the current Lua file or selection with `Snacks.debug.run()` |

### YAML and Markdown

| Key | Mode | Scope | What it does |
| --- | --- | --- | --- |
| `<leader>fy` | `n` | filetype-local (`yaml`) | find a YAML key via `yaml.nvim` |
| `<leader>cp` | `n` | filetype-local (`markdown`) | toggle Markdown preview |

### Python

| Key | Mode | Scope | What it does |
| --- | --- | --- | --- |
| `<leader>cv` | `n` | filetype-local (`python`) | select a Python virtual environment |
| `<leader>dPt` | `n` | filetype-local (`python`) | debug the current Python test method |
| `<leader>dPc` | `n` | filetype-local (`python`) | debug the current Python test class |

### Rust

These override some generic meanings in Rust buffers.

| Key | Mode | Scope | What it does |
| --- | --- | --- | --- |
| `<leader>cR` | `n` | buffer-local (`rust`) | open `RustLsp codeAction` |
| `<leader>dr` | `n` | buffer-local (`rust`) | open `RustLsp debuggables` |

### TypeScript / JavaScript via `vtsls`

| Key | Mode | Scope | What it does |
| --- | --- | --- | --- |
| `gR` | `n` | buffer-local | show file references |
| `<leader>cM` | `n` | buffer-local | add missing imports |
| `<leader>cu` | `n` | buffer-local | remove unused imports |
| `<leader>cD` | `n` | buffer-local | fix all diagnostics |
| `<leader>cV` | `n` | buffer-local | select the workspace TypeScript version |

### Notes on precedence

- Generic LSP keys are attached before server-specific keys and deduped by `mode + lhs`.
- That means server-specific duplicates such as `vtsls` trying to reuse `gD` or `<leader>co` can be blocked by the generic mapping that attached first.
- Rust is different: it sets fresh buffer-local mappings in `rustaceanvim`'s `on_attach`, so its Rust-specific keys do override the generic ones.

---

## 8. Local UI keymaps

These keys only work inside specific plugin windows.

### 8.1 Snacks picker-local keys

| Key | Modes | Scope | What it does |
| --- | --- | --- | --- |
| `<A-c>` | `n,i` | picker-local | toggle picker cwd between project root and current working directory |
| `<A-s>` | `n,i` | picker-local | trigger Flash inside the picker |
| `s` | picker input | picker-local | trigger Flash inside the picker |

### 8.2 Dashboard-local keys

These only work on the startup dashboard.

| Key | Scope | What it does |
| --- | --- | --- |
| `f` | dashboard-local | find file |
| `n` | dashboard-local | new file |
| `g` | dashboard-local | find text |
| `r` | dashboard-local | recent files |
| `c` | dashboard-local | find config files |
| `p` | dashboard-local | projects |
| `s` | dashboard-local | restore session |
| `l` | dashboard-local | open plugin manager |
| `q` | dashboard-local | quit |

### 8.3 Terminal-local Snacks keys

| Key | Mode | Scope | What it does |
| --- | --- | --- | --- |
| `<C-h>` | `t` | terminal-local | go to left window when terminal is not floating |
| `<C-j>` | `t` | terminal-local | go to lower window when terminal is not floating |
| `<C-k>` | `t` | terminal-local | go to upper window when terminal is not floating |
| `<C-l>` | `t` | terminal-local | go to right window when terminal is not floating |
| `<C-/>` | `t` | terminal-local | hide the current Snacks terminal |
| `<C-_>` | `t` | terminal-local | same hide-terminal alias |

### 8.4 Plugin manager (`:Pack`) local keys

These only work inside the floating `vim.pack` UI opened by `<leader>sp` or `:Pack`.

| Key | Scope | What it does |
| --- | --- | --- |
| `q`, `<Esc>` | plugin-manager-local | close the window |
| `U` | plugin-manager-local | update all plugins |
| `u` | plugin-manager-local | update the plugin under the cursor |
| `X` | plugin-manager-local | clean all non-active plugins |
| `D` | plugin-manager-local | delete the plugin under the cursor |
| `L` | plugin-manager-local | open the `nvim-pack.log` file |
| `<CR>` | plugin-manager-local | expand/collapse commit details for the plugin under the cursor |
| `]]` / `[[` | plugin-manager-local | jump to next / previous plugin entry |
| `C` | plugin-manager-local | check for plugin updates |
| `?` | plugin-manager-local | toggle the help panel |

---

## 9. Most useful commands

These are the commands a beginner is most likely to need.

### 9.1 Built-in commands worth memorizing

| Command | What it does | When to use it |
| --- | --- | --- |
| `:w` | save the current file | after edits |
| `:q` | quit the current window | when you are done with that window |
| `:wq` | save and quit | very common |
| `:q!` | quit without saving | emergency escape hatch |
| `:e {file}` | edit a file | open a file directly |
| `:e #` | edit the alternate file | switch back to the previous file |
| `:e!` | reload the current file from disk | discard local changes |
| `:enew` | open a new empty buffer | scratch editing |
| `:split` | horizontal split | compare two views |
| `:vsplit` | vertical split | compare side by side |
| `:tabnew` | new tab | separate task/context |
| `:noh` | clear search highlight | after `/` searches |
| `:help {topic}` | open help | learn any built-in topic |
| `:checkhealth` | run health checks | diagnose missing tools or plugin issues |
| `:messages` | show message history | review errors/warnings |
| `:registers` | inspect registers | debug copies, macros, clipboard |
| `:marks` | inspect marks | see saved jump locations |
| `:jumps` | inspect jump list | understand navigation history |
| `:changes` | inspect change list | revisit edits |
| `:copen` / `:cclose` | open/close quickfix | after grep/build/lint flows |
| `:lopen` / `:lclose` | open/close location list | buffer-local diagnostics/search flows |
| `:verbose map {lhs}` | show where a keymap came from | perfect for debugging mappings |

### 9.1a Ranges and substitution you should know

| Command | What it does | Why it matters |
| --- | --- | --- |
| `:%s/old/new/g` | replace all matches in the current file | the classic whole-file replace |
| `:%s/old/new/gc` | replace with confirmation | safer whole-file replace |
| `:'<,'>s/old/new/g` | replace only inside the current visual selection | perfect after selecting a block or paragraph |
| `:.,$s/old/new/g` | replace from the current line to the end of the file | good for local cleanup |
| `:1,20s/old/new/g` | replace only inside a numbered line range | precise batch editing |
| `:g/pattern/d` | delete lines matching a pattern | powerful line filtering |
| `:v/pattern/d` | delete lines not matching a pattern | inverse line filtering |

> `'<,'>` is the range Neovim inserts automatically after you make a visual selection and then press `:`.

### 9.1b Project search and quickfix workflow

This config sets `grepprg` to `rg --vimgrep`, so built-in `:grep` is already very useful.

| Command | What it does | Typical next step |
| --- | --- | --- |
| `:grep pattern` | search the project with ripgrep | then `:copen` |
| `:copen` | open quickfix results | navigate with `[q`, `]q`, `:cnext`, or `:cprev` |
| `:cclose` | close quickfix | after review |
| `:vimgrep /pattern/ **/*` | Vim-style project search | another built-in way to fill quickfix |

A great built-in workflow is:

1. `:grep TODO`
2. `:copen`
3. jump through matches with `[q` and `]q`

### 9.1c Help-window navigation

| Key / Command | Where | What it does |
| --- | --- | --- |
| `:help {topic}` | anywhere | open a help page |
| `<C-]>` | help buffer | jump to the help tag under the cursor |
| `<C-t>` | help buffer | jump back from a followed help tag |
| `/pattern` | help buffer | search inside help |
| `q` | help buffer in this config | close the help window |

### 9.2 Repo-provided commands worth knowing

| Command | What it does | Notes |
| --- | --- | --- |
| `:Format` | format the current buffer/selection | same idea as `<leader>cf` |
| `:FormatInfo` | show formatter information | useful when format-on-save is confusing |
| `:Tmp` / `:tmp` | open a writable temporary copy of the current file in a separate buffer | temp buffers are prefixed with `~` in the bufferline |
| `:Untmp` / `:untmp` | write the current temporary buffer back to the original file | errors unless you are inside a temp buffer |
| `:ProjectRoot` | show detected project roots | helpful when pickers seem to use the wrong root |
| `:Mason` | open Mason | same as `<leader>cm` |
| `:GuessIndent` | detect indentation | same as `<leader>cg` |
| `:Pack` | open the plugin manager window | same as `<leader>sp` |
| `:Pack check` | open `:Pack` and check for updates | plugin manager helper |
| `:Pack update` | update plugins | plugin manager helper |
| `:PackUpdate` | check/update plugins from the command line | can take plugin names |

### 9.3 Filetype-specific commands you may need later

| Command | Usually available in | What it does |
| --- | --- | --- |
| `:MarkdownPreviewToggle` | Markdown | open/close Markdown preview |
| `:VenvSelect` | Python | choose a Python virtualenv |
| `:RustLsp codeAction` | Rust | Rust-specific code actions |
| `:RustLsp debuggables` | Rust | Rust-specific debuggable targets |

### 9.4 Helpful `:help` topics for beginners

Try these directly:

- `:help motion.txt`
- `:help usr_03.txt`
- `:help text-objects`
- `:help registers`
- `:help quote_alpha`
- `:help ctrl-w`
- `:help quickfix`
- `:help pattern`
- `:help :substitute`

---

## 10. Suggested first-week practice routine

If you want to build muscle memory quickly, spend five minutes a day on this:

### Drill 1: open, move, save

1. Press `<leader>ff` and open any file.
2. Move with `w`, `b`, `0`, `$`, `gg`, `G`.
3. Press `<C-s>` to save.

### Drill 2: edit with operators

1. Use `ciw` to change a word.
2. Use `daw` to delete a word plus its surrounding space.
3. Use `p` to paste it back.
4. Use `.` to repeat a change.

### Drill 3: search and jump

1. Use `/something`.
2. Repeat with `n` and `N`.
3. Use `s` for a Flash jump.
4. Clear highlights with `<Esc>`.

### Drill 4: inspect code

In a file with LSP attached:

1. Press `gd`.
2. Press `<C-o>` to go back.
3. Press `K` for documentation.
4. Press `<leader>ca` for actions.

### Drill 5: project navigation

1. Press `<leader>ff` to find a file.
2. Press `<leader>/` to search text in the project.
3. Press `<leader>fe` to open the explorer.
4. Press `<leader>,` to switch buffers.

---

## 11. Quick reference summary

If you only remember one compact list, make it this one:

| Goal | Key |
| --- | --- |
| save | `<C-s>` or `:w` |
| quit current window | `:q` or `<leader>wd` |
| quit everything | `<leader>qq` or `:qa` |
| find a file | `<leader>ff` |
| search project text | `<leader>/` |
| open explorer | `<leader>fe` |
| switch buffers | `<leader>,` or `<S-h>` / `<S-l>` |
| go to definition | `gd` |
| hover docs | `K` |
| code action | `<leader>ca` |
| rename symbol | `<leader>cr` |
| format | `<leader>cf` |
| diagnostics | `<leader>xx` |
| Git status | `<leader>gs` |
| terminal | `<leader>ft` |
| keymap help | `<leader>?` or `<leader>sk` |

If you are unsure what a key does, use one of these immediately:

- `<leader>?`
- `<leader>sk`
- `:verbose map {lhs}`
- `:help {topic}`

