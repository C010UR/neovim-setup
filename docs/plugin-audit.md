# Plugin audit and simplification recommendations

_Audited against the current repo-owned plugin graph on April 20, 2026._

## Scope and baseline

This report is based on the plugin specs currently imported by `lua/config/lazy.lua`:

- `init.lua` loads `require("config.lazy")`
- `lua/config/lazy.lua` imports only `{ import = "plugins" }`
- active specs therefore live under `lua/plugins/*.lua`
- `defaults.lazy = false`, so any plugin without a lazy trigger is eager by default

## Executive summary

The config is not wildly overgrown, but it has three clear cleanup layers:

1. **Dead or inert branches** that can be removed with little or no risk.
2. **Convenience-only plugins** that add maintenance surface more than core capability.
3. **A few dense overlap zones** where simplification would materially reduce complexity, especially:
   - the **TS/web toolchain**
   - the **DAP/debugging subsystem**
   - extra **UI layering on top of Snacks**

The safest order of operations is:

1. remove dead branches and unused installs
2. trim low-risk convenience plugins
3. simplify TS/web and DAP only if you want a leaner long-term maintenance surface

## Inventory by category

### Core/runtime

| Plugin | Owning file(s) | Current role | Recommendation |
| --- | --- | --- | --- |
| `folke/snacks.nvim` | `lua/plugins/snacks.lua`, `lua/plugins/snacks-explorer.lua`, `lua/plugins/ui.lua` | central picker, explorer, notifier, dashboard, terminal, scratch, toggles, words, profiler | **Keep** |
| `folke/persistence.nvim` | `lua/plugins/snacks.lua` | session save/restore | Keep |
| `nvim-lua/plenary.nvim` | `lua/plugins/snacks.lua` | shared utility dependency | Keep |
| `nvim-treesitter/nvim-treesitter` | `lua/plugins/treesitter.lua` plus language augments | parser/runtime backbone for many language files | **Keep** |
| `nvim-treesitter/nvim-treesitter-textobjects` | `lua/plugins/treesitter.lua` | treesitter textobjects and motions | Review |
| `windwp/nvim-ts-autotag` | `lua/plugins/treesitter.lua` | autotag behavior for HTML-like files | Keep |
| `nvim-treesitter/nvim-treesitter-context` | `lua/plugins/treesitter.lua` | sticky context header | Review |
| `NMAC427/guess-indent.nvim` | `lua/plugins/guess-indent.lua` | indentation detection convenience | Review |

### UI

| Plugin | Owning file(s) | Current role | Recommendation |
| --- | --- | --- | --- |
| `folke/tokyonight.nvim` | `lua/plugins/theme.lua` | active default theme | **Keep** |
| `ellisonleao/gruvbox.nvim` | `lua/plugins/theme.lua` | alternate theme | Likely removable if Tokyonight is fixed |
| `catppuccin/nvim` | `lua/plugins/theme.lua` | alternate theme | Likely removable if Tokyonight is fixed |
| `akinsho/bufferline.nvim` | `lua/plugins/ui.lua`, `lua/plugins/theme.lua` | buffer tabline plus Catppuccin highlight integration | Review |
| `nvim-lualine/lualine.nvim` | `lua/plugins/ui.lua` | statusline | Keep |
| `folke/noice.nvim` | `lua/plugins/ui.lua` | commandline/message/LSP markdown UI | Review closely |
| `MunifTanjim/nui.nvim` | `lua/plugins/ui.lua` | Noice dependency | Remove if Noice goes |
| `nvim-mini/mini.icons` | `lua/plugins/ui.lua`, `lua/plugins/lang-typescript.lua` | icon provider and devicons bridge | Keep |
| `nvim-mini/mini.diff` | `lua/plugins/ui.lua` | inline git diff display | Review |
| `nvim-mini/mini.indentscope` | `lua/plugins/ui.lua` | indent scope guides; explicitly chosen over Snacks scope | Review |

### Editing and completion

