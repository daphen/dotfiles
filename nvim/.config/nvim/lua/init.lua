require("core.keymaps")
require("core.options")
require("notes-sync")

-- Own filetype for .mdx so render-markdown can target it (and the lz.n
-- ft trigger can fire) without fighting markview on plain markdown.
vim.filetype.add({ extension = { mdx = "mdx" } })

-- Skip in kitty-scrollback nvim — that's a pager, not an editor.
if vim.env.KITTY_SCROLLBACK_NVIM ~= "true" then
  require("hunk-nvim").setup()
  require("file-watcher").setup()

  -- Eager: session restore must hook VimEnter before it fires.
  vim.opt.sessionoptions:remove("terminal")
  -- Drop buffers from sessions — restoring 10+ files in a TS monorepo
  -- triggers a serial LSP-attach storm (10s+ blank screen). Layout/cwd/
  -- folds still restore.
  vim.opt.sessionoptions:remove("buffers")
  local auto_session = require("auto-session")
  auto_session.setup({
    auto_restore_enabled = true,
    auto_session_suppress_dirs = { "~/", "~/Dev/", "~/Downloads", "~/Documents", "~/Desktop/" },
    restore_error_handler = function(error_msg)
      if error_msg and error_msg:find("E216", 1, true) and error_msg:find("SessionLoadPre", 1, true) then
        return true
      end
      return auto_session.default_restore_error_handler(error_msg)
    end,
  })
  vim.keymap.set("n", "<leader>wr", "<cmd>SessionRestore<CR>", { desc = "Restore session for cwd" })

  local map = vim.keymap.set
  map("n", "<C-g>j", function() require("hunk-nvim.signs").next_hunk() end, { desc = "Next hunk" })
  map("n", "<C-g>k", function() require("hunk-nvim.signs").prev_hunk() end, { desc = "Prev hunk" })
end
