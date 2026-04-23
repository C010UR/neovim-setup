# Plugins

## Core UI / pickers / sessions

| Plugin | Role in this config | Sources |
| --- | --- | --- |
| [`folke/snacks.nvim`](https://github.com/folke/snacks.nvim) | Primary UI layer for pickers, explorer, terminal, dashboard, notifications, scratch buffers, git helpers, toggles, profiler tools, and shared search/navigation workflows. Explorer-specific augments live elsewhere, and Snacks indent scope is disabled in favor of `mini.indentscope`. | `lua/plugins/snacks.lua`, `lua/plugins/snacks-explorer.lua`, `lua/plugins/editor.lua`, `lua/plugins/lang-conffiles.lua`, `lua/plugins/ui.lua` |
| [`folke/persistence.nvim`](https://github.com/folke/persistence.nvim) | Session save, restore, and selection support behind the `<leader>q*` workflow. | `lua/plugins/snacks.lua` |
| [`folke/which-key.nvim`](https://github.com/folke/which-key.nvim) | Keymap discovery layer using the `helix` preset and the repo's leader-group layout. | `lua/plugins/editor.lua` |
| [`MagicDuck/grug-far.nvim`](https://github.com/MagicDuck/grug-far.nvim) | Interactive search-and-replace interface with repo-specific logic to prefill the current file extension when possible. | `lua/plugins/editor.lua` |
| [`nvim-lua/plenary.nvim`](https://github.com/nvim-lua/plenary.nvim) | General utility dependency; in this configuration it is used most visibly by the DAP stack to strip comments from VS Code-style JSON launch files. | `lua/plugins/snacks.lua`, `lua/plugins/dap.lua` |

## Appearance / theme / statusline / bufferline

| Plugin | Role in this config | Sources |
| --- | --- | --- |
| [`folke/tokyonight.nvim`](https://github.com/folke/tokyonight.nvim) | Default active colorscheme (`tokyonight`, `night`). | `lua/plugins/theme.lua` |
| [`ellisonleao/gruvbox.nvim`](https://github.com/ellisonleao/gruvbox.nvim) | Alternate colorscheme kept installed as a secondary option. | `lua/plugins/theme.lua` |
| [`catppuccin/nvim`](https://github.com/catppuccin/nvim) | Alternate colorscheme with integration modules enabled and an optional Bufferline highlight augment. | `lua/plugins/theme.lua` |
| [`akinsho/bufferline.nvim`](https://github.com/akinsho/bufferline.nvim) | Buffer tabline with diagnostics badges, `Snacks.bufdelete` close behavior, and Catppuccin-aware highlights when that palette is active. | `lua/plugins/ui.lua`, `lua/plugins/theme.lua` |
| [`nvim-lualine/lualine.nvim`](https://github.com/nvim-lualine/lualine.nvim) | Statusline with mode, branch, root directory, diagnostics, Navic breadcrumbs, and DAP status. | `lua/plugins/ui.lua` |
| [`nvim-mini/mini.icons`](https://github.com/nvim-mini/mini.icons) | Icon provider with local overrides for dotfiles and JS/TS config files, plus a `nvim-web-devicons` compatibility shim. | `lua/plugins/ui.lua`, `lua/plugins/lang-typescript.lua` |
| [`nvim-mini/mini.indentscope`](https://github.com/nvim-mini/mini.indentscope) | Indent guides with animation disabled and a repo-defined disable list for dashboard, help, notify, and terminal-style buffers. | `lua/plugins/ui.lua` |

## Editing / navigation / search

| Plugin | Role in this config | Sources |
| --- | --- | --- |
| [`folke/flash.nvim`](https://github.com/folke/flash.nvim) | Motion and search layer that replaces `s`, `S`, `r`, and `R`, and adds Treesitter-powered selection on `<C-Space>`. | `lua/plugins/editor.lua` |
| [`folke/todo-comments.nvim`](https://github.com/folke/todo-comments.nvim) | Highlights TODO-style annotations and exposes jump and picker workflows for them. | `lua/plugins/editor.lua` |
| [`NMAC427/guess-indent.nvim`](https://github.com/NMAC427/guess-indent.nvim) | Detects indentation style on demand and exposes `GuessIndent` through a leader mapping. | `lua/plugins/guess-indent.lua` |
| [`nvim-mini/mini.move`](https://github.com/nvim-mini/mini.move) | Line and block movement helpers kept close to default behavior. | `lua/plugins/editor.lua` |

## Coding / textobjects / comments

| Plugin | Role in this config | Sources |
| --- | --- | --- |
| [`nvim-mini/mini.pairs`](https://github.com/nvim-mini/mini.pairs) | Autopairs with repo-specific handling for Markdown fences, Treesitter/string checks, and unbalanced-pair avoidance. | `lua/plugins/coding.lua`, `lua/config/mini.lua` |
| [`folke/ts-comments.nvim`](https://github.com/folke/ts-comments.nvim) | Treesitter-aware `commentstring` support for mixed-language buffers. | `lua/plugins/coding.lua` |
| [`nvim-mini/mini.ai`](https://github.com/nvim-mini/mini.ai) | Textobject engine extended with repo-defined objects for functions, classes, tags, digit runs, symbol segments, whole-buffer ranges, and call/use patterns. | `lua/plugins/coding.lua`, `lua/config/mini.lua` |
| [`nvim-mini/mini.comment`](https://github.com/nvim-mini/mini.comment) | Comment operator kept near default behavior; core keymaps add helper flows such as `gco` and `gcO`. | `lua/plugins/coding.lua`, `lua/config/keymaps.lua` |
| [`nvim-mini/mini.surround`](https://github.com/nvim-mini/mini.surround) | Surround editing kept near default Mini.nvim behavior. | `lua/plugins/coding.lua` |
| [`danymat/neogen`](https://github.com/danymat/neogen) | Annotation and docblock generator exposed through a single leader mapping. | `lua/plugins/coding.lua` |

## Treesitter / parsing

| Plugin | Role in this config | Sources |
| --- | --- | --- |
| [`nvim-treesitter/nvim-treesitter`](https://github.com/nvim-treesitter/nvim-treesitter) | Main parsing, highlighting, indent, and fold backbone. Parsers are installed through the registry-backed `main`-branch workflow, features are enabled on `FileType`, and language modules extend parser and filetype coverage. | `lua/plugins/treesitter.lua`, `lua/plugins/lang-conffiles.lua`, `lua/plugins/lang-php.lua`, `lua/plugins/lang-python.lua`, `lua/plugins/lang-ruby.lua`, `lua/plugins/lang-rust.lua`, `lua/plugins/lang-shell.lua` |
| [`neovim-treesitter/treesitter-parser-registry`](https://github.com/neovim-treesitter/treesitter-parser-registry) | Parser registry dependency used by the current `nvim-treesitter` installation workflow. | `lua/plugins/treesitter.lua` |
| [`nvim-treesitter/nvim-treesitter-textobjects`](https://github.com/nvim-treesitter/nvim-treesitter-textobjects) | Function, class, and parameter textobject motions such as `]f`, `[f`, `]c`, `[c`, `]a`, and `[a`. | `lua/plugins/treesitter.lua` |
| [`windwp/nvim-ts-autotag`](https://github.com/windwp/nvim-ts-autotag) | Automatic tag closing and renaming in HTML-like filetypes. | `lua/plugins/treesitter.lua` |
| [`nvim-treesitter/nvim-treesitter-context`](https://github.com/nvim-treesitter/nvim-treesitter-context) | Sticky context header for the current Treesitter scope. | `lua/plugins/treesitter.lua` |

## LSP / formatting / linting / tool management

| Plugin | Role in this config | Sources |
| --- | --- | --- |
| [`folke/lazydev.nvim`](https://github.com/folke/lazydev.nvim) | Lua typing helper that extends the library used by Neovim and `vim.uv` development. | `lua/plugins/lsp.lua` |
| [`neovim/nvim-lspconfig`](https://github.com/neovim/nvim-lspconfig) | Primary LSP layer for diagnostics, fold configuration, inlay hints, native Neovim 0.12 completion, lazy key attachment, and per-language server setup. Language modules extend it for config files, Markdown, PHP/Twig, Python, Ruby, Bash/Fish, Tailwind, TypeScript/JavaScript, and Rust-adjacent tools. | `lua/plugins/lsp.lua`, `lua/plugins/coding.lua`, `lua/plugins/lang-conffiles.lua`, `lua/plugins/lang-markdown.lua`, `lua/plugins/lang-php.lua`, `lua/plugins/lang-python.lua`, `lua/plugins/lang-ruby.lua`, `lua/plugins/lang-rust.lua`, `lua/plugins/lang-shell.lua`, `lua/plugins/lang-tailwind.lua`, `lua/plugins/lang-typescript.lua` |
| [`SmiteshP/nvim-navic`](https://github.com/SmiteshP/nvim-navic) | Breadcrumb provider attached from the LSP layer and displayed in Lualine. | `lua/plugins/coding.lua`, `lua/plugins/ui.lua`, `lua/config/lsp.lua` |
| [`stevearc/conform.nvim`](https://github.com/stevearc/conform.nvim) | Primary formatter dispatcher. The base config covers Lua, Fish, and shell files; language augments extend formatter selection for config files, Markdown, PHP/Twig, Ruby/ERB, and JS/TS/CSS-family files. | `lua/plugins/formatting.lua`, `lua/plugins/lang-conffiles.lua`, `lua/plugins/lang-markdown.lua`, `lua/plugins/lang-php.lua`, `lua/plugins/lang-ruby.lua`, `lua/plugins/lang-typescript.lua` |
| [`mfussenegger/nvim-lint`](https://github.com/mfussenegger/nvim-lint) | Debounced lint dispatcher. The base config covers Fish, and language augments extend it for Dockerfile, Markdown, PHP, and Twig. | `lua/plugins/linting.lua`, `lua/plugins/lang-conffiles.lua`, `lua/plugins/lang-markdown.lua`, `lua/plugins/lang-php.lua` |
| [`mason-org/mason.nvim`](https://github.com/mason-org/mason.nvim) | Tool installer that keeps the repo's chosen LSP servers, formatters, linters, and debug adapters available in interactive sessions. | `lua/plugins/lsp.lua`, `lua/plugins/formatting.lua`, `lua/plugins/lang-conffiles.lua`, `lua/plugins/lang-markdown.lua`, `lua/plugins/lang-php.lua`, `lua/plugins/lang-ruby.lua`, `lua/plugins/lang-rust.lua`, `lua/plugins/lang-typescript.lua` |
| [`mason-org/mason-lspconfig.nvim`](https://github.com/mason-org/mason-lspconfig.nvim) | Mason bridge that auto-installs and auto-enables supported language servers. | `lua/plugins/lsp.lua` |

## Debugging

| Plugin | Role in this config | Sources |
| --- | --- | --- |
| [`mfussenegger/nvim-dap`](https://github.com/mfussenegger/nvim-dap) | Core debugging framework with signs, run/step/breakpoint mappings, VS Code launch config parsing, and language-specific adapter augments. | `lua/plugins/dap.lua`, `lua/plugins/lang-php.lua`, `lua/plugins/lang-python.lua`, `lua/plugins/lang-ruby.lua` |
| [`rcarriga/nvim-dap-ui`](https://github.com/rcarriga/nvim-dap-ui) | Debugger panes that open automatically on session start and close on exit or termination. | `lua/plugins/dap.lua` |
| [`theHamsta/nvim-dap-virtual-text`](https://github.com/theHamsta/nvim-dap-virtual-text) | Inline virtual text for current debug values. | `lua/plugins/dap.lua` |
| [`nvim-neotest/nvim-nio`](https://github.com/nvim-neotest/nvim-nio) | Runtime dependency required by `nvim-dap-ui`. | `lua/plugins/dap.lua` |
| [`jay-babu/mason-nvim-dap.nvim`](https://github.com/jay-babu/mason-nvim-dap.nvim) | DAP adapter installer and bridge, with a Python augment that keeps local `debugpy` setup authoritative. | `lua/plugins/dap.lua`, `lua/plugins/lang-python.lua` |
| [`mfussenegger/nvim-dap-python`](https://github.com/mfussenegger/nvim-dap-python) | Python-specific DAP helper for test method and test class debugging. | `lua/plugins/lang-python.lua` |
| [`suketa/nvim-dap-ruby`](https://github.com/suketa/nvim-dap-ruby) | Ruby-specific DAP helper used by the Ruby debugger setup. | `lua/plugins/lang-ruby.lua` |

## AI

| Plugin | Role in this config | Sources |
| --- | --- | --- |
| [`ThePrimeagen/99`](https://github.com/ThePrimeagen/99) | AI workflow helper configured for `OpenCodeProvider`, `AGENT.md` discovery, custom rule directories from `opencode/skills` and `.mux/skills`, and native Neovim completion in prompt buffers. | `lua/plugins/ai.lua` |

## Language-specific tooling

| Plugin | Role in this config | Sources |
| --- | --- | --- |
| [`b0o/SchemaStore.nvim`](https://github.com/b0o/SchemaStore.nvim) | JSON and YAML schema catalog used by `jsonls` and `yamlls`. | `lua/plugins/lang-conffiles.lua` |
| [`yaml.nvim`](https://tangled.org/cuducos.me/yaml.nvim) | YAML key finder exposed through a Snacks-powered picker flow. | `lua/plugins/lang-conffiles.lua` |
| [`iamcco/markdown-preview.nvim`](https://github.com/iamcco/markdown-preview.nvim) | Browser preview for Markdown files, with install and update hooks wired into the pack layer. | `lua/plugins/lang-markdown.lua` |
| [`linux-cultist/venv-selector.nvim`](https://github.com/linux-cultist/venv-selector.nvim) | Python virtual environment selector. | `lua/plugins/lang-python.lua` |
| [`Saecki/crates.nvim`](https://github.com/Saecki/crates.nvim) | Cargo.toml dependency helper with completion, actions, and hover support. | `lua/plugins/lang-rust.lua` |
| [`mrcjkb/rustaceanvim`](https://github.com/mrcjkb/rustaceanvim) | Rust-specific workflow layer that owns the main rust-analyzer path, adds Rust buffer-local commands, and can wire in `codelldb`. | `lua/plugins/lang-rust.lua` |