| Plugin | Owning file(s) | Current role | Recommendation |
| --- | --- | --- | --- |
| `nvim-mini/mini.pairs` | `lua/plugins/coding.lua` | autopairs | Keep |
| `folke/ts-comments.nvim` | `lua/plugins/coding.lua` | treesitter-aware commentstring support | Keep |
| `nvim-mini/mini.ai` | `lua/plugins/coding.lua` | textobjects | Review |
| `nvim-mini/mini.comment` | `lua/plugins/coding.lua` | commenting | Keep |
| `nvim-mini/mini.surround` | `lua/plugins/coding.lua` | surround editing | Keep |
| `danymat/neogen` | `lua/plugins/coding.lua` | docstring/annotation generation | Review |
| `saghen/blink.cmp` | `lua/plugins/coding.lua`, `lua/plugins/lang-tailwind.lua` | completion engine | **Keep** |
| `rafamadriz/friendly-snippets` | `lua/plugins/coding.lua` | snippet source for Blink | Keep |
| `MagicDuck/grug-far.nvim` | `lua/plugins/editor.lua` | batch search/replace UI | Review |
| `folke/flash.nvim` | `lua/plugins/editor.lua` | jump/motion tooling | Keep |
| `folke/which-key.nvim` | `lua/plugins/editor.lua` | keymap discovery | Keep |
| `folke/trouble.nvim` | `lua/plugins/editor.lua` | diagnostics/symbol list UI | Review closely |
| `folke/todo-comments.nvim` | `lua/plugins/editor.lua` | TODO highlighting and search | Review |
| `nvim-mini/mini.move` | `lua/plugins/editor.lua` | move lines/blocks | Review |
| `ThePrimeagen/99` | `lua/plugins/ai.lua` | AI actions via keymaps; completion source disabled | Likely optional/removable |

### LSP / formatting / linting / debugging

| Plugin | Owning file(s) | Current role | Recommendation |
| --- | --- | --- | --- |
| `neovim/nvim-lspconfig` | `lua/plugins/lsp.lua` plus many language augments | central LSP orchestration | **Keep** |
| `mason-org/mason.nvim` | `lua/plugins/lsp.lua` plus many augments | tool installer | **Keep** |
| `mason-org/mason-lspconfig.nvim` | `lua/plugins/lsp.lua` | Mason/LSP bridge | Keep |
| `stevearc/conform.nvim` | `lua/plugins/formatting.lua` plus language augments | formatter routing | **Keep** |
| `mfussenegger/nvim-lint` | `lua/plugins/linting.lua` plus language augments | lint runner | Review, especially where LSP/formatter overlap exists |
| `mfussenegger/nvim-dap` | `lua/plugins/dap.lua` plus language augments | debugger base | Review closely |
| `rcarriga/nvim-dap-ui` | `lua/plugins/dap.lua` | debugger UI | Review with DAP |
| `theHamsta/nvim-dap-virtual-text` | `lua/plugins/dap.lua` | inline debug values | Review with DAP |
| `nvim-neotest/nvim-nio` | `lua/plugins/dap.lua` | DAP UI dependency | Remove if DAP UI goes |
| `jay-babu/mason-nvim-dap.nvim` | `lua/plugins/dap.lua` plus augments | debugger adapter installer/handler layer | Review with DAP |

### Language-specific plugins and augments

