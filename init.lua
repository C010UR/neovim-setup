-- Entry point for the local Neovim configuration.
-- Ensure the config root is on runtimepath even when loaded via `-u /path/to/init.lua`.
local init_path = debug.getinfo(1, "S").source:sub(2)
local config_root = vim.fs.dirname(vim.fs.normalize(init_path))
if not vim.tbl_contains(vim.opt.rtp:get(), config_root) then
  vim.opt.rtp:prepend(config_root)
end

-- Bootstraps the repo-owned vim.pack loader and plugin graph.
require("config.pack").setup()
