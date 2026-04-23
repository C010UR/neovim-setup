# Plugin inventory

_Audited against the repo-owned `vim.pack` graph on April 23, 2026._

## Scope and conventions

- Source of truth: `init.lua` → `lua/config/pack.lua` → every file in `lua/plugins/*.lua`.
- `lua/config/pack.lua` installs plugins through Neovim 0.12 `vim.pack`, merges repeated specs (including `opts`, `data`, and `hooks`), and applies the normalized graph.
- Augment specs are merged into their primary plugin entry instead of being listed twice.
- Dependency-only plugins are listed when the repo gives them a clear user-facing role.
- Short-name augments such as `catppuccin` and `snacks.nvim` are documented under their canonical plugin entry.
- Insert-mode and command-line completion now come from Neovim 0.12 built-ins (`vim.lsp.completion`, popup completion, and command-line wildmenu/pum options), so there is no third-party completion plugin in this inventory.
- The generated lockfile is `nvim-pack-lock.json`.

## Bootstrap / plugin manager

| Component | What it does here | Sources |
| --- | --- | --- |
| Built-in `vim.pack` + repo loader | Installs plugins, normalizes repeated specs, and exposes shared merged plugin metadata to the rest of the config. | `init.lua`, `lua/config/pack.lua` |
| Local `pack-ui` module | Provides the floating `:Pack` UI plus `:PackUpdate` for inspecting, checking, updating, cleaning, and logging `vim.pack` plugins without pushing UI policy back into `config.pack`. | `lua/plugins/pack-ui.lua` |

## Pack spec / hook conventions

- Prefer explicit `hooks = { pre = ..., post = ... }` for plugin lifecycle work instead of the legacy `build = ...` shorthand.
- Hook stages map to native `vim.pack` events: `pre` runs on `PackChangedPre`, `post` runs on `PackChanged`.
- Hook kinds can target `install`, `update`, `delete`, or `"*"` for all three kinds.
- Hook actions can be:
  - an Ex command string, like `":TSUpdate"`
  - a Lua callback, like `function(plugin, event) ... end`
  - a list of actions, mixed as needed
  - a structured shell command, like `{ cmd = { "make", "install" } }`, which runs in the plugin directory
- `build = ...` is still supported, but it is treated as a compatibility shorthand for `hooks.post.install` and `hooks.post.update`.
- `data = { ... }` is merged across augment specs and passed through to the final `vim.pack.add()` spec.

Current examples in this repo:

- `lua/plugins/treesitter.lua` uses explicit post-install/post-update hooks to run `:TSUpdate`.
- `lua/plugins/lang-markdown.lua` uses explicit post-install/post-update hooks to run Markdown Preview's install helper.

## Core UI / pickers / sessions

| Plugin | What it does here | Sources |
| --- | --- | --- |
| `folke/snacks.nvim` | Main UI backbone for this setup: picker, explorer, terminal, dashboard, notifier, scratch buffers, git helpers, toggle framework, word/reference jumping, profiler tools, and shared picker/search commands. The repo also uses an explorer-specific augment and disables Snacks indent scope in favor of `mini.indentscope`. | `lua/plugins/snacks.lua`, `lua/plugins/snacks-explorer.lua`, `lua/plugins/editor.lua`, `lua/plugins/lang-conffiles.lua`, `lua/plugins/ui.lua` |
| `folke/persistence.nvim` | Session save/restore/select support behind the `<leader>q*` session commands. | `lua/plugins/snacks.lua` |
| `folke/which-key.nvim` | Keymap discovery UI. This repo uses the `helix` preset and defines the major leader-key groups that shape the rest of the documentation. | `lua/plugins/editor.lua` |
| `MagicDuck/grug-far.nvim` | Search-and-replace UI, with repo-specific logic to prefill the current file extension when possible. | `lua/plugins/editor.lua` |
| `nvim-lua/plenary.nvim` | Support library used by the repo's Snacks/DAP stack; notably used to strip comments from VS Code-style JSON debug configs. | `lua/plugins/snacks.lua`, `lua/plugins/dap.lua` |

## Appearance / theme / statusline / bufferline

| Plugin | What it does here | Sources |
| --- | --- | --- |
| `folke/tokyonight.nvim` | Default active colorscheme (`tokyonight`, style `night`). | `lua/plugins/theme.lua` |
| `ellisonleao/gruvbox.nvim` | Alternate colorscheme kept installed as an optional theme. | `lua/plugins/theme.lua` |
| `catppuccin/nvim` | Alternate colorscheme with many enabled integrations and optional Bufferline theming when Catppuccin is active. | `lua/plugins/theme.lua` |
| `akinsho/bufferline.nvim` | Buffer tabline with custom diagnostics badges, `Snacks.bufdelete` close behavior, and optional Catppuccin highlights. | `lua/plugins/ui.lua`, `lua/plugins/theme.lua` |
| `nvim-lualine/lualine.nvim` | Statusline showing mode, branch, root directory, diagnostics, Navic breadcrumbs, and DAP status. | `lua/plugins/ui.lua` |
| `nvim-mini/mini.icons` | File/icon provider with custom overrides for dotfiles and JS/TS config files, plus a `nvim-web-devicons` compatibility shim. | `lua/plugins/ui.lua`, `lua/plugins/lang-typescript.lua` |
| `nvim-mini/mini.indentscope` | Indent guides with animation disabled and a repo-defined disable list for dashboard/help/notify/terminal-like buffers. | `lua/plugins/ui.lua` |