| Plugin | Owning file(s) | Current role | Recommendation |
| --- | --- | --- | --- |
| `b0o/SchemaStore.nvim` | `lua/plugins/lang-conffiles.lua` | JSON/YAML schema source | Keep |
| `https://tangled.org/cuducos.me/yaml.nvim` | `lua/plugins/lang-conffiles.lua` | YAML key search helper on `<leader>fy` | Likely optional/removable |
| `iamcco/markdown-preview.nvim` | `lua/plugins/lang-markdown.lua` | browser Markdown preview | Likely optional/removable |
| `linux-cultist/venv-selector.nvim` | `lua/plugins/lang-python.lua` | virtualenv picker | Review |
| `Saecki/crates.nvim` | `lua/plugins/lang-rust.lua` | Cargo dependency UX | Review |
| `mrcjkb/rustaceanvim` | `lua/plugins/lang-rust.lua` | Rust-specific LSP/DAP workflow | Keep if Rust matters |
| `brenoprata10/nvim-highlight-colors` | `lua/plugins/lang-tailwind.lua` | color chips for completion/docs | Review |
| `mfussenegger/nvim-dap-python` | `lua/plugins/lang-python.lua` | Python debug/test integration | Review with DAP |
| `suketa/nvim-dap-ruby` | `lua/plugins/lang-ruby.lua` | Ruby debug integration | Review with DAP |

### Inert optional branches

These specs are declared as optional augments, but there is **no base `nvim-neotest/neotest` plugin in the active graph**, so they do not currently activate:

| Plugin or dependency | Owning file(s) | Status | Recommendation |
| --- | --- | --- | --- |
| `nvim-neotest/neotest` | `lua/plugins/lang-python.lua` | inert optional spec | Remove |
| `nvim-neotest/neotest-python` | `lua/plugins/lang-python.lua` | inert dependency under inert spec | Remove |
| `nvim-neotest/neotest` | `lua/plugins/lang-ruby.lua` | inert optional spec | Remove |
| `olimorris/neotest-rspec` | `lua/plugins/lang-ruby.lua` | inert dependency under inert spec | Remove |
| `nvim-neotest/neotest` | `lua/plugins/lang-rust.lua` | inert optional spec | Remove |

## Language module review by file

### `lua/plugins/lang-conffiles.lua`

- Core value:
  - `SchemaStore.nvim`
  - Treesitter parser/filetype support
  - `jsonls`, `yamlls`, `taplo`, `lemminx`, Docker language servers
- Convenience layer:
  - `yaml.nvim` on `<leader>fy`
- Overlap to simplify:
  - JSON/JSONC formatting overlaps with the TS/web formatter stack.
  - YAML/JSON formatting also overlaps with formatter-capable language servers.
- Recommendation:
  - **Keep** schema + LSP support.
  - **Review** formatter ownership for JSON/JSONC.
  - **Remove or optionalize** `yaml.nvim` if the YAML key finder is rare.

### `lua/plugins/lang-markdown.lua`

- Core value:
  - `marksman`
  - Markdown lint/format wiring through Conform and `nvim-lint`
- Convenience layer:
  - `iamcco/markdown-preview.nvim`
- Overlap to simplify:
  - formatting and linting are split across Conform and `nvim-lint`, though this is still manageable.
- Recommendation:
  - **Keep** `marksman` and the current lint/format basics if Markdown is common.
  - **Review or remove** `markdown-preview.nvim` if browser preview is infrequent.

### `lua/plugins/lang-php.lua`

- Core value:
  - Treesitter parsers for `php` and `twig`
  - active LSP path is `phpactor`
  - formatting/linting for PHP and Twig
- Convenience / complexity:
  - DAP adapter for PHP debugging
- Stale branch:
  - `intelephense` is fully configured but explicitly disabled.
- Recommendation:
  - **Keep** the active PHP path if PHP matters.
  - **Prune** the disabled `intelephense` branch if it is no longer part of your workflow.
  - **Review** PHP DAP only if Neovim debugging is valuable.

### `lua/plugins/lang-python.lua`

- Core value:
  - active LSP defaults are `pyright` + `ruff`
  - Python DAP and virtualenv selection are available
- Complexity:
  - compatibility branches for `basedpyright` and `ruff_lsp`
  - `venv-selector.nvim` adds a Python-only convenience path
- Inert branch:
  - optional Neotest integration does not activate because there is no base Neotest plugin.
- Recommendation:
  - **Keep** the active Python LSP path.
  - **Remove** the inert Neotest branch.
  - **Review** `venv-selector.nvim` and dormant compatibility branches if you no longer switch via globals.

