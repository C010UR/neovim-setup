# Plugin inventory

_Audited against the current repo-owned plugin graph on April 20, 2026._

## Scope and conventions

- Source of truth: `init.lua` → `lua/config/lazy.lua` → every file in `lua/plugins/*.lua`.
- `folke/lazy.nvim` is bootstrapped directly in `lua/config/lazy.lua`, so it is included here even though it does not live under `lua/plugins/`.
- Augment specs are merged into their primary plugin entry instead of being listed twice.
- Dependency-only plugins are included when the repo config gives them a clear user-facing role.
- Short-name augments such as `catppuccin`, `mini.diff`, and `snacks.nvim` are documented under their canonical plugin entry.

## Bootstrap / plugin manager

| Plugin | What it does here | Sources |
| --- | --- | --- |
| `folke/lazy.nvim` | Bootstraps the plugin manager, defines the custom `LazyFile` event, imports all repo-owned specs, and loads the core config modules before plugin setup. | `lua/config/lazy.lua` |

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
| `ellisonleao/gruvbox.nvim` | Alternate colorscheme kept installed as a lazy-loaded option. | `lua/plugins/theme.lua` |
| `catppuccin/nvim` | Alternate colorscheme with many enabled integrations; the repo also wires in Blink support and optional Bufferline theming when Catppuccin is active. | `lua/plugins/theme.lua`, `lua/plugins/coding.lua` |
| `akinsho/bufferline.nvim` | Buffer tabline with custom diagnostics badges, `Snacks.bufdelete` close behavior, and optional Catppuccin highlights. | `lua/plugins/ui.lua`, `lua/plugins/theme.lua` |
| `nvim-lualine/lualine.nvim` | Statusline showing mode, branch, root directory, diagnostics, Navic breadcrumbs, DAP status, Lazy updates, and MiniDiff summaries. | `lua/plugins/ui.lua` |
| `nvim-mini/mini.icons` | File/icon provider with custom overrides for dotfiles and JS/TS config files, plus a `nvim-web-devicons` compatibility shim. | `lua/plugins/ui.lua`, `lua/plugins/lang-typescript.lua` |
| `nvim-mini/mini.diff` | Inline Git diff signs and overlay. The repo also adds a toggle for the signs and exposes an overlay keymap. | `lua/plugins/ui.lua` |
| `nvim-mini/mini.indentscope` | Indent guides with animation disabled and a repo-defined disable list for dashboard/help/notify/terminal-like buffers. | `lua/plugins/ui.lua` |

## Editing / navigation / search

| Plugin | What it does here | Sources |
| --- | --- | --- |
| `folke/flash.nvim` | Motion/search replacement for `s`, `S`, `r`, `R`, plus a Treesitter selection mode on `<C-Space>`. | `lua/plugins/editor.lua` |
| `folke/todo-comments.nvim` | Highlights TODO/FIX/FIXME comments and adds jump/picker commands for them. | `lua/plugins/editor.lua` |
| `NMAC427/guess-indent.nvim` | Detects indentation style on demand and exposes `GuessIndent` through a leader mapping. | `lua/plugins/guess-indent.lua` |
| `nvim-mini/mini.move` | Line/block move helper plugin kept on with defaults; the repo does not redefine its built-in mapping set. | `lua/plugins/editor.lua` |

## Coding / completion / textobjects / comments

| Plugin | What it does here | Sources |
| --- | --- | --- |
| `nvim-mini/mini.pairs` | Autopairs with repo-specific behavior for Markdown fences, Treesitter/string skipping, and unbalanced-pair avoidance. | `lua/plugins/coding.lua`, `lua/config/mini.lua` |
| `folke/ts-comments.nvim` | Treesitter-aware `commentstring` support. | `lua/plugins/coding.lua` |
| `nvim-mini/mini.ai` | Textobject engine extended with repo-defined objects for functions, classes, tags, digit runs, camel/snake segments, whole-buffer ranges, and call/use patterns. | `lua/plugins/coding.lua`, `lua/config/mini.lua` |
| `nvim-mini/mini.comment` | Comment plugin kept with defaults; the repo adds helper `gco` and `gcO` mappings in core keymaps instead of changing the plugin defaults. | `lua/plugins/coding.lua`, `lua/config/keymaps.lua` |
| `nvim-mini/mini.surround` | Surround editing plugin kept with defaults. | `lua/plugins/coding.lua` |
| `danymat/neogen` | Generates annotations/docblocks through a single leader mapping. | `lua/plugins/coding.lua` |
| `saghen/blink.cmp` | Primary completion engine. This setup enables command-line completion, customizes accept behavior with `<C-y>`, uses Blink for AI prompt completion, and extends completion display for Tailwind color entries. | `lua/plugins/coding.lua`, `lua/plugins/lang-tailwind.lua` |
| `rafamadriz/friendly-snippets` | Snippet source used by Blink. | `lua/plugins/coding.lua` |
| `saghen/blink.compat` | Lazy-loaded Blink compatibility bridge for older completion sources; included but not otherwise customized in repo code. | `lua/plugins/coding.lua` |