## Editing / navigation / search

| Plugin | What it does here | Sources |
| --- | --- | --- |
| `folke/flash.nvim` | Motion/search replacement for `s`, `S`, `r`, `R`, plus a Treesitter selection mode on `<C-Space>`. | `lua/plugins/editor.lua` |
| `folke/todo-comments.nvim` | Highlights TODO/FIX/FIXME comments and adds jump/picker commands for them. | `lua/plugins/editor.lua` |
| `NMAC427/guess-indent.nvim` | Detects indentation style on demand and exposes `GuessIndent` through a leader mapping. | `lua/plugins/guess-indent.lua` |
| `nvim-mini/mini.move` | Line/block move helper plugin kept on with defaults; the repo does not redefine its built-in mapping set. | `lua/plugins/editor.lua` |

## Coding / textobjects / comments

| Plugin | What it does here | Sources |
| --- | --- | --- |
| `nvim-mini/mini.pairs` | Autopairs with repo-specific behavior for Markdown fences, Treesitter/string skipping, and unbalanced-pair avoidance. | `lua/plugins/coding.lua`, `lua/config/mini.lua` |
| `folke/ts-comments.nvim` | Treesitter-aware `commentstring` support. | `lua/plugins/coding.lua` |
| `nvim-mini/mini.ai` | Textobject engine extended with repo-defined objects for functions, classes, tags, digit runs, camel/snake segments, whole-buffer ranges, and call/use patterns. | `lua/plugins/coding.lua`, `lua/config/mini.lua` |
| `nvim-mini/mini.comment` | Comment plugin kept with defaults; the repo adds helper `gco` and `gcO` mappings in core keymaps instead of changing the plugin defaults. | `lua/plugins/coding.lua`, `lua/config/keymaps.lua` |
| `nvim-mini/mini.surround` | Surround editing plugin kept with defaults. | `lua/plugins/coding.lua` |
| `danymat/neogen` | Generates annotations/docblocks through a single leader mapping. | `lua/plugins/coding.lua` |

## Treesitter / parsing

| Plugin | What it does here | Sources |
| --- | --- | --- |
| `nvim-treesitter/nvim-treesitter` | Parser/highlight/indent backbone on the `main` rewrite. The config now installs parsers via the registry-backed workflow and enables Treesitter features explicitly on `FileType`, while language modules extend its parser list and filetype detection for config files, PHP, Python, Ruby, Rust, and shell-adjacent files including Fish. | `lua/plugins/treesitter.lua`, `lua/plugins/lang-conffiles.lua`, `lua/plugins/lang-php.lua`, `lua/plugins/lang-python.lua`, `lua/plugins/lang-ruby.lua`, `lua/plugins/lang-rust.lua`, `lua/plugins/lang-shell.lua` |
| `nvim-treesitter/nvim-treesitter-textobjects` | Adds the explicit function/class/parameter motion maps such as `]f`, `[f`, `]c`, and `[c`. | `lua/plugins/treesitter.lua` |
| `windwp/nvim-ts-autotag` | Auto close/rename tag pairs in HTML-like files. | `lua/plugins/treesitter.lua` |
| `nvim-treesitter/nvim-treesitter-context` | Sticky context header for the current Treesitter scope. | `lua/plugins/treesitter.lua` |

## LSP / formatting / linting / tool management