### `lua/plugins/lang-ruby.lua`

- Core value:
  - Ruby treesitter, LSP, and formatting support
- Complexity:
  - Ruby DAP integration
- Inert / unused pieces:
  - optional Neotest integration is inert
  - `erb-lint` is Mason-installed but not wired elsewhere in the repo
- Recommendation:
  - **Keep** the main Ruby language support if needed.
  - **Remove** the inert Neotest branch.
  - **Drop or wire** `erb-lint` intentionally.
  - **Review** Ruby DAP only if used.

### `lua/plugins/lang-rust.lua`

- Core value:
  - `rustaceanvim` is the main Rust workflow layer
  - Treesitter and optional `bacon_ls` integration
- Convenience layer:
  - `crates.nvim`
- Inert branch:
  - optional Neotest integration is inert
- Recommendation:
  - **Keep** `rustaceanvim` if Rust is an active language.
  - **Remove** the inert Neotest branch.
  - **Review** `crates.nvim` as a convenience-only extra.

### `lua/plugins/lang-shell.lua`

- Core value:
  - shell Treesitter and `bashls`
- Unused install:
  - `shellcheck` is ensured via Mason but not wired into linting or formatting in this repo.
- Recommendation:
  - **Keep** shell Treesitter + LSP.
  - **Remove or wire** `shellcheck` intentionally.

### `lua/plugins/lang-tailwind.lua`

- Core value:
  - Tailwind language server
- Convenience layer:
  - Blink color rendering via `nvim-highlight-colors`
- Recommendation:
  - **Keep** Tailwind LSP if you work in Tailwind.
  - **Review** `nvim-highlight-colors` as purely visual polish.

### `lua/plugins/lang-typescript.lua`

- Core value:
  - `vtsls`-centered TS/JS language support
  - web formatting and debugging support
- Biggest overlap zone in the repo:
  - `vtsls`, `eslint`, and `biome` all participate
  - Conform also adds `biome-check`
  - JSON/JSONC behavior overlaps with `lang-conffiles.lua`
- Recommendation:
  - **Keep** the TS/JS module.
  - **Simplify** tool ownership inside it: decide whether `eslint`, `biome`, and Conform should all stay active for the same workflows.
  - **Review** the JS/TS DAP path if in-editor debugging is rare.

## Likely keep

These plugins look central, low-overlap, or clearly worth their maintenance cost in the current graph.

- `folke/snacks.nvim` — `lua/plugins/snacks.lua`, `lua/plugins/snacks-explorer.lua`, `lua/plugins/ui.lua`
  - Why it exists: this is the main picker/explorer/dashboard/notifier/toggle layer.
  - Overlap: it overlaps with several other UI plugins, but it is the anchor, not the redundancy.
  - Removal tradeoff: very high workflow disruption.
- `neovim/nvim-lspconfig` — `lua/plugins/lsp.lua` plus language augments
  - Why it exists: central LSP orchestration and per-language server wiring.
  - Overlap: none meaningful; other language files extend it.
  - Removal tradeoff: breaks most language intelligence.
- `mason-org/mason.nvim` and `mason-org/mason-lspconfig.nvim` — `lua/plugins/lsp.lua` plus augments
  - Why it exists: installer and bridge layer for LSP/tools.
  - Overlap: none significant in repo.
  - Removal tradeoff: more manual tool management.
- `stevearc/conform.nvim` — `lua/plugins/formatting.lua` plus augments
  - Why it exists: unified formatting entrypoint.
  - Overlap: some overlap with formatter-capable LSPs, but still the current formatting center.
  - Removal tradeoff: format workflow becomes fragmented.
- `nvim-treesitter/nvim-treesitter` — `lua/plugins/treesitter.lua` plus augments
  - Why it exists: parser backbone for syntax, textobjects, comments, and language extras.
  - Overlap: none meaningful.
  - Removal tradeoff: broad editing regression.
