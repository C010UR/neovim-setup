vim.api.nvim_create_autocmd("LspProgress", {
  callback = function(ev)
    local value = ev.data.params.value or {}
    local msg = value.message or "done"

    if #msg > 40 then
      msg = msg:sub(1, 37) .. "..."
    end

    -- vim.api.nvim_echo({ { msg } }, false, {
    --   id = "lsp",
    --   kind = "progress",
    --   title = value.title,
    --   status = value.kind ~= "end" and "running" or "success",
    --   percent = value.percentage,
    -- })
  end,
})
