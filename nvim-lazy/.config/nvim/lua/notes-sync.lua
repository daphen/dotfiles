-- Auto-push notes on save
local notes_storage = vim.fn.expand("~/personal/notes/storage")

vim.api.nvim_create_autocmd("BufWritePost", {
  pattern = notes_storage .. "/*.md",
  callback = function()
    -- Run notes push in background
    vim.fn.jobstart({ "fish", "-c", "notes push" }, {
      detach = true,
      on_exit = function(_, code)
        if code == 0 then
          vim.notify("Notes synced", vim.log.levels.INFO, { title = "Notes" })
        end
      end,
    })
  end,
  desc = "Auto-push notes to server on save",
})