- `saghen/blink.cmp` and `rafamadriz/friendly-snippets` — `lua/plugins/coding.lua`
  - Why they exist: completion engine plus snippet source.
  - Overlap: none in current graph.
  - Removal tradeoff: major completion downgrade.
- `nvim-lualine/lualine.nvim` — `lua/plugins/ui.lua`
  - Why it exists: current statusline glue across diagnostics, diff, lazy status, DAP, and Noice.
  - Overlap: not much direct overlap.
  - Removal tradeoff: statusline replacement needed.
- `folke/flash.nvim` — `lua/plugins/editor.lua`
  - Why it exists: high-value motion/navigation layer.
  - Overlap: some with built-in search, but still distinct.
  - Removal tradeoff: noticeable navigation downgrade.
- `folke/which-key.nvim` — `lua/plugins/editor.lua`
  - Why it exists: keymap discoverability.
  - Overlap: none significant.
  - Removal tradeoff: lower discoverability, especially in a rich mapping setup.
- `b0o/SchemaStore.nvim` — `lua/plugins/lang-conffiles.lua`
  - Why it exists: schemas for JSON/YAML editing.
  - Overlap: complementary, not redundant.
  - Removal tradeoff: weaker config-file language support.
- `mrcjkb/rustaceanvim` — `lua/plugins/lang-rust.lua`
  - Why it exists: the real Rust-specific workflow center.
  - Overlap: intentionally replaces plain `rust_analyzer` handling.
  - Removal tradeoff: only safe if Rust support is no longer important.

## Worth reviewing

These plugins may still be useful, but they either overlap with stronger primitives, serve narrower workflows, or add meaningful maintenance surface.

- `folke/noice.nvim` — `lua/plugins/ui.lua`
  - Why it exists: enhanced commandline/message/LSP markdown UX.
  - Overlap: biggest UI-layer overlap with Snacks.
  - Tradeoff if removed: simpler UI stack, but you lose Noice-specific commandline/message behavior.
- `folke/trouble.nvim` — `lua/plugins/editor.lua`
  - Why it exists: diagnostics, symbols, quickfix/location list UI.
  - Overlap: strong overlap with Snacks diagnostics, qflist, loclist, and symbol pickers.
  - Tradeoff if removed: likely small if Snacks already covers your navigation habits.
- `akinsho/bufferline.nvim` — `lua/plugins/ui.lua`
  - Why it exists: visible buffer tabline.
  - Overlap: Snacks buffer picker plus built-in buffer switching.
  - Tradeoff if removed: less persistent visual buffer surfacing.
- `mfussenegger/nvim-lint` — `lua/plugins/linting.lua` plus augments
  - Why it exists: external lint diagnostics.
  - Overlap: LSP diagnostics and formatter-based checks in multiple languages.
  - Tradeoff if removed: some diagnostics disappear unless replaced by LSP/tool-specific alternatives.
- `mfussenegger/nvim-dap` cluster — `lua/plugins/dap.lua` plus language augments
  - Why it exists: in-editor debugging for JS/TS, Python, Ruby, PHP, and Rust.
  - Overlap: not duplicated elsewhere, but it is a large optional subsystem.
  - Tradeoff if removed: you lose Neovim debugging but gain meaningful config simplification.
- `nvim-treesitter/nvim-treesitter-textobjects` — `lua/plugins/treesitter.lua`
  - Why it exists: treesitter-driven textobjects/motions.
  - Overlap: `mini.ai` and some Flash capabilities.
  - Tradeoff if removed: depends on how much you use those motions versus Mini.
- `nvim-mini/mini.ai` — `lua/plugins/coding.lua`
  - Why it exists: textobject ergonomics.
  - Overlap: treesitter textobjects.
  - Tradeoff if removed: you need to decide which textobject system is your primary one.
- `nvim-mini/mini.indentscope` — `lua/plugins/ui.lua`
  - Why it exists: explicit choice over Snacks indent scope.
  - Overlap: direct overlap with the indent scope already available in Snacks.
  - Tradeoff if removed: minimal if you are willing to switch back to Snacks scope.
