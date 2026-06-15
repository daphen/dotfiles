return {
  "kitty-scrollback.nvim",
  after = function()
    require('kitty-scrollback').setup({
      {
        callbacks = {
          after_ready = function()
            vim.o.number = true
            vim.o.relativenumber = true
          end,
        },
      },
    })
  end,
}
