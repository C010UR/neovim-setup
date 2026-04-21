-- Global leaders used throughout the config.
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Global toggles and project-root behavior shared by other modules.
vim.g.autoformat = false
vim.g.snacks_animate = false
vim.g.root_spec = { "lsp", { ".git", "lua" }, "cwd" }
vim.g.root_lsp_ignore = { "copilot" }

local opt = vim.opt

-- Editing behavior.
opt.autowrite = true
opt.expandtab = true
opt.shiftwidth = 2
opt.shiftround = true
opt.smartindent = true
opt.tabstop = 2
opt.undofile = true
opt.undolevels = 10000
opt.virtualedit = "block"

-- Search and replace behavior.
opt.ignorecase = true
opt.inccommand = "nosplit"
opt.smartcase = true
opt.grepformat = "%f:%l:%c:%m"
opt.grepprg = "rg --vimgrep"

-- Completion and command-line UI.
opt.completeopt = "menu,menuone,noselect,popup"
opt.pumblend = 10
opt.pumborder = "single"
opt.pumheight = 10
opt.wildmenu = true
opt.wildoptions = "pum,fuzzy"
opt.wildmode = "longest:full,full"

-- Window, split, and scrolling behavior.
opt.confirm = true
opt.jumpoptions = "view"
opt.laststatus = 3
opt.mouse = "a"
opt.scrolloff = 4
opt.sidescrolloff = 8
opt.splitbelow = true
opt.splitkeep = "screen"
opt.splitright = true
opt.timeoutlen = vim.g.vscode and 1000 or 300
opt.updatetime = 200
opt.winborder = "single"
opt.winminwidth = 5

-- Line numbers and cursor feedback.
opt.cursorline = true
opt.number = true
opt.relativenumber = true
opt.ruler = false
opt.signcolumn = "yes"

-- Indentation, wrapping, and text formatting.
opt.formatoptions = "jcroqlnt"
opt.formatexpr = "v:lua.require'config.format'.formatexpr()"
opt.linebreak = true
opt.showmode = false
opt.smoothscroll = true
opt.spelllang = { "en" }
opt.wrap = false

-- Folding and filler characters.
opt.conceallevel = 2
opt.fillchars = {
  foldopen = "",
  foldclose = "",
  fold = " ",
  foldsep = " ",
  diff = "╱",
  eob = " ",
}
opt.foldlevel = 99
opt.foldmethod = "indent"
opt.foldtext = ""

-- Session persistence.
opt.sessionoptions = { "buffers", "curdir", "tabpages", "winsize", "help", "globals", "skiprtp", "folds" }

-- Visual polish and color support.
opt.clipboard = "unnamedplus"
opt.list = true
opt.shortmess:append({ W = true, I = true, c = true, C = true })
opt.termguicolors = true

-- Markdown plugin defaults.
vim.g.markdown_recommended_style = 0