- `nvim-mini/mini.diff` — `lua/plugins/ui.lua`
  - Why it exists: inline git diff display.
  - Overlap: some overlap with Snacks git views and lualine summaries, but still unique inline feedback.
  - Tradeoff if removed: less per-line diff context.
- `MagicDuck/grug-far.nvim` — `lua/plugins/editor.lua`
  - Why it exists: structured search/replace workflow.
  - Overlap: Snacks covers search well, but not the same replace UX.
  - Tradeoff if removed: batch replace becomes less ergonomic.
- `danymat/neogen` — `lua/plugins/coding.lua`
  - Why it exists: docstring generation.
  - Overlap: manual docs and snippets can substitute.
  - Tradeoff if removed: minor unless you use it often.
- `linux-cultist/venv-selector.nvim` — `lua/plugins/lang-python.lua`
  - Why it exists: Python virtualenv switching in-editor.
  - Overlap: shell/env-manager workflows.
  - Tradeoff if removed: Python environment selection shifts outside Neovim.
- `Saecki/crates.nvim` — `lua/plugins/lang-rust.lua`
  - Why it exists: Cargo.toml dependency ergonomics.
  - Overlap: little direct overlap, but it is convenience-only.
  - Tradeoff if removed: you lose Cargo-specific niceties, not core Rust editing.
- `brenoprata10/nvim-highlight-colors` — `lua/plugins/lang-tailwind.lua`
  - Why it exists: cosmetic completion/docs enhancement.
  - Overlap: purely visual.
  - Tradeoff if removed: almost none beyond UI polish.
- `NMAC427/guess-indent.nvim` — `lua/plugins/guess-indent.lua`
  - Why it exists: convenience for odd indentation cases.
  - Overlap: none, but low activation.
  - Tradeoff if removed: you may occasionally need to set indentation manually.

## Likely redundant / removable

These look like the lowest-risk simplification targets, or at least the strongest candidates to optionalize.

- Inert Neotest branches — `lua/plugins/lang-python.lua`, `lua/plugins/lang-ruby.lua`, `lua/plugins/lang-rust.lua`
  - Why they exist: leftover optional test integrations.
  - Overlap: none, because they are currently inactive.
  - Tradeoff if removed: none unless you plan to add base Neotest later.
- Unused Mason installs: `shellcheck` and `erb-lint` — `lua/plugins/lang-shell.lua`, `lua/plugins/lang-ruby.lua`
  - Why they exist: tool-install intent.
  - Overlap: not even overlap; they are installed without repo wiring.
  - Tradeoff if removed: none for current behavior.
- `ThePrimeagen/99` — `lua/plugins/ai.lua`
  - Why it exists: AI helper commands on keymaps.
  - Overlap: not duplicated elsewhere, but it is isolated from Blink and its completion source is explicitly disabled.
  - Tradeoff if removed: low unless those keymaps are a daily habit.
- `iamcco/markdown-preview.nvim` — `lua/plugins/lang-markdown.lua`
  - Why it exists: browser preview workflow.
  - Overlap: outside-core convenience.
  - Tradeoff if removed: preview leaves Neovim/plugin space.
- `https://tangled.org/cuducos.me/yaml.nvim` — `lua/plugins/lang-conffiles.lua`
  - Why it exists: YAML key-finder shortcut.
  - Overlap: Snacks/manual search can cover most needs.
  - Tradeoff if removed: low.
- `ellisonleao/gruvbox.nvim` and `catppuccin/nvim` — `lua/plugins/theme.lua`
  - Why they exist: alternate theme choices.
  - Overlap: fully redundant if Tokyonight is the settled default.
  - Tradeoff if removed: you lose easy theme switching only.