## Treesitter / parsing

| Plugin | What it does here | Sources |
| --- | --- | --- |
| `nvim-treesitter/nvim-treesitter` | Parser/highlight/indent backbone. Language modules extend its parser list and add filetype detection for config files, PHP, Python, Ruby, Rust, and shell-adjacent files. | `lua/plugins/treesitter.lua`, `lua/plugins/lang-conffiles.lua`, `lua/plugins/lang-php.lua`, `lua/plugins/lang-python.lua`, `lua/plugins/lang-ruby.lua`, `lua/plugins/lang-rust.lua`, `lua/plugins/lang-shell.lua` |
| `nvim-treesitter/nvim-treesitter-textobjects` | Adds the explicit function/class/parameter motion maps such as `]f`, `[f`, `]c`, and `[c`. | `lua/plugins/treesitter.lua` |
| `windwp/nvim-ts-autotag` | Auto close/rename tag pairs in HTML-like files. | `lua/plugins/treesitter.lua` |
| `nvim-treesitter/nvim-treesitter-context` | Sticky context header for the current Treesitter scope. | `lua/plugins/treesitter.lua` |

## LSP / formatting / linting / tool management

| Plugin | What it does here | Sources |
| --- | --- | --- |
| `folke/lazydev.nvim` | Lua-development helper for `vim.uv` and related library typing. | `lua/plugins/lsp.lua` |
| `neovim/nvim-lspconfig` | Main LSP layer: diagnostics styling, foldexpr setup, inlay hints, formatter registration, lazy LSP key attachment, and per-language server config. Language modules extend it for JSON/YAML/XML, Markdown, PHP/Twig, Python, Ruby, Shell, Tailwind, TypeScript/JavaScript, and Rust-adjacent tools. | `lua/plugins/lsp.lua`, `lua/plugins/coding.lua`, `lua/plugins/lang-conffiles.lua`, `lua/plugins/lang-markdown.lua`, `lua/plugins/lang-php.lua`, `lua/plugins/lang-python.lua`, `lua/plugins/lang-ruby.lua`, `lua/plugins/lang-rust.lua`, `lua/plugins/lang-shell.lua`, `lua/plugins/lang-tailwind.lua`, `lua/plugins/lang-typescript.lua` |
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
| `ThePrimeagen/99` | AI workflow helper configured for `OpenCodeProvider`, AGENT-file discovery, custom rules from `opencode/skills` and `.mux/skills`, and Blink-backed prompt completion. | `lua/plugins/ai.lua` |

## Language-specific tooling

| Plugin | What it does here | Sources |
| --- | --- | --- |
| `b0o/SchemaStore.nvim` | Supplies JSON and YAML schemas to `jsonls` and `yamlls`. | `lua/plugins/lang-conffiles.lua` |
| `https://tangled.org/cuducos.me/yaml.nvim` | YAML key finder exposed through a Snacks-based command. | `lua/plugins/lang-conffiles.lua` |
| `iamcco/markdown-preview.nvim` | Browser preview for Markdown files. | `lua/plugins/lang-markdown.lua` |
| `linux-cultist/venv-selector.nvim` | Python virtualenv selector. | `lua/plugins/lang-python.lua` |
| `Saecki/crates.nvim` | Cargo.toml dependency helper with completion, actions, and hover support. | `lua/plugins/lang-rust.lua` |
| `mrcjkb/rustaceanvim` | Rust-specific LSP/DAP workflow layer that can wire in `codelldb`, adds Rust buffer-local commands, and owns the main Rust analyzer configuration path. | `lua/plugins/lang-rust.lua` |
| `brenoprata10/nvim-highlight-colors` | Colors Tailwind/LSP completion entries inside Blink's menu so CSS utility classes show real color chips. | `lua/plugins/lang-tailwind.lua` |

## Notes on merged specs

The following plugins are configured across multiple files and are intentionally documented once above rather than as separate entries:

- `folke/snacks.nvim`
- `neovim/nvim-lspconfig`
- `mason-org/mason.nvim`
- `stevearc/conform.nvim`
- `mfussenegger/nvim-lint`
- `mfussenegger/nvim-dap`
- `jay-babu/mason-nvim-dap.nvim`
- `saghen/blink.cmp`
- `nvim-treesitter/nvim-treesitter`
- `akinsho/bufferline.nvim`
- `nvim-mini/mini.icons`
- `nvim-mini/mini.diff`
- `catppuccin/nvim`

## Not listed as standalone active plugins

These strings appear in specs, but they are not separate top-level entries in this setup:

- short-name augments: `catppuccin`, `mini.diff`, `snacks.nvim`
- nested theme augment for Bufferline inside `lua/plugins/theme.lua`
- optional language augments for already-listed plugins such as `conform.nvim`, `nvim-lint`, `nvim-dap`, `mason.nvim`, and `blink.cmp`

