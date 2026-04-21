local format = require("config.format")
local root = require("config.root")

local map = vim.keymap.set

local function stop_snippet()
  if vim.snippet and vim.snippet.stop then
    pcall(vim.snippet.stop)
  end
end

local function diagnostic_goto(next, severity)
  return function()
    vim.diagnostic.jump({
      count = (next and 1 or -1) * vim.v.count1,
      severity = severity and vim.diagnostic.severity[severity] or nil,
      float = true,
    })
  end
end

local function accept_completion_tab()
  if vim.fn.pumvisible() == 1 then
    local info = vim.fn.complete_info({ "selected" })
    if (info.selected or -1) == -1 then
      return "<C-n><C-y>"
    end
    return "<C-y>"
  end

  if vim.lsp.inline_completion and vim.lsp.inline_completion.get() then
    return ""
  end

  if vim.snippet and vim.snippet.active and vim.snippet.active({ direction = 1 }) then
    return "<Cmd>lua vim.snippet.jump(1)<CR>"
  end

  return "<Tab>"
end

map({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { desc = "Move Down (Display Line)", expr = true, silent = true })
map(
  { "n", "x" },
  "<Down>",
  "v:count == 0 ? 'gj' : 'j'",
  { desc = "Move Down (Display Line)", expr = true, silent = true }
)
map({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { desc = "Move Up (Display Line)", expr = true, silent = true })
map({ "n", "x" }, "<Up>", "v:count == 0 ? 'gk' : 'k'", { desc = "Move Up (Display Line)", expr = true, silent = true })

map("n", "<C-h>", "<C-w>h", { desc = "Go to Left Window", remap = true })
map("n", "<C-j>", "<C-w>j", { desc = "Go to Lower Window", remap = true })
map("n", "<C-k>", "<C-w>k", { desc = "Go to Upper Window", remap = true })
map("n", "<C-l>", "<C-w>l", { desc = "Go to Right Window", remap = true })

map("n", "<C-Up>", "<cmd>resize +2<cr>", { desc = "Increase Window Height" })
map("n", "<C-Down>", "<cmd>resize -2<cr>", { desc = "Decrease Window Height" })
map("n", "<C-Left>", "<cmd>vertical resize -2<cr>", { desc = "Decrease Window Width" })
map("n", "<C-Right>", "<cmd>vertical resize +2<cr>", { desc = "Increase Window Width" })

map("n", "<A-j>", "<cmd>execute 'move .+' . v:count1<cr>==", { desc = "Move Line Down" })
map("n", "<A-k>", "<cmd>execute 'move .-' . (v:count1 + 1)<cr>==", { desc = "Move Line Up" })
map("i", "<A-j>", "<esc><cmd>m .+1<cr>==gi", { desc = "Move Line Down" })
map("i", "<A-k>", "<esc><cmd>m .-2<cr>==gi", { desc = "Move Line Up" })
map("v", "<A-j>", ":<C-u>execute \"'<,'>move '>+\" . v:count1<cr>gv=gv", { desc = "Move Selection Down" })
map("v", "<A-k>", ":<C-u>execute \"'<,'>move '<-\" . (v:count1 + 1)<cr>gv=gv", { desc = "Move Selection Up" })

map("n", "<S-h>", "<cmd>bprevious<cr>", { desc = "Previous Buffer" })
map("n", "<S-l>", "<cmd>bnext<cr>", { desc = "Next Buffer" })
map("n", "[b", "<cmd>bprevious<cr>", { desc = "Previous Buffer" })
map("n", "]b", "<cmd>bnext<cr>", { desc = "Next Buffer" })
map("n", "<leader>`", "<cmd>e #<cr>", { desc = "Switch to Alternate Buffer" })
map("n", "<leader>bb", "<cmd>e!<cr>", { desc = "Reload Buffer from Disk" })
map("n", "<leader>bd", function()
  Snacks.bufdelete()
end, { desc = "Close Buffer" })
map("n", "<leader>bo", function()
  Snacks.bufdelete.other()
end, { desc = "Close Other Buffers" })
map("n", "<leader>bD", "<cmd>:bd<cr>", { desc = "Close Buffer and Window" })
map("n", "<leader>bc", function()
  local path = Utils.relativePath()
  if path == nil then
    vim.notify("Buffer is not a file", vim.log.levels.ERROR)
    return
  end
  vim.fn.setreg("+", path)
  vim.notify('Copied "' .. path .. '" to the clipboard')
end, { desc = "Copy Buffer Path" })
map("n", "<leader>bC", function()
  local path = Utils.relativePath()
  if path == nil then
    vim.notify("Buffer is not a file", vim.log.levels.ERROR)
    return
  end
  path = path .. ":" .. Utils.currentLineNumber()
  vim.fn.setreg("+", path)
  vim.notify('Copied "' .. path .. '" to the clipboard')
end, { desc = "Copy Buffer Path with Line Number" })
map("n", "<leader>bn", function()
  local clipboard = vim.fn.getreg("+"):gsub("^%s*(.-)%s*$", "%1")
  if clipboard == "" then
    vim.notify("Clipboard is empty", vim.log.levels.WARN)
    return
  end
  local parsed = Utils.parsePath(clipboard)
  if not parsed.exists then
    vim.notify('File not found: "' .. clipboard .. '"', vim.log.levels.ERROR)
    return
  end
  vim.cmd("edit " .. vim.fn.fnameescape(parsed.path))
  if parsed.row ~= nil then
    local row = math.min(parsed.row, vim.api.nvim_buf_line_count(0))
    local col = parsed.col or 0
    if parsed.col then
      local line_content = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1] or ""
      col = math.min(parsed.col, #line_content)
    end
    vim.api.nvim_win_set_cursor(0, { row, col })
    vim.cmd("normal! zz")
    if parsed.col then
      vim.notify(string.format('Opened "%s:%d:%d"', parsed.path, row, col + 1))
    else
      vim.notify(string.format('Opened "%s:%d"', parsed.path, row))
    end
  else
    vim.notify(string.format('Opened "%s"', parsed.path))
  end
end, { desc = "Open File from Clipboard Path" })

map({ "i", "n", "s" }, "<esc>", function()
  vim.cmd("noh")
  stop_snippet()
  return "<esc>"
end, { expr = true, desc = "Escape and Clear Search Highlight" })

map(
  "n",
  "<leader>ur",
  "<Cmd>nohlsearch<Bar>diffupdate<Bar>normal! <C-L><CR>",
  { desc = "Redraw / Clear Search / Update Diff" }
)
map("n", "n", "'Nn'[v:searchforward].'zv'", { expr = true, desc = "Next Search Result" })
map("x", "n", "'Nn'[v:searchforward]", { expr = true, desc = "Next Search Result" })
map("o", "n", "'Nn'[v:searchforward]", { expr = true, desc = "Next Search Result" })
map("n", "N", "'nN'[v:searchforward].'zv'", { expr = true, desc = "Previous Search Result" })
map("x", "N", "'nN'[v:searchforward]", { expr = true, desc = "Previous Search Result" })
map("o", "N", "'nN'[v:searchforward]", { expr = true, desc = "Previous Search Result" })

map("i", ",", ",<c-g>u", { desc = "Insert Comma (Undo Breakpoint)" })
map("i", ".", ".<c-g>u", { desc = "Insert Period (Undo Breakpoint)" })
map("i", ";", ";<c-g>u", { desc = "Insert Semicolon (Undo Breakpoint)" })
map({ "i", "x", "n", "s" }, "<C-s>", "<cmd>w<cr><esc>", { desc = "Save File" })
map({ "i", "s" }, "<Tab>", accept_completion_tab, { expr = true, desc = "Accept Completion / Jump Snippet" })
map("i", "<C-Space>", function()
  if vim.lsp.completion then
    vim.lsp.completion.get()
  end
end, { desc = "Trigger Completion" })
map("x", "<", "<gv", { desc = "Indent Left and Reselect" })
map("x", ">", ">gv", { desc = "Indent Right and Reselect" })
map("n", "gco", "o<esc>Vcx<esc><cmd>normal gcc<cr>fxa<bs>", { desc = "Add Comment Below" })
map("n", "gcO", "O<esc>Vcx<esc><cmd>normal gcc<cr>fxa<bs>", { desc = "Add Comment Above" })
map("n", "<leader>fn", "<cmd>enew<cr>", { desc = "New Empty Buffer" })

map("n", "<leader>xl", function()
  local ok, err = pcall(vim.fn.getloclist(0, { winid = 0 }).winid ~= 0 and vim.cmd.lclose or vim.cmd.lopen)
  if not ok and err then
    vim.notify(err, vim.log.levels.ERROR)
  end
end, { desc = "Toggle Location List" })
map("n", "<leader>xq", function()
  local ok, err = pcall(vim.fn.getqflist({ winid = 0 }).winid ~= 0 and vim.cmd.cclose or vim.cmd.copen)
  if not ok and err then
    vim.notify(err, vim.log.levels.ERROR)
  end
end, { desc = "Toggle Quickfix List" })
map("n", "[q", vim.cmd.cprev, { desc = "Previous Quickfix Item" })
map("n", "]q", vim.cmd.cnext, { desc = "Next Quickfix Item" })

map({ "n", "x" }, "<leader>cf", function()
  format.format({ force = true })
end, { desc = "Format Buffer" })
map("n", "<leader>cd", vim.diagnostic.open_float, { desc = "Show Line Diagnostics" })
map("n", "]d", diagnostic_goto(true), { desc = "Next Diagnostic" })
map("n", "[d", diagnostic_goto(false), { desc = "Previous Diagnostic" })
map("n", "]e", diagnostic_goto(true, "ERROR"), { desc = "Next Error" })
map("n", "[e", diagnostic_goto(false, "ERROR"), { desc = "Previous Error" })
map("n", "]w", diagnostic_goto(true, "WARN"), { desc = "Next Warning" })
map("n", "[w", diagnostic_goto(false, "WARN"), { desc = "Previous Warning" })

format.snacks_toggle():map("<leader>uf")
format.snacks_toggle(true):map("<leader>uF")
Snacks.toggle.option("spell", { name = "Spelling" }):map("<leader>us")
Snacks.toggle.option("wrap", { name = "Wrap" }):map("<leader>uw")
Snacks.toggle.option("relativenumber", { name = "Relative Number" }):map("<leader>uL")
Snacks.toggle.diagnostics():map("<leader>ud")
Snacks.toggle.line_number():map("<leader>ul")
Snacks.toggle
  .option("conceallevel", { off = 0, on = vim.o.conceallevel > 0 and vim.o.conceallevel or 2, name = "Conceal Level" })
  :map("<leader>uc")
Snacks.toggle
  .option("showtabline", { off = 0, on = vim.o.showtabline > 0 and vim.o.showtabline or 2, name = "Tabline" })
  :map("<leader>uA")
Snacks.toggle.treesitter():map("<leader>uT")
Snacks.toggle.option("background", { off = "light", on = "dark", name = "Dark Background" }):map("<leader>ub")
Snacks.toggle.dim():map("<leader>uD")
Snacks.toggle.animate():map("<leader>ua")
Snacks.toggle.indent():map("<leader>ug")
Snacks.toggle.scroll():map("<leader>uS")
Snacks.toggle.profiler():map("<leader>dpp")
Snacks.toggle.profiler_highlights():map("<leader>dph")
if vim.lsp.inlay_hint then
  Snacks.toggle.inlay_hints():map("<leader>uh")
end
if vim.lsp.inline_completion then
  Snacks.toggle({
    name = "Inline Completion",
    get = function()
      return vim.lsp.inline_completion.is_enabled({ bufnr = 0 })
    end,
    set = function(state)
      vim.lsp.inline_completion.enable(state, { bufnr = 0 })
    end,
  }):map("<leader>ue")
end
if vim.fn.executable("lazygit") == 1 then
  map("n", "<leader>gg", function()
    Snacks.lazygit({ cwd = root.git() })
  end, { desc = "LazyGit (Root Dir)" })
  map("n", "<leader>gG", function()
    Snacks.lazygit()
  end, { desc = "LazyGit (CWD)" })
end
map("n", "<leader>gL", function()
  Snacks.picker.git_log()
end, { desc = "Open Git Log (CWD)" })
map("n", "<leader>gb", function()
  Snacks.picker.git_log_line()
end, { desc = "Show Git Blame for Line" })
map("n", "<leader>gf", function()
  Snacks.picker.git_log_file()
end, { desc = "Open Git File History" })
map("n", "<leader>gl", function()
  Snacks.picker.git_log({ cwd = root.git() })
end, { desc = "Open Git Log (Root Dir)" })
map({ "n", "x" }, "<leader>gB", function()
  Snacks.gitbrowse()
end, { desc = "Open Git Browse URL" })
map({ "n", "x" }, "<leader>gY", function()
  Snacks.gitbrowse({
    open = function(url)
      vim.fn.setreg("+", url)
    end,
    notify = false,
  })
end, { desc = "Copy Git Browse URL" })
map("n", "<leader>qq", "<cmd>qa<cr>", { desc = "Quit All Windows" })
map("n", "<leader>ui", vim.show_pos, { desc = "Inspect Cursor Position" })
map("n", "<leader>uI", function()
  vim.treesitter.inspect_tree()
  vim.api.nvim_input("I")
end, { desc = "Inspect Treesitter Tree" })
map("n", "<leader>fT", function()
  Snacks.terminal()
end, { desc = "Open Terminal (CWD)" })
map("n", "<leader>ft", function()
  Snacks.terminal(nil, { cwd = root.get() })
end, { desc = "Open Terminal (Root Dir)" })
map({ "n", "t" }, "<c-/>", function()
  Snacks.terminal.focus(nil, { cwd = root.get() })
end, { desc = "Focus Terminal (Root Dir)" })
map({ "n", "t" }, "<c-_>", function()
  Snacks.terminal.focus(nil, { cwd = root.get() })
end, { desc = "which_key_ignore" })
map("n", "<leader>wd", "<C-W>c", { desc = "Close Window", remap = true })
Snacks.toggle.zoom():map("<leader>wm"):map("<leader>uZ")
Snacks.toggle.zen():map("<leader>uz")
map("n", "<leader><tab>l", "<cmd>tablast<cr>", { desc = "Go to Last Tab" })
map("n", "<leader><tab>o", "<cmd>tabonly<cr>", { desc = "Close Other Tabs" })
map("n", "<leader><tab>f", "<cmd>tabfirst<cr>", { desc = "Go to First Tab" })
map("n", "<leader><tab><tab>", "<cmd>tabnew<cr>", { desc = "Open New Tab" })
map("n", "<leader><tab>]", "<cmd>tabnext<cr>", { desc = "Next Tab" })
map("n", "<leader><tab>d", "<cmd>tabclose<cr>", { desc = "Close Tab" })
map("n", "<leader><tab>[", "<cmd>tabprevious<cr>", { desc = "Previous Tab" })
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("config_lua_run_keymap", { clear = true }),
  pattern = "lua",
  callback = function(event)
    map({ "n", "x" }, "<localleader>r", function()
      Snacks.debug.run()
    end, { buffer = event.buf, desc = "Run Current Lua File" })
  end,
})