- Legacy/stale config branches worth pruning even if the parent plugin stays:
  - disabled `intelephense` path in `lua/plugins/lang-php.lua`
  - dormant `ruff_lsp` / `basedpyright` compatibility branches if you no longer switch via globals in `lua/plugins/lang-python.lua`
  - Catppuccin integration entries for plugins not present in the active graph in `lua/plugins/theme.lua`
  - Noice config that still references `cmp`-era documentation overrides in `lua/plugins/ui.lua`

## Highest-value overlap zones

### 1. TS/web stack

Files:

- `lua/plugins/lang-typescript.lua`
- `lua/plugins/lang-conffiles.lua`
- `lua/plugins/formatting.lua`
- `lua/plugins/linting.lua`

Why this is the main simplification target:

- `vtsls`, `eslint`, and `biome` are all enabled through LSP paths.
- Conform also adds `biome-check` across JS/TS/CSS and related filetypes.
- `json` and `jsonc` formatting is split across config-file and TS/web layers.
- this is the densest area of formatter, diagnostics, and server overlap in the repo.

Good simplification questions:

- Do you need both `eslint` and `biome` active in-editor?
- Should `biome` be the primary formatter/linter for web files, with `eslint` only where required?
- Should JSON and JSONC formatting live in one module instead of being split between config and TS/web logic?

### 2. DAP subsystem

Files:

- `lua/plugins/dap.lua`
- `lua/plugins/lang-typescript.lua`
- `lua/plugins/lang-python.lua`
- `lua/plugins/lang-ruby.lua`
- `lua/plugins/lang-php.lua`
- `lua/plugins/lang-rust.lua`

Why this is the other major simplification target:

- base DAP + UI + virtual text + Mason DAP + language adapters is a lot of surface area.
- it is valuable if you debug inside Neovim regularly.
- if you do not, it is one of the largest removable complexity clusters in the config.

### 3. UI layering on top of Snacks

Files:

- `lua/plugins/ui.lua`
- `lua/plugins/editor.lua`
- `lua/plugins/snacks.lua`

Pressure-test these pairs:

- Snacks vs Noice
- Snacks vs Trouble
- Snacks buffer picker vs Bufferline
- Snacks indent scope vs `mini.indentscope`

## Ranked cleanup shortlist

### Easiest high-ROI cleanup

1. Remove inert Neotest branches.
2. Remove unused Mason installs for `shellcheck` and `erb-lint` unless you intend to wire them.
3. Optionalize or remove `ThePrimeagen/99`.
4. Remove `iamcco/markdown-preview.nvim` if browser preview is rare.
5. Remove `yaml.nvim` if `<leader>fy` is not pulling its weight.
6. Remove alternate themes if Tokyonight is effectively fixed.

### Next simplification pass

1. Decide whether `Trouble` still earns its place over Snacks pickers.
2. Decide whether `Noice` still earns its place over Snacks plus the built-in UI.
3. Decide whether `Bufferline` is adding enough beyond the buffer picker.
4. Choose a primary textobject/indent strategy where Mini and Treesitter/Snacks overlap.

### Deep simplification pass

1. Simplify the TS/web stack so fewer tools own diagnostics and formatting.
2. Trim or keep the DAP stack as an intentional workflow choice, not as default ballast.
3. Prune stale compatibility branches in PHP, Python, and theme integrations.

## Suggested implementation order

If you want to actually remove plugins in a follow-up pass, use this order:

1. **Zero-risk cleanup**
   - inert Neotest specs
   - unused Mason installs
   - stale integration branches
2. **Low-risk convenience cleanup**
   - AI helper
   - Markdown preview
   - YAML helper
   - extra themes
3. **Medium-risk UI cleanup**
   - Trouble
   - Bufferline
   - Noice
   - Mini vs Snacks/Treesitter overlap
4. **High-impact subsystem cleanup**
   - TS/web toolchain
   - DAP stack

## Bottom line

The config already has a solid local core. The main improvement opportunity is not replacing the core; it is **removing stale branches, trimming convenience-only plugins, and choosing fewer overlapping tools in the TS/web, DAP, and UI layers**.