| Plugin | What it does here | Sources |
| --- | --- | --- |
| `folke/lazydev.nvim` | Lua-development helper for `vim.uv` and related library typing. | `lua/plugins/lsp.lua` |
| `neovim/nvim-lspconfig` | Main LSP layer: diagnostics styling, foldexpr setup, inlay hints, native Neovim 0.12 completion enablement, formatter registration, lazy LSP key attachment, and per-language server config. Language modules extend it for JSON/YAML/XML, Markdown, PHP/Twig, Python, Ruby, Bash/Fish, Tailwind, TypeScript/JavaScript, and Rust-adjacent tools. | `lua/plugins/lsp.lua`, `lua/plugins/coding.lua`, `lua/plugins/lang-conffiles.lua`, `lua/plugins/lang-markdown.lua`, `lua/plugins/lang-php.lua`, `lua/plugins/lang-python.lua`, `lua/plugins/lang-ruby.lua`, `lua/plugins/lang-rust.lua`, `lua/plugins/lang-shell.lua`, `lua/plugins/lang-tailwind.lua`, `lua/plugins/lang-typescript.lua` |
| `SmiteshP/nvim-navic` | Breadcrumb provider attached from `config.lsp` and shown in Lualine. | `lua/plugins/coding.lua`, `lua/plugins/ui.lua`, `lua/config/lsp.lua` |
| `stevearc/conform.nvim` | Primary formatter dispatcher used by `config.format`. Base config covers Lua/Fish/Shell; language augments add JSON/YAML/XML/SVG, Markdown/MDX, PHP/Twig, Ruby/ERB, and JS/TS/CSS-family formatting. | `lua/plugins/formatting.lua`, `lua/plugins/lang-conffiles.lua`, `lua/plugins/lang-markdown.lua`, `lua/plugins/lang-php.lua`, `lua/plugins/lang-ruby.lua`, `lua/plugins/lang-typescript.lua` |
| `mfussenegger/nvim-lint` | Debounced lint-on-read/write/insert-leave. Base config covers Fish; augments add Dockerfile, Markdown, PHP, and Twig linters. | `lua/plugins/linting.lua`, `lua/plugins/lang-conffiles.lua`, `lua/plugins/lang-markdown.lua`, `lua/plugins/lang-php.lua` |
| `mason-org/mason.nvim` | Tool installer that auto-installs the repo's chosen LSP servers, formatters, linters, and debug tools across the language modules. | `lua/plugins/lsp.lua`, `lua/plugins/formatting.lua`, `lua/plugins/lang-conffiles.lua`, `lua/plugins/lang-markdown.lua`, `lua/plugins/lang-php.lua`, `lua/plugins/lang-ruby.lua`, `lua/plugins/lang-rust.lua`, `lua/plugins/lang-typescript.lua` |
| `mason-org/mason-lspconfig.nvim` | Bridge between Mason and `nvim-lspconfig`, used here to auto-install and auto-enable supported language servers. | `lua/plugins/lsp.lua` |

## Debugging

| Plugin | What it does here | Sources |
| --- | --- | --- |
| `mfussenegger/nvim-dap` | Core debugging framework with signs, run/step/breakpoint mappings, and VS Code launch config parsing support. Language modules extend it for PHP, Python, and Ruby. | `lua/plugins/dap.lua`, `lua/plugins/lang-php.lua`, `lua/plugins/lang-python.lua`, `lua/plugins/lang-ruby.lua` |
| `rcarriga/nvim-dap-ui` | Debugger UI panes that auto-open on start and close on exit/termination. | `lua/plugins/dap.lua` |
| `theHamsta/nvim-dap-virtual-text` | Inline debug values rendered next to code. | `lua/plugins/dap.lua` |
| `nvim-neotest/nvim-nio` | Runtime dependency used by `nvim-dap-ui`. | `lua/plugins/dap.lua` |
| `jay-babu/mason-nvim-dap.nvim` | DAP adapter installer/bridge. Python adds a small augment so local `debugpy` setup stays in charge. | `lua/plugins/dap.lua`, `lua/plugins/lang-python.lua` |
| `mfussenegger/nvim-dap-python` | Python-specific DAP helper used for test method/class debugging. | `lua/plugins/lang-python.lua` |
| `suketa/nvim-dap-ruby` | Ruby-specific DAP helper used to configure Ruby debugging. | `lua/plugins/lang-ruby.lua` |

## AI

| Plugin | What it does here | Sources |
| --- | --- | --- |
| `ThePrimeagen/99` | AI workflow helper configured for `OpenCodeProvider`, AGENT-file discovery, custom rules from `opencode/skills` and `.mux/skills`, and native Neovim completion in prompt buffers. | `lua/plugins/ai.lua` |

## Language-specific tooling

| Plugin | What it does here | Sources |
| --- | --- | --- |
| `b0o/SchemaStore.nvim` | Supplies JSON and YAML schemas to `jsonls` and `yamlls`. | `lua/plugins/lang-conffiles.lua` |
| `https://tangled.org/cuducos.me/yaml.nvim` | YAML key finder exposed through a Snacks-based command. | `lua/plugins/lang-conffiles.lua` |
| `iamcco/markdown-preview.nvim` | Browser preview for Markdown files. | `lua/plugins/lang-markdown.lua` |
| `linux-cultist/venv-selector.nvim` | Python virtualenv selector. | `lua/plugins/lang-python.lua` |
| `Saecki/crates.nvim` | Cargo.toml dependency helper with completion, actions, and hover support. | `lua/plugins/lang-rust.lua` |
| `mrcjkb/rustaceanvim` | Rust-specific LSP/DAP workflow layer that can wire in `codelldb`, adds Rust buffer-local commands, and owns the main Rust analyzer configuration path. | `lua/plugins/lang-rust.lua` |

